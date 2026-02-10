import AppKit
import SwiftUI

@MainActor
final class AppContainer {
    let overlayViewModel: OverlayViewModel
    let settingsViewModel: SettingsViewModel
    let onboardingViewModel: OnboardingViewModel
    let feedbackViewModel: FeedbackViewModel
    let themeModeStore: ThemeModeStore
    let appLocaleStore: AppLocaleStore

    private let orchestrator: AppOrchestrator
    private let statusBarController: StatusBarController
    private let overlayPanelController: OverlayPanelController
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

    private lazy var runtimeCoordinator = AppRuntimeCoordinator(
        orchestrator: orchestrator,
        settingsViewModel: settingsViewModel,
        themeModeStore: themeModeStore,
        appLocaleStore: appLocaleStore,
        statusBarController: statusBarController,
        overlayPanelController: overlayPanelController,
        overlayViewModel: overlayViewModel,
        onboardingViewModel: onboardingViewModel,
        windowCoordinator: windowCoordinator
    )

    init() {
        var onShowResultHandler: (@MainActor (ShowOverlayForCurrentAppUseCase.Result) -> Void)?

        let preferencesStore = UserDefaultsPreferencesStore()
        let shortcutRepository = AXMenuBarShortcutRepository()

        let overlayState = OverlaySceneState()

        let permissionChecker = AXPermissionChecker()
        let permissionGuide = SystemPermissionGuide()
        let appContextProvider = NSWorkspaceAppContextProvider()
        let overlayPresenter = OverlayScenePresenter(state: overlayState)
        let eventSource = NSEventGlobalHotkeySource()

        let activationPolicy = DefaultActivationPolicy()

        let evaluateActivation = EvaluateActivationUseCase(policy: activationPolicy)
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

        self.overlayViewModel = OverlayViewModel(
            state: overlayState,
            showOverlay: showOverlay,
            hideOverlay: hideOverlay
        )

        self.settingsViewModel = SettingsViewModel(
            loadPreferences: loadPreferences,
            updatePreferences: updatePreferences
        )
        self.themeModeStore = ThemeModeStore(initialTheme: settingsViewModel.selectedTheme)
        self.appLocaleStore = AppLocaleStore(initialLanguage: settingsViewModel.selectedLanguage)

        self.onboardingViewModel = OnboardingViewModel(
            loadPreferences: loadPreferences,
            getAccessibilityPermissionState: getAccessibilityPermissionState,
            requestAccessibilityPermission: requestAccessibilityPermission,
            openAccessibilitySettings: openAccessibilitySettings,
            updatePreferences: updatePreferences
        )
        self.feedbackViewModel = FeedbackViewModel(submitFeedbackUseCase: submitFeedback)

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
            onShowResult: { result in
                onShowResultHandler?(result)
            }
        )

        onShowResultHandler = { [weak self] result in
            self?.runtimeCoordinator.handleShowResult(result)
        }
    }

    func start() {
        runtimeCoordinator.start()
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
