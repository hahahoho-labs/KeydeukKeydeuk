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
        let successMessage = await MainActor.run { vm.successMessage }
        let errorMessage = await MainActor.run { vm.errorMessage }
        XCTAssertEqual(title, "")
        XCTAssertEqual(message, "")
        XCTAssertNotNil(successMessage)
        XCTAssertNil(errorMessage)
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

        let successMessage = await MainActor.run { vm.successMessage }
        let errorMessage = await MainActor.run { vm.errorMessage }
        XCTAssertNil(successMessage)
        XCTAssertEqual(errorMessage, "boom")
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
