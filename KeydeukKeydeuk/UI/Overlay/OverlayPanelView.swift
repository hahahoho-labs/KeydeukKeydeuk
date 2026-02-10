import SwiftUI

struct OverlayPanelView: View {
    @ObservedObject var viewModel: OverlayViewModel
    @ObservedObject var themeModeStore: ThemeModeStore
    @ObservedObject var localeStore: AppLocaleStore
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset

    var body: some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
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
        .applyTheme(
            mode: themeModeStore.selectedThemeMode,
            preset: themeModeStore.selectedThemePreset
        )
        .environment(\.locale, localeStore.locale)
    }
}
