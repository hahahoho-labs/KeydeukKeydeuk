import Foundation
import os

private let feedbackLog = Logger(
    subsystem: "hexdrinker.KeydeukKeydeuk",
    category: "FeedbackService"
)

struct SupabaseFeedbackService: FeedbackSubmissionService {
    enum Error: LocalizedError {
        case missingEndpoint
        case invalidResponse
        case server(statusCode: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .missingEndpoint:
                return "Feedback endpoint is not configured."
            case .invalidResponse:
                return "Feedback server returned an invalid response."
            case let .server(statusCode, message):
                if message.isEmpty {
                    return "Feedback request failed (\(statusCode))."
                }
                return "Feedback request failed (\(statusCode)): \(message)"
            }
        }
    }

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
            throw Error.missingEndpoint
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
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }

        guard [200, 201, 202, 207].contains(httpResponse.statusCode) else {
            let message = Self.readServerMessage(from: data)
            if httpResponse.statusCode == 401 && message.lowercased().contains("missing authorization header") {
                throw Error.server(
                    statusCode: 401,
                    message: "Missing authorization header. Disable JWT verification for the feedback function or set KEYDEUK_FEEDBACK_AUTH_TOKEN."
                )
            }
            throw Error.server(statusCode: httpResponse.statusCode, message: message)
        }

        guard !data.isEmpty else {
            return FeedbackSubmissionResult(submissionID: nil, githubIssueURL: nil)
        }

        guard let body = try? JSONDecoder().decode(ResponseBody.self, from: data) else {
            return FeedbackSubmissionResult(submissionID: nil, githubIssueURL: nil)
        }

        return FeedbackSubmissionResult(
            submissionID: body.submissionID,
            githubIssueURL: body.githubIssueURL.flatMap(URL.init(string:))
        )
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

    private static func readServerMessage(from data: Data) -> String {
        guard !data.isEmpty else { return "" }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = jsonObject["message"] as? String {
                return message
            }
            if let error = jsonObject["error"] as? String {
                return error
            }
        }

        return String(data: data, encoding: .utf8) ?? ""
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
    }
}

private struct ResponseBody: Decodable {
    let submissionID: String?
    let githubIssueURL: String?

    enum CodingKeys: String, CodingKey {
        case submissionID = "submissionId"
        case githubIssueURL = "githubIssueUrl"
    }
}
