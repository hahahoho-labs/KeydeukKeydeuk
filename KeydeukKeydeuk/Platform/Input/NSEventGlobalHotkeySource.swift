import AppKit
import Foundation

final class NSEventGlobalHotkeySource: EventSource {
    var onEvent: ((KeyEvent) -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?

    func start() {
        guard globalMonitor == nil else { return }

        // 글로벌 모니터: 다른 앱에 포커스가 있을 때 keyDown + flagsChanged 캡처
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.onEvent?(Self.map(event: event))
        }

        // 로컬 모니터: 우리 앱(오버레이 패널)에 포커스가 있을 때 flagsChanged 캡처
        // → ⌘ 릴리스 감지에 필수 (keyDown은 제외 — 검색 필드 입력과 충돌 방지)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.onEvent?(Self.map(event: event))
            return event // 이벤트를 소비하지 않고 그대로 전달
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private static func map(event: NSEvent) -> KeyEvent {
        var modifiers: KeyModifiers = []
        if event.modifierFlags.contains(.command) { modifiers.insert(.command) }
        if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
        if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
        if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }

        let isFlagsChanged = event.type == .flagsChanged

        return KeyEvent(
            keyCode: Int(event.keyCode),
            modifiers: modifiers,
            isKeyDown: isFlagsChanged ? modifiers.contains(.command) : event.type == .keyDown,
            isFlagsChanged: isFlagsChanged
        )
    }
}
