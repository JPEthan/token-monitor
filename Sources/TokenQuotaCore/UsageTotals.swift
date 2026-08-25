import Foundation

/// Token and request totals accumulated across one or more usage pages.
public struct UsageTotals: Equatable, Sendable {
    public private(set) var inputTokens: Int64
    public private(set) var outputTokens: Int64
    public private(set) var inputCachedTokens: Int64
    public private(set) var modelRequests: Int64

    public init(
        inputTokens: Int64 = 0,
        outputTokens: Int64 = 0,
        inputCachedTokens: Int64 = 0,
        modelRequests: Int64 = 0
    ) {
        self.inputTokens = max(inputTokens, 0)
        self.outputTokens = max(outputTokens, 0)
        self.inputCachedTokens = max(inputCachedTokens, 0)
        self.modelRequests = max(modelRequests, 0)
    }

    public static let zero = UsageTotals()

    /// Billable/consumed token count for the monitor.
    ///
    /// OpenAI's completions Usage API defines `input_tokens` as already including
    /// cached and cache-write tokens. Consequently `input_cached_tokens` is not
    /// added again here.
    public var totalUsedTokens: Int64 {
        Self.saturatingAdd(inputTokens, outputTokens)
    }

    public mutating func add(_ result: CompletionsUsageResult) {
        inputTokens = Self.saturatingAdd(inputTokens, max(result.inputTokens, 0))
        outputTokens = Self.saturatingAdd(outputTokens, max(result.outputTokens, 0))
        inputCachedTokens = Self.saturatingAdd(
            inputCachedTokens,
            max(result.inputCachedTokens, 0)
        )
        modelRequests = Self.saturatingAdd(modelRequests, max(result.numModelRequests, 0))
    }

    public mutating func add(_ other: UsageTotals) {
        inputTokens = Self.saturatingAdd(inputTokens, max(other.inputTokens, 0))
        outputTokens = Self.saturatingAdd(outputTokens, max(other.outputTokens, 0))
        inputCachedTokens = Self.saturatingAdd(
            inputCachedTokens,
            max(other.inputCachedTokens, 0)
        )
        modelRequests = Self.saturatingAdd(modelRequests, max(other.modelRequests, 0))
    }

    public static func totals(for page: CompletionsUsagePage) -> UsageTotals {
        var totals = UsageTotals.zero
        for bucket in page.data {
            for result in bucket.results {
                totals.add(result)
            }
        }
        return totals
    }

    private static func saturatingAdd(_ lhs: Int64, _ rhs: Int64) -> Int64 {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? Int64.max : sum
    }
}

/// A quota-oriented view over usage totals and a user-configured token limit.
public struct TokenQuotaSnapshot: Equatable, Sendable {
    public let limit: Int64
    public let totals: UsageTotals

    public init(limit: Int64, totals: UsageTotals) {
        self.limit = max(limit, 0)
        self.totals = totals
    }

    public var usedTokens: Int64 {
        totals.totalUsedTokens
    }

    public var remainingTokens: Int64 {
        guard usedTokens < limit else { return 0 }
        return limit - usedTokens
    }

    /// A progress-friendly value clamped to `0...1`.
    public var usedFraction: Double {
        guard limit > 0 else { return usedTokens > 0 ? 1 : 0 }
        return min(max(Double(usedTokens) / Double(limit), 0), 1)
    }

    public var usedPercentage: Double {
        usedFraction * 100
    }

    public var remainingPercentage: Double {
        (1 - usedFraction) * 100
    }

    public var isLimitExceeded: Bool {
        usedTokens > limit
    }
}
