import Foundation

protocol OverlayPolicy {
    func shouldHideOnAppSwitch(preferences: Preferences) -> Bool
    func shouldHideOnEsc(preferences: Preferences) -> Bool
}

struct DefaultOverlayPolicy: OverlayPolicy {
    func shouldHideOnAppSwitch(preferences: Preferences) -> Bool {
        preferences.autoHideOnAppSwitch
    }

    func shouldHideOnEsc(preferences: Preferences) -> Bool {
        preferences.autoHideOnEsc
    }
}
