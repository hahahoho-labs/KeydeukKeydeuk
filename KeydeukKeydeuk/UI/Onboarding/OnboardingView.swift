import SwiftUI

struct OnboardingView: View {
    let permissionState: PermissionState
    let requestPermissionPrompt: () -> Void
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset

    private var permissionStatusKey: String {
        switch permissionState {
        case .granted:
            return "onboarding.permission.status.granted"
        case .denied:
            return "onboarding.permission.status.denied"
        case .notDetermined:
            return "onboarding.permission.status.not_determined"
        }
    }

    var body: some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
        VStack(alignment: .leading, spacing: 10) {
            Text("onboarding.title")
                .font(.headline)
            Text("onboarding.description")
                .foregroundStyle(.secondary)
            Text(LocalizedStringKey(permissionStatusKey))
                .font(.callout.weight(.semibold))

            HStack(spacing: 8) {
                Button("onboarding.request_permission") {
                    requestPermissionPrompt()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(palette.settingsSectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
