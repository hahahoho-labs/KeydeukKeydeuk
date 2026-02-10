import XCTest
@testable import KeydeukKeydeuk

@MainActor
final class ActivationPolicyTests: XCTestCase {
    private let policy = DefaultActivationPolicy()

    func testEvaluate_whenEscAndAutoHideEnabled_returnsHide() {
        var preferences = Preferences.default
        preferences.autoHideOnEsc = true

        let event = KeyEvent(
            keyCode: 53,
            modifiers: [],
            isKeyDown: true,
            isFlagsChanged: false
        )

        let decision = policy.evaluate(event: event, preferences: preferences)
        XCTAssertEqual(decision, .hide)
    }

    func testEvaluate_whenEscAndAutoHideDisabled_returnsIgnore() {
        var preferences = Preferences.default
        preferences.autoHideOnEsc = false

        let event = KeyEvent(
            keyCode: 53,
            modifiers: [],
            isKeyDown: true,
            isFlagsChanged: false
        )

        let decision = policy.evaluate(event: event, preferences: preferences)
        XCTAssertEqual(decision, .ignore)
    }
}
