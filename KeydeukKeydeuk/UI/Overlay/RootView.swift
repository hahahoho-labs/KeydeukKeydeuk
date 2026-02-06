import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("KeydeukKeydeuk MVP")
                    .font(.title2.bold())
                Spacer()
                Button("Show Overlay") {
                    Task { await viewModel.requestShow() }
                }
                Button("Hide") {
                    viewModel.requestHide()
                }
            }

            if let permissionHint = viewModel.permissionHint {
                Text(permissionHint)
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            if viewModel.isVisible {
                OverlayView(viewModel: viewModel)
            } else {
                OnboardingView()
            }
        }
        .padding(20)
    }
}
