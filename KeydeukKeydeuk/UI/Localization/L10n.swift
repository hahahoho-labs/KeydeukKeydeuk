import Foundation

enum L10n {
    static func text(_ key: String, locale: Locale, fallback: String? = nil) -> String {
        let bundle = bundle(for: locale)
        let localized = bundle.localizedString(forKey: key, value: fallback ?? key, table: nil)
        if localized != key || fallback != nil {
            return localized
        }

        return Bundle.main.localizedString(forKey: key, value: fallback ?? key, table: nil)
    }

    static func formatted(
        _ key: String,
        locale: Locale,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        let format = text(key, locale: locale, fallback: fallback)
        return String(format: format, locale: locale, arguments: arguments)
    }

    private static func bundle(for locale: Locale) -> Bundle {
        guard
            let localization = localizationIdentifier(for: locale),
            let path = Bundle.main.path(forResource: localization, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return Bundle.main
        }
        return bundle
    }

    private static func localizationIdentifier(for locale: Locale) -> String? {
        let availableLocalizations = Set(Bundle.main.localizations.map { $0.lowercased() })

        for candidate in localizationCandidates(for: locale) where availableLocalizations.contains(candidate) {
            return candidate
        }

        if availableLocalizations.contains("en") {
            return "en"
        }

        if let preferred = Bundle.main.preferredLocalizations.first?.lowercased(),
           availableLocalizations.contains(preferred) {
            return preferred
        }

        if let development = Bundle.main.developmentLocalization?.lowercased(),
           availableLocalizations.contains(development) {
            return development
        }

        return nil
    }

    private static func localizationCandidates(for locale: Locale) -> [String] {
        let normalized = locale.identifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")

        guard !normalized.isEmpty else { return [] }

        var candidates: [String] = [normalized]
        if let baseLanguage = normalized.split(separator: "-").first.map(String.init),
           baseLanguage != normalized {
            candidates.append(baseLanguage)
        }

        var seen: Set<String> = []
        return candidates.filter { seen.insert($0).inserted }
    }
}
