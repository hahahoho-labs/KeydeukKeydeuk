import AppKit
import Combine
import SwiftUI

@MainActor
final class OverlayPanelController {
    private final class OverlayPanel: NSPanel {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { true }
    }

    private let state: OverlaySceneState
    private let viewModel: OverlayViewModel

    private var panel: NSPanel?
    private var cancellables: Set<AnyCancellable> = []

    init(state: OverlaySceneState, viewModel: OverlayViewModel) {
        self.state = state
        self.viewModel = viewModel
    }

    func start() {
        state.$isVisible
            .removeDuplicates()
            .sink { [weak self] isVisible in
                guard let self else { return }
                if isVisible {
                    show()
                } else {
                    hide()
                }
            }
            .store(in: &cancellables)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func show() {
        let overlayPanel = ensurePanel()
        if let screen = NSScreen.main {
            overlayPanel.setFrame(screen.frame, display: true)
        }
        NSApp.activate(ignoringOtherApps: true)
        overlayPanel.makeKeyAndOrderFront(nil)
    }

    private func ensurePanel() -> NSPanel {
        if let panel {
            return panel
        }

        let hostingController = NSHostingController(rootView: OverlayPanelView(viewModel: viewModel))
        let panel = OverlayPanel(
            contentRect: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 720),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.level = .screenSaver
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.contentViewController = hostingController

        self.panel = panel
        return panel
    }
}
