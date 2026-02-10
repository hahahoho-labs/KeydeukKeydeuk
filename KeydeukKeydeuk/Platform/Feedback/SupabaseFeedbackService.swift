import Foundation
import os

private let feedbackLog = Logger(
    subsystem: "hexdrinker.KeydeukKeydeuk",
    category: "FeedbackService"
)

struct SupabaseFeedbackService: FeedbackSubmissionService {
    private let endpointProvider: () -> URL?
    private let session: URLSession

    init(
        endpointProvider: @escaping () -> URL? = SupabaseFeedbackService.defaultEndpointURL,
        session: URLSession = .shared
    ) {
        self.endpointProvider = endpointProvider
        self.session = session
    }

    func submit(_ feedback: FeedbackSubmission) async throws -> FeedbackSubmissionResult {
        guard let endpoint = endpointProvider() else {
            feedbackLog.error("피드백 전송 실패: endpoint 미설정")
            throw FeedbackSubmissionServiceError.missingEndpoint
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let authToken = Self.defaultAuthToken() {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.setValue(authToken, forHTTPHeaderField: "apikey")
        }
        request.httpBody = try JSONEncoder().encode(RequestBody(feedback: feedback))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            feedbackLog.error("피드백 전송 네트워크 오류: \(error.localizedDescription)")
            throw FeedbackSubmissionServiceError.network(description: error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackSubmissionServiceError.invalidResponse
        }

        guard [200, 201, 202, 207].contains(httpResponse.statusCode) else {
            let errorBody = Self.parseServerError(from: data)
            let message = errorBody.message

            if httpResponse.statusCode == 429 {
                throw FeedbackSubmissionServiceError.rateLimited(
                    retryAfterSeconds: errorBody.retryAfterSeconds ?? (12 * 60 * 60)
                )
            }

            if httpResponse.statusCode == 401 && message.lowercased().contains("missing authorization header") {
                throw FeedbackSubmissionServiceError.server(
                    statusCode: 401,
                    message: "Missing authorization header. Disable JWT verification for the feedback function or set KEYDEUK_FEEDBACK_AUTH_TOKEN."
                )
            }
            throw FeedbackSubmissionServiceError.server(statusCode: httpResponse.statusCode, message: message)
        }

        guard !data.isEmpty else {
            return FeedbackSubmissionResult(submissionID: nil)
        }

        guard let body = try? JSONDecoder().decode(ResponseBody.self, from: data) else {
            return FeedbackSubmissionResult(submissionID: nil)
        }

        return FeedbackSubmissionResult(submissionID: body.submissionID)
    }

    nonisolated private static func defaultEndpointURL() -> URL? {
        if let raw = ProcessInfo.processInfo.environment["KEYDEUK_FEEDBACK_ENDPOINT"],
           !raw.isEmpty,
           let url = URL(string: raw) {
            return url
        }

        if let raw = Bundle.main.object(forInfoDictionaryKey: "KEYDEUK_FEEDBACK_ENDPOINT") as? String,
           !raw.isEmpty,
           let url = URL(string: raw) {
            return url
        }

        return nil
    }

    nonisolated private static func defaultAuthToken() -> String? {
        if let raw = ProcessInfo.processInfo.environment["KEYDEUK_FEEDBACK_AUTH_TOKEN"],
           !raw.isEmpty {
            return raw
        }

        if let raw = Bundle.main.object(forInfoDictionaryKey: "KEYDEUK_FEEDBACK_AUTH_TOKEN") as? String,
           !raw.isEmpty {
            return raw
        }

        return nil
    }

    private static func parseServerError(from data: Data) -> ParsedServerError {
        guard !data.isEmpty else {
            return ParsedServerError(message: "", retryAfterSeconds: nil)
        }

        if let decoded = try? JSONDecoder().decode(ServerErrorBody.self, from: data) {
            return ParsedServerError(
                message: decoded.message ?? decoded.error ?? "",
                retryAfterSeconds: decoded.retryAfterSeconds ?? decoded.retryAfterSecondsSnake
            )
        }

        return ParsedServerError(
            message: String(data: data, encoding: .utf8) ?? "",
            retryAfterSeconds: nil
        )
    }
}

private struct RequestBody: Encodable {
    let email: String?
    let title: String
    let message: String
    let appVersion: String
    let buildNumber: String
    let osVersion: String
    let osName: String
    let localeIdentifier: String
    let bundleID: String
    let installationId: String

    init(feedback: FeedbackSubmission) {
        email = feedback.draft.email
        title = feedback.draft.title
        message = feedback.draft.message
        appVersion = feedback.diagnostics.appVersion
        buildNumber = feedback.diagnostics.buildNumber
        osVersion = feedback.diagnostics.osVersion
        osName = feedback.diagnostics.osName
        localeIdentifier = feedback.diagnostics.localeIdentifier
        bundleID = feedback.diagnostics.bundleID
        installationId = feedback.installationID
    }
}

private struct ResponseBody: Decodable {
    let submissionID: String?

    enum CodingKeys: String, CodingKey {
        case submissionID = "submissionId"
    }
}

private struct ServerErrorBody: Decodable {
    let message: String?
    let error: String?
    let retryAfterSeconds: Int?
    let retryAfterSecondsSnake: Int?

    enum CodingKeys: String, CodingKey {
        case message
        case error
        case retryAfterSeconds
        case retryAfterSecondsSnake = "retry_after_seconds"
    }
}

private struct ParsedServerError {
    let message: String
    let retryAfterSeconds: Int?
}
