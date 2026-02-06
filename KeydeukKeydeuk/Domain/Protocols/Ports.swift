import Foundation

protocol EventSource: AnyObject {
    var onEvent: ((KeyEvent) -> Void)? { get set }
    func start()
    func stop()
}

protocol PermissionChecker {
    func state(for requirement: PermissionRequirement) -> PermissionState
}

protocol PermissionGuide {
    func requestAccessibilityPermissionPrompt() -> Bool
    func openAccessibilitySettings()
}

protocol PreferencesStore {
    func load() -> Preferences
    func save(_ preferences: Preferences) throws
}

protocol ShortcutRepository {
    func shortcuts(for bundleID: String) async throws -> ShortcutCatalog?
}

protocol AppContextProvider {
    func currentApp() -> AppContext?
}

@MainActor
protocol OverlayPresenter {
    func show(catalog: ShortcutCatalog, app: AppContext)
    func hide()
}

protocol BillingService {
    func hasProAccess() async -> Bool
}
