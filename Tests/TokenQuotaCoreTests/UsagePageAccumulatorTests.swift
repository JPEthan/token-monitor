import XCTest
@testable import TokenQuotaCore

final class UsagePageAccumulatorTests: XCTestCase {
    func overlappingPagesDoNotDoubleCountRepeatedResults() {
        let firstBucket = bucket(
            start: 100,
            end: 200,
            result: result(input: 100, output: 20, cached: 50, requests: 1, model: "gpt-a")
        )
        let secondBucket = bucket(
            start: 200,
            end: 300,
            result: result(input: 200, output: 30, cached: 80, requests: 2, model: "gpt-b")
        )

        let firstPage = CompletionsUsagePage(
            data: [firstBucket],
            hasMore: true,
            nextPage: "cursor-2"
        )
        let overlappingSecondPage = CompletionsUsagePage(
            data: [firstBucket, secondBucket],
            hasMore: false,
            nextPage: nil
        )

        var accumulator = UsagePageAccumulator()
        let firstAppend = accumulator.append(firstPage)
        let secondAppend = accumulator.append(
            overlappingSecondPage,
            requestedCursor: "cursor-2"
        )

        XCTAssertEqual(firstAppend.addedResultCount, 1)
        XCTAssertEqual(firstAppend.duplicateResultCount, 0)
        XCTAssertEqual(firstAppend.nextPage, "cursor-2")
        XCTAssertEqual(secondAppend.addedResultCount, 1)
        XCTAssertEqual(secondAppend.duplicateResultCount, 1)
        XCTAssertNil(secondAppend.nextPage)

        XCTAssertEqual(accumulator.totals.inputTokens, 300)
        XCTAssertEqual(accumulator.totals.outputTokens, 50)
        XCTAssertEqual(accumulator.totals.inputCachedTokens, 130)
        XCTAssertEqual(accumulator.totals.totalUsedTokens, 350)
        XCTAssertEqual(accumulator.totals.modelRequests, 3)
    }

    func detectsRepeatedNextCursor() {
        var accumulator = UsagePageAccumulator(requestedCursors: ["cursor-loop"])
        let page = CompletionsUsagePage(
            data: [],
            hasMore: true,
            nextPage: "cursor-loop"
        )

        let result = accumulator.append(page)

        XCTAssertTrue(result.wouldRepeatCursor)
        XCTAssertFalse(result.hasMalformedPagination)
    }

    func logicalRowWithChangedCountersIsStillDeduplicated() {
        let original = bucket(
            start: 100,
            end: 200,
            result: result(input: 100, output: 20, cached: 50, requests: 1, model: "gpt-a")
        )
        let sameRowUpdated = bucket(
            start: 100,
            end: 200,
            result: result(input: 110, output: 25, cached: 55, requests: 2, model: "gpt-a")
        )

        var accumulator = UsagePageAccumulator()
        _ = accumulator.append(
            CompletionsUsagePage(data: [original], hasMore: true, nextPage: "next")
        )
        let secondAppend = accumulator.append(
            CompletionsUsagePage(data: [sameRowUpdated], hasMore: false, nextPage: nil),
            requestedCursor: "next"
        )

        XCTAssertEqual(secondAppend.addedResultCount, 0)
        XCTAssertEqual(secondAppend.duplicateResultCount, 1)
        XCTAssertEqual(accumulator.totals.totalUsedTokens, 120)
    }

    func detectsHasMoreWithoutNextPage() {
        var accumulator = UsagePageAccumulator()
        let page = CompletionsUsagePage(data: [], hasMore: true, nextPage: nil)

        let result = accumulator.append(page)

        XCTAssertTrue(result.hasMalformedPagination)
        XCTAssertNil(result.nextPage)
    }

    private func bucket(
        start: Int64,
        end: Int64,
        result: CompletionsUsageResult
    ) -> CompletionsUsageBucket {
        CompletionsUsageBucket(startTime: start, endTime: end, results: [result])
    }

    private func result(
        input: Int64,
        output: Int64,
        cached: Int64,
        requests: Int64,
        model: String
    ) -> CompletionsUsageResult {
        CompletionsUsageResult(
            inputTokens: input,
            outputTokens: output,
            inputCachedTokens: cached,
            numModelRequests: requests,
            model: model
        )
    }
}
