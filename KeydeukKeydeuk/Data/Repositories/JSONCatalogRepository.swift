import Foundation

struct JSONCatalogRepository: ShortcutRepository {
    private struct Root: Decodable {
        let apps: [ShortcutCatalog]
    }

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func shortcuts(for bundleID: String) async throws -> ShortcutCatalog? {
        guard let url = bundle.url(forResource: "shortcuts_catalog", withExtension: "json") else {
            return nil
        }

        let data = try Data(contentsOf: url)
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.apps.first { $0.bundleID == bundleID }
    }
}
