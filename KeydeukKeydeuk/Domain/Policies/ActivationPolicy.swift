import Foundation

protocol ActivationPolicy {
    func evaluate(event: KeyEvent, preferences: Preferences) -> ActivationDecision
}

struct DefaultActivationPolicy: ActivationPolicy {
    func evaluate(event: KeyEvent, preferences: Preferences) -> ActivationDecision {
        // NOTE: custom shortcut feature is temporarily disabled.
//        if preferences.trigger == .customShortcut,
//           event.isKeyDown,
//           preferences.customHotkeys.contains(where: { $0.matches(event) }) {
//            return .activate
//        }

        if preferences.autoHideOnEsc && event.isKeyDown && event.keyCode == 53 {
            return .hide
        }

        return .ignore
    }
}
