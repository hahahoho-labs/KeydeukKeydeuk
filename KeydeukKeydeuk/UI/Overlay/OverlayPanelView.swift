import SwiftUI

struct OverlayPanelView: View {
    @ObservedObject var viewModel: OverlayViewModel
    @ObservedObject var themeModeStore: ThemeModeStore
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme

    var body: some View {
        let palette = ThemePalette.resolved(for: appEffectiveColorScheme)
        ZStack {
            palette.overlayBackdrop
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
        .applyThemeMode(themeModeStore.selectedThemeMode)
    }
}
