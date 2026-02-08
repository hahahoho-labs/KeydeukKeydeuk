import SwiftUI

struct AppWindowView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    @ObservedObject var settingsVM: SettingsViewModel
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset

    var body: some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
        Group {
            if onboardingVM.needsOnboarding {
                RootView(onboardingVM: onboardingVM, settingsVM: settingsVM)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("KeydeukKeydeuk is running")
                        .font(.headline)
                    Text("Use the status bar icon or hotkey to open overlay.")
                        .foregroundStyle(.secondary)
                    if let message = onboardingVM.permissionHint {
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
                .background(palette.settingsSectionBackground.opacity(0.7))
            }
        }
        .background(
            palette.overlayBackdrop
                .opacity(appEffectiveColorScheme == .dark ? 0.35 : 0.2)
                .ignoresSafeArea()
        )
    }
}
