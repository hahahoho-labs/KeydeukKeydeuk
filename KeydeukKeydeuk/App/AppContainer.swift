import AppKit
import Combine
import Foundation
import os
import SwiftUI

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "AppContainer")

@MainActor
final class AppContainer {
    let overlayViewModel: OverlayViewModel
    let settingsViewModel: SettingsViewModel
    let onboardingViewModel: OnboardingViewModel
    let feedbackViewModel: FeedbackViewModel
    let themeModeStore: ThemeModeStore

    private var orchestrator: AppOrchestrator?
    private let statusBarController: StatusBarController
    private let overlayPanelController: OverlayPanelController
    private var settingsWindowController: NSWindowController?
    private var pendingOverlayAfterPermission = false
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let preferencesStore = UserDefaultsPreferencesStore()
        let shortcutRepository = AXMenuBarShortcutRepository()

        let overlayState = OverlaySceneState()

        let permissionChecker = AXPermissionChecker()
        let permissionGuide = SystemPermissionGuide()
        let appContextProvider = NSWorkspaceAppContextProvider()
        let overlayPresenter = OverlayWindowHost(state: overlayState)
        let eventSource = NSEventGlobalHotkeySource()

        let activationPolicy = DefaultActivationPolicy()

        let evaluateActivation = EvaluateActivationUseCase(
            policy: activationPolicy
        )
        let loadShortcuts = LoadShortcutsForAppUseCase(repository: shortcutRepository)
        let loadPreferences = LoadPreferencesUseCase(preferencesStore: preferencesStore)
        let getAccessibilityPermissionState = GetAccessibilityPermissionStateUseCase(permissionChecker: permissionChecker)
        let requestAccessibilityPermission = RequestAccessibilityPermissionUseCase(permissionGuide: permissionGuide)
        let showOverlay = ShowOverlayForCurrentAppUseCase(
            permissionChecker: permissionChecker,
            appContextProvider: appContextProvider,
            loadShortcuts: loadShortcuts,
            presenter: overlayPresenter
        )
        let hideOverlay = HideOverlayUseCase(presenter: overlayPresenter)
        let updatePreferences = UpdatePreferencesUseCase(preferencesStore: preferencesStore)
        let openAccessibilitySettings = OpenAccessibilitySettingsUseCase(permissionGuide: permissionGuide)
        let feedbackDiagnosticsProvider = AppFeedbackDiagnosticsProvider()
        let feedbackSubmissionService = SupabaseFeedbackService()
        let submitFeedback = SubmitFeedbackUseCase(
            feedbackSubmissionService: feedbackSubmissionService,
            diagnosticsProvider: feedbackDiagnosticsProvider
        )

        // ViewModel 조립
        self.overlayViewModel = OverlayViewModel(
            state: overlayState,
            showOverlay: showOverlay,
            hideOverlay: hideOverlay
        )

        self.settingsViewModel = SettingsViewModel(
            loadPreferences: loadPreferences,
            updatePreferences: updatePreferences
        )
        self.themeModeStore = ThemeModeStore(
            initialTheme: settingsViewModel.selectedTheme
        )

        self.onboardingViewModel = OnboardingViewModel(
            loadPreferences: loadPreferences,
            getAccessibilityPermissionState: getAccessibilityPermissionState,
            requestAccessibilityPermission: requestAccessibilityPermission,
            openAccessibilitySettings: openAccessibilitySettings,
            updatePreferences: updatePreferences
        )
        self.feedbackViewModel = FeedbackViewModel(
            submitFeedbackUseCase: submitFeedback
        )

        self.overlayPanelController = OverlayPanelController(
            state: overlayState,
            viewModel: overlayViewModel,
            themeModeStore: themeModeStore
        )
        self.statusBarController = StatusBarController()

        self.orchestrator = AppOrchestrator(
            eventSource: eventSource,
            evaluateActivation: evaluateActivation,
            showOverlay: showOverlay,
            hideOverlay: hideOverlay,
            initialPreferences: settingsViewModel.preferences,
            onShowResult: { [weak self] result in
                self?.handleShowResult(result)
            }
        )

        // 설정 변경 시 Orchestrator에 전파 (Store 직접 참조 대신 Combine 구독)
        settingsViewModel.$preferences
            .dropFirst() // 초기값은 이미 initialPreferences로 전달됨
            .sink { [weak self] prefs in
                self?.orchestrator?.updatePreferences(prefs)
                self?.themeModeStore.update(theme: prefs.theme)
            }
            .store(in: &cancellables)
        self.statusBarController.onPrimaryClick = { [weak self] in
            guard let self else { return }
            log.info("🖱️ StatusBar 좌클릭 — 오버레이 표시 시도")
            Task { @MainActor in
                let result = await self.overlayViewModel.requestShow()
                if result == .shown {
                    log.info("✅ 오버레이 표시 성공")
                    return
                }

                if self.onboardingViewModel.needsOnboarding {
                    log.warning("⚠️ 온보딩 미완료 — 온보딩 창 표시")
                    NSApp.activate(ignoringOtherApps: true)
                    self.bringMainWindowToFront()
                } else if self.onboardingViewModel.permissionState != .granted {
                    // 권한 미허용 → 프롬프트만 띄우고, 허용 후 복귀 시 자동 오버레이
                    log.info("🔒 접근성 권한 미허용 — 권한 프롬프트 표시, 허용 대기")
                    self.pendingOverlayAfterPermission = true
                    self.onboardingViewModel.requestAccessibilityPermissionPrompt()
                } else {
                    log.warning("⚠️ 오버레이 표시 실패 — fallback: 설정 창 표시")
                    NSApp.activate(ignoringOtherApps: true)
                    self.presentSettingsWindow()
                }
            }
        }
        self.statusBarController.onSettingsClick = { [weak self] in
            guard let self else { return }
            NSApp.activate(ignoringOtherApps: true)
            self.presentSettingsWindow()
        }

        onboardingViewModel.$needsOnboarding
            .dropFirst() // init 중 즉시 방출 무시 → start()에서 수동 호출
            .removeDuplicates()
            .sink { [weak self] needsOnboarding in
                self?.applyAppPresentation(needsOnboarding: needsOnboarding)
            }
            .store(in: &cancellables)

        // 앱 활성화 시 권한 허용 대기 상태면 자동으로 오버레이 표시 시도
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.pendingOverlayAfterPermission else { return }
                self.onboardingViewModel.refreshPermissionState()
                guard self.onboardingViewModel.permissionState == .granted else { return }
                self.pendingOverlayAfterPermission = false
                log.info("✅ 권한 허용 확인 — 오버레이 자동 표시")
                Task { @MainActor in
                    _ = await self.overlayViewModel.requestShow()
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        settingsViewModel.refreshPreferences()
        overlayPanelController.start()
        statusBarController.start()
        orchestrator?.start()
        applyAppPresentation(needsOnboarding: onboardingViewModel.needsOnboarding)

        // WindowGroup can be created after start(); re-apply presentation on next runloop.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.applyAppPresentation(needsOnboarding: self.onboardingViewModel.needsOnboarding)
        }
    }

    // MARK: - Show Result Routing

    private func handleShowResult(_ result: ShowOverlayForCurrentAppUseCase.Result) {
        switch result {
        case .shown, .noCatalog:
            break
        case .needsPermission:
            onboardingViewModel.showInfoMessage("Accessibility permission is required to show shortcuts.")
        case .noFocusedApp:
            onboardingViewModel.showInfoMessage("Could not detect the focused application.")
        }
    }

    // MARK: - App Presentation

    private func applyAppPresentation(needsOnboarding: Bool) {
        if needsOnboarding {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            bringMainWindowToFront()
            return
        }

        NSApp.setActivationPolicy(.accessory)
        overlayPanelController.hide()
        NSApp.windows.forEach { $0.orderOut(nil) }
    }

    private func bringMainWindowToFront() {
        if let window = NSApp.windows.first(where: { $0.title == "Onboarding" || $0.title == "KeydeukKeydeuk" }) {
            window.makeKeyAndOrderFront(nil)
            return
        }
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    private func presentSettingsWindow() {
        if let existingWindow = settingsWindowController?.window {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let host = NSHostingController(
            rootView: SettingsWindowView(
                settingsVM: settingsViewModel,
                onboardingVM: onboardingViewModel,
                feedbackVM: feedbackViewModel,
                themeModeStore: themeModeStore
            )
        )
        let window = NSWindow(contentViewController: host)
        window.title = "Settings"
        window.styleMask = NSWindow.StyleMask([.titled, .closable, .miniaturizable])
        window.setContentSize(NSSize(width: 760, height: 560))
        window.center()
        let controller = NSWindowController(window: window)
        controller.showWindow(nil)
        settingsWindowController = controller
    }
}
