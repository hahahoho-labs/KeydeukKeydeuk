import Foundation
import XCTest
@testable import KeydeukKeydeuk

final class SupabaseFeedbackServiceTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocolStub.requestHandler = nil
    }

    func testSubmit_when200_returnsSubmissionID() async throws {
        URLProtocolStub.requestHandler = { _ in
            let data = Data("{\"submissionId\":\"sub-123\"}".utf8)
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/feedback")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }

        let service = makeService()
        let result = try await service.submit(await makeSubmission())

        let submissionID = await MainActor.run { result.submissionID }
        XCTAssertEqual(submissionID, "sub-123")
    }

    func testSubmit_when429_throwsRateLimitedError() async {
        URLProtocolStub.requestHandler = { _ in
            let data = Data("{\"error\":\"Too many requests\",\"retryAfterSeconds\":3600}".utf8)
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/feedback")!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }

        let service = makeService()

        do {
            _ = try await service.submit(await makeSubmission())
            XCTFail("Expected rateLimited error")
        } catch let error as SupabaseFeedbackService.Error {
            switch error {
            case let .rateLimited(retryAfterSeconds):
                XCTAssertEqual(retryAfterSeconds, 3600)
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSubmit_when401MissingAuthorization_mapsFriendlyMessage() async {
        URLProtocolStub.requestHandler = { _ in
            let data = Data("{\"error\":\"Missing authorization header\"}".utf8)
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/feedback")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }

        let service = makeService()

        do {
            _ = try await service.submit(await makeSubmission())
            XCTFail("Expected server error")
        } catch let error as SupabaseFeedbackService.Error {
            switch error {
            case let .server(statusCode, message):
                XCTAssertEqual(statusCode, 401)
                XCTAssertTrue(message.contains("Missing authorization header"))
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeService() -> SupabaseFeedbackService {
        SupabaseFeedbackService(
            endpointProvider: { URL(string: "https://example.com/feedback") },
            session: stubbedSession()
        )
    }

    private func stubbedSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    private func makeSubmission() async -> FeedbackSubmission {
        await MainActor.run {
            FeedbackSubmission(
                draft: FeedbackDraft(email: "user@example.com", title: "title", message: "message"),
                diagnostics: FeedbackDiagnostics(
                    appVersion: "1.0.0",
                    buildNumber: "100",
                    osVersion: "macOS 15",
                    osName: "macOS",
                    localeIdentifier: "ko_KR",
                    bundleID: "hexdrinker.KeydeukKeydeuk"
                ),
                installationID: "installation-123"
            )
        }
    }
}

private final class URLProtocolStub: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            fatalError("requestHandler is not set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
