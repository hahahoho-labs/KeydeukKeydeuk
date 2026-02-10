import XCTest
@testable import KeydeukKeydeuk

final class PreferencesTests: XCTestCase {
    func testDefaultLanguage_isSystem() {
        XCTAssertEqual(Preferences.default.language, .system)
    }

    func testDecodeLegacyPreferences_withoutLanguage_defaultsToSystem() throws {
        let legacyJSON = """
        {
          "trigger": "holdCommand",
          "customHotkeys": [],
          "holdDurationSeconds": 1.0,
          "autoHideOnAppSwitch": true,
          "autoHideOnEsc": true,
          "theme": "system",
          "hasCompletedOnboarding": false
        }
        """

        let decoded = try JSONDecoder().decode(Preferences.self, from: Data(legacyJSON.utf8))
        XCTAssertEqual(decoded.language, .system)
    }

    func testRoundTrip_withExplicitLanguage_persistsLanguage() throws {
        let source = Preferences(
            trigger: .commandDoubleTap,
            customHotkeys: [],
            holdDurationSeconds: 0.8,
            autoHideOnAppSwitch: true,
            autoHideOnEsc: true,
            theme: .graphite,
            language: .korean,
            hasCompletedOnboarding: true
        )

        let data = try JSONEncoder().encode(source)
        let restored = try JSONDecoder().decode(Preferences.self, from: data)
        XCTAssertEqual(restored.language, .korean)
        XCTAssertEqual(restored, source)
    }

    func testDecodeLegacyLanguageRawValue_korean_mapsToCurrentCode() throws {
        let legacyJSON = """
        {
          "trigger": "holdCommand",
          "customHotkeys": [],
          "holdDurationSeconds": 1.0,
          "autoHideOnAppSwitch": true,
          "autoHideOnEsc": true,
          "theme": "system",
          "language": "korean",
          "hasCompletedOnboarding": false
        }
        """

        let decoded = try JSONDecoder().decode(Preferences.self, from: Data(legacyJSON.utf8))
        XCTAssertEqual(decoded.language, .korean)
        XCTAssertEqual(decoded.language.rawValue, "ko")
    }

    func testDecodeLanguage_withArbitraryLanguageCode_preservesValue() throws {
        let json = """
        {
          "trigger": "holdCommand",
          "customHotkeys": [],
          "holdDurationSeconds": 1.0,
          "autoHideOnAppSwitch": true,
          "autoHideOnEsc": true,
          "theme": "system",
          "language": "ja",
          "hasCompletedOnboarding": false
        }
        """

        let decoded = try JSONDecoder().decode(Preferences.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.language.rawValue, "ja")
    }

    func testDecodeLegacyGlobalHotkeyTrigger_migratesToHoldCommand() throws {
        let legacyJSON = """
        {
          "trigger": "globalHotkey",
          "customHotkeys": [],
          "hotkeyKeyCode": 8,
          "hotkeyModifiersRawValue": 1,
          "holdDurationSeconds": 1.0,
          "autoHideOnAppSwitch": true,
          "autoHideOnEsc": true,
          "theme": "system",
          "hasCompletedOnboarding": false
        }
        """

        let decoded = try JSONDecoder().decode(Preferences.self, from: Data(legacyJSON.utf8))
        XCTAssertEqual(decoded.trigger, .holdCommand)
        XCTAssertEqual(decoded.customHotkeys.count, 1)
        XCTAssertEqual(decoded.customHotkeys.first?.keyCode, 8)
        XCTAssertEqual(decoded.customHotkeys.first?.modifiersRawValue, 1)
    }

    func testDecodeCustomShortcutTrigger_migratesToHoldCommand() throws {
        let legacyJSON = """
        {
          "trigger": "customShortcut",
          "customHotkeys": [{ "keyCode": 12, "modifiersRawValue": 1 }],
          "holdDurationSeconds": 1.0,
          "autoHideOnAppSwitch": true,
          "autoHideOnEsc": true,
          "theme": "system",
          "hasCompletedOnboarding": false
        }
        """

        let decoded = try JSONDecoder().decode(Preferences.self, from: Data(legacyJSON.utf8))
        XCTAssertEqual(decoded.trigger, .holdCommand)
        XCTAssertEqual(decoded.customHotkeys.count, 1)
        XCTAssertEqual(decoded.customHotkeys.first?.keyCode, 12)
        XCTAssertEqual(decoded.customHotkeys.first?.modifiersRawValue, 1)
    }
}
