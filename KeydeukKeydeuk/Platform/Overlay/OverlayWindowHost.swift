import Foundation

@MainActor
final class OverlayWindowHost: OverlayPresenter {
    private let state: OverlaySceneState

    init(state: OverlaySceneState) {
        self.state = state
    }

    func show(catalog: ShortcutCatalog, app: AppContext) {
        state.appName = app.appName
        state.shortcuts = catalog.shortcuts
        state.isVisible = true
    }

    func hide() {
        state.isVisible = false
    }
}
