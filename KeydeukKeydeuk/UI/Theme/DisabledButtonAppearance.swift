import SwiftUI

private struct DisabledButtonAppearanceModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .opacity(isEnabled ? 1.0 : 0.58)
            .saturation(isEnabled ? 1.0 : 0.35)
            .brightness(isEnabled ? 0.0 : -0.12)
    }
}

extension View {
    func applyDisabledButtonAppearance() -> some View {
        modifier(DisabledButtonAppearanceModifier())
    }
}
