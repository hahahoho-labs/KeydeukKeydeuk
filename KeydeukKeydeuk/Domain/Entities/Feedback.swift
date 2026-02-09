import Foundation

enum FeedbackConstraints {
    static let maxTitleLength = 50
    static let maxMessageLength = 500
    static let maxEmailLength = 120
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
}

struct FeedbackSubmissionResult: Equatable {
    let submissionID: String?
    let githubIssueURL: URL?
}
