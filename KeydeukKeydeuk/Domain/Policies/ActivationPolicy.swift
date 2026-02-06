import Foundation

protocol ActivationPolicy {
    func evaluate(event: KeyEvent, preferences: Preferences) -> ActivationDecision
}

struct DefaultActivationPolicy: ActivationPolicy {
    func evaluate(event: KeyEvent, preferences: Preferences) -> ActivationDecision {
        guard preferences.trigger == .globalHotkey else {
            return .ignore
        }

        let hotkeyMatched = event.isKeyDown
            && event.keyCode == preferences.hotkeyKeyCode
            && event.modifiers == preferences.hotkeyModifiers

        if hotkeyMatched {
            return .activate
        }

        if preferences.autoHideOnEsc && event.isKeyDown && event.keyCode == 53 {
            return .hide
        }

        return .ignore
    }
}
