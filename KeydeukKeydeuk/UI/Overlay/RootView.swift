import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Welcome to KeydeukKeydeuk")
                .font(.title2.bold())

            if let permissionHint = viewModel.permissionHint {
                Text(permissionHint)
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            OnboardingView(
                permissionState: viewModel.permissionState,
                requestPermissionPrompt: {
                    viewModel.requestAccessibilityPermissionPrompt()
                },
                openAccessibilitySettings: {
                    viewModel.openAccessibilityPreferences()
                },
                refreshPermissionState: {
                    viewModel.refreshPermissionState()
                }
            )

            SettingsView(viewModel: viewModel)

            HStack {
                Spacer()
                Button("Finish Setup") {
                    viewModel.completeOnboardingIfPossible()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canFinishOnboarding)
            }
        }
        .padding(20)
    }
}
