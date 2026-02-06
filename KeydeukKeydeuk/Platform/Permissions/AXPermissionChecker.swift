import ApplicationServices
import Foundation

struct AXPermissionChecker: PermissionChecker {
    func state(for requirement: PermissionRequirement) -> PermissionState {
        switch requirement {
        case .accessibility:
            if AXIsProcessTrusted() {
                return .granted
            }
            return .notDetermined
        }
    }
}
