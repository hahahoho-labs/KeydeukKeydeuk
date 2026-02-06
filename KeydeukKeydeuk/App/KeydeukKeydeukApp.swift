import AppKit
import SwiftUI

struct ContainerHolder {
    @MainActor static let shared = AppContainer()
}

@main
struct KeydeukKeydeukApp: App {
    @StateObject private var viewModel: OverlayViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ContainerHolder.shared.overlayViewModel)
        Task { @MainActor in
            ContainerHolder.shared.start()
        }
    }

    var body: some Scene {
        WindowGroup("Onboarding") {
            Group {
                if viewModel.needsOnboarding {
                    RootView(viewModel: viewModel)
                        .frame(minWidth: 720, minHeight: 520)
                } else {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .onAppear {
                            NSApp.windows.forEach { $0.close() }
                        }
                }
            }
        }

        Settings {
            Text("Settings window is not implemented yet.")
                .padding(20)
        }
    }
}
