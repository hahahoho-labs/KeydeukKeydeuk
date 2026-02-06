import AppKit
import ApplicationServices
import Foundation

struct SystemPermissionGuide: PermissionGuide {
    func requestAccessibilityPermissionPrompt() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        // 앱을 손쉬운 사용 목록에 등록 (미등록 시에만 프롬프트 표시)
        _ = requestAccessibilityPermissionPrompt()

        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
