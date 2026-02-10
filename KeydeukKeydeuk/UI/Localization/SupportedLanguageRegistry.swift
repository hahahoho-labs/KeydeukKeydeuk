import Foundation

struct SupportedLanguageOption: Identifiable, Hashable {
    let language: Preferences.Language
    let titleKey: String

    var id: String { language.rawValue }
}

protocol LanguageOptionProviding {
    var options: [SupportedLanguageOption] { get }
}

protocol AppLocaleResolving {
    func locale(for language: Preferences.Language) -> Locale
}

struct SupportedLanguageCatalog: LanguageOptionProviding {
    let options: [SupportedLanguageOption]

    init(options: [SupportedLanguageOption] = [
        SupportedLanguageOption(
            language: .system,
            titleKey: "settings.general.language.option.system"
        ),
        SupportedLanguageOption(
            language: .korean,
            titleKey: "settings.general.language.option.korean"
        ),
        SupportedLanguageOption(
            language: .english,
            titleKey: "settings.general.language.option.english"
        )
    ]) {
        self.options = options
    }
}

struct DefaultAppLocaleResolver: AppLocaleResolving {
    func locale(for language: Preferences.Language) -> Locale {
        guard language != .system else {
            return .autoupdatingCurrent
        }
        return Locale(identifier: language.rawValue)
    }
}
