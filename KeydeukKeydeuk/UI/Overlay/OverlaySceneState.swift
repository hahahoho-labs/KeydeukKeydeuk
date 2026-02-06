import Combine
import Foundation

@MainActor
final class OverlaySceneState: ObservableObject {
    @Published var isVisible = false
    @Published var appName = ""
    @Published var appBundleID = ""
    @Published var shortcuts: [Shortcut] = []
}
