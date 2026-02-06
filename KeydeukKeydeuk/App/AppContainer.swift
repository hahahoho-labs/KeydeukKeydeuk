import AppKit
import Combine
import Foundation
import os
import SwiftUI

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "AppContainer")

@MainActor
final class AppContainer {
    let overlayViewModel: OverlayViewModel

    private let orchestrator: AppOrchestrator
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
            policy: activationPolicy,
            preferencesStore: preferencesStore
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

        self.overlayViewModel = OverlayViewModel(
            state: overlayState,
            loadPreferences: loadPreferences,
            getAccessibilityPermissionState: getAccessibilityPermissionState,
            requestAccessibilityPermission: requestAccessibilityPermission,
            showOverlay: showOverlay,
            hideOverlay: hideOverlay,
            updatePreferencesUseCase: updatePreferences,
            openAccessibilitySettings: openAccessibilitySettings
        )
        self.overlayPanelController = OverlayPanelController(state: overlayState, viewModel: overlayViewModel)

        self.orchestrator = AppOrchestrator(
            eventSource: eventSource,
            evaluateActivation: evaluateActivation,
            showOverlay: showOverlay,
            hideOverlay: hideOverlay,
            preferencesStore: preferencesStore,
            onShowResult: { [weak overlayViewModel] result in
                overlayViewModel?.handle(showResult: result)
            }
        )

        self.statusBarController = StatusBarController()
        self.statusBarController.onPrimaryClick = { [weak self, weak overlayViewModel] in
            guard let self else { return }
            guard let overlayViewModel else { return }
            log.info("🖱️ StatusBar 좌클릭 — 오버레이 표시 시도")
            Task { @MainActor in
                await overlayViewModel.requestShow()
                if overlayViewModel.isVisible {
                    log.info("✅ 오버레이 표시 성공")
                    return
                }

                if overlayViewModel.needsOnboarding {
                    log.warning("⚠️ 온보딩 미완료 — 온보딩 창 표시")
                    NSApp.activate(ignoringOtherApps: true)
                    self.bringMainWindowToFront()
                } else if overlayViewModel.permissionState != .granted {
                    // 권한 미허용 → 프롬프트만 띄우고, 허용 후 복귀 시 자동 오버레이
                    log.info("🔒 접근성 권한 미허용 — 권한 프롬프트 표시, 허용 대기")
                    self.pendingOverlayAfterPermission = true
                    overlayViewModel.requestAccessibilityPermissionPrompt()
                } else {
                    log.warning("⚠️ 오버레이 표시 실패 — fallback: 설정 창 표시")
                    NSApp.activate(ignoringOtherApps: true)
                    self.presentSettingsWindow()
                }
            }
        }
        self.statusBarController.onSettingsClick = { [weak self, weak overlayViewModel] in
            guard let self else { return }
            NSApp.activate(ignoringOtherApps: true)
            self.presentSettingsWindow()
            if self.settingsWindowController == nil {
                overlayViewModel?.showInfoMessage("Unable to open Settings window.")
            }
        }

        overlayViewModel.$needsOnboarding
            .removeDuplicates()
            .sink { [weak self] needsOnboarding in
                self?.applyAppPresentation(needsOnboarding: needsOnboarding)
            }
            .store(in: &cancellables)

        // 앱 활성화 시 권한 허용 대기 상태면 자동으로 오버레이 표시 시도
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self, weak overlayViewModel] _ in
                guard let self, let overlayViewModel else { return }
                guard self.pendingOverlayAfterPermission else { return }
                overlayViewModel.refreshPermissionState()
                guard overlayViewModel.permissionState == .granted else { return }
                self.pendingOverlayAfterPermission = false
                log.info("✅ 권한 허용 확인 — 오버레이 자동 표시")
                Task { @MainActor in
                    await overlayViewModel.requestShow()
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        overlayViewModel.refreshPreferences()
        overlayPanelController.start()
        statusBarController.start()
        orchestrator.start()
        applyAppPresentation(needsOnboarding: overlayViewModel.needsOnboarding)

        // WindowGroup can be created after start(); re-apply presentation on next runloop.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.applyAppPresentation(needsOnboarding: self.overlayViewModel.needsOnboarding)
        }
    }

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

        let host = NSHostingController(rootView: SettingsWindowView(viewModel: overlayViewModel))
        let window = NSWindow(contentViewController: host)
        window.title = "Settings"
        window.styleMask = NSWindow.StyleMask([.titled, .closable, .miniaturizable])
        window.setContentSize(NSSize(width: 620, height: 480))
        window.center()
        let controller = NSWindowController(window: window)
        controller.showWindow(nil)
        settingsWindowController = controller
    }
}
