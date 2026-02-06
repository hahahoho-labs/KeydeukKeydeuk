import AppKit
import Foundation

struct NSWorkspaceAppContextProvider: AppContextProvider {
    func currentApp() -> AppContext? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else {
            return nil
        }

        return AppContext(
            bundleID: bundleID,
            appName: app.localizedName ?? bundleID
        )
    }
}
