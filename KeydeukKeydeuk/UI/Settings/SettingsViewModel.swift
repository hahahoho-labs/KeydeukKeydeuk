import Combine
import Foundation
import os

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "SettingsVM")

@MainActor
final class SettingsViewModel: ObservableObject {
    struct HotkeyPreset: Identifiable, Equatable {
        let id: String
        let title: String
        let keyCode: Int
        let modifiers: KeyModifiers
    }

    @Published private(set) var preferences: Preferences
    @Published private(set) var errorMessage: String?

    private let loadPreferences: LoadPreferencesUseCase
    private let updatePreferencesUseCase: UpdatePreferencesUseCase

    let hotkeyPresets: [HotkeyPreset] = [
        HotkeyPreset(id: "cmd-shift-k", title: "Command + Shift + K", keyCode: 40, modifiers: [.command, .shift]),
        HotkeyPreset(id: "cmd-shift-l", title: "Command + Shift + L", keyCode: 37, modifiers: [.command, .shift]),
        HotkeyPreset(id: "cmd-shift-j", title: "Command + Shift + J", keyCode: 38, modifiers: [.command, .shift])
    ]

    init(
        loadPreferences: LoadPreferencesUseCase,
        updatePreferences: UpdatePreferencesUseCase
    ) {
        self.loadPreferences = loadPreferences
        self.updatePreferencesUseCase = updatePreferences
        self.preferences = loadPreferences.execute()
    }

    // MARK: - Computed Properties

    var selectedTriggerType: Preferences.Trigger { preferences.trigger }
    var holdDuration: Double { preferences.holdDurationSeconds }
    var autoHideOnEsc: Bool { preferences.autoHideOnEsc }
    var autoHideOnAppSwitch: Bool { preferences.autoHideOnAppSwitch }
    var selectedTheme: Preferences.Theme { preferences.theme }

    var selectedHotkeyPresetID: String {
        hotkeyPresets.first {
            $0.keyCode == preferences.hotkeyKeyCode && $0.modifiers == preferences.hotkeyModifiers
        }?.id ?? hotkeyPresets.first?.id ?? "cmd-shift-k"
    }

    // MARK: - Actions

    func refreshPreferences() {
        preferences = loadPreferences.execute()
    }

    func setTriggerType(_ type: Preferences.Trigger) {
        updatePreferences { $0.trigger = type }
    }

    func setHoldDuration(_ duration: Double) {
        updatePreferences { $0.holdDurationSeconds = duration }
    }

    func selectHotkeyPreset(id: String) {
        guard let preset = hotkeyPresets.first(where: { $0.id == id }) else { return }
        updatePreferences {
            $0.hotkeyKeyCode = preset.keyCode
            $0.hotkeyModifiersRawValue = preset.modifiers.rawValue
        }
    }

    func setAutoHideOnEsc(_ isOn: Bool) {
        updatePreferences { $0.autoHideOnEsc = isOn }
    }

    func setAutoHideOnAppSwitch(_ isOn: Bool) {
        updatePreferences { $0.autoHideOnAppSwitch = isOn }
    }

    func setTheme(_ theme: Preferences.Theme) {
        updatePreferences { $0.theme = theme }
    }

    // MARK: - Private

    func dismissError() {
        errorMessage = nil
    }

    private func updatePreferences(_ mutate: (inout Preferences) -> Void) {
        var next = preferences
        mutate(&next)
        do {
            try updatePreferencesUseCase.execute(next)
            preferences = next
            errorMessage = nil
        } catch {
            log.error("설정 저장 실패: \(error.localizedDescription)")
            errorMessage = "Failed to save settings. Please try again."
        }
    }
}
