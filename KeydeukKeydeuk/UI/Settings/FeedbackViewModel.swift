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
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

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
            successMessage = "Thanks for your feedback. Submitted successfully."
            title = ""
            message = ""
            feedbackVMLog.info("피드백 제출 성공: submissionId=\(result.submissionID ?? "nil")")
        } catch {
            let message = Self.errorMessage(from: error)
            errorMessage = message
            feedbackVMLog.error("피드백 제출 실패: \(message)")
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
        errorMessage = nil
        successMessage = nil
    }

    private static func errorMessage(from error: Swift.Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return "Failed to submit feedback. Please try again."
    }

    private static func validateEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}
