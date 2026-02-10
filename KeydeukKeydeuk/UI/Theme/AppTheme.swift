import AppKit
import SwiftUI

enum ThemeText {
    static func title(for theme: Preferences.Theme) -> String {
        switch theme {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .graphite: return "Graphite"
        case .warmPaper: return "Warm Paper"
        case .nordMist: return "Nord Mist"
        case .highContrast: return "High Contrast"
        }
    }

    static func descriptionKey(for theme: Preferences.Theme) -> LocalizedStringKey {
        switch theme {
        case .system: return "theme.description.system"
        case .light: return "theme.description.light"
        case .dark: return "theme.description.dark"
        case .graphite: return "theme.description.graphite"
        case .warmPaper: return "theme.description.warm_paper"
        case .nordMist: return "theme.description.nord_mist"
        case .highContrast: return "theme.description.high_contrast"
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

private struct AppThemePresetKey: EnvironmentKey {
    static let defaultValue: Preferences.ThemePreset = .frost
}

extension EnvironmentValues {
    var appEffectiveColorScheme: ColorScheme {
        get { self[AppEffectiveColorSchemeKey.self] }
        set { self[AppEffectiveColorSchemeKey.self] = newValue }
    }

    var appThemePreset: Preferences.ThemePreset {
        get { self[AppThemePresetKey.self] }
        set { self[AppThemePresetKey.self] = newValue }
    }
}

extension View {
    func applyTheme(mode: Preferences.ThemeMode, preset: Preferences.ThemePreset) -> some View {
        let scheme = ThemeModeResolver.effectiveColorScheme(for: mode)
        return self
            .environment(\.appEffectiveColorScheme, scheme)
            .environment(\.appThemePreset, preset)
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
    let settingsWindowBackground: Color
    let settingsTabActiveBackground: Color
    let settingsSectionBackground: Color
    let settingsErrorBackground: Color

    let overlayBackdrop: Color
    let overlayPanelBackground: Color
    let overlayPanelBorder: Color
    let overlaySearchBackground: Color
    let overlayRowBackground: Color
    let overlayRowHoverBackground: Color
    let overlayShadow: Color

    @MainActor
    static func resolved(for preset: Preferences.ThemePreset, scheme: ColorScheme) -> ThemePalette {
        ThemePaletteCatalog.palette(for: preset, scheme: scheme)
    }

    @MainActor
    static func resolved(for scheme: ColorScheme) -> ThemePalette {
        resolved(for: .frost, scheme: scheme)
    }
}

private typealias ThemePaletteBuilder = (ColorScheme) -> ThemePalette

@MainActor
private enum ThemePaletteCatalog {
    private static let builders: [Preferences.ThemePreset: ThemePaletteBuilder] = [
        .frost: frost,
        .graphite: graphite,
        .warmPaper: warmPaper,
        .nordMist: nordMist,
        .highContrast: highContrast
    ]

    static func palette(for preset: Preferences.ThemePreset, scheme: ColorScheme) -> ThemePalette {
        guard let builder = builders[preset] else { return frost(scheme) }
        return builder(scheme)
    }

    private static func frost(_ scheme: ColorScheme) -> ThemePalette {
        switch scheme {
        case .light:
            return ThemePalette(
                settingsWindowBackground: Color(red: 0.96, green: 0.965, blue: 0.98),
                settingsTabActiveBackground: Color.accentColor.opacity(0.12),
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
                settingsWindowBackground: Color(red: 0.14, green: 0.14, blue: 0.16),
                settingsTabActiveBackground: Color.accentColor.opacity(0.15),
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
            return frost(.dark)
        }
    }

    private static func graphite(_ scheme: ColorScheme) -> ThemePalette {
        switch scheme {
        case .light:
            return ThemePalette(
                settingsWindowBackground: Color(red: 0.92, green: 0.925, blue: 0.94),
                settingsTabActiveBackground: Color(red: 0.52, green: 0.54, blue: 0.58).opacity(0.18),
                settingsSectionBackground: Color(red: 0.90, green: 0.91, blue: 0.93),
                settingsErrorBackground: Color(red: 0.98, green: 0.88, blue: 0.88),
                overlayBackdrop: Color.black.opacity(0.20),
                overlayPanelBackground: Color(red: 0.92, green: 0.93, blue: 0.95).opacity(0.97),
                overlayPanelBorder: Color.black.opacity(0.09),
                overlaySearchBackground: Color.black.opacity(0.055),
                overlayRowBackground: Color.black.opacity(0.022),
                overlayRowHoverBackground: Color.black.opacity(0.052),
                overlayShadow: Color.black.opacity(0.12)
            )
        case .dark:
            return ThemePalette(
                settingsWindowBackground: Color(red: 0.12, green: 0.125, blue: 0.14),
                settingsTabActiveBackground: Color(red: 0.55, green: 0.57, blue: 0.62).opacity(0.20),
                settingsSectionBackground: Color(red: 0.15, green: 0.16, blue: 0.18),
                settingsErrorBackground: Color(red: 0.43, green: 0.16, blue: 0.16),
                overlayBackdrop: Color.black.opacity(0.62),
                overlayPanelBackground: Color(red: 0.11, green: 0.12, blue: 0.14).opacity(0.92),
                overlayPanelBorder: Color.white.opacity(0.09),
                overlaySearchBackground: Color.white.opacity(0.09),
                overlayRowBackground: Color.white.opacity(0.035),
                overlayRowHoverBackground: Color.white.opacity(0.09),
                overlayShadow: Color.black.opacity(0.50)
            )
        @unknown default:
            return graphite(.dark)
        }
    }

    private static func warmPaper(_ scheme: ColorScheme) -> ThemePalette {
        switch scheme {
        case .light:
            return ThemePalette(
                settingsWindowBackground: Color(red: 0.97, green: 0.945, blue: 0.91),
                settingsTabActiveBackground: Color(red: 0.72, green: 0.56, blue: 0.36).opacity(0.16),
                settingsSectionBackground: Color(red: 0.96, green: 0.93, blue: 0.88),
                settingsErrorBackground: Color(red: 0.99, green: 0.90, blue: 0.87),
                overlayBackdrop: Color(red: 0.16, green: 0.12, blue: 0.07).opacity(0.15),
                overlayPanelBackground: Color(red: 0.97, green: 0.95, blue: 0.91).opacity(0.97),
                overlayPanelBorder: Color(red: 0.28, green: 0.21, blue: 0.13).opacity(0.12),
                overlaySearchBackground: Color(red: 0.21, green: 0.16, blue: 0.11).opacity(0.07),
                overlayRowBackground: Color(red: 0.21, green: 0.16, blue: 0.11).opacity(0.03),
                overlayRowHoverBackground: Color(red: 0.21, green: 0.16, blue: 0.11).opacity(0.06),
                overlayShadow: Color.black.opacity(0.10)
            )
        case .dark:
            return ThemePalette(
                settingsWindowBackground: Color(red: 0.17, green: 0.145, blue: 0.12),
                settingsTabActiveBackground: Color(red: 0.78, green: 0.62, blue: 0.42).opacity(0.20),
                settingsSectionBackground: Color(red: 0.22, green: 0.19, blue: 0.16),
                settingsErrorBackground: Color(red: 0.47, green: 0.22, blue: 0.18),
                overlayBackdrop: Color.black.opacity(0.58),
                overlayPanelBackground: Color(red: 0.19, green: 0.16, blue: 0.13).opacity(0.91),
                overlayPanelBorder: Color(red: 0.95, green: 0.86, blue: 0.74).opacity(0.14),
                overlaySearchBackground: Color.white.opacity(0.08),
                overlayRowBackground: Color.white.opacity(0.03),
                overlayRowHoverBackground: Color.white.opacity(0.08),
                overlayShadow: Color.black.opacity(0.46)
            )
        @unknown default:
            return warmPaper(.dark)
        }
    }

    private static func nordMist(_ scheme: ColorScheme) -> ThemePalette {
        switch scheme {
        case .light:
            return ThemePalette(
                settingsWindowBackground: Color(red: 0.93, green: 0.955, blue: 0.975),
                settingsTabActiveBackground: Color(red: 0.36, green: 0.55, blue: 0.74).opacity(0.14),
                settingsSectionBackground: Color(red: 0.91, green: 0.94, blue: 0.97),
                settingsErrorBackground: Color(red: 0.95, green: 0.90, blue: 0.90),
                overlayBackdrop: Color(red: 0.11, green: 0.17, blue: 0.25).opacity(0.14),
                overlayPanelBackground: Color(red: 0.94, green: 0.96, blue: 0.98).opacity(0.96),
                overlayPanelBorder: Color(red: 0.19, green: 0.29, blue: 0.40).opacity(0.10),
                overlaySearchBackground: Color(red: 0.16, green: 0.23, blue: 0.33).opacity(0.06),
                overlayRowBackground: Color(red: 0.16, green: 0.23, blue: 0.33).opacity(0.025),
                overlayRowHoverBackground: Color(red: 0.16, green: 0.23, blue: 0.33).opacity(0.055),
                overlayShadow: Color.black.opacity(0.11)
            )
        case .dark:
            return ThemePalette(
                settingsWindowBackground: Color(red: 0.13, green: 0.16, blue: 0.20),
                settingsTabActiveBackground: Color(red: 0.45, green: 0.65, blue: 0.85).opacity(0.18),
                settingsSectionBackground: Color(red: 0.16, green: 0.20, blue: 0.25),
                settingsErrorBackground: Color(red: 0.36, green: 0.19, blue: 0.20),
                overlayBackdrop: Color.black.opacity(0.56),
                overlayPanelBackground: Color(red: 0.14, green: 0.18, blue: 0.23).opacity(0.90),
                overlayPanelBorder: Color(red: 0.71, green: 0.80, blue: 0.90).opacity(0.12),
                overlaySearchBackground: Color.white.opacity(0.08),
                overlayRowBackground: Color.white.opacity(0.03),
                overlayRowHoverBackground: Color.white.opacity(0.08),
                overlayShadow: Color.black.opacity(0.47)
            )
        @unknown default:
            return nordMist(.dark)
        }
    }

    private static func highContrast(_ scheme: ColorScheme) -> ThemePalette {
        switch scheme {
        case .light:
            return ThemePalette(
                settingsWindowBackground: Color(red: 0.97, green: 0.97, blue: 0.97),
                settingsTabActiveBackground: Color.black.opacity(0.10),
                settingsSectionBackground: Color.white,
                settingsErrorBackground: Color(red: 1.0, green: 0.90, blue: 0.90),
                overlayBackdrop: Color.black.opacity(0.22),
                overlayPanelBackground: Color.white.opacity(0.99),
                overlayPanelBorder: Color.black.opacity(0.14),
                overlaySearchBackground: Color.black.opacity(0.08),
                overlayRowBackground: Color.black.opacity(0.028),
                overlayRowHoverBackground: Color.black.opacity(0.08),
                overlayShadow: Color.black.opacity(0.16)
            )
        case .dark:
            return ThemePalette(
                settingsWindowBackground: Color(red: 0.06, green: 0.06, blue: 0.07),
                settingsTabActiveBackground: Color.white.opacity(0.14),
                settingsSectionBackground: Color(red: 0.09, green: 0.09, blue: 0.10),
                settingsErrorBackground: Color(red: 0.48, green: 0.18, blue: 0.18),
                overlayBackdrop: Color.black.opacity(0.68),
                overlayPanelBackground: Color(red: 0.08, green: 0.08, blue: 0.09).opacity(0.96),
                overlayPanelBorder: Color.white.opacity(0.16),
                overlaySearchBackground: Color.white.opacity(0.12),
                overlayRowBackground: Color.white.opacity(0.045),
                overlayRowHoverBackground: Color.white.opacity(0.12),
                overlayShadow: Color.black.opacity(0.58)
            )
        @unknown default:
            return highContrast(.dark)
        }
    }
}
