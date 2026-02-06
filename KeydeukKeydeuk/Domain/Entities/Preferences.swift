import Foundation

struct Preferences: Codable, Equatable {
    enum Trigger: String, Codable {
        case holdCommand
        case globalHotkey
    }

    var trigger: Trigger
    var hotkeyKeyCode: Int
    var hotkeyModifiersRawValue: Int
    var holdDurationSeconds: Double
    var autoHideOnAppSwitch: Bool
    var autoHideOnEsc: Bool
    var hasCompletedOnboarding: Bool

    var hotkeyModifiers: KeyModifiers {
        KeyModifiers(rawValue: hotkeyModifiersRawValue)
    }

    init(
        trigger: Trigger,
        hotkeyKeyCode: Int,
        hotkeyModifiersRawValue: Int,
        holdDurationSeconds: Double,
        autoHideOnAppSwitch: Bool,
        autoHideOnEsc: Bool,
        hasCompletedOnboarding: Bool
    ) {
        self.trigger = trigger
        self.hotkeyKeyCode = hotkeyKeyCode
        self.hotkeyModifiersRawValue = hotkeyModifiersRawValue
        self.holdDurationSeconds = holdDurationSeconds
        self.autoHideOnAppSwitch = autoHideOnAppSwitch
        self.autoHideOnEsc = autoHideOnEsc
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    static let `default` = Preferences(
        trigger: .holdCommand,
        hotkeyKeyCode: 40,
        hotkeyModifiersRawValue: KeyModifiers.command.union(.shift).rawValue,
        holdDurationSeconds: 1.0,
        autoHideOnAppSwitch: true,
        autoHideOnEsc: true,
        hasCompletedOnboarding: false
    )

    private enum CodingKeys: String, CodingKey {
        case trigger
        case hotkeyKeyCode
        case hotkeyModifiersRawValue
        case holdDurationSeconds
        case autoHideOnAppSwitch
        case autoHideOnEsc
        case hasCompletedOnboarding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Preferences.default

        trigger = try container.decodeIfPresent(Trigger.self, forKey: .trigger) ?? defaults.trigger
        hotkeyKeyCode = try container.decodeIfPresent(Int.self, forKey: .hotkeyKeyCode) ?? defaults.hotkeyKeyCode
        hotkeyModifiersRawValue = try container.decodeIfPresent(Int.self, forKey: .hotkeyModifiersRawValue) ?? defaults.hotkeyModifiersRawValue
        holdDurationSeconds = try container.decodeIfPresent(Double.self, forKey: .holdDurationSeconds) ?? defaults.holdDurationSeconds
        autoHideOnAppSwitch = try container.decodeIfPresent(Bool.self, forKey: .autoHideOnAppSwitch) ?? defaults.autoHideOnAppSwitch
        autoHideOnEsc = try container.decodeIfPresent(Bool.self, forKey: .autoHideOnEsc) ?? defaults.autoHideOnEsc
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? defaults.hasCompletedOnboarding
    }
}
