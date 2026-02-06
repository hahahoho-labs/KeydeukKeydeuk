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
            AppWindowView(viewModel: viewModel)
                .frame(minWidth: 720, minHeight: 520)
        }

        Settings {
            SettingsWindowView(viewModel: viewModel)
        }
    }
}
