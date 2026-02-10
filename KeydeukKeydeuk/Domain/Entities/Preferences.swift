import Foundation

struct Preferences: Codable, Equatable {
    struct HotkeyBinding: Codable, Equatable, Identifiable {
        var keyCode: Int
        var modifiersRawValue: Int

        var id: String { "\(keyCode)-\(modifiersRawValue)" }
        var modifiers: KeyModifiers { KeyModifiers(rawValue: modifiersRawValue) }

        func matches(_ event: KeyEvent) -> Bool {
            event.keyCode == keyCode && event.modifiers == modifiers
        }
    }

    enum Trigger: String, Codable {
        case holdCommand
        case commandDoubleTap
        case customShortcut
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

    struct Language: RawRepresentable, Codable, Equatable, Hashable {
        let rawValue: String

        private enum Canonical {
            static let system = "system"
            static let korean = "ko"
            static let english = "en"
        }

        static let system = Language(rawValue: Canonical.system)
        static let korean = Language(rawValue: Canonical.korean)
        static let english = Language(rawValue: Canonical.english)

        init(rawValue: String) {
            self.rawValue = Self.normalize(rawValue)
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = (try? container.decode(String.self)) ?? Self.system.rawValue
            self.init(rawValue: raw)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }

        private static func normalize(_ rawValue: String) -> String {
            let normalized = rawValue
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: "_", with: "-")
            switch normalized {
            case "", "system", "auto", "default":
                return Canonical.system
            // Backward compatibility for legacy enum raw values.
            case "korean":
                return Canonical.korean
            case "english":
                return Canonical.english
            default:
                return normalized
            }
        }
    }

    var trigger: Trigger
    var customHotkeys: [HotkeyBinding]
    var holdDurationSeconds: Double
    var autoHideOnAppSwitch: Bool
    var autoHideOnEsc: Bool
    var theme: Theme
    var language: Language
    var hasCompletedOnboarding: Bool

    var themeMode: ThemeMode { theme.mode }
    var themePreset: ThemePreset { theme.preset }

    init(
        trigger: Trigger,
        customHotkeys: [HotkeyBinding],
        holdDurationSeconds: Double,
        autoHideOnAppSwitch: Bool,
        autoHideOnEsc: Bool,
        theme: Theme,
        language: Language,
        hasCompletedOnboarding: Bool
    ) {
        self.trigger = trigger
        self.customHotkeys = customHotkeys
        self.holdDurationSeconds = holdDurationSeconds
        self.autoHideOnAppSwitch = autoHideOnAppSwitch
        self.autoHideOnEsc = autoHideOnEsc
        self.theme = theme
        self.language = language
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    static let `default` = Preferences(
        trigger: .holdCommand,
        customHotkeys: [],
        holdDurationSeconds: 1.0,
        autoHideOnAppSwitch: true,
        autoHideOnEsc: true,
        theme: .system,
        language: .system,
        hasCompletedOnboarding: false
    )

    private enum CodingKeys: String, CodingKey {
        case trigger
        case customHotkeys
        case hotkeyKeyCode
        case hotkeyModifiersRawValue
        case holdDurationSeconds
        case autoHideOnAppSwitch
        case autoHideOnEsc
        case theme
        case language
        case themeMode
        case themePreset
        case hasCompletedOnboarding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Preferences.default

        if let rawTrigger = try container.decodeIfPresent(String.self, forKey: .trigger) {
            if rawTrigger == "globalHotkey" {
                trigger = .customShortcut
            } else {
                trigger = Trigger(rawValue: rawTrigger) ?? defaults.trigger
            }
        } else {
            trigger = defaults.trigger
        }
        customHotkeys = try container.decodeIfPresent([HotkeyBinding].self, forKey: .customHotkeys) ?? defaults.customHotkeys

        // Legacy migration: globalHotkey 모드로 쓰던 단일 핫키를 customHotkeys로 이전
        if customHotkeys.isEmpty,
           trigger == .commandDoubleTap,
           let legacyKeyCode = try container.decodeIfPresent(Int.self, forKey: .hotkeyKeyCode),
           let legacyModifiersRawValue = try container.decodeIfPresent(Int.self, forKey: .hotkeyModifiersRawValue) {
            customHotkeys = [HotkeyBinding(keyCode: legacyKeyCode, modifiersRawValue: legacyModifiersRawValue)]
        }

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
        language = try container.decodeIfPresent(Language.self, forKey: .language) ?? defaults.language
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? defaults.hasCompletedOnboarding
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trigger, forKey: .trigger)
        try container.encode(customHotkeys, forKey: .customHotkeys)
        try container.encode(holdDurationSeconds, forKey: .holdDurationSeconds)
        try container.encode(autoHideOnAppSwitch, forKey: .autoHideOnAppSwitch)
        try container.encode(autoHideOnEsc, forKey: .autoHideOnEsc)
        try container.encode(theme, forKey: .theme)
        try container.encode(language, forKey: .language)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
    }
}
