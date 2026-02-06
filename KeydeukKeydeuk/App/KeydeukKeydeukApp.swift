import SwiftUI

struct ContainerHolder {
    @MainActor static let shared = AppContainer()
}

@main
struct KeydeukKeydeukApp: App {
    @State private var hasStarted = false
    @State private var container = ContainerHolder.shared

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: container.overlayViewModel)
                .frame(minWidth: 720, minHeight: 520)
                .onAppear {
                    guard !hasStarted else { return }
                    hasStarted = true
                    container.start()
                }
        }
    }
}
