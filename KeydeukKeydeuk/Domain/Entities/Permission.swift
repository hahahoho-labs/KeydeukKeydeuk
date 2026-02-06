import Foundation

enum PermissionState: Equatable {
    case granted
    case denied
    case notDetermined
}

enum PermissionRequirement: Equatable {
    case accessibility
}
