import Combine
import Foundation

@MainActor
final class OverlayViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var permissionHint: String?

    private let state: OverlaySceneState
    private let showOverlay: ShowOverlayForCurrentAppUseCase
    private let hideOverlay: HideOverlayUseCase
    private let updatePreferences: UpdatePreferencesUseCase

    init(
        state: OverlaySceneState,
        showOverlay: ShowOverlayForCurrentAppUseCase,
        hideOverlay: HideOverlayUseCase,
        updatePreferences: UpdatePreferencesUseCase
    ) {
        self.state = state
        self.showOverlay = showOverlay
        self.hideOverlay = hideOverlay
        self.updatePreferences = updatePreferences
    }

    var isVisible: Bool { state.isVisible }
    var appName: String { state.appName }

    var filteredShortcuts: [Shortcut] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return state.shortcuts }

        return state.shortcuts.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.keys.localizedCaseInsensitiveContains(trimmed)
                || ($0.section?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    func requestShow() async {
        let result = await showOverlay.execute()
        handle(showResult: result)
    }

    func requestHide() {
        hideOverlay.execute()
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

    func updateHotkey(keyCode: Int, modifiers: KeyModifiers) {
        var current = Preferences.default
        current.hotkeyKeyCode = keyCode
        current.hotkeyModifiersRawValue = modifiers.rawValue
        try? updatePreferences.execute(current)
    }
}
