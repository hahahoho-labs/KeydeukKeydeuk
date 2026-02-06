import ApplicationServices
import AppKit
import Foundation
import os

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "AXMenuBar")

/// macOS Accessibility API를 이용해 실행 중인 앱의 메뉴바에서
/// 단축키를 실시간 추출하는 ShortcutRepository 구현체.
///
/// KeyCue와 동일한 방식으로 AXUIElement 계층을 순회한다:
/// AXApplication → AXMenuBar → AXMenuBarItem → AXMenu → AXMenuItem
struct AXMenuBarShortcutRepository: ShortcutRepository {

    func shortcuts(for bundleID: String) async throws -> ShortcutCatalog? {
        log.info("🔍 단축키 추출 시작: \(bundleID)")

        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == bundleID
        }) else {
            log.warning("⚠️ 실행 중인 앱을 찾을 수 없음: \(bundleID)")
            return nil
        }

        let pid = app.processIdentifier
        let appName = app.localizedName ?? bundleID
        let axApp = AXUIElementCreateApplication(pid)
        log.info("📱 앱 발견: \(appName) (pid: \(pid))")

        // 메뉴바 접근
        var menuBarValue: CFTypeRef?
        let axResult = AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &menuBarValue)
        guard axResult == .success else {
            log.error("❌ 메뉴바 접근 실패 — AXError: \(axResult.rawValue) (앱: \(appName))")
            log.error("   → AXError 코드: 0=success, -25200=apiDisabled, -25201=invalidElement, -25204=cannotComplete, -25211=notImplemented")
            return ShortcutCatalog(bundleID: bundleID, appName: appName, shortcuts: [])
        }

        let menuBar = menuBarValue as! AXUIElement
        let shortcuts = extractAllShortcuts(from: menuBar, appName: appName)
        log.info("✅ AX 추출 성공: \(appName) → \(shortcuts.count)개 단축키")

        return ShortcutCatalog(bundleID: bundleID, appName: appName, shortcuts: shortcuts)
    }

    // MARK: - Menu Bar Traversal

    private func extractAllShortcuts(from menuBar: AXUIElement, appName: String) -> [Shortcut] {
        guard let barItems = axChildren(of: menuBar) else { return [] }

        var result: [Shortcut] = []
        var counter = 0

        for barItem in barItems {
            // 메뉴바 항목의 타이틀이 섹션명 (File, Edit, View, …)
            let section = axTitle(of: barItem) ?? appName
            guard let menus = axChildren(of: barItem) else { continue }

            for menu in menus {
                collectShortcuts(from: menu, section: section, into: &result, counter: &counter)
            }
        }

        return result
    }

    /// AXMenu를 재귀 순회하면서 단축키가 있는 메뉴 항목을 수집한다.
    private func collectShortcuts(
        from menu: AXUIElement,
        section: String,
        into result: inout [Shortcut],
        counter: inout Int
    ) {
        guard let items = axChildren(of: menu) else { return }

        for item in items {
            // 구분선(separator) 및 빈 타이틀 건너뛰기
            guard let title = axTitle(of: item), !title.isEmpty else { continue }

            // 1) 문자(char) 기반 단축키 확인
            if let keys = readShortcutKeys(from: item) {
                result.append(Shortcut(id: "ax_\(counter)", title: title, keys: keys, section: section))
                counter += 1
            }

            // 2) 서브메뉴가 있으면 재귀 순회
            if let submenus = axChildren(of: item) {
                for sub in submenus {
                    collectShortcuts(from: sub, section: section, into: &result, counter: &counter)
                }
            }
        }
    }

    // MARK: - Shortcut Key Reading

    private func readShortcutKeys(from item: AXUIElement) -> String? {
        // 문자 기반 단축키 (⌘C, ⌘N 등)
        var charRef: CFTypeRef?
        AXUIElementCopyAttributeValue(item, "AXMenuItemCmdChar" as CFString, &charRef)

        var modRef: CFTypeRef?
        AXUIElementCopyAttributeValue(item, "AXMenuItemCmdModifiers" as CFString, &modRef)
        let mods = (modRef as? Int) ?? 0

        if let char = charRef as? String, !char.isEmpty {
            return formatKeys(key: char.uppercased(), modifiers: mods)
        }

        // 가상키 기반 단축키 (F1-F12, 방향키, ⌫ 등)
        var vkRef: CFTypeRef?
        AXUIElementCopyAttributeValue(item, "AXMenuItemCmdVirtualKey" as CFString, &vkRef)

        if let vk = vkRef as? Int, let name = virtualKeyName(vk) {
            return formatKeys(key: name, modifiers: mods)
        }

        return nil
    }

    // MARK: - Key Formatting

    /// Carbon kMenu*Modifier 상수 기반으로 modifier 심볼을 조합한다.
    ///
    /// - Shift  = 1 (kMenuShiftModifier)
    /// - Option = 2 (kMenuOptionModifier)
    /// - Control = 4 (kMenuControlModifier)
    /// - NoCommand = 8 (kMenuNoCommandModifier)
    ///
    /// Command(⌘)는 NoCommand 플래그가 없는 한 항상 포함된다.
    private func formatKeys(key: String, modifiers: Int) -> String {
        var symbols: [String] = []

        if modifiers & 4 != 0 { symbols.append("⌃") }  // Control
        if modifiers & 2 != 0 { symbols.append("⌥") }  // Option
        if modifiers & 1 != 0 { symbols.append("⇧") }  // Shift
        if modifiers & 8 == 0 { symbols.append("⌘") }  // Command (implied unless suppressed)

        symbols.append(key)
        return symbols.joined()
    }

    /// macOS 가상 키코드를 사람이 읽을 수 있는 심볼/이름으로 매핑한다.
    private func virtualKeyName(_ code: Int) -> String? {
        switch code {
        case 122: "F1"
        case 120: "F2"
        case 99:  "F3"
        case 118: "F4"
        case 96:  "F5"
        case 97:  "F6"
        case 98:  "F7"
        case 100: "F8"
        case 101: "F9"
        case 109: "F10"
        case 103: "F11"
        case 111: "F12"
        case 51:  "⌫"
        case 117: "⌦"
        case 36:  "↩"
        case 76:  "⌅"
        case 53:  "⎋"
        case 48:  "⇥"
        case 49:  "Space"
        case 126: "↑"
        case 125: "↓"
        case 123: "←"
        case 124: "→"
        case 115: "Home"
        case 119: "End"
        case 116: "PgUp"
        case 121: "PgDn"
        default:  nil
        }
    }

    // MARK: - AX Primitives

    private func axChildren(of element: AXUIElement) -> [AXUIElement]? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &ref) == .success else {
            return nil
        }
        return ref as? [AXUIElement]
    }

    private func axTitle(of element: AXUIElement) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &ref) == .success else {
            return nil
        }
        return ref as? String
    }
}
