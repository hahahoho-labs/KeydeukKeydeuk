import Foundation

struct Preferences: Codable, Equatable {
    enum Trigger: String, Codable {
        case globalHotkey
    }

    var trigger: Trigger
    var hotkeyKeyCode: Int
    var hotkeyModifiersRawValue: Int
    var autoHideOnAppSwitch: Bool
    var autoHideOnEsc: Bool

    var hotkeyModifiers: KeyModifiers {
        KeyModifiers(rawValue: hotkeyModifiersRawValue)
    }

    static let `default` = Preferences(
        trigger: .globalHotkey,
        hotkeyKeyCode: 40,
        hotkeyModifiersRawValue: KeyModifiers.command.union(.shift).rawValue,
        autoHideOnAppSwitch: true,
        autoHideOnEsc: true
    )
}
