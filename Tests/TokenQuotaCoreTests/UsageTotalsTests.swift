import XCTest
@testable import TokenQuotaCore

final class UsageTotalsTests: XCTestCase {
    func totalUsedDoesNotDoubleCountCachedInputTokens() {
        let totals = UsageTotals(
            inputTokens: 600,
            outputTokens: 200,
            inputCachedTokens: 500,
            modelRequests: 4
        )

        XCTAssertEqual(totals.totalUsedTokens, 800)
    }

    func quotaSnapshotCalculatesRemainingAndPercentages() {
        let totals = UsageTotals(
            inputTokens: 600,
            outputTokens: 200,
            inputCachedTokens: 500,
            modelRequests: 4
        )
        let snapshot = TokenQuotaSnapshot(limit: 1_000, totals: totals)

        XCTAssertEqual(snapshot.usedTokens, 800)
        XCTAssertEqual(snapshot.remainingTokens, 200)
        XCTAssertEqual(snapshot.usedFraction, 0.8, accuracy: 0.000_001)
        XCTAssertEqual(snapshot.usedPercentage, 80, accuracy: 0.000_001)
        XCTAssertEqual(snapshot.remainingPercentage, 20, accuracy: 0.000_001)
        XCTAssertFalse(snapshot.isLimitExceeded)
    }

    func quotaSnapshotClampsAtZeroWhenUsageExceedsLimit() {
        let totals = UsageTotals(inputTokens: 700, outputTokens: 400)
        let snapshot = TokenQuotaSnapshot(limit: 1_000, totals: totals)

        XCTAssertEqual(snapshot.usedTokens, 1_100)
        XCTAssertEqual(snapshot.remainingTokens, 0)
        XCTAssertEqual(snapshot.usedPercentage, 100, accuracy: 0.000_001)
        XCTAssertEqual(snapshot.remainingPercentage, 0, accuracy: 0.000_001)
        XCTAssertTrue(snapshot.isLimitExceeded)
    }

    func negativeCountersCannotReduceAccumulatedUsage() {
        var totals = UsageTotals.zero
        totals.add(
            CompletionsUsageResult(
                inputTokens: -5,
                outputTokens: -2,
                inputCachedTokens: -3,
                numModelRequests: -1
            )
        )

        XCTAssertEqual(totals, .zero)
    }

    func aggregationSaturatesInsteadOfOverflowing() {
        var totals = UsageTotals(inputTokens: Int64.max)
        totals.add(
            CompletionsUsageResult(
                inputTokens: 1,
                outputTokens: Int64.max,
                numModelRequests: Int64.max
            )
        )

        XCTAssertEqual(totals.inputTokens, Int64.max)
        XCTAssertEqual(totals.totalUsedTokens, Int64.max)
    }
}
