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
    let appLocaleStore: AppLocaleStore

    private var orchestrator: AppOrchestrator?
    private let statusBarController: StatusBarController
    private let overlayPanelController: OverlayPanelController
    private var pendingOverlayAfterPermission = false
    private var cancellables: Set<AnyCancellable> = []
    private lazy var windowCoordinator = AppWindowCoordinator(
        overlayPanelController: overlayPanelController,
        makeSettingsRootView: { [weak self] in
            guard let self else { return AnyView(EmptyView()) }
            return AnyView(
                SettingsWindowRootView(
                    settingsVM: self.settingsViewModel,
                    onboardingVM: self.onboardingViewModel,
                    feedbackVM: self.feedbackViewModel,
                    themeModeStore: self.themeModeStore,
                    localeStore: self.appLocaleStore
                )
            )
        }
    )

    init() {
        let preferencesStore = UserDefaultsPreferencesStore()
        let shortcutRepository = AXMenuBarShortcutRepository()

        let overlayState = OverlaySceneState()

        let permissionChecker = AXPermissionChecker()
        let permissionGuide = SystemPermissionGuide()
        let appContextProvider = NSWorkspaceAppContextProvider()
        let overlayPresenter = OverlayScenePresenter(state: overlayState)
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
        let installationIDProvider = UserDefaultsInstallationIDProvider()
        let feedbackSubmissionService = SupabaseFeedbackService()
        let submitFeedback = SubmitFeedbackUseCase(
            feedbackSubmissionService: feedbackSubmissionService,
            diagnosticsProvider: feedbackDiagnosticsProvider,
            installationIDProvider: installationIDProvider
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
        self.appLocaleStore = AppLocaleStore(
            initialLanguage: settingsViewModel.selectedLanguage
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
            themeModeStore: themeModeStore,
            localeStore: appLocaleStore
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
                self?.appLocaleStore.update(language: prefs.language)
                if let self {
                    self.updateStatusBarTexts()
                    self.windowCoordinator.updateSettingsWindowTitle(self.settingsWindowTitle())
                }
            }
            .store(in: &cancellables)
        self.statusBarController.onPrimaryClick = { [weak self] in
            guard let self else { return }
            log.info("🖱️ StatusBar 좌클릭 — 오버레이 표시 시도")
            Task { @MainActor in
                let result = await self.overlayViewModel.requestShow()
                if result == .shown || result == .noCatalog {
                    log.info("✅ 오버레이 표시 성공")
                    return
                }

                if self.onboardingViewModel.needsOnboarding {
                    log.warning("⚠️ 온보딩 미완료 — 온보딩 창 표시")
                    self.windowCoordinator.showOnboardingWindow()
                } else if self.onboardingViewModel.permissionState != .granted {
                    // 권한 미허용 → 프롬프트만 띄우고, 허용 후 복귀 시 자동 오버레이
                    log.info("🔒 접근성 권한 미허용 — 권한 프롬프트 표시, 허용 대기")
                    self.pendingOverlayAfterPermission = true
                    self.onboardingViewModel.requestAccessibilityPermissionPrompt()
                } else {
                    log.warning("⚠️ 오버레이 표시 실패 — fallback: 설정 창 표시")
                    self.windowCoordinator.presentSettingsWindow(title: self.settingsWindowTitle())
                }
            }
        }
        self.statusBarController.onSettingsClick = { [weak self] in
            guard let self else { return }
            self.windowCoordinator.presentSettingsWindow(title: self.settingsWindowTitle())
        }

        onboardingViewModel.$needsOnboarding
            .dropFirst() // init 중 즉시 방출 무시 → start()에서 수동 호출
            .removeDuplicates()
            .sink { [weak self] needsOnboarding in
                self?.windowCoordinator.applyPresentation(needsOnboarding: needsOnboarding)
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
        updateStatusBarTexts()
        orchestrator?.start()
        windowCoordinator.applyPresentation(needsOnboarding: onboardingViewModel.needsOnboarding)

        // WindowGroup can be created after start(); re-apply presentation on next runloop.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.windowCoordinator.applyPresentation(needsOnboarding: self.onboardingViewModel.needsOnboarding)
        }
    }

    // MARK: - Show Result Routing

    private func handleShowResult(_ result: ShowOverlayForCurrentAppUseCase.Result) {
        switch result {
        case .shown, .noCatalog:
            break
        case .needsPermission:
            onboardingViewModel.showInfoMessage(key: "overlay.error.permission_required")
        case .noFocusedApp:
            onboardingViewModel.showInfoMessage(key: "overlay.error.focused_app_unavailable")
        }
    }

    private func updateStatusBarTexts() {
        let locale = appLocaleStore.locale
        statusBarController.updateMenuTitles(
            settings: L10n.text("statusbar.menu.settings", locale: locale, fallback: "Settings"),
            quit: L10n.text("statusbar.menu.quit", locale: locale, fallback: "Quit")
        )
    }

    private func settingsWindowTitle() -> String {
        L10n.text("settings.window.title", locale: appLocaleStore.locale, fallback: "Settings")
    }
}

private struct SettingsWindowRootView: View {
    @ObservedObject var settingsVM: SettingsViewModel
    @ObservedObject var onboardingVM: OnboardingViewModel
    @ObservedObject var feedbackVM: FeedbackViewModel
    @ObservedObject var themeModeStore: ThemeModeStore
    @ObservedObject var localeStore: AppLocaleStore

    var body: some View {
        SettingsWindowView(
            settingsVM: settingsVM,
            onboardingVM: onboardingVM,
            feedbackVM: feedbackVM,
            themeModeStore: themeModeStore
        )
        .environment(\.locale, localeStore.locale)
    }
}
