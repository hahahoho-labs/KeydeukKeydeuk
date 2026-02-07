import Combine
import Foundation

@MainActor
final class ThemeModeStore: ObservableObject {
    @Published private(set) var selectedThemeMode: Preferences.ThemeMode

    init(initialMode: Preferences.ThemeMode) {
        self.selectedThemeMode = initialMode
    }

    func update(mode: Preferences.ThemeMode) {
        guard selectedThemeMode != mode else { return }
        selectedThemeMode = mode
    }
}
