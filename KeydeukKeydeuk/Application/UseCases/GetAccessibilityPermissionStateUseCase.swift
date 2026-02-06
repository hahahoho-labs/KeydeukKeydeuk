import Foundation

struct GetAccessibilityPermissionStateUseCase {
    private let permissionChecker: PermissionChecker

    init(permissionChecker: PermissionChecker) {
        self.permissionChecker = permissionChecker
    }

    func execute() -> PermissionState {
        permissionChecker.state(for: .accessibility)
    }
}
