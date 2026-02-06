import Foundation

struct EvaluateActivationUseCase {
    private let policy: ActivationPolicy

    init(policy: ActivationPolicy) {
        self.policy = policy
    }

    func execute(event: KeyEvent, preferences: Preferences) -> ActivationDecision {
        policy.evaluate(event: event, preferences: preferences)
    }
}
