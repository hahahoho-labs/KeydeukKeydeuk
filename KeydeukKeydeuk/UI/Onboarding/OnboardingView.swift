import SwiftUI

struct OnboardingView: View {
    let permissionState: PermissionState
    let openAccessibilitySettings: () -> Void
    let refreshPermissionState: () -> Void

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
        VStack(alignment: .leading, spacing: 10) {
            Text("Onboarding")
                .font(.headline)
            Text("Grant Accessibility permission and configure trigger settings.")
                .foregroundStyle(.secondary)
            Text(permissionStatusText)
                .font(.callout.weight(.semibold))

            HStack(spacing: 8) {
                Button("Open Accessibility Settings") {
                    openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)

                Button("Refresh Status") {
                    refreshPermissionState()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
