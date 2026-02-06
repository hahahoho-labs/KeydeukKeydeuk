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

        guard let catalog = try? await loadShortcuts.execute(bundleID: app.bundleID) else {
            return .noCatalog
        }

        presenter.show(catalog: catalog, app: app)
        return .shown
    }
}
