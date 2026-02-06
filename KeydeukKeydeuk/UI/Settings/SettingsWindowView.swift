import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("KeydeukKeydeuk Settings")
                .font(.title3.weight(.semibold))

            SettingsView(viewModel: viewModel)
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 260)
    }
}
