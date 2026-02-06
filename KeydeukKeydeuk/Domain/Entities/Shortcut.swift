import Foundation

struct Shortcut: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let keys: String
    let section: String?
}
