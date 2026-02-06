import SwiftUI

struct AppWindowView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    @ObservedObject var settingsVM: SettingsViewModel

    var body: some View {
        Group {
            if onboardingVM.needsOnboarding {
                RootView(onboardingVM: onboardingVM, settingsVM: settingsVM)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("KeydeukKeydeuk is running")
                        .font(.headline)
                    Text("Use the status bar icon or hotkey to open overlay.")
                        .foregroundStyle(.secondary)
                    if let message = onboardingVM.permissionHint {
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
            }
        }
    }
}
