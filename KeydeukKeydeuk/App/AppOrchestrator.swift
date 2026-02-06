import Foundation
import os

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "Orchestrator")

@MainActor
final class AppOrchestrator {
    private let eventSource: EventSource
    private let evaluateActivation: EvaluateActivationUseCase
    private let showOverlay: ShowOverlayForCurrentAppUseCase
    private let hideOverlay: HideOverlayUseCase
    private let onShowResult: @MainActor (ShowOverlayForCurrentAppUseCase.Result) -> Void

    private var currentPreferences: Preferences

    // Hold 트리거 상태
    private var holdTimer: DispatchWorkItem?
    private var holdTriggered = false

    init(
        eventSource: EventSource,
        evaluateActivation: EvaluateActivationUseCase,
        showOverlay: ShowOverlayForCurrentAppUseCase,
        hideOverlay: HideOverlayUseCase,
        initialPreferences: Preferences,
        onShowResult: @escaping @MainActor (ShowOverlayForCurrentAppUseCase.Result) -> Void
    ) {
        self.eventSource = eventSource
        self.evaluateActivation = evaluateActivation
        self.showOverlay = showOverlay
        self.hideOverlay = hideOverlay
        self.currentPreferences = initialPreferences
        self.onShowResult = onShowResult
    }

    // MARK: - Preferences 갱신

    func updatePreferences(_ preferences: Preferences) {
        let triggerChanged = currentPreferences.trigger != preferences.trigger
        currentPreferences = preferences

        // 트리거 타입이 변경되면 진행 중인 홀드 상태 초기화
        if triggerChanged {
            cancelHold()
            holdTriggered = false
            log.info("트리거 타입 변경 → 홀드 상태 초기화")
        }
    }

    func start() {
        eventSource.onEvent = { [weak self] event in
            guard let self else { return }

            switch self.currentPreferences.trigger {
            case .holdCommand:
                self.handleHoldCommand(event: event, duration: self.currentPreferences.holdDurationSeconds)
            case .globalHotkey:
                self.handleGlobalHotkey(event: event)
            }
        }
        eventSource.start()
    }

    func stop() {
        cancelHold()
        eventSource.stop()
    }

    // MARK: - Hold Command 트리거

    private func handleHoldCommand(event: KeyEvent, duration: Double) {
        if event.isFlagsChanged {
            let commandOnly = event.modifiers == .command

            if commandOnly && !holdTriggered && holdTimer == nil {
                // ⌘ 단독 누름 → 홀드 타이머 시작
                log.debug("⌘ 홀드 타이머 시작 (\(duration)초)")
                let work = DispatchWorkItem { [weak self] in
                    guard let self else { return }
                    self.holdTriggered = true
                    log.info("⌘ 홀드 \(duration)초 경과 — 오버레이 표시")
                    Task { @MainActor in
                        let result = await self.showOverlay.execute()
                        self.onShowResult(result)
                    }
                }
                holdTimer = work
                DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)

            } else if commandOnly && holdTriggered {
                // ⌘가 여전히 눌린 상태 + 이미 트리거됨 → 무시
                return

            } else if !event.modifiers.contains(.command) {
                // ⌘ 릴리스 → 타이머만 정리, 오버레이는 유지 (트리거 전용)
                log.debug("⌘ 릴리스 (holdTriggered: \(self.holdTriggered))")
                cancelHold()
                holdTriggered = false

            } else {
                // ⌘ + 다른 modifier 조합 (⌘⇧ 등) → 타이머 취소
                log.debug("⌘ + 다른 modifier 감지 — 홀드 타이머 취소")
                cancelHold()
            }

        } else if !holdTriggered {
            // keyDown 이벤트 (홀드 트리거 전) → 사용자가 단축키 사용 중, 타이머 취소
            if holdTimer != nil {
                log.debug("keyDown 감지 — 홀드 타이머 취소 (단축키 사용)")
                cancelHold()
            }
        }
        // holdTriggered == true 상태에서 keyDown → 오버레이 유지 (사용자가 단축키 확인 중)
    }

    private func cancelHold() {
        holdTimer?.cancel()
        holdTimer = nil
    }

    // MARK: - Global Hotkey 트리거

    private func handleGlobalHotkey(event: KeyEvent) {
        // flagsChanged 이벤트는 글로벌 핫키 모드에서는 무시
        guard !event.isFlagsChanged else { return }

        let decision = evaluateActivation.execute(event: event, preferences: currentPreferences)
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
}
