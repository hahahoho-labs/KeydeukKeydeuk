import Foundation

struct UserDefaultsInstallationIDProvider: InstallationIDProvider {
    private enum Keys {
        static let installationID = "feedback.installation_id"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func currentInstallationID() -> String {
        if let existing = userDefaults.string(forKey: Keys.installationID),
           !existing.isEmpty {
            return existing
        }

        let created = UUID().uuidString.lowercased()
        userDefaults.set(created, forKey: Keys.installationID)
        return created
    }
}
