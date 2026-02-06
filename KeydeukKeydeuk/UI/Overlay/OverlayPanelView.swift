import SwiftUI

struct OverlayPanelView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.requestHide()
                }

            OverlayView(viewModel: viewModel)
                .frame(maxWidth: 1280, maxHeight: 820)
                .padding(32)
        }
        .onExitCommand {
            viewModel.requestHide()
        }
    }
}
