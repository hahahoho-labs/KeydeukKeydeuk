import Combine
import Foundation

@MainActor
final class ThemeModeStore: ObservableObject {
    @Published private(set) var selectedTheme: Preferences.Theme

    var selectedThemeMode: Preferences.ThemeMode { selectedTheme.mode }
    var selectedThemePreset: Preferences.ThemePreset { selectedTheme.preset }

    init(initialTheme: Preferences.Theme) {
        self.selectedTheme = initialTheme
    }

    func update(theme: Preferences.Theme) {
        guard selectedTheme != theme else { return }
        selectedTheme = theme
    }
}
