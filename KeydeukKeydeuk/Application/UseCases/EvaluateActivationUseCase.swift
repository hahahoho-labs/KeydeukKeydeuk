import Foundation

struct EvaluateActivationUseCase {
    private let policy: ActivationPolicy
    private let preferencesStore: PreferencesStore

    init(policy: ActivationPolicy, preferencesStore: PreferencesStore) {
        self.policy = policy
        self.preferencesStore = preferencesStore
    }

    func execute(event: KeyEvent) -> ActivationDecision {
        let preferences = preferencesStore.load()
        return policy.evaluate(event: event, preferences: preferences)
    }
}
