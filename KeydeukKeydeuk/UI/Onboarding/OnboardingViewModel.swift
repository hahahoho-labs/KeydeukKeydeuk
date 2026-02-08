import Combine
import AppKit
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
    private var cancellables: Set<AnyCancellable> = []
    private var permissionPollingCancellable: AnyCancellable?

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

        // View lifecycle에 의존하지 않고 앱 복귀 시 권한 상태를 항상 동기화한다.
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshPermissionState()
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func refreshPermissionState() {
        permissionState = getAccessibilityPermissionState.execute()
        if permissionState == .granted {
            permissionHint = nil
        }
    }

    func requestAccessibilityPermissionPrompt() {
        let isGranted = requestAccessibilityPermission.execute()
        refreshPermissionState()
        if isGranted || permissionState == .granted {
            permissionHint = nil
            return
        }
        permissionHint = "Permission request sent. If no prompt appears, allow KeydeukKeydeuk in System Settings > Privacy & Security > Accessibility."
        startPermissionStatePolling()
    }

    func openAccessibilityPreferences() {
        openAccessibilitySettings.execute()
        startPermissionStatePolling()
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

    private func startPermissionStatePolling() {
        permissionPollingCancellable?.cancel()

        let start = Date()
        permissionPollingCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.refreshPermissionState()

                let elapsed = Date().timeIntervalSince(start)
                if self.permissionState == .granted || elapsed >= 20 {
                    self.permissionPollingCancellable?.cancel()
                    self.permissionPollingCancellable = nil
                }
            }
    }
}
