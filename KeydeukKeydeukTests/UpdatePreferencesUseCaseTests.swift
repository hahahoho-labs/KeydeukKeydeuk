import XCTest
@testable import KeydeukKeydeuk

@MainActor
final class UpdatePreferencesUseCaseTests: XCTestCase {
    func testExecute_withValidPreferences_savesToStore() throws {
        let store = SpyPreferencesStore()
        let useCase = UpdatePreferencesUseCase(preferencesStore: store)
        var preferences = Preferences.default
        preferences.customHotkeys = [
            Preferences.HotkeyBinding(keyCode: 12, modifiersRawValue: KeyModifiers.command.rawValue)
        ]

        try useCase.execute(preferences)

        XCTAssertEqual(store.saveCallCount, 1)
        XCTAssertEqual(store.lastSaved, preferences)
    }

    func testExecute_withDuplicateHotkeys_throwsDuplicateHotkey() {
        let store = SpyPreferencesStore()
        let useCase = UpdatePreferencesUseCase(preferencesStore: store)
        var preferences = Preferences.default
        let duplicate = Preferences.HotkeyBinding(keyCode: 12, modifiersRawValue: KeyModifiers.command.rawValue)
        preferences.customHotkeys = [duplicate, duplicate]

        XCTAssertThrowsError(try useCase.execute(preferences)) { error in
            XCTAssertEqual(error as? UpdatePreferencesUseCase.Error, .duplicateHotkey)
        }
        XCTAssertEqual(store.saveCallCount, 0)
    }

    func testExecute_withModifierlessHotkey_throwsInvalidHotkey() {
        let store = SpyPreferencesStore()
        let useCase = UpdatePreferencesUseCase(preferencesStore: store)
        var preferences = Preferences.default
        preferences.customHotkeys = [
            Preferences.HotkeyBinding(keyCode: 12, modifiersRawValue: 0)
        ]

        XCTAssertThrowsError(try useCase.execute(preferences)) { error in
            XCTAssertEqual(error as? UpdatePreferencesUseCase.Error, .invalidHotkey)
        }
        XCTAssertEqual(store.saveCallCount, 0)
    }
}

private final class SpyPreferencesStore: PreferencesStore {
    private(set) var saveCallCount = 0
    private(set) var lastSaved: Preferences?

    func load() -> Preferences {
        .default
    }

    func save(_ preferences: Preferences) throws {
        saveCallCount += 1
        lastSaved = preferences
    }
}
