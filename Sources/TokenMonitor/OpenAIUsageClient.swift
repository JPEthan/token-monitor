import Foundation
import TokenQuotaCore

struct TokenSnapshot: Sendable, Equatable {
    let inputTokens: Int64
    let outputTokens: Int64
    let cachedInputTokens: Int64
    let requests: Int64

    var usedTokens: Int64 {
        inputTokens + outputTokens
    }

    static let zero = TokenSnapshot(
        inputTokens: 0,
        outputTokens: 0,
        cachedInputTokens: 0,
        requests: 0
    )
}

struct OpenAIUsageClient: Sendable {
    private let session: URLSession

    private static var userAgent: String {
        let version = (Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "development"
        return "TokenMonitor/\(version)"
    }

    init(session: URLSession? = nil) {
        self.session = session ?? Self.makePrivacyPreservingSession()
    }

    private static func makePrivacyPreservingSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        return URLSession(configuration: configuration)
    }

    func monthToDateTokens(apiKey: String, now: Date = Date()) async throws -> TokenSnapshot {
        let interval = UTCMonthRange.containing(now)
        var page: String?
        var accumulator = UsagePageAccumulator()

        repeat {
            let requestedPage = page
            let response = try await fetchPage(
                apiKey: apiKey,
                start: interval.start,
                end: now,
                page: page
            )
            let appended = accumulator.append(response, requestedCursor: requestedPage)

            if appended.hasMalformedPagination {
                throw UsageClientError.invalidResponse("伺服器表示仍有下一頁，但沒有提供游標。")
            }
            if appended.wouldRepeatCursor {
                throw UsageClientError.invalidResponse("伺服器重複傳回相同分頁游標。")
            }
            page = appended.nextPage
        } while page != nil

        let totals = accumulator.totals
        return TokenSnapshot(
            inputTokens: Int64(totals.inputTokens),
            outputTokens: Int64(totals.outputTokens),
            cachedInputTokens: Int64(totals.inputCachedTokens),
            requests: Int64(totals.modelRequests)
        )
    }

    private func fetchPage(
        apiKey: String,
        start: Date,
        end: Date,
        page: String?
    ) async throws -> CompletionsUsagePage {
        var components = URLComponents(string: "https://api.openai.com/v1/organization/usage/completions")
        var queryItems = [
            URLQueryItem(name: "start_time", value: String(Int(start.timeIntervalSince1970))),
            URLQueryItem(name: "end_time", value: String(Int(end.timeIntervalSince1970) + 1)),
            URLQueryItem(name: "bucket_width", value: "1d"),
            URLQueryItem(name: "limit", value: "31")
        ]
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: page))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw UsageClientError.invalidResponse("無法建立 Usage API 網址。")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 25
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw UsageClientError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw UsageClientError.invalidResponse("沒有收到有效的 HTTP 回應。")
        }

        guard (200..<300).contains(http.statusCode) else {
            let apiMessage = (try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data).error.message)
            throw UsageClientError.http(status: http.statusCode, message: apiMessage)
        }

        do {
            return try JSONDecoder().decode(CompletionsUsagePage.self, from: data)
        } catch {
            throw UsageClientError.invalidResponse("JSON 解析失敗：\(error.localizedDescription)")
        }
    }
}

private struct OpenAIErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
}

enum UsageClientError: LocalizedError {
    case network(String)
    case http(status: Int, message: String?)
    case invalidResponse(String)

    var errorDescription: String? {
        switch self {
        case .network(let message):
            return "網路連線失敗：\(message)"
        case .http(let status, let message):
            if status == 401 || status == 403 {
                return "OpenAI 拒絕存取（HTTP \(status)）。此功能需要組織 Admin API Key；一般 Project API Key 無法讀取組織用量。"
            }
            return "OpenAI API 錯誤（HTTP \(status)）：\(message ?? "沒有錯誤訊息")"
        case .invalidResponse(let message):
            return "OpenAI 回應格式異常：\(message)"
        }
    }
}
