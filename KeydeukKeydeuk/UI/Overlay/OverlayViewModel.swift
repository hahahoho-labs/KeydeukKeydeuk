import AppKit
import Combine
import Foundation

@MainActor
final class OverlayViewModel: ObservableObject {
    @Published var query = ""

    private let state: OverlaySceneState
    private let showOverlay: ShowOverlayForCurrentAppUseCase
    private let hideOverlay: HideOverlayUseCase
    private var cancellables: Set<AnyCancellable> = []

    init(
        state: OverlaySceneState,
        showOverlay: ShowOverlayForCurrentAppUseCase,
        hideOverlay: HideOverlayUseCase
    ) {
        self.state = state
        self.showOverlay = showOverlay
        self.hideOverlay = hideOverlay

        state.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - State Accessors

    var isVisible: Bool { state.isVisible }
    var appName: String { state.appName }
    var appBundleID: String { state.appBundleID }
    var appIcon: NSImage? { state.appIcon }
    var shortcuts: [Shortcut] { state.shortcuts }

    var filteredShortcuts: [Shortcut] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return state.shortcuts }

        return state.shortcuts.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.keys.localizedCaseInsensitiveContains(trimmed)
                || ($0.section?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    // MARK: - Actions

    func requestShow() async -> ShowOverlayForCurrentAppUseCase.Result {
        await showOverlay.execute()
    }

    func requestHide() {
        hideOverlay.execute()
    }
}
