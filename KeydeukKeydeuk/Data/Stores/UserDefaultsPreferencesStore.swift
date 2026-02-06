import Foundation
import os

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "PreferencesStore")

struct UserDefaultsPreferencesStore: PreferencesStore {
    private let defaults: UserDefaults
    private let key = "preferences.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Preferences {
        guard let data = defaults.data(forKey: key) else {
            log.info("저장된 설정 없음 → 기본값 사용")
            return .default
        }

        do {
            return try JSONDecoder().decode(Preferences.self, from: data)
        } catch {
            log.error("설정 디코딩 실패 (손상/스키마 변경 가능): \(error.localizedDescription)")
            return .default
        }
    }

    func save(_ preferences: Preferences) throws {
        let data = try JSONEncoder().encode(preferences)
        defaults.set(data, forKey: key)
    }
}
