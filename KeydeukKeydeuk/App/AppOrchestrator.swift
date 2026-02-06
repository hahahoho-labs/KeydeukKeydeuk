import Foundation

@MainActor
final class AppOrchestrator {
    private let eventSource: EventSource
    private let evaluateActivation: EvaluateActivationUseCase
    private let showOverlay: ShowOverlayForCurrentAppUseCase
    private let hideOverlay: HideOverlayUseCase
    private let onShowResult: @MainActor (ShowOverlayForCurrentAppUseCase.Result) -> Void

    init(
        eventSource: EventSource,
        evaluateActivation: EvaluateActivationUseCase,
        showOverlay: ShowOverlayForCurrentAppUseCase,
        hideOverlay: HideOverlayUseCase,
        onShowResult: @escaping @MainActor (ShowOverlayForCurrentAppUseCase.Result) -> Void
    ) {
        self.eventSource = eventSource
        self.evaluateActivation = evaluateActivation
        self.showOverlay = showOverlay
        self.hideOverlay = hideOverlay
        self.onShowResult = onShowResult
    }

    func start() {
        eventSource.onEvent = { [weak self] event in
            guard let self else { return }
            let decision = self.evaluateActivation.execute(event: event)
            Task { @MainActor in
                switch decision {
                case .activate:
                    let result = await self.showOverlay.execute()
                    self.onShowResult(result)
                case .hide:
                    self.hideOverlay.execute()
                case .ignore:
                    break
                }
            }
        }
        eventSource.start()
    }

    func stop() {
        eventSource.stop()
    }
}
