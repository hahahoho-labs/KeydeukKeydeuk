import Combine
import Foundation
import os

private let feedbackVMLog = Logger(
    subsystem: "hexdrinker.KeydeukKeydeuk",
    category: "FeedbackVM"
)

@MainActor
final class FeedbackViewModel: ObservableObject {
    @Published var email = ""
    @Published var title = ""
    @Published var message = ""

    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessageKey: String?
    @Published private(set) var errorMessageRaw: String?
    @Published private(set) var successMessageKey: String?

    private let submitFeedbackUseCase: SubmitFeedbackUseCase

    init(submitFeedbackUseCase: SubmitFeedbackUseCase) {
        self.submitFeedbackUseCase = submitFeedbackUseCase
    }

    var maxTitleLength: Int { FeedbackConstraints.maxTitleLength }
    var maxMessageLength: Int { FeedbackConstraints.maxMessageLength }
    var maxEmailLength: Int { FeedbackConstraints.maxEmailLength }

    var titleCountText: String { "\(title.count)/\(maxTitleLength)" }
    var messageCountText: String { "\(message.count)/\(maxMessageLength)" }

    var hasInvalidEmail: Bool {
        !trimmedEmail.isEmpty && !Self.validateEmail(trimmedEmail)
    }

    var canSubmit: Bool {
        !trimmedTitle.isEmpty && !trimmedMessage.isEmpty && !hasInvalidEmail && !isSubmitting
    }

    func setEmail(_ value: String) {
        email = String(value.prefix(maxEmailLength))
        clearMessages()
    }

    func setTitle(_ value: String) {
        title = String(value.prefix(maxTitleLength))
        clearMessages()
    }

    func setMessage(_ value: String) {
        message = String(value.prefix(maxMessageLength))
        clearMessages()
    }

    func submit() async {
        guard canSubmit else { return }

        isSubmitting = true
        clearMessages()
        defer { isSubmitting = false }

        let draft = FeedbackDraft(
            email: trimmedEmail.isEmpty ? nil : trimmedEmail,
            title: trimmedTitle,
            message: trimmedMessage
        )

        do {
            let result = try await submitFeedbackUseCase.execute(draft: draft)
            successMessageKey = "settings.help.feedback.success"
            title = ""
            message = ""
            feedbackVMLog.info("피드백 제출 성공: submissionId=\(result.submissionID ?? "nil")")
        } catch {
            if let errorKey = Self.errorMessageKey(from: error) {
                errorMessageKey = errorKey
                feedbackVMLog.error("피드백 제출 실패: key=\(errorKey)")
            } else {
                if let message = Self.explicitErrorMessage(from: error) {
                    errorMessageRaw = message
                    feedbackVMLog.error("피드백 제출 실패: \(message)")
                } else {
                    errorMessageKey = "settings.help.feedback.error.submit_failed"
                    feedbackVMLog.error("피드백 제출 실패: unknown")
                }
            }
        }
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func clearMessages() {
        errorMessageKey = nil
        errorMessageRaw = nil
        successMessageKey = nil
    }

    private static func errorMessageKey(from error: Swift.Error) -> String? {
        if let validationError = error as? SubmitFeedbackUseCase.Error {
            switch validationError {
            case .emptyTitle:
                return "settings.help.feedback.error.empty_title"
            case .titleTooLong:
                return "settings.help.feedback.error.title_too_long"
            case .emptyMessage:
                return "settings.help.feedback.error.empty_message"
            case .messageTooLong:
                return "settings.help.feedback.error.message_too_long"
            case .emailTooLong:
                return "settings.help.feedback.error.email_too_long"
            case .invalidEmail:
                return "settings.help.feedback.error.invalid_email"
            case let .submissionFailed(serviceError):
                switch serviceError {
                case .missingEndpoint:
                    return "settings.help.feedback.error.endpoint_missing"
                case .invalidResponse:
                    return "settings.help.feedback.error.invalid_response"
                case .rateLimited:
                    return "settings.help.feedback.error.rate_limited"
                case .network:
                    return "settings.help.feedback.error.network"
                case .server:
                    return nil
                }
            }
        }

        return nil
    }

    private static func explicitErrorMessage(from error: Swift.Error) -> String? {
        if let useCaseError = error as? SubmitFeedbackUseCase.Error,
           case let .submissionFailed(serviceError) = useCaseError,
           case let .server(_, message) = serviceError,
           !message.isEmpty {
            return message
        }

        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return nil
    }

    private static func validateEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}
