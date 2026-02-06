import Foundation

struct ShortcutCatalog: Codable, Equatable {
    let bundleID: String
    let appName: String
    let shortcuts: [Shortcut]
}
