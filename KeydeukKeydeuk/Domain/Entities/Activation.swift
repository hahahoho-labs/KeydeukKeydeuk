import Foundation

struct KeyModifiers: OptionSet, Codable, Equatable {
    let rawValue: Int

    static let command = KeyModifiers(rawValue: 1 << 0)
    static let option = KeyModifiers(rawValue: 1 << 1)
    static let control = KeyModifiers(rawValue: 1 << 2)
    static let shift = KeyModifiers(rawValue: 1 << 3)
}

struct KeyEvent: Equatable {
    let keyCode: Int
    let modifiers: KeyModifiers
    let isKeyDown: Bool
}

enum ActivationDecision: Equatable {
    case activate
    case hide
    case ignore
}
