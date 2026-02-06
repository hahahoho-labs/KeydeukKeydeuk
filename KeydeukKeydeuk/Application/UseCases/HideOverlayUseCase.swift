import Foundation

struct HideOverlayUseCase {
    private let presenter: OverlayPresenter

    init(presenter: OverlayPresenter) {
        self.presenter = presenter
    }

    @MainActor
    func execute() {
        presenter.hide()
    }
}
