import Combine
import Foundation

@MainActor
final class OverlayViewModel: ObservableObject {
    struct HotkeyPreset: Identifiable, Equatable {
        let id: String
        let title: String
        let keyCode: Int
        let modifiers: KeyModifiers
    }

    @Published var query = ""
    @Published private(set) var permissionHint: String?
    @Published private(set) var preferences: Preferences
    @Published private(set) var permissionState: PermissionState
    @Published private(set) var needsOnboarding: Bool

    private let state: OverlaySceneState
    private let loadPreferences: LoadPreferencesUseCase
    private let getAccessibilityPermissionState: GetAccessibilityPermissionStateUseCase
    private let requestAccessibilityPermission: RequestAccessibilityPermissionUseCase
    private let showOverlay: ShowOverlayForCurrentAppUseCase
    private let hideOverlay: HideOverlayUseCase
    private let updatePreferencesUseCase: UpdatePreferencesUseCase
    private let openAccessibilitySettings: OpenAccessibilitySettingsUseCase

    let hotkeyPresets: [HotkeyPreset] = [
        HotkeyPreset(id: "cmd-shift-k", title: "Command + Shift + K", keyCode: 40, modifiers: [.command, .shift]),
        HotkeyPreset(id: "cmd-shift-l", title: "Command + Shift + L", keyCode: 37, modifiers: [.command, .shift]),
        HotkeyPreset(id: "cmd-shift-j", title: "Command + Shift + J", keyCode: 38, modifiers: [.command, .shift])
    ]

    init(
        state: OverlaySceneState,
        loadPreferences: LoadPreferencesUseCase,
        getAccessibilityPermissionState: GetAccessibilityPermissionStateUseCase,
        requestAccessibilityPermission: RequestAccessibilityPermissionUseCase,
        showOverlay: ShowOverlayForCurrentAppUseCase,
        hideOverlay: HideOverlayUseCase,
        updatePreferencesUseCase: UpdatePreferencesUseCase,
        openAccessibilitySettings: OpenAccessibilitySettingsUseCase
    ) {
        self.state = state
        self.loadPreferences = loadPreferences
        self.getAccessibilityPermissionState = getAccessibilityPermissionState
        self.requestAccessibilityPermission = requestAccessibilityPermission
        self.showOverlay = showOverlay
        self.hideOverlay = hideOverlay
        self.updatePreferencesUseCase = updatePreferencesUseCase
        self.openAccessibilitySettings = openAccessibilitySettings

        let initialPreferences = loadPreferences.execute()
        self.preferences = initialPreferences
        self.permissionState = getAccessibilityPermissionState.execute()
        self.needsOnboarding = !initialPreferences.hasCompletedOnboarding
    }

    var isVisible: Bool { state.isVisible }
    var appName: String { state.appName }
    var autoHideOnEsc: Bool { preferences.autoHideOnEsc }
    var autoHideOnAppSwitch: Bool { preferences.autoHideOnAppSwitch }
    var canFinishOnboarding: Bool { permissionState == .granted }

    var selectedHotkeyPresetID: String {
        hotkeyPresets.first {
            $0.keyCode == preferences.hotkeyKeyCode && $0.modifiers == preferences.hotkeyModifiers
        }?.id ?? hotkeyPresets[0].id
    }

    var filteredShortcuts: [Shortcut] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return state.shortcuts }

        return state.shortcuts.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.keys.localizedCaseInsensitiveContains(trimmed)
                || ($0.section?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    func refreshPreferences() {
        preferences = loadPreferences.execute()
        needsOnboarding = !preferences.hasCompletedOnboarding
        refreshPermissionState()
    }

    func refreshPermissionState() {
        permissionState = getAccessibilityPermissionState.execute()
    }

    func requestShow() async {
        let result = await showOverlay.execute()
        handle(showResult: result)
    }

    func requestHide() {
        hideOverlay.execute()
    }

    func requestAccessibilityPermissionPrompt() {
        let isGranted = requestAccessibilityPermission.execute()
        refreshPermissionState()
        if isGranted || permissionState == .granted {
            permissionHint = nil
            return
        }
        permissionHint = "Permission request sent. If no prompt appears, open Accessibility Settings and add this app manually."
        openAccessibilityPreferences()
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

        updatePreferences { current in
            current.hasCompletedOnboarding = true
        }
        needsOnboarding = false
        permissionHint = nil
    }

    func handle(showResult: ShowOverlayForCurrentAppUseCase.Result) {
        switch showResult {
        case .shown:
            permissionHint = nil
        case .needsPermission:
            permissionHint = "Accessibility permission is required."
        case .noFocusedApp:
            permissionHint = "No focused app detected."
        case .noCatalog:
            permissionHint = "No shortcut catalog for this app yet."
        }
    }

    func selectHotkeyPreset(id: String) {
        guard let preset = hotkeyPresets.first(where: { $0.id == id }) else { return }
        updatePreferences { current in
            current.hotkeyKeyCode = preset.keyCode
            current.hotkeyModifiersRawValue = preset.modifiers.rawValue
        }
    }

    func setAutoHideOnEsc(_ isOn: Bool) {
        updatePreferences { current in
            current.autoHideOnEsc = isOn
        }
    }

    func setAutoHideOnAppSwitch(_ isOn: Bool) {
        updatePreferences { current in
            current.autoHideOnAppSwitch = isOn
        }
    }

    private func updatePreferences(_ mutate: (inout Preferences) -> Void) {
        var next = preferences
        mutate(&next)
        do {
            try updatePreferencesUseCase.execute(next)
            preferences = next
        } catch {
            // Keep in-memory state unchanged on persistence failure.
        }
    }
}
