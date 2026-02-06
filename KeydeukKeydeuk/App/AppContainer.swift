import AppKit
import Combine
import Foundation

@MainActor
final class AppContainer {
    let overlayViewModel: OverlayViewModel

    private let orchestrator: AppOrchestrator
    private let statusBarController: StatusBarController
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let preferencesStore = UserDefaultsPreferencesStore()
        let shortcutRepository = JSONCatalogRepository()

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
            showOverlay: showOverlay,
            hideOverlay: hideOverlay,
            updatePreferencesUseCase: updatePreferences,
            openAccessibilitySettings: openAccessibilitySettings
        )

        self.orchestrator = AppOrchestrator(
            eventSource: eventSource,
            evaluateActivation: evaluateActivation,
            showOverlay: showOverlay,
            hideOverlay: hideOverlay,
            onShowResult: { [weak overlayViewModel] result in
                overlayViewModel?.handle(showResult: result)
            }
        )

        self.statusBarController = StatusBarController()
        self.statusBarController.onPrimaryClick = { [weak overlayViewModel] in
            guard let overlayViewModel else { return }
            Task { @MainActor in
                await overlayViewModel.requestShow()
            }
        }
        self.statusBarController.onSettingsClick = { [weak overlayViewModel] in
            // Settings window is planned next. Bring app forward for now.
            NSApp.activate(ignoringOtherApps: true)
            overlayViewModel?.showInfoMessage("Settings window is coming soon.")
        }

        overlayViewModel.$needsOnboarding
            .removeDuplicates()
            .sink { [weak self] needsOnboarding in
                self?.applyAppPresentation(needsOnboarding: needsOnboarding)
            }
            .store(in: &cancellables)
    }

    func start() {
        overlayViewModel.refreshPreferences()
        statusBarController.start()
        orchestrator.start()
        applyAppPresentation(needsOnboarding: overlayViewModel.needsOnboarding)
    }

    private func applyAppPresentation(needsOnboarding: Bool) {
        if needsOnboarding {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        NSApp.setActivationPolicy(.accessory)
        NSApp.windows.forEach { $0.close() }
    }
}
