import SwiftUI

struct RootView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    @ObservedObject var settingsVM: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("onboarding.welcome.title")
                .font(.title2.bold())

            if let permissionHintKey = onboardingVM.permissionHintKey {
                Text(LocalizedStringKey(permissionHintKey))
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            OnboardingView(
                permissionState: onboardingVM.permissionState,
                requestPermissionPrompt: {
                    onboardingVM.requestAccessibilityPermissionPrompt()
                }
            )

            OnboardingTriggerSettingsView(viewModel: settingsVM)

            HStack {
                Spacer()
                Button("onboarding.finish_setup") {
                    onboardingVM.completeOnboardingIfPossible()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!onboardingVM.canFinishOnboarding)
                .applyDisabledButtonAppearance()
            }
        }
        .padding(20)
    }
}
