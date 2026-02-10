import AppKit
import SwiftUI

@MainActor
final class AppWindowCoordinator {
    private let overlayPanelController: OverlayPanelController
    private let makeSettingsRootView: () -> AnyView
    private var settingsWindowController: NSWindowController?

    init(
        overlayPanelController: OverlayPanelController,
        makeSettingsRootView: @escaping () -> AnyView
    ) {
        self.overlayPanelController = overlayPanelController
        self.makeSettingsRootView = makeSettingsRootView
    }

    func applyPresentation(needsOnboarding: Bool) {
        if needsOnboarding {
            showOnboardingWindow()
            return
        }

        NSApp.setActivationPolicy(.accessory)
        overlayPanelController.hide()
        NSApp.windows.forEach { $0.orderOut(nil) }
    }

    func showOnboardingWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        bringMainWindowToFront()
    }

    func presentSettingsWindow(title: String) {
        if let existingWindow = settingsWindowController?.window {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let host = NSHostingController(rootView: makeSettingsRootView())
        let window = NSWindow(contentViewController: host)
        window.title = title
        window.styleMask = NSWindow.StyleMask([.titled, .closable, .miniaturizable])
        window.setContentSize(NSSize(width: 760, height: 560))
        window.center()
        let controller = NSWindowController(window: window)
        controller.showWindow(nil)
        settingsWindowController = controller
    }

    func updateSettingsWindowTitle(_ title: String) {
        settingsWindowController?.window?.title = title
    }

    private func bringMainWindowToFront() {
        if let window = NSApp.windows.first(where: { !($0 is NSPanel) }) {
            window.makeKeyAndOrderFront(nil)
            return
        }
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
}
