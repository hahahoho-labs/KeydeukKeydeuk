import SwiftUI

struct OverlayPanelView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.48)
                .ignoresSafeArea()

            OverlayView(viewModel: viewModel)
                .frame(maxWidth: 1120, maxHeight: 720)
                .padding(32)
        }
        .onExitCommand {
            viewModel.requestHide()
        }
    }
}
