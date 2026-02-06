import SwiftUI

struct RootView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    @ObservedObject var settingsVM: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Welcome to KeydeukKeydeuk")
                .font(.title2.bold())

            if let permissionHint = onboardingVM.permissionHint {
                Text(permissionHint)
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            OnboardingView(
                permissionState: onboardingVM.permissionState,
                requestPermissionPrompt: {
                    onboardingVM.requestAccessibilityPermissionPrompt()
                },
                openAccessibilitySettings: {
                    onboardingVM.openAccessibilityPreferences()
                },
                refreshPermissionState: {
                    onboardingVM.refreshPermissionState()
                }
            )

            OnboardingTriggerSettingsView(viewModel: settingsVM)

            HStack {
                Spacer()
                Button("Finish Setup") {
                    onboardingVM.completeOnboardingIfPossible()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!onboardingVM.canFinishOnboarding)
            }
        }
        .padding(20)
    }
}
