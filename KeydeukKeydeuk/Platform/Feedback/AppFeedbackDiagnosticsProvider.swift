import Foundation

struct AppFeedbackDiagnosticsProvider: FeedbackDiagnosticsProvider {
    func currentDiagnostics() -> FeedbackDiagnostics {
        let info = Bundle.main.infoDictionary ?? [:]
        let appVersion = info["CFBundleShortVersionString"] as? String ?? "unknown"
        let buildNumber = info["CFBundleVersion"] as? String ?? "unknown"
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"

        return FeedbackDiagnostics(
            appVersion: appVersion,
            buildNumber: buildNumber,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            osName: "macOS",
            localeIdentifier: Locale.current.identifier,
            bundleID: bundleID
        )
    }
}
