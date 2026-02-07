import AppKit
import SwiftUI

enum ThemeModeText {
    static func title(for mode: Preferences.ThemeMode) -> String {
        switch mode {
        case .system: return "System Theme"
        case .light: return "Light Theme"
        case .dark: return "Dark Theme"
        }
    }

    static func description(for mode: Preferences.ThemeMode) -> String {
        switch mode {
        case .system: return "Follow macOS appearance"
        case .light: return "Always use light appearance"
        case .dark: return "Always use dark appearance"
        }
    }
}

enum ThemeModeResolver {
    static func effectiveColorScheme(for mode: Preferences.ThemeMode, app: NSApplication? = NSApp) -> ColorScheme {
        switch mode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            guard let app else { return .light }
            let match = app.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
            return match == .darkAqua ? .dark : .light
        }
    }

    static func windowAppearance(for mode: Preferences.ThemeMode) -> NSAppearance? {
        switch mode {
        case .system:
            return nil
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
}

private struct AppEffectiveColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme = .light
}

extension EnvironmentValues {
    var appEffectiveColorScheme: ColorScheme {
        get { self[AppEffectiveColorSchemeKey.self] }
        set { self[AppEffectiveColorSchemeKey.self] = newValue }
    }
}

extension View {
    func applyThemeMode(_ mode: Preferences.ThemeMode) -> some View {
        let scheme = ThemeModeResolver.effectiveColorScheme(for: mode)
        return self
            .environment(\.appEffectiveColorScheme, scheme)
            .background(WindowAppearanceConfigurator(mode: mode).frame(width: 0, height: 0))
            .preferredColorScheme(scheme)
    }
}

private struct WindowAppearanceConfigurator: NSViewRepresentable {
    let mode: Preferences.ThemeMode

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { [weak view] in
            applyAppearance(from: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            applyAppearance(from: nsView)
        }
    }

    private func applyAppearance(from view: NSView?) {
        guard let window = view?.window else { return }
        window.appearance = ThemeModeResolver.windowAppearance(for: mode)
    }
}

struct ThemePalette {
    let settingsSectionBackground: Color
    let settingsErrorBackground: Color

    let overlayBackdrop: Color
    let overlayPanelBackground: Color
    let overlayPanelBorder: Color
    let overlaySearchBackground: Color
    let overlayRowBackground: Color
    let overlayRowHoverBackground: Color
    let overlayShadow: Color

    static func resolved(for scheme: ColorScheme) -> ThemePalette {
        switch scheme {
        case .light:
            return ThemePalette(
                settingsSectionBackground: Color(red: 0.94, green: 0.95, blue: 0.97),
                settingsErrorBackground: Color(red: 1.0, green: 0.92, blue: 0.92),
                overlayBackdrop: Color.black.opacity(0.16),
                overlayPanelBackground: Color(red: 0.97, green: 0.97, blue: 0.98).opacity(0.96),
                overlayPanelBorder: Color.black.opacity(0.06),
                overlaySearchBackground: Color.black.opacity(0.045),
                overlayRowBackground: Color.black.opacity(0.018),
                overlayRowHoverBackground: Color.black.opacity(0.045),
                overlayShadow: Color.black.opacity(0.10)
            )
        case .dark:
            return ThemePalette(
                settingsSectionBackground: Color.white.opacity(0.08),
                settingsErrorBackground: Color(red: 0.42, green: 0.14, blue: 0.14),
                overlayBackdrop: Color.black.opacity(0.55),
                overlayPanelBackground: Color(red: 0.13, green: 0.13, blue: 0.15).opacity(0.88),
                overlayPanelBorder: Color.white.opacity(0.08),
                overlaySearchBackground: Color.white.opacity(0.08),
                overlayRowBackground: Color.white.opacity(0.03),
                overlayRowHoverBackground: Color.white.opacity(0.08),
                overlayShadow: Color.black.opacity(0.45)
            )
        @unknown default:
            return resolved(for: .dark)
        }
    }
}
