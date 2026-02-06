import Foundation

struct OpenAccessibilitySettingsUseCase {
    private let permissionGuide: PermissionGuide

    init(permissionGuide: PermissionGuide) {
        self.permissionGuide = permissionGuide
    }

    func execute() {
        permissionGuide.openAccessibilitySettings()
    }
}
