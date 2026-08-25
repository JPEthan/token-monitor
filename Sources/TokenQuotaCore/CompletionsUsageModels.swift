import Foundation

/// A page returned by `GET /v1/organization/usage/completions`.
public struct CompletionsUsagePage: Codable, Equatable, Sendable {
    public let object: String?
    public let data: [CompletionsUsageBucket]
    public let hasMore: Bool
    public let nextPage: String?

    public init(
        object: String? = "page",
        data: [CompletionsUsageBucket],
        hasMore: Bool,
        nextPage: String?
    ) {
        self.object = object
        self.data = data
        self.hasMore = hasMore
        self.nextPage = nextPage
    }

    private enum CodingKeys: String, CodingKey {
        case object
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}

/// One time bucket in a completions usage page.
public struct CompletionsUsageBucket: Codable, Equatable, Sendable {
    public let object: String?
    public let startTime: Int64
    public let endTime: Int64
    public let results: [CompletionsUsageResult]

    public init(
        object: String? = "bucket",
        startTime: Int64,
        endTime: Int64,
        results: [CompletionsUsageResult]
    ) {
        self.object = object
        self.startTime = startTime
        self.endTime = endTime
        self.results = results
    }

    private enum CodingKeys: String, CodingKey {
        case object
        case startTime = "start_time"
        case endTime = "end_time"
        case results
    }
}

/// Aggregated completions usage for a bucket and, when requested, grouping dimensions.
public struct CompletionsUsageResult: Codable, Equatable, Sendable {
    public let object: String?
    public let inputTokens: Int64
    public let outputTokens: Int64
    public let inputCachedTokens: Int64
    public let numModelRequests: Int64

    // Grouping dimensions are retained so identical-looking rows from different
    // groups are not accidentally merged by the pagination accumulator.
    public let projectID: String?
    public let userID: String?
    public let apiKeyID: String?
    public let model: String?
    public let batch: Bool?
    public let serviceTier: String?

    public init(
        object: String? = "organization.usage.completions.result",
        inputTokens: Int64,
        outputTokens: Int64,
        inputCachedTokens: Int64 = 0,
        numModelRequests: Int64,
        projectID: String? = nil,
        userID: String? = nil,
        apiKeyID: String? = nil,
        model: String? = nil,
        batch: Bool? = nil,
        serviceTier: String? = nil
    ) {
        self.object = object
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.inputCachedTokens = inputCachedTokens
        self.numModelRequests = numModelRequests
        self.projectID = projectID
        self.userID = userID
        self.apiKeyID = apiKeyID
        self.model = model
        self.batch = batch
        self.serviceTier = serviceTier
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        object = try container.decodeIfPresent(String.self, forKey: .object)
        inputTokens = try container.decodeIfPresent(Int64.self, forKey: .inputTokens) ?? 0
        outputTokens = try container.decodeIfPresent(Int64.self, forKey: .outputTokens) ?? 0
        inputCachedTokens = try container.decodeIfPresent(Int64.self, forKey: .inputCachedTokens) ?? 0
        numModelRequests = try container.decodeIfPresent(Int64.self, forKey: .numModelRequests) ?? 0
        projectID = try container.decodeIfPresent(String.self, forKey: .projectID)
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        apiKeyID = try container.decodeIfPresent(String.self, forKey: .apiKeyID)
        model = try container.decodeIfPresent(String.self, forKey: .model)
        batch = try container.decodeIfPresent(Bool.self, forKey: .batch)
        serviceTier = try container.decodeIfPresent(String.self, forKey: .serviceTier)
    }

    private enum CodingKeys: String, CodingKey {
        case object
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case inputCachedTokens = "input_cached_tokens"
        case numModelRequests = "num_model_requests"
        case projectID = "project_id"
        case userID = "user_id"
        case apiKeyID = "api_key_id"
        case model
        case batch
        case serviceTier = "service_tier"
    }
}
