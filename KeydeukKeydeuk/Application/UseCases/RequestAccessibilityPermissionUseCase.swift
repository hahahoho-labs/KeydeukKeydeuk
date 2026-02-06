import Foundation

struct RequestAccessibilityPermissionUseCase {
    private let permissionGuide: PermissionGuide

    init(permissionGuide: PermissionGuide) {
        self.permissionGuide = permissionGuide
    }

    func execute() -> Bool {
        permissionGuide.requestAccessibilityPermissionPrompt()
    }
}
