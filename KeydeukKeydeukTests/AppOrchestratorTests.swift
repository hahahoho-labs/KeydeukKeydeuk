import XCTest
@testable import KeydeukKeydeuk

@MainActor
final class AppOrchestratorTests: XCTestCase {
    func testStart_whenCommandDoubleTapDetected_requestsOverlayShow() async throws {
        let eventSource = StubEventSource()
        let presenter = SpyOverlayPresenter()
        let orchestrator = makeOrchestrator(
            eventSource: eventSource,
            presenter: presenter,
            initialPreferences: preferences(trigger: .commandDoubleTap)
        )

        orchestrator.start()
        XCTAssertTrue(eventSource.isStarted)

        eventSource.send(KeyEvent(keyCode: 55, modifiers: .command, isKeyDown: true, isFlagsChanged: true))
        eventSource.send(KeyEvent(keyCode: 55, modifiers: [], isKeyDown: false, isFlagsChanged: true))
        eventSource.send(KeyEvent(keyCode: 55, modifiers: .command, isKeyDown: true, isFlagsChanged: true))

        try await waitUntil(seconds: 1.0) {
            presenter.showCallCount == 1
        }
    }

    func testStart_whenEscPressedAndAutoHideEnabled_requestsOverlayHide() async throws {
        let eventSource = StubEventSource()
        let presenter = SpyOverlayPresenter()
        let orchestrator = makeOrchestrator(
            eventSource: eventSource,
            presenter: presenter,
            initialPreferences: preferences(trigger: .commandDoubleTap)
        )

        orchestrator.start()
        eventSource.send(KeyEvent(keyCode: 53, modifiers: [], isKeyDown: true, isFlagsChanged: false))

        try await waitUntil(seconds: 1.0) {
            presenter.hideCallCount == 1
        }
    }

    private func makeOrchestrator(
        eventSource: StubEventSource,
        presenter: SpyOverlayPresenter,
        initialPreferences: Preferences
    ) -> AppOrchestrator {
        let showOverlay = ShowOverlayForCurrentAppUseCase(
            permissionChecker: StubPermissionChecker(state: .granted),
            appContextProvider: StubAppContextProvider(
                app: AppContext(bundleID: "com.apple.Finder", appName: "Finder")
            ),
            loadShortcuts: LoadShortcutsForAppUseCase(repository: StubShortcutRepository()),
            presenter: presenter
        )
        return AppOrchestrator(
            eventSource: eventSource,
            evaluateActivation: EvaluateActivationUseCase(policy: DefaultActivationPolicy()),
            showOverlay: showOverlay,
            hideOverlay: HideOverlayUseCase(presenter: presenter),
            initialPreferences: initialPreferences,
            onShowResult: { _ in }
        )
    }

    private func preferences(trigger: Preferences.Trigger) -> Preferences {
        Preferences(
            trigger: trigger,
            customHotkeys: [],
            holdDurationSeconds: 1.0,
            autoHideOnAppSwitch: true,
            autoHideOnEsc: true,
            theme: .system,
            language: .system,
            hasCompletedOnboarding: false
        )
    }

    private func waitUntil(seconds: TimeInterval, condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if condition() {
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Condition was not met within \(seconds) seconds")
    }
}

private final class StubEventSource: EventSource {
    var onEvent: ((KeyEvent) -> Void)?
    private(set) var isStarted = false

    func start() {
        isStarted = true
    }

    func stop() {
        isStarted = false
    }

    func send(_ event: KeyEvent) {
        onEvent?(event)
    }
}

private struct StubPermissionChecker: PermissionChecker {
    let state: PermissionState

    func state(for requirement: PermissionRequirement) -> PermissionState {
        state
    }
}

private struct StubAppContextProvider: AppContextProvider {
    let app: AppContext?

    func currentApp() -> AppContext? {
        app
    }
}

private struct StubShortcutRepository: ShortcutRepository {
    func shortcuts(for bundleID: String) async throws -> ShortcutCatalog? {
        ShortcutCatalog(
            bundleID: bundleID,
            appName: "Finder",
            shortcuts: [Shortcut(id: "1", title: "New Window", keys: "⌘N", section: "File")]
        )
    }
}

@MainActor
private final class SpyOverlayPresenter: OverlayPresenter {
    private(set) var showCallCount = 0
    private(set) var hideCallCount = 0

    func show(catalog: ShortcutCatalog, app: AppContext) {
        showCallCount += 1
    }

    func hide() {
        hideCallCount += 1
    }
}
