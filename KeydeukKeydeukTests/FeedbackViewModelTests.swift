import XCTest
@testable import KeydeukKeydeuk

final class FeedbackViewModelTests: XCTestCase {
    func testCanSubmit_transitionsByInputValidity() async {
        let vm = await makeViewModel()

        let initialCanSubmit = await MainActor.run { vm.canSubmit }
        XCTAssertFalse(initialCanSubmit)

        await MainActor.run { vm.setTitle("hello") }
        let afterTitleCanSubmit = await MainActor.run { vm.canSubmit }
        XCTAssertFalse(afterTitleCanSubmit)

        await MainActor.run { vm.setMessage("world") }
        let afterMessageCanSubmit = await MainActor.run { vm.canSubmit }
        XCTAssertTrue(afterMessageCanSubmit)

        await MainActor.run { vm.setEmail("invalid") }
        let afterInvalidEmailCanSubmit = await MainActor.run { vm.canSubmit }
        XCTAssertFalse(afterInvalidEmailCanSubmit)

        await MainActor.run { vm.setEmail("user@example.com") }
        let afterValidEmailCanSubmit = await MainActor.run { vm.canSubmit }
        XCTAssertTrue(afterValidEmailCanSubmit)
    }

    func testSubmit_success_setsSuccessMessageAndClearsForm() async {
        let vm = await makeViewModel()
        await MainActor.run {
            vm.setTitle("title")
            vm.setMessage("message")
        }

        await vm.submit()

        let title = await MainActor.run { vm.title }
        let message = await MainActor.run { vm.message }
        let successMessageKey = await MainActor.run { vm.successMessageKey }
        let errorMessageKey = await MainActor.run { vm.errorMessageKey }
        let errorMessageRaw = await MainActor.run { vm.errorMessageRaw }
        XCTAssertEqual(title, "")
        XCTAssertEqual(message, "")
        XCTAssertEqual(successMessageKey, "settings.help.feedback.success")
        XCTAssertNil(errorMessageKey)
        XCTAssertNil(errorMessageRaw)
    }

    func testSubmit_failure_setsErrorMessage() async {
        let spyService = SpyFeedbackSubmissionService()
        spyService.result = .failure(SpyFeedbackSubmissionService.SpyError.forced("boom"))

        let vm = await makeViewModel(service: spyService)
        await MainActor.run {
            vm.setTitle("title")
            vm.setMessage("message")
        }

        await vm.submit()

        let successMessageKey = await MainActor.run { vm.successMessageKey }
        let errorMessageKey = await MainActor.run { vm.errorMessageKey }
        let errorMessageRaw = await MainActor.run { vm.errorMessageRaw }
        XCTAssertNil(successMessageKey)
        XCTAssertNil(errorMessageKey)
        XCTAssertEqual(errorMessageRaw, "boom")
        XCTAssertEqual(spyService.receivedSubmissions.count, 1)
    }

    private func makeViewModel(
        service: SpyFeedbackSubmissionService = SpyFeedbackSubmissionService()
    ) async -> FeedbackViewModel {
        await MainActor.run {
            let useCase = SubmitFeedbackUseCase(
                feedbackSubmissionService: service,
                diagnosticsProvider: StubFeedbackDiagnosticsProvider(),
                installationIDProvider: StubInstallationIDProvider()
            )
            return FeedbackViewModel(submitFeedbackUseCase: useCase)
        }
    }
}
