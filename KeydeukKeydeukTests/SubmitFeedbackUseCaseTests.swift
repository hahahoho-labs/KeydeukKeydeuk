import XCTest
@testable import KeydeukKeydeuk

final class SubmitFeedbackUseCaseTests: XCTestCase {
    func testExecute_withValidDraft_submitsNormalizedSubmission() async throws {
        let spyService = SpyFeedbackSubmissionService()
        let diagnosticsProvider = await MainActor.run { StubFeedbackDiagnosticsProvider() }
        let installationProvider = await MainActor.run { StubInstallationIDProvider(installationID: "install-abc") }
        let useCase = await MainActor.run {
            SubmitFeedbackUseCase(
                feedbackSubmissionService: spyService,
                diagnosticsProvider: diagnosticsProvider,
                installationIDProvider: installationProvider
            )
        }

        let result = try await useCase.execute(
            draft: await MainActor.run {
                FeedbackDraft(
                    email: "  user@example.com  ",
                    title: "  title  ",
                    message: "  message body  "
                )
            }
        )

        let submissionID = await MainActor.run { result.submissionID }
        XCTAssertEqual(submissionID, "submission-1")
        XCTAssertEqual(spyService.receivedSubmissions.count, 1)

        let submitted = try XCTUnwrap(spyService.receivedSubmissions.first)
        let submittedEmail = await MainActor.run { submitted.draft.email }
        let submittedTitle = await MainActor.run { submitted.draft.title }
        let submittedMessage = await MainActor.run { submitted.draft.message }
        let submittedInstallationID = await MainActor.run { submitted.installationID }
        let submittedBundleID = await MainActor.run { submitted.diagnostics.bundleID }
        XCTAssertEqual(submittedEmail, "user@example.com")
        XCTAssertEqual(submittedTitle, "title")
        XCTAssertEqual(submittedMessage, "message body")
        XCTAssertEqual(submittedInstallationID, "install-abc")
        XCTAssertEqual(submittedBundleID, "hexdrinker.KeydeukKeydeuk")
    }

    func testExecute_withTitleTooLong_throwsTitleTooLong() async {
        let useCase = await MainActor.run {
            SubmitFeedbackUseCase(
                feedbackSubmissionService: SpyFeedbackSubmissionService(),
                diagnosticsProvider: StubFeedbackDiagnosticsProvider(),
                installationIDProvider: StubInstallationIDProvider()
            )
        }

        let maxTitleLength = await MainActor.run { FeedbackConstraints.maxTitleLength }
        let tooLongTitle = String(repeating: "a", count: maxTitleLength + 1)

        do {
            _ = try await useCase.execute(
                draft: await MainActor.run {
                    FeedbackDraft(email: nil, title: tooLongTitle, message: "valid")
                }
            )
            XCTFail("Expected titleTooLong error")
        } catch let error as SubmitFeedbackUseCase.Error {
            XCTAssertEqual(error, .titleTooLong)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecute_withInvalidEmail_throwsInvalidEmail() async {
        let useCase = await MainActor.run {
            SubmitFeedbackUseCase(
                feedbackSubmissionService: SpyFeedbackSubmissionService(),
                diagnosticsProvider: StubFeedbackDiagnosticsProvider(),
                installationIDProvider: StubInstallationIDProvider()
            )
        }

        do {
            _ = try await useCase.execute(
                draft: await MainActor.run {
                    FeedbackDraft(email: "invalid-email", title: "title", message: "valid")
                }
            )
            XCTFail("Expected invalidEmail error")
        } catch let error as SubmitFeedbackUseCase.Error {
            XCTAssertEqual(error, .invalidEmail)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
