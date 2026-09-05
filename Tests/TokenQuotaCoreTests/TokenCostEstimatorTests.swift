import XCTest
@testable import TokenQuotaCore

final class TokenCostEstimatorTests: XCTestCase {
    func testOfficialStandardRatesForAllSupportedModels() {
        let usage = (input: Int64(1_000_000), cached: Int64(200_000), output: Int64(100_000))

        let astra = TokenCostEstimator.estimate(
            inputTokens: usage.input,
            cachedInputTokens: usage.cached,
            outputTokens: usage.output,
            model: .astra
        )
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

        XCTAssertEqual(astra.uncachedInputUSD, 8)
        XCTAssertEqual(astra.cachedInputUSD, Decimal(string: "0.20"))
        XCTAssertEqual(astra.outputUSD, 5)
        XCTAssertEqual(astra.totalUSD, Decimal(string: "13.20"))
        XCTAssertEqual(sol.totalUSD, Decimal(string: "5.28"))
        XCTAssertEqual(terra.totalUSD, Decimal(string: "2.84"))
        XCTAssertEqual(luna.totalUSD, Decimal(string: "0.284"))
    }

    func testAstraCachedOnlyAndInvalidUsage() {
        let cachedOnly = TokenCostEstimator.estimate(
            inputTokens: 1_000_000,
            cachedInputTokens: 1_000_000,
            outputTokens: 0,
            model: .astra
        )
        XCTAssertEqual(cachedOnly.uncachedInputUSD, 0)
        XCTAssertEqual(cachedOnly.totalUSD, 1)

        let invalid = TokenCostEstimator.estimate(
            inputTokens: -100,
            cachedInputTokens: 500,
            outputTokens: -20,
            model: .astra
        )
        XCTAssertEqual(invalid.totalUSD, 0)
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
