import Foundation
@testable import KeydeukKeydeuk

struct StubFeedbackDiagnosticsProvider: FeedbackDiagnosticsProvider {
    var diagnostics = FeedbackDiagnostics(
        appVersion: "1.0.0",
        buildNumber: "100",
        osVersion: "macOS 15",
        osName: "macOS",
        localeIdentifier: "ko_KR",
        bundleID: "hexdrinker.KeydeukKeydeuk"
    )

    func currentDiagnostics() -> FeedbackDiagnostics {
        diagnostics
    }
}

struct StubInstallationIDProvider: InstallationIDProvider {
    var installationID = "installation-123"

    func currentInstallationID() -> String {
        installationID
    }
}

final class SpyFeedbackSubmissionService: FeedbackSubmissionService {
    enum SpyError: LocalizedError {
        case forced(String)

        var errorDescription: String? {
            switch self {
            case let .forced(message):
                return message
            }
        }
    }

    var receivedSubmissions: [FeedbackSubmission] = []
    var result: Result<FeedbackSubmissionResult, Swift.Error> = .success(
        FeedbackSubmissionResult(submissionID: "submission-1")
    )

    func submit(_ feedback: FeedbackSubmission) async throws -> FeedbackSubmissionResult {
        receivedSubmissions.append(feedback)
        return try result.get()
    }
}
