import Foundation

struct LoadShortcutsForAppUseCase {
    private let repository: ShortcutRepository

    init(repository: ShortcutRepository) {
        self.repository = repository
    }

    func execute(bundleID: String) async throws -> ShortcutCatalog? {
        try await repository.shortcuts(for: bundleID)
    }
}
