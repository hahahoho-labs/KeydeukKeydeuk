import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var permissionState: PermissionState
    @Published private(set) var permissionHint: String?
    @Published private(set) var needsOnboarding: Bool

    private let getAccessibilityPermissionState: GetAccessibilityPermissionStateUseCase
    private let requestAccessibilityPermission: RequestAccessibilityPermissionUseCase
    private let openAccessibilitySettings: OpenAccessibilitySettingsUseCase
    private let updatePreferencesUseCase: UpdatePreferencesUseCase
    private let loadPreferences: LoadPreferencesUseCase

    var canFinishOnboarding: Bool { permissionState == .granted }

    init(
        loadPreferences: LoadPreferencesUseCase,
        getAccessibilityPermissionState: GetAccessibilityPermissionStateUseCase,
        requestAccessibilityPermission: RequestAccessibilityPermissionUseCase,
        openAccessibilitySettings: OpenAccessibilitySettingsUseCase,
        updatePreferences: UpdatePreferencesUseCase
    ) {
        self.loadPreferences = loadPreferences
        self.getAccessibilityPermissionState = getAccessibilityPermissionState
        self.requestAccessibilityPermission = requestAccessibilityPermission
        self.openAccessibilitySettings = openAccessibilitySettings
        self.updatePreferencesUseCase = updatePreferences

        let initialPreferences = loadPreferences.execute()
        self.permissionState = getAccessibilityPermissionState.execute()
        self.needsOnboarding = !initialPreferences.hasCompletedOnboarding
    }

    // MARK: - Actions

    func refreshPermissionState() {
        permissionState = getAccessibilityPermissionState.execute()
    }

    func requestAccessibilityPermissionPrompt() {
        let isGranted = requestAccessibilityPermission.execute()
        refreshPermissionState()
        if isGranted || permissionState == .granted {
            permissionHint = nil
            return
        }
        permissionHint = "Permission request sent. If no prompt appears, click 'Open System Settings' to add this app manually."
    }

    func openAccessibilityPreferences() {
        openAccessibilitySettings.execute()
    }

    func showInfoMessage(_ message: String) {
        permissionHint = message
    }

    func completeOnboardingIfPossible() {
        refreshPermissionState()
        guard canFinishOnboarding else {
            permissionHint = "Please grant Accessibility permission to finish onboarding."
            return
        }

        var prefs = loadPreferences.execute()
        prefs.hasCompletedOnboarding = true
        do {
            try updatePreferencesUseCase.execute(prefs)
            needsOnboarding = false
            permissionHint = nil
        } catch {
            permissionHint = "Failed to save onboarding state."
        }
    }

    func refreshOnboardingState() {
        let prefs = loadPreferences.execute()
        needsOnboarding = !prefs.hasCompletedOnboarding
        refreshPermissionState()
    }
}
