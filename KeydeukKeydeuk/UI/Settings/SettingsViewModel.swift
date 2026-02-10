import Combine
import Foundation
import os

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "SettingsVM")

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var preferences: Preferences
    @Published private(set) var errorMessageKey: String?

    private let loadPreferences: LoadPreferencesUseCase
    private let updatePreferencesUseCase: UpdatePreferencesUseCase
    private let languageOptionsProvider: any LanguageOptionProviding

    convenience init(
        loadPreferences: LoadPreferencesUseCase,
        updatePreferences: UpdatePreferencesUseCase
    ) {
        self.init(
            loadPreferences: loadPreferences,
            updatePreferences: updatePreferences,
            languageOptionsProvider: SupportedLanguageCatalog()
        )
    }

    init(
        loadPreferences: LoadPreferencesUseCase,
        updatePreferences: UpdatePreferencesUseCase,
        languageOptionsProvider: any LanguageOptionProviding
    ) {
        self.loadPreferences = loadPreferences
        self.updatePreferencesUseCase = updatePreferences
        self.languageOptionsProvider = languageOptionsProvider
        self.preferences = loadPreferences.execute()
    }

    // MARK: - Computed Properties

    var selectedTriggerType: Preferences.Trigger { preferences.trigger }
    var holdDuration: Double { preferences.holdDurationSeconds }
    var autoHideOnEsc: Bool { preferences.autoHideOnEsc }
    var autoHideOnAppSwitch: Bool { preferences.autoHideOnAppSwitch }
    var selectedTheme: Preferences.Theme { preferences.theme }
    var selectedLanguage: Preferences.Language { preferences.language }
    var supportedLanguages: [SupportedLanguageOption] { languageOptionsProvider.options }

    // MARK: - Actions

    func refreshPreferences() {
        preferences = loadPreferences.execute()
    }

    func setTriggerType(_ type: Preferences.Trigger) {
        let normalizedType: Preferences.Trigger = type == .customShortcut ? .holdCommand : type
        updatePreferences { $0.trigger = normalizedType }
    }

    func setHoldDuration(_ duration: Double) {
        updatePreferences { $0.holdDurationSeconds = duration }
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

    func setLanguage(_ language: Preferences.Language) {
        updatePreferences { $0.language = language }
    }

    // MARK: - Private

    func dismissError() {
        errorMessageKey = nil
    }

    private func updatePreferences(_ mutate: (inout Preferences) -> Void) {
        var next = preferences
        mutate(&next)
        do {
            try updatePreferencesUseCase.execute(next)
            preferences = next
            errorMessageKey = nil
        } catch {
            log.error("설정 저장 실패: \(error.localizedDescription)")
            if let updateError = error as? UpdatePreferencesUseCase.Error {
                switch updateError {
                case .invalidHotkey:
                    errorMessageKey = "settings.error.shortcut_modifier_required"
                case .duplicateHotkey:
                    errorMessageKey = "settings.error.shortcut_duplicate"
                }
            } else {
                errorMessageKey = "settings.error.save_failed"
            }
        }
    }
}
