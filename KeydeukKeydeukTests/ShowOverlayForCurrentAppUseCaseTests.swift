import XCTest
@testable import KeydeukKeydeuk

@MainActor
final class ShowOverlayForCurrentAppUseCaseTests: XCTestCase {
    func testExecute_withEmptyCatalog_returnsNoCatalogAndStillPresents() async {
        let permissionChecker = StubPermissionChecker(state: .granted)
        let appContextProvider = StubAppContextProvider(
            app: AppContext(bundleID: "com.apple.Finder", appName: "Finder")
        )
        let shortcutRepository = StubShortcutRepository(catalog: nil, error: nil)
        let loadShortcuts = LoadShortcutsForAppUseCase(repository: shortcutRepository)
        let presenter = SpyOverlayPresenter()
        let useCase = ShowOverlayForCurrentAppUseCase(
            permissionChecker: permissionChecker,
            appContextProvider: appContextProvider,
            loadShortcuts: loadShortcuts,
            presenter: presenter
        )

        let result = await useCase.execute()

        XCTAssertEqual(result, .noCatalog)
        XCTAssertEqual(presenter.showCallCount, 1)
        XCTAssertEqual(presenter.lastCatalog?.shortcuts.count, 0)
    }

    func testExecute_withCatalogShortcuts_returnsShown() async {
        let permissionChecker = StubPermissionChecker(state: .granted)
        let appContextProvider = StubAppContextProvider(
            app: AppContext(bundleID: "com.apple.Finder", appName: "Finder")
        )
        let catalog = ShortcutCatalog(
            bundleID: "com.apple.Finder",
            appName: "Finder",
            shortcuts: [
                Shortcut(id: "1", title: "Close Window", keys: "⌘W", section: "File")
            ]
        )
        let shortcutRepository = StubShortcutRepository(catalog: catalog, error: nil)
        let loadShortcuts = LoadShortcutsForAppUseCase(repository: shortcutRepository)
        let presenter = SpyOverlayPresenter()
        let useCase = ShowOverlayForCurrentAppUseCase(
            permissionChecker: permissionChecker,
            appContextProvider: appContextProvider,
            loadShortcuts: loadShortcuts,
            presenter: presenter
        )

        let result = await useCase.execute()

        XCTAssertEqual(result, .shown)
        XCTAssertEqual(presenter.showCallCount, 1)
        XCTAssertEqual(presenter.lastCatalog?.shortcuts.count, 1)
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
    let catalog: ShortcutCatalog?
    let error: Error?

    func shortcuts(for bundleID: String) async throws -> ShortcutCatalog? {
        if let error {
            throw error
        }
        return catalog
    }
}

@MainActor
private final class SpyOverlayPresenter: OverlayPresenter {
    private(set) var showCallCount = 0
    private(set) var lastCatalog: ShortcutCatalog?

    func show(catalog: ShortcutCatalog, app: AppContext) {
        showCallCount += 1
        lastCatalog = catalog
    }

    func hide() {}
}
