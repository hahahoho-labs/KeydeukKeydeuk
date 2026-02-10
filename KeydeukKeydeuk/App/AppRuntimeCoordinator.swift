import AppKit
import Combine
import Foundation
import os

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "AppRuntime")

@MainActor
final class AppRuntimeCoordinator {
    private let orchestrator: AppOrchestrator
    private let settingsViewModel: SettingsViewModel
    private let themeModeStore: ThemeModeStore
    private let appLocaleStore: AppLocaleStore
    private let statusBarController: StatusBarController
    private let overlayPanelController: OverlayPanelController
    private let overlayViewModel: OverlayViewModel
    private let onboardingViewModel: OnboardingViewModel
    private let windowCoordinator: AppWindowCoordinator

    private var pendingOverlayAfterPermission = false
    private var cancellables: Set<AnyCancellable> = []

    init(
        orchestrator: AppOrchestrator,
        settingsViewModel: SettingsViewModel,
        themeModeStore: ThemeModeStore,
        appLocaleStore: AppLocaleStore,
        statusBarController: StatusBarController,
        overlayPanelController: OverlayPanelController,
        overlayViewModel: OverlayViewModel,
        onboardingViewModel: OnboardingViewModel,
        windowCoordinator: AppWindowCoordinator
    ) {
        self.orchestrator = orchestrator
        self.settingsViewModel = settingsViewModel
        self.themeModeStore = themeModeStore
        self.appLocaleStore = appLocaleStore
        self.statusBarController = statusBarController
        self.overlayPanelController = overlayPanelController
        self.overlayViewModel = overlayViewModel
        self.onboardingViewModel = onboardingViewModel
        self.windowCoordinator = windowCoordinator

        bindPreferences()
        bindStatusBarActions()
        bindOnboardingStateChanges()
        bindAppDidBecomeActive()
    }

    func start() {
        settingsViewModel.refreshPreferences()
        overlayPanelController.start()
        statusBarController.start()
        updateStatusBarTexts()
        orchestrator.start()

        windowCoordinator.applyPresentation(needsOnboarding: onboardingViewModel.needsOnboarding)

        // WindowGroup can be created after start(); re-apply presentation on next runloop.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.windowCoordinator.applyPresentation(needsOnboarding: self.onboardingViewModel.needsOnboarding)
        }
    }

    func handleShowResult(_ result: ShowOverlayForCurrentAppUseCase.Result) {
        switch result {
        case .shown, .noCatalog:
            break
        case .needsPermission:
            onboardingViewModel.showInfoMessage(key: "overlay.error.permission_required")
        case .noFocusedApp:
            onboardingViewModel.showInfoMessage(key: "overlay.error.focused_app_unavailable")
        }
    }

    private func bindPreferences() {
        settingsViewModel.$preferences
            .dropFirst() // 초기값은 이미 orchestrator initialPreferences로 전달됨
            .sink { [weak self] prefs in
                guard let self else { return }
                self.orchestrator.updatePreferences(prefs)
                self.themeModeStore.update(theme: prefs.theme)
                self.appLocaleStore.update(language: prefs.language)
                self.updateStatusBarTexts()
                self.windowCoordinator.updateSettingsWindowTitle(self.settingsWindowTitle())
            }
            .store(in: &cancellables)
    }

    private func bindStatusBarActions() {
        statusBarController.onPrimaryClick = { [weak self] in
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
                    log.info("🔒 접근성 권한 미허용 — 권한 프롬프트 표시, 허용 대기")
                    self.pendingOverlayAfterPermission = true
                    self.onboardingViewModel.requestAccessibilityPermissionPrompt()
                } else {
                    log.warning("⚠️ 오버레이 표시 실패 — fallback: 설정 창 표시")
                    self.windowCoordinator.presentSettingsWindow(title: self.settingsWindowTitle())
                }
            }
        }

        statusBarController.onSettingsClick = { [weak self] in
            guard let self else { return }
            self.windowCoordinator.presentSettingsWindow(title: self.settingsWindowTitle())
        }
    }

    private func bindOnboardingStateChanges() {
        onboardingViewModel.$needsOnboarding
            .dropFirst() // init 중 즉시 방출 무시 → start()에서 수동 호출
            .removeDuplicates()
            .sink { [weak self] needsOnboarding in
                self?.windowCoordinator.applyPresentation(needsOnboarding: needsOnboarding)
            }
            .store(in: &cancellables)
    }

    private func bindAppDidBecomeActive() {
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
