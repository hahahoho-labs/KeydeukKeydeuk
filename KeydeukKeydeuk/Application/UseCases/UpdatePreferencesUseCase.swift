import Foundation

struct UpdatePreferencesUseCase {
    enum Error: Swift.Error, Equatable {
        case invalidHotkey
        case duplicateHotkey
    }

    private let preferencesStore: PreferencesStore

    init(preferencesStore: PreferencesStore) {
        self.preferencesStore = preferencesStore
    }

    func execute(_ preferences: Preferences) throws {
        for hotkey in preferences.customHotkeys {
            guard hotkey.keyCode >= 0, !hotkey.modifiers.isEmpty else {
                throw Error.invalidHotkey
            }
        }

        let uniqueHotkeys = Set(preferences.customHotkeys.map { "\($0.keyCode)-\($0.modifiersRawValue)" })
        guard uniqueHotkeys.count == preferences.customHotkeys.count else {
            throw Error.duplicateHotkey
        }
        try preferencesStore.save(preferences)
    }
}
