import AppKit
import Combine
import Foundation
import os

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "SettingsVM")

@MainActor
final class SettingsViewModel: ObservableObject {
    struct EditableHotkey: Identifiable, Equatable {
        let id: String
        let keyCode: Int
        let modifiers: KeyModifiers
        let displayTitle: String
    }

    @Published private(set) var preferences: Preferences
    @Published private(set) var errorMessage: String?
    @Published private(set) var isCapturingCustomHotkey = false

    private let loadPreferences: LoadPreferencesUseCase
    private let updatePreferencesUseCase: UpdatePreferencesUseCase
    private var hotkeyCaptureMonitor: Any?

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

    var primaryCustomHotkey: EditableHotkey? {
        guard let hotkey = preferences.customHotkeys.first else { return nil }
        return EditableHotkey(
            id: hotkey.id,
            keyCode: hotkey.keyCode,
            modifiers: hotkey.modifiers,
            displayTitle: Self.hotkeyDisplayText(keyCode: hotkey.keyCode, modifiers: hotkey.modifiers)
        )
    }

    // MARK: - Actions

    func refreshPreferences() {
        preferences = loadPreferences.execute()
    }

    func setTriggerType(_ type: Preferences.Trigger) {
        updatePreferences { $0.trigger = type }
        if type == .customShortcut {
            if primaryCustomHotkey == nil {
                beginCustomHotkeyCapture()
            }
        } else {
            cancelCustomHotkeyCapture()
        }
    }

    func setHoldDuration(_ duration: Double) {
        updatePreferences { $0.holdDurationSeconds = duration }
    }

    func beginCustomHotkeyCapture() {
        guard !isCapturingCustomHotkey else { return }
        isCapturingCustomHotkey = true
        hotkeyCaptureMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 {
                self.cancelCustomHotkeyCapture()
                return nil
            }

            let modifiers = Self.mapModifiers(from: event.modifierFlags)
            guard !modifiers.isEmpty else { return nil }

            self.addCustomHotkey(
                keyCode: Int(event.keyCode),
                modifiers: modifiers
            )
            self.cancelCustomHotkeyCapture()
            return nil
        }
    }

    func cancelCustomHotkeyCapture() {
        if let hotkeyCaptureMonitor {
            NSEvent.removeMonitor(hotkeyCaptureMonitor)
            self.hotkeyCaptureMonitor = nil
        }
        isCapturingCustomHotkey = false
    }

    func removeCustomHotkey(id: String) {
        updatePreferences {
            $0.customHotkeys.removeAll { $0.id == id }
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

    deinit {
        if let hotkeyCaptureMonitor {
            NSEvent.removeMonitor(hotkeyCaptureMonitor)
        }
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
            if let updateError = error as? UpdatePreferencesUseCase.Error {
                switch updateError {
                case .invalidHotkey:
                    errorMessage = "Shortcut needs at least one modifier key."
                case .duplicateHotkey:
                    errorMessage = "Shortcut is already registered."
                }
            } else {
                errorMessage = "Failed to save settings. Please try again."
            }
        }
    }

    private func addCustomHotkey(keyCode: Int, modifiers: KeyModifiers) {
        updatePreferences {
            let newHotkey = Preferences.HotkeyBinding(
                keyCode: keyCode,
                modifiersRawValue: modifiers.rawValue
            )
            $0.customHotkeys = [newHotkey]
        }
    }

    private static func mapModifiers(from flags: NSEvent.ModifierFlags) -> KeyModifiers {
        var modifiers: KeyModifiers = []
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        return modifiers
    }

    private static func hotkeyDisplayText(keyCode: Int, modifiers: KeyModifiers) -> String {
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("⌃") }
        parts.append(keyName(for: keyCode))
        return parts.joined()
    }

    private static func keyName(for keyCode: Int) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 49: return "Space"
        case 50: return "`"
        case 53: return "Esc"
        default:
            return "Key\(keyCode)"
        }
    }
}
