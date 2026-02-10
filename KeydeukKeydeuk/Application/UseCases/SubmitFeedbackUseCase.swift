import Foundation

struct SubmitFeedbackUseCase {
    enum Error: Swift.Error, Equatable {
        case emptyTitle
        case titleTooLong
        case emptyMessage
        case messageTooLong
        case emailTooLong
        case invalidEmail
        case submissionFailed(FeedbackSubmissionServiceError)
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
        do {
            return try await feedbackSubmissionService.submit(submission)
        } catch let serviceError as FeedbackSubmissionServiceError {
            throw Error.submissionFailed(serviceError)
        }
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
            guard FeedbackEmailValidator.isValid(email) else { throw Error.invalidEmail }
        }
    }
}
