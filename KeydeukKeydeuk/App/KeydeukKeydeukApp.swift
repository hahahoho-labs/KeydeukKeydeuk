import AppKit
import SwiftUI

struct ContainerHolder {
    @MainActor static let shared = AppContainer()
}

@main
struct KeydeukKeydeukApp: App {
    @StateObject private var overlayVM: OverlayViewModel
    @StateObject private var settingsVM: SettingsViewModel
    @StateObject private var onboardingVM: OnboardingViewModel

    init() {
        let container = ContainerHolder.shared
        _overlayVM = StateObject(wrappedValue: container.overlayViewModel)
        _settingsVM = StateObject(wrappedValue: container.settingsViewModel)
        _onboardingVM = StateObject(wrappedValue: container.onboardingViewModel)
        Task { @MainActor in
            ContainerHolder.shared.start()
        }
    }

    var body: some Scene {
        WindowGroup("Onboarding") {
            AppWindowView(onboardingVM: onboardingVM, settingsVM: settingsVM)
                .frame(minWidth: 720, minHeight: 520)
        }

        Settings {
            SettingsWindowView(settingsVM: settingsVM, onboardingVM: onboardingVM)
        }
    }
}
