import SwiftUI

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @ObservedObject var settingsVM: SettingsViewModel
    @ObservedObject var onboardingVM: OnboardingViewModel
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let error = settingsVM.errorMessage {
                    errorBanner(error)
                }
                activationSection
                behaviorSection
                permissionSection
            }
            .padding(20)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
        return HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.callout)
            Spacer()
            Button {
                settingsVM.dismissError()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(palette.settingsErrorBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Activation

    private var activationSection: some View {
        SettingsSection(title: "Activation") {
            Picker(
                "Trigger",
                selection: Binding(
                    get: { settingsVM.selectedTriggerType },
                    set: { settingsVM.setTriggerType($0) }
                )
            ) {
                Text("Hold ⌘ Command").tag(Preferences.Trigger.holdCommand)
                Text("Global Hotkey").tag(Preferences.Trigger.globalHotkey)
            }
            .pickerStyle(.menu)

            if settingsVM.selectedTriggerType == .holdCommand {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Hold Duration")
                        Spacer()
                        Text("\(settingsVM.holdDuration, specifier: "%.1f")s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { settingsVM.holdDuration },
                            set: { settingsVM.setHoldDuration($0) }
                        ),
                        in: 0.3...3.0,
                        step: 0.1
                    )
                }
            } else {
                Picker(
                    "Global Hotkey",
                    selection: Binding(
                        get: { settingsVM.selectedHotkeyPresetID },
                        set: { settingsVM.selectHotkeyPreset(id: $0) }
                    )
                ) {
                    ForEach(settingsVM.hotkeyPresets) { preset in
                        Text(preset.title).tag(preset.id)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        SettingsSection(title: "Behavior") {
            Toggle(
                "Hide on ESC",
                isOn: Binding(
                    get: { settingsVM.autoHideOnEsc },
                    set: { settingsVM.setAutoHideOnEsc($0) }
                )
            )

            Toggle(
                "Hide on App Switch",
                isOn: Binding(
                    get: { settingsVM.autoHideOnAppSwitch },
                    set: { settingsVM.setAutoHideOnAppSwitch($0) }
                )
            )
        }
    }

    // MARK: - Permission

    private var permissionSection: some View {
        SettingsSection(title: "Permissions") {
            HStack {
                Text("Accessibility")
                Spacer()
                permissionBadge

                Button {
                    onboardingVM.refreshPermissionState()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Refresh permission status")
            }

            if onboardingVM.permissionState != .granted {
                Text("Overlay requires Accessibility permission to read menu shortcuts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Open Accessibility Settings") {
                    onboardingVM.openAccessibilityPreferences()
                }

                if let hint = onboardingVM.permissionHint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private var permissionBadge: some View {
        switch onboardingVM.permissionState {
        case .granted:
            Label("Granted", systemImage: "checkmark.circle.fill")
                .font(.callout.weight(.medium))
                .foregroundStyle(.green)
        case .denied:
            Label("Denied", systemImage: "xmark.circle.fill")
                .font(.callout.weight(.medium))
                .foregroundStyle(.red)
        case .notDetermined:
            Label("Not Determined", systemImage: "questionmark.circle.fill")
                .font(.callout.weight(.medium))
                .foregroundStyle(.orange)
        }
    }
}

// MARK: - Theme Tab

struct ThemeSettingsTab: View {
    @ObservedObject var settingsVM: SettingsViewModel
    @State private var draftTheme: Preferences.Theme?

    private let defaultThemes: [Preferences.Theme] = [.system, .light, .dark]
    private let customThemes: [Preferences.Theme] = [.graphite, .warmPaper, .nordMist, .highContrast]

    private var selectedTheme: Preferences.Theme {
        draftTheme ?? settingsVM.selectedTheme
    }

    private var hasPendingThemeChange: Bool {
        selectedTheme != settingsVM.selectedTheme
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection(title: "Theme") {
                    Text("Choose one theme for onboarding, settings, and overlay.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Picker(
                        "Theme",
                        selection: Binding(
                            get: { selectedTheme },
                            set: { draftTheme = $0 }
                        )
                    ) {
                        ForEach(defaultThemes, id: \.self) { theme in
                            Text(ThemeText.title(for: theme)).tag(theme)
                        }

                        Divider()

                        ForEach(customThemes, id: \.self) { theme in
                            Text(ThemeText.title(for: theme)).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(ThemeText.description(for: selectedTheme))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                SettingsSection(title: "Preview") {
                    VStack(spacing: 10) {
                        ThemePreviewCard(theme: selectedTheme)
                            .frame(maxWidth: 640)
                            .frame(maxWidth: .infinity)

                        Text(hasPendingThemeChange ? "Click Save to apply this preview." : "This theme is currently active.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Spacer()
                    Button("Save") {
                        let targetTheme = selectedTheme
                        settingsVM.setTheme(targetTheme)
                        if settingsVM.selectedTheme == targetTheme {
                            draftTheme = nil
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasPendingThemeChange)
                    .applyDisabledButtonAppearance()
                }
            }
            .padding(20)
        }
        .onAppear {
            draftTheme = nil
        }
    }
}

private struct ThemePreviewCard: View {
    let theme: Preferences.Theme

    private var scheme: ColorScheme {
        ThemeModeResolver.effectiveColorScheme(for: theme.mode)
    }

    private var primaryText: Color {
        switch theme {
        case .system:
            return scheme == .dark
                ? Color.white.opacity(0.93)
                : Color(red: 0.15, green: 0.17, blue: 0.22)
        case .light:
            return Color(red: 0.15, green: 0.17, blue: 0.22)
        case .dark, .graphite:
            return Color.white.opacity(0.93)
        case .warmPaper:
            return Color(red: 0.25, green: 0.19, blue: 0.12)
        case .nordMist:
            return Color(red: 0.89, green: 0.94, blue: 0.98)
        case .highContrast:
            return scheme == .dark ? .white : .black
        }
    }

    private var secondaryText: Color {
        switch theme {
        case .system:
            return scheme == .dark
                ? Color.white.opacity(0.72)
                : Color(red: 0.31, green: 0.34, blue: 0.41)
        case .light:
            return Color(red: 0.31, green: 0.34, blue: 0.41)
        case .dark, .graphite:
            return Color.white.opacity(0.72)
        case .warmPaper:
            return Color(red: 0.39, green: 0.30, blue: 0.21)
        case .nordMist:
            return Color(red: 0.71, green: 0.80, blue: 0.89)
        case .highContrast:
            return scheme == .dark ? Color.white.opacity(0.88) : Color.black.opacity(0.82)
        }
    }

    var body: some View {
        let palette = ThemePalette.resolved(for: theme.preset, scheme: scheme)
        ZStack {
            palette.overlayBackdrop
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.15),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.accentColor.opacity(0.7))
                        .frame(width: 10, height: 10)
                    Text("Preview Overlay")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(primaryText)
                    Spacer()
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(palette.overlaySearchBackground)
                        .frame(width: 100, height: 18)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider()

                HStack(alignment: .top, spacing: 10) {
                    ThemePreviewColumn(
                        title: "App",
                        rows: ["Hide", "Preferences", "Quit"],
                        palette: palette,
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )
                    ThemePreviewColumn(
                        title: "Window",
                        rows: ["Minimize", "Zoom", "Bring All to Front"],
                        palette: palette,
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )
                    ThemePreviewColumn(
                        title: "Help",
                        rows: ["Search", "Support", "Shortcuts"],
                        palette: palette,
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )
                }
                .padding(10)
            }
            .background(palette.overlayPanelBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(palette.overlayPanelBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(20)
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(palette.overlayPanelBorder.opacity(0.65), lineWidth: 1)
        )
        .preferredColorScheme(scheme)
    }
}

private struct ThemePreviewColumn: View {
    let title: String
    let rows: [String]
    let palette: ThemePalette
    let primaryText: Color
    let secondaryText: Color
    private let keySamples = ["⌘1", "⌘2", "⌘3", "⌘4", "⌘5", "⌘6"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(secondaryText)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 4) {
                    Text(row)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(primaryText)
                    Spacer(minLength: 4)
                    Text(keySamples[index % keySamples.count])
                        .font(.caption.monospaced())
                        .foregroundStyle(secondaryText)
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 5)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(palette.overlayRowBackground)
                )
            }
        }
    }
}

// MARK: - Help Tab (Placeholder)

struct HelpSettingsTab: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("Help & About")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Usage guide, FAQ, and version information.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Onboarding Trigger Settings (simplified for RootView)

struct OnboardingTriggerSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SettingsSection(title: "Trigger Settings") {
            Picker(
                "Trigger",
                selection: Binding(
                    get: { viewModel.selectedTriggerType },
                    set: { viewModel.setTriggerType($0) }
                )
            ) {
                Text("Hold ⌘ Command").tag(Preferences.Trigger.holdCommand)
                Text("Global Hotkey").tag(Preferences.Trigger.globalHotkey)
            }
            .pickerStyle(.menu)

            if viewModel.selectedTriggerType == .holdCommand {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Hold Duration")
                        Spacer()
                        Text("\(viewModel.holdDuration, specifier: "%.1f")s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { viewModel.holdDuration },
                            set: { viewModel.setHoldDuration($0) }
                        ),
                        in: 0.3...3.0,
                        step: 0.1
                    )
                }
            } else {
                Picker(
                    "Global Hotkey",
                    selection: Binding(
                        get: { viewModel.selectedHotkeyPresetID },
                        set: { viewModel.selectHotkeyPreset(id: $0) }
                    )
                ) {
                    ForEach(viewModel.hotkeyPresets) { preset in
                        Text(preset.title).tag(preset.id)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

// MARK: - Reusable Section Container

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset

    var body: some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(palette.settingsSectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
