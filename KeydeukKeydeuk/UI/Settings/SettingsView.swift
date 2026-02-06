import SwiftUI

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @ObservedObject var settingsVM: SettingsViewModel
    @ObservedObject var onboardingVM: OnboardingViewModel

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
        HStack(spacing: 8) {
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
        .background(Color.red.opacity(0.1))
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

// MARK: - Theme Tab (Placeholder)

struct ThemeSettingsTab: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "paintbrush")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("Theme settings coming soon")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Customize overlay appearance, colors, and layout.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
