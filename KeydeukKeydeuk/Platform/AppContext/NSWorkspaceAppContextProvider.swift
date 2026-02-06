import AppKit
import Foundation

final class NSWorkspaceAppContextProvider: AppContextProvider {
    private let ownBundleID: String?
    private var lastKnownApp: AppContext?
    private var activationObserver: NSObjectProtocol?

    init(ownBundleID: String? = Bundle.main.bundleIdentifier) {
        self.ownBundleID = ownBundleID
        self.lastKnownApp = Self.makeContext(from: NSWorkspace.shared.frontmostApplication, ownBundleID: ownBundleID)

        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let context = Self.makeContext(from: app, ownBundleID: self.ownBundleID) else {
                return
            }
            self.lastKnownApp = context
        }
    }

    deinit {
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
        }
    }

    func currentApp() -> AppContext? {
        if let frontmost = Self.makeContext(from: NSWorkspace.shared.frontmostApplication, ownBundleID: ownBundleID) {
            lastKnownApp = frontmost
            return frontmost
        }
        return lastKnownApp
    }

    private static func makeContext(from app: NSRunningApplication?, ownBundleID: String?) -> AppContext? {
        guard let app, let bundleID = app.bundleIdentifier else {
            return nil
        }
        if bundleID == ownBundleID {
            return nil
        }
        return AppContext(bundleID: bundleID, appName: app.localizedName ?? bundleID)
    }
}
