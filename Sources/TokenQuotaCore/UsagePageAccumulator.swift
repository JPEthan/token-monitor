import Foundation

/// Stable identity for a result within its time bucket.
///
/// The Usage API does not expose a row ID. The bucket interval and grouping
/// dimensions therefore form the logical row identity. Counters are excluded so
/// an overlapping page cannot double-count the same row if its values changed.
public struct CompletionsUsageResultKey: Hashable, Sendable {
    public let bucketStartTime: Int64
    public let bucketEndTime: Int64
    public let projectID: String?
    public let userID: String?
    public let apiKeyID: String?
    public let model: String?
    public let batch: Bool?
    public let serviceTier: String?

    public init(bucket: CompletionsUsageBucket, result: CompletionsUsageResult) {
        bucketStartTime = bucket.startTime
        bucketEndTime = bucket.endTime
        projectID = result.projectID
        userID = result.userID
        apiKeyID = result.apiKeyID
        model = result.model
        batch = result.batch
        serviceTier = result.serviceTier
    }
}

public struct UsagePageAppendResult: Equatable, Sendable {
    public let addedResultCount: Int
    public let duplicateResultCount: Int
    public let nextPage: String?
    public let hasMalformedPagination: Bool
    public let wouldRepeatCursor: Bool

    public init(
        addedResultCount: Int,
        duplicateResultCount: Int,
        nextPage: String?,
        hasMalformedPagination: Bool,
        wouldRepeatCursor: Bool
    ) {
        self.addedResultCount = addedResultCount
        self.duplicateResultCount = duplicateResultCount
        self.nextPage = nextPage
        self.hasMalformedPagination = hasMalformedPagination
        self.wouldRepeatCursor = wouldRepeatCursor
    }
}

/// Incrementally combines paginated Usage API results without double-counting
/// repeated rows or following the same cursor twice.
public struct UsagePageAccumulator: Sendable {
    public private(set) var totals: UsageTotals
    public private(set) var seenResultKeys: Set<CompletionsUsageResultKey>
    public private(set) var requestedCursors: Set<String>

    public init(
        totals: UsageTotals = .zero,
        seenResultKeys: Set<CompletionsUsageResultKey> = [],
        requestedCursors: Set<String> = []
    ) {
        self.totals = totals
        self.seenResultKeys = seenResultKeys
        self.requestedCursors = requestedCursors
    }

    /// Adds a response page. Pass the cursor used to request this page (or `nil`
    /// for the first page) so cursor cycles can be detected before the next fetch.
    @discardableResult
    public mutating func append(
        _ page: CompletionsUsagePage,
        requestedCursor: String? = nil
    ) -> UsagePageAppendResult {
        if let requestedCursor {
            requestedCursors.insert(requestedCursor)
        }

        var added = 0
        var duplicates = 0

        for bucket in page.data {
            for result in bucket.results {
                let key = CompletionsUsageResultKey(bucket: bucket, result: result)
                if seenResultKeys.insert(key).inserted {
                    totals.add(result)
                    added += 1
                } else {
                    duplicates += 1
                }
            }
        }

        let nextCursor = page.hasMore ? page.nextPage : nil
        return UsagePageAppendResult(
            addedResultCount: added,
            duplicateResultCount: duplicates,
            nextPage: nextCursor,
            hasMalformedPagination: page.hasMore && page.nextPage == nil,
            wouldRepeatCursor: nextCursor.map(requestedCursors.contains) ?? false
        )
    }
}
