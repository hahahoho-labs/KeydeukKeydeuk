import AppKit
import ApplicationServices
import Foundation
import os

private let log = Logger(subsystem: "hexdrinker.KeydeukKeydeuk", category: "PermissionGuide")

struct SystemPermissionGuide: PermissionGuide {
    func requestAccessibilityPermissionPrompt() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        // 앱을 손쉬운 사용 목록에 등록 (미등록 시에만 프롬프트 표시)
        _ = requestAccessibilityPermissionPrompt()

        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            log.error("접근성 설정 URL 생성 실패")
            return
        }

        let opened = NSWorkspace.shared.open(url)
        if !opened {
            log.error("시스템 접근성 설정 열기 실패: \(url.absoluteString)")
        }
    }
}
