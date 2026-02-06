import Foundation

struct LoadPreferencesUseCase {
    private let preferencesStore: PreferencesStore

    init(preferencesStore: PreferencesStore) {
        self.preferencesStore = preferencesStore
    }

    func execute() -> Preferences {
        preferencesStore.load()
    }
}
