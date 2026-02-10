import AppKit
import Combine
import os
import SwiftUI

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "OverlayPanel")

@MainActor
final class OverlayPanelController {
    private final class OverlayPanel: NSPanel {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { false }
    }

    private let state: OverlaySceneState
    private let viewModel: OverlayViewModel
    private let themeModeStore: ThemeModeStore
    private let localeStore: AppLocaleStore

    private var panel: NSPanel?
    private var cancellables: Set<AnyCancellable> = []

    init(
        state: OverlaySceneState,
        viewModel: OverlayViewModel,
        themeModeStore: ThemeModeStore,
        localeStore: AppLocaleStore
    ) {
        self.state = state
        self.viewModel = viewModel
        self.themeModeStore = themeModeStore
        self.localeStore = localeStore
    }

    func start() {
        state.$isVisible
            .removeDuplicates()
            .sink { [weak self] isVisible in
                guard let self else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if isVisible {
                        self.show()
                    } else {
                        self.hide()
                    }
                }
            }
            .store(in: &cancellables)
    }

    func hide() {
        log.info("🔽 오버레이 패널 숨김")
        panel?.orderOut(nil)
    }

    private func show() {
        let overlayPanel = ensurePanel()

        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? NSScreen.main
            ?? NSScreen.screens.first

        if let screen = targetScreen {
            overlayPanel.setFrame(screen.frame, display: false)
            log.info("🖥️ 패널 프레임 설정: \(screen.frame.width)×\(screen.frame.height)")
        } else {
            log.warning("⚠️ 사용 가능한 화면 없음")
        }

        overlayPanel.orderFrontRegardless()
        overlayPanel.makeKey()
        NSApp.activate(ignoringOtherApps: true)
        log.info("🔼 오버레이 패널 표시 완료 (level: \(overlayPanel.level.rawValue))")
    }

    private func ensurePanel() -> NSPanel {
        if let panel {
            return panel
        }

        let hostingController = NSHostingController(
            rootView: OverlayPanelView(
                viewModel: viewModel,
                themeModeStore: themeModeStore,
                localeStore: localeStore
            )
        )
        let panel = OverlayPanel(
            contentRect: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 720),
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
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
