import Foundation

struct UpdatePreferencesUseCase {
    enum Error: Swift.Error, Equatable {
        case invalidHotkey
    }

    private let preferencesStore: PreferencesStore

    init(preferencesStore: PreferencesStore) {
        self.preferencesStore = preferencesStore
    }

    func execute(_ preferences: Preferences) throws {
        guard preferences.hotkeyKeyCode >= 0 else {
            throw Error.invalidHotkey
        }
        try preferencesStore.save(preferences)
    }
}
