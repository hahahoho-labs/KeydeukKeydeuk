import Combine
import Foundation

@MainActor
final class AppLocaleStore: ObservableObject {
    @Published private(set) var locale: Locale
    private let resolver: any AppLocaleResolving

    convenience init(initialLanguage: Preferences.Language) {
        self.init(
            initialLanguage: initialLanguage,
            resolver: DefaultAppLocaleResolver()
        )
    }

    init(
        initialLanguage: Preferences.Language,
        resolver: any AppLocaleResolving
    ) {
        self.resolver = resolver
        self.locale = resolver.locale(for: initialLanguage)
    }

    func update(language: Preferences.Language) {
        let next = resolver.locale(for: language)
        guard locale.identifier != next.identifier else { return }
        locale = next
    }
}
