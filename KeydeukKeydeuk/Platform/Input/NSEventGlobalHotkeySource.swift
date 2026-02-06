import AppKit
import Foundation

final class NSEventGlobalHotkeySource: EventSource {
    var onEvent: ((KeyEvent) -> Void)?

    private var globalMonitor: Any?

    func start() {
        guard globalMonitor == nil else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.onEvent?(Self.map(event: event))
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    private static func map(event: NSEvent) -> KeyEvent {
        var modifiers: KeyModifiers = []
        if event.modifierFlags.contains(.command) { modifiers.insert(.command) }
        if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
        if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
        if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }

        return KeyEvent(
            keyCode: Int(event.keyCode),
            modifiers: modifiers,
            isKeyDown: event.type == .keyDown
        )
    }
}
