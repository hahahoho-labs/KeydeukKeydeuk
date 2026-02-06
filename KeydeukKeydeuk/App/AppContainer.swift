import Foundation

@MainActor
final class AppContainer {
    let overlayViewModel: OverlayViewModel

    private let orchestrator: AppOrchestrator

    init() {
        let preferencesStore = UserDefaultsPreferencesStore()
        let shortcutRepository = JSONCatalogRepository()

        let overlayState = OverlaySceneState()

        let permissionChecker = AXPermissionChecker()
        let appContextProvider = NSWorkspaceAppContextProvider()
        let overlayPresenter = OverlayWindowHost(state: overlayState)
        let eventSource = NSEventGlobalHotkeySource()

        let activationPolicy = DefaultActivationPolicy()

        let evaluateActivation = EvaluateActivationUseCase(
            policy: activationPolicy,
            preferencesStore: preferencesStore
        )
        let loadShortcuts = LoadShortcutsForAppUseCase(repository: shortcutRepository)
        let showOverlay = ShowOverlayForCurrentAppUseCase(
            permissionChecker: permissionChecker,
            appContextProvider: appContextProvider,
            loadShortcuts: loadShortcuts,
            presenter: overlayPresenter
        )
        let hideOverlay = HideOverlayUseCase(presenter: overlayPresenter)
        let updatePreferences = UpdatePreferencesUseCase(preferencesStore: preferencesStore)

        self.overlayViewModel = OverlayViewModel(
            state: overlayState,
            showOverlay: showOverlay,
            hideOverlay: hideOverlay,
            updatePreferences: updatePreferences
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
    }

    func start() {
        orchestrator.start()
    }
}
