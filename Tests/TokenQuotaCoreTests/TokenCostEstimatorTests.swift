import XCTest
@testable import TokenQuotaCore

final class TokenCostEstimatorTests: XCTestCase {
    func testOfficialStandardRatesForAllSupportedModels() {
        let usage = (input: Int64(1_000_000), cached: Int64(200_000), output: Int64(100_000))

        let sol = TokenCostEstimator.estimate(
            inputTokens: usage.input,
            cachedInputTokens: usage.cached,
            outputTokens: usage.output,
            model: .sol
        )
        let terra = TokenCostEstimator.estimate(
            inputTokens: usage.input,
            cachedInputTokens: usage.cached,
            outputTokens: usage.output,
            model: .terra
        )
        let luna = TokenCostEstimator.estimate(
            inputTokens: usage.input,
            cachedInputTokens: usage.cached,
            outputTokens: usage.output,
            model: .luna
        )

        XCTAssertEqual(sol.totalUSD, Decimal(string: "5.28"))
        XCTAssertEqual(terra.totalUSD, Decimal(string: "2.84"))
        XCTAssertEqual(luna.totalUSD, Decimal(string: "0.284"))
    }

    func testCachedInputIsNotChargedAgainAtTheFullInputRate() {
        let estimate = TokenCostEstimator.estimate(
            inputTokens: 1_000_000,
            cachedInputTokens: 1_000_000,
            outputTokens: 0,
            model: .sol
        )

        XCTAssertEqual(estimate.uncachedInputUSD, 0)
        XCTAssertEqual(estimate.cachedInputUSD, Decimal(string: "0.40"))
        XCTAssertEqual(estimate.totalUSD, Decimal(string: "0.40"))
    }

    func testMalformedCountersAreClamped() {
        let estimate = TokenCostEstimator.estimate(
            inputTokens: 100,
            cachedInputTokens: 1_000,
            outputTokens: -20,
            model: .terra
        )

        XCTAssertEqual(estimate.uncachedInputUSD, 0)
        XCTAssertEqual(estimate.cachedInputUSD, Decimal(string: "0.00002"))
        XCTAssertEqual(estimate.outputUSD, 0)
    }
}
