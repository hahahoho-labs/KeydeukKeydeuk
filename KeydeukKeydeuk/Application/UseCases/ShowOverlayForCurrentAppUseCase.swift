import Foundation
import os

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "ShowOverlay")

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
        let permState = permissionChecker.state(for: .accessibility)
        log.info("🔐 접근성 권한 상태: \(String(describing: permState))")

        guard permState == .granted else {
            log.warning("⛔ 접근성 권한 없음 → .needsPermission 반환")
            return .needsPermission
        }

        guard let app = appContextProvider.currentApp() else {
            log.warning("⚠️ 포커스된 앱 감지 실패 → .noFocusedApp 반환")
            return .noFocusedApp
        }
        log.info("🖥️ 포커스 앱: \(app.appName) (\(app.bundleID))")

        let catalog: ShortcutCatalog
        do {
            if let loaded = try await loadShortcuts.execute(bundleID: app.bundleID) {
                catalog = loaded
                log.info("📦 카탈로그 로드 완료: \(catalog.shortcuts.count)개 단축키 (소스: AX API)")
            } else {
                catalog = ShortcutCatalog(bundleID: app.bundleID, appName: app.appName, shortcuts: [])
                log.info("📦 앱에 메뉴바 단축키 없음 → 빈 카탈로그")
            }
        } catch {
            catalog = ShortcutCatalog(bundleID: app.bundleID, appName: app.appName, shortcuts: [])
            log.error("📦 단축키 추출 실패: \(error.localizedDescription) → 빈 카탈로그로 대체")
        }

        presenter.show(catalog: catalog, app: app)
        log.info("✅ 오버레이 표시 요청 완료 → .shown")
        return .shown
    }
}
