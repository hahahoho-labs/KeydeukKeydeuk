import Foundation

struct ShowOverlayForCurrentAppUseCase {
    enum Result: Equatable {
        case shown
        case needsPermission
        case noFocusedApp
        case noCatalog
    }

    private let permissionChecker: PermissionChecker
    private let appContextProvider: AppContextProvider
    private let loadShortcuts: LoadShortcutsForAppUseCase
    private let presenter: OverlayPresenter

    init(
        permissionChecker: PermissionChecker,
        appContextProvider: AppContextProvider,
        loadShortcuts: LoadShortcutsForAppUseCase,
        presenter: OverlayPresenter
    ) {
        self.permissionChecker = permissionChecker
        self.appContextProvider = appContextProvider
        self.loadShortcuts = loadShortcuts
        self.presenter = presenter
    }

    @MainActor
    func execute() async -> Result {
        guard permissionChecker.state(for: .accessibility) == .granted else {
            return .needsPermission
        }

        guard let app = appContextProvider.currentApp() else {
            return .noFocusedApp
        }

        let catalog: ShortcutCatalog
        if let loaded = try? await loadShortcuts.execute(bundleID: app.bundleID) {
            catalog = loaded
        } else {
            catalog = ShortcutCatalog(bundleID: app.bundleID, appName: app.appName, shortcuts: [])
        }

        presenter.show(catalog: catalog, app: app)
        return .shown
    }
}
