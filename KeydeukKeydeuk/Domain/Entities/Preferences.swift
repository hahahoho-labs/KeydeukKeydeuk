import Foundation

struct Preferences: Codable, Equatable {
    enum Trigger: String, Codable {
        case holdCommand
        case globalHotkey
    }

    enum ThemeMode: String, Codable, CaseIterable {
        case system
        case light
        case dark
    }

    enum ThemePreset: String, Codable, CaseIterable {
        case frost
        case graphite
        case warmPaper
        case nordMist
        case highContrast
    }

    enum Theme: String, Codable, CaseIterable {
        case system
        case light
        case dark
        case graphite
        case warmPaper
        case nordMist
        case highContrast

        var mode: ThemeMode {
            switch self {
            case .system:
                return .system
            case .light:
                return .light
            case .dark, .graphite, .nordMist, .highContrast:
                return .dark
            case .warmPaper:
                return .light
            }
        }

        var preset: ThemePreset {
            switch self {
            case .system, .light, .dark:
                return .frost
            case .graphite:
                return .graphite
            case .warmPaper:
                return .warmPaper
            case .nordMist:
                return .nordMist
            case .highContrast:
                return .highContrast
            }
        }

        static func from(mode: ThemeMode, preset: ThemePreset) -> Theme {
            switch preset {
            case .frost:
                switch mode {
                case .system: return .system
                case .light: return .light
                case .dark: return .dark
                }
            case .graphite:
                return .graphite
            case .warmPaper:
                return .warmPaper
            case .nordMist:
                return .nordMist
            case .highContrast:
                return .highContrast
            }
        }
    }

    var trigger: Trigger
    var hotkeyKeyCode: Int
    var hotkeyModifiersRawValue: Int
    var holdDurationSeconds: Double
    var autoHideOnAppSwitch: Bool
    var autoHideOnEsc: Bool
    var theme: Theme
    var hasCompletedOnboarding: Bool

    var themeMode: ThemeMode { theme.mode }
    var themePreset: ThemePreset { theme.preset }

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
        theme: Theme,
        hasCompletedOnboarding: Bool
    ) {
        self.trigger = trigger
        self.hotkeyKeyCode = hotkeyKeyCode
        self.hotkeyModifiersRawValue = hotkeyModifiersRawValue
        self.holdDurationSeconds = holdDurationSeconds
        self.autoHideOnAppSwitch = autoHideOnAppSwitch
        self.autoHideOnEsc = autoHideOnEsc
        self.theme = theme
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    static let `default` = Preferences(
        trigger: .holdCommand,
        hotkeyKeyCode: 40,
        hotkeyModifiersRawValue: KeyModifiers.command.union(.shift).rawValue,
        holdDurationSeconds: 1.0,
        autoHideOnAppSwitch: true,
        autoHideOnEsc: true,
        theme: .system,
        hasCompletedOnboarding: false
    )

    private enum CodingKeys: String, CodingKey {
        case trigger
        case hotkeyKeyCode
        case hotkeyModifiersRawValue
        case holdDurationSeconds
        case autoHideOnAppSwitch
        case autoHideOnEsc
        case theme
        case themeMode
        case themePreset
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
        if let decodedTheme = try container.decodeIfPresent(Theme.self, forKey: .theme) {
            theme = decodedTheme
        } else {
            let legacyMode = try container.decodeIfPresent(ThemeMode.self, forKey: .themeMode) ?? defaults.themeMode
            let legacyPreset = try container.decodeIfPresent(ThemePreset.self, forKey: .themePreset) ?? defaults.themePreset
            theme = Theme.from(mode: legacyMode, preset: legacyPreset)
        }
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? defaults.hasCompletedOnboarding
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trigger, forKey: .trigger)
        try container.encode(hotkeyKeyCode, forKey: .hotkeyKeyCode)
        try container.encode(hotkeyModifiersRawValue, forKey: .hotkeyModifiersRawValue)
        try container.encode(holdDurationSeconds, forKey: .holdDurationSeconds)
        try container.encode(autoHideOnAppSwitch, forKey: .autoHideOnAppSwitch)
        try container.encode(autoHideOnEsc, forKey: .autoHideOnEsc)
        try container.encode(theme, forKey: .theme)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
    }
}
