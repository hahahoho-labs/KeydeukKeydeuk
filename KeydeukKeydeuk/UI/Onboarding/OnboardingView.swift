import SwiftUI

struct OnboardingView: View {
    let permissionState: PermissionState
    let requestPermissionPrompt: () -> Void
    let openAccessibilitySettings: () -> Void
    let refreshPermissionState: () -> Void
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset

    private var permissionStatusText: String {
        switch permissionState {
        case .granted:
            return "Accessibility: Granted"
        case .denied:
            return "Accessibility: Denied"
        case .notDetermined:
            return "Accessibility: Not Determined"
        }
    }

    var body: some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
        VStack(alignment: .leading, spacing: 10) {
            Text("Onboarding")
                .font(.headline)
            Text("Grant Accessibility permission and configure trigger settings.")
                .foregroundStyle(.secondary)
            Text(permissionStatusText)
                .font(.callout.weight(.semibold))

            HStack(spacing: 8) {
                Button("Request Permission") {
                    requestPermissionPrompt()
                }
                .buttonStyle(.borderedProminent)

                Button("Open Accessibility Settings") {
                    openAccessibilitySettings()
                }
                .buttonStyle(.bordered)

                Button("Refresh Status") {
                    refreshPermissionState()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(palette.settingsSectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
