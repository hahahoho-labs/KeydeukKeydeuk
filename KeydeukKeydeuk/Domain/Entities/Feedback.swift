import Foundation

enum FeedbackConstraints {
    static let maxTitleLength = 50
    static let maxMessageLength = 500
    static let maxEmailLength = 120
}

enum FeedbackEmailValidator {
    static func isValid(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}

struct FeedbackDraft: Equatable {
    let email: String?
    let title: String
    let message: String
}

struct FeedbackDiagnostics: Equatable {
    let appVersion: String
    let buildNumber: String
    let osVersion: String
    let osName: String
    let localeIdentifier: String
    let bundleID: String
}

struct FeedbackSubmission: Equatable {
    let draft: FeedbackDraft
    let diagnostics: FeedbackDiagnostics
    let installationID: String
}

struct FeedbackSubmissionResult: Equatable {
    let submissionID: String?
}

enum FeedbackSubmissionServiceError: Error, Equatable {
    case missingEndpoint
    case invalidResponse
    case rateLimited(retryAfterSeconds: Int)
    case server(statusCode: Int, message: String)
    case network(description: String)
}
