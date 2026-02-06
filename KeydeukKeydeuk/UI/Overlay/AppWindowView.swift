import SwiftUI

struct AppWindowView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        Group {
            if viewModel.needsOnboarding {
                RootView(viewModel: viewModel)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("KeydeukKeydeuk is running")
                        .font(.headline)
                    Text("Use the status bar icon or hotkey to open overlay.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
            }
        }
    }
}
