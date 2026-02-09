import Foundation

struct SubmitFeedbackUseCase {
    enum Error: LocalizedError {
        case emptyTitle
        case titleTooLong
        case emptyMessage
        case messageTooLong
        case emailTooLong
        case invalidEmail

        var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return "Title is required."
            case .titleTooLong:
                return "Title must be at most \(FeedbackConstraints.maxTitleLength) characters."
            case .emptyMessage:
                return "Message is required."
            case .messageTooLong:
                return "Message must be at most \(FeedbackConstraints.maxMessageLength) characters."
            case .emailTooLong:
                return "Email must be at most \(FeedbackConstraints.maxEmailLength) characters."
            case .invalidEmail:
                return "Please enter a valid email address."
            }
        }
    }

    private let feedbackSubmissionService: FeedbackSubmissionService
    private let diagnosticsProvider: FeedbackDiagnosticsProvider
    private let installationIDProvider: InstallationIDProvider

    init(
        feedbackSubmissionService: FeedbackSubmissionService,
        diagnosticsProvider: FeedbackDiagnosticsProvider,
        installationIDProvider: InstallationIDProvider
    ) {
        self.feedbackSubmissionService = feedbackSubmissionService
        self.diagnosticsProvider = diagnosticsProvider
        self.installationIDProvider = installationIDProvider
    }

    func execute(draft: FeedbackDraft) async throws -> FeedbackSubmissionResult {
        let normalizedDraft = normalize(draft)
        try validate(normalizedDraft)

        let submission = FeedbackSubmission(
            draft: normalizedDraft,
            diagnostics: diagnosticsProvider.currentDiagnostics(),
            installationID: installationIDProvider.currentInstallationID()
        )
        return try await feedbackSubmissionService.submit(submission)
    }

    private func normalize(_ draft: FeedbackDraft) -> FeedbackDraft {
        let normalizedEmail = draft.email?.trimmingCharacters(in: .whitespacesAndNewlines)
        return FeedbackDraft(
            email: normalizedEmail?.isEmpty == true ? nil : normalizedEmail,
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            message: draft.message.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func validate(_ draft: FeedbackDraft) throws {
        guard !draft.title.isEmpty else { throw Error.emptyTitle }
        guard draft.title.count <= FeedbackConstraints.maxTitleLength else { throw Error.titleTooLong }

        guard !draft.message.isEmpty else { throw Error.emptyMessage }
        guard draft.message.count <= FeedbackConstraints.maxMessageLength else { throw Error.messageTooLong }

        if let email = draft.email {
            guard email.count <= FeedbackConstraints.maxEmailLength else { throw Error.emailTooLong }
            guard Self.isValidEmail(email) else { throw Error.invalidEmail }
        }
    }

    private static func isValidEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}
