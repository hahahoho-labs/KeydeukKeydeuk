import AppKit
import Foundation

@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?

    var onPrimaryClick: (() -> Void)?
    var onSettingsClick: (() -> Void)?

    func start() {
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "KD"
        item.button?.target = self
        item.button?.action = #selector(handleStatusBarClick(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item

        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(handleSettingsClick), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(handleQuitClick), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        self.menu = menu
    }

    @objc
    private func handleStatusBarClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            onPrimaryClick?()
            return
        }

        switch event.type {
        case .rightMouseUp:
            showContextMenu()
        default:
            onPrimaryClick?()
        }
    }

    @objc
    private func handleSettingsClick() {
        onSettingsClick?()
    }

    @objc
    private func handleQuitClick() {
        NSApp.terminate(nil)
    }

    private func showContextMenu() {
        guard let statusItem, let menu else { return }
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
}
