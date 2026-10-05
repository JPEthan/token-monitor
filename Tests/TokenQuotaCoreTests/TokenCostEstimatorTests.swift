import XCTest
@testable import TokenQuotaCore

final class TokenCostEstimatorTests: XCTestCase {
    func testExistingModelEstimatesRemainUnchanged() {
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

    func testNewModelsMixedAndFullyCachedUsage() {
        let cases: [(model: PricingModel, input: String, cached: String, output: String, total: String)] = [
            (.sol6, "2", "0.20", "10", "2.64"),
            (.luna6, "0.10", "0.01", "0.50", "0.132"),
            (.sol61, "2", "0.10", "10", "2.62"),
        ]
        for item in cases {
            XCTAssertEqual(item.model.inputUSDPerMillion, Decimal(string: item.input))
            XCTAssertEqual(item.model.cachedInputUSDPerMillion, Decimal(string: item.cached))
            XCTAssertEqual(item.model.outputUSDPerMillion, Decimal(string: item.output))
            let mixed = TokenCostEstimator.estimate(
                inputTokens: 1_000_000, cachedInputTokens: 200_000,
                outputTokens: 100_000, model: item.model
            )
            XCTAssertEqual(mixed.totalUSD, Decimal(string: item.total), item.model.rawValue)
            let cachedOnly = TokenCostEstimator.estimate(
                inputTokens: 1_000_000, cachedInputTokens: 1_000_000,
                outputTokens: 0, model: item.model
            )
            XCTAssertEqual(cachedOnly.uncachedInputUSD, 0)
            XCTAssertEqual(cachedOnly.totalUSD, Decimal(string: item.cached), item.model.rawValue)
        }
    }

    func testModelIDsPreserveSavedSelectionsAcrossGenerations() {
        let cases: [(id: String, model: PricingModel, name: String)] = [
            ("gpt-6-astra", .astra, "GPT-6 Astra"),
            ("gpt-6.1-sol", .sol61, "GPT-6.1 Sol"),
            ("gpt-6-sol", .sol6, "GPT-6 Sol"),
            ("gpt-6-luna", .luna6, "GPT-6 Luna"),
            ("gpt-5.6-sol", .sol, "GPT-5.6 Sol"),
            ("gpt-5.6-terra", .terra, "GPT-5.6 Terra"),
            ("gpt-5.6-luna", .luna, "GPT-5.6 Luna"),
        ]
        XCTAssertEqual(PricingModel.allCases.count, cases.count)
        for item in cases {
            XCTAssertEqual(PricingModel(rawValue: item.id), item.model)
            XCTAssertEqual(item.model.rawValue, item.id)
            XCTAssertEqual(item.model.displayName, item.name)
            XCTAssertTrue(PricingModel.allCases.contains(item.model))
        }
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
