import AppKit
import Foundation

@MainActor
final class OverlayWindowHost: OverlayPresenter {
    private let state: OverlaySceneState

    init(state: OverlaySceneState) {
        self.state = state
    }

    func show(catalog: ShortcutCatalog, app: AppContext) {
        state.appName = app.appName
        state.appBundleID = app.bundleID
        state.shortcuts = catalog.shortcuts
        state.appIcon = Self.loadIcon(for: app.bundleID)
        state.isVisible = true
    }

    func hide() {
        state.isVisible = false
    }

    private static func loadIcon(for bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)
        return icon
    }
}
