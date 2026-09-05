import Foundation

/// Models supported by the monitor's what-if cost estimate.
///
/// Standard short-context text-token rates, verified on 2026-09-06 at
/// https://developers.openai.com/api/docs/pricing (USD per one million tokens).
public enum PricingModel: String, CaseIterable, Identifiable, Sendable {
    case astra = "gpt-6-astra"
    case sol = "gpt-5.6-sol"
    case terra = "gpt-5.6-terra"
    case luna = "gpt-5.6-luna"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .astra: "GPT-6 Astra"
        case .sol: "GPT-5.6 Sol"
        case .terra: "GPT-5.6 Terra"
        case .luna: "GPT-5.6 Luna"
        }
    }

    public var inputUSDPerMillion: Decimal { rates.input }

    public var cachedInputUSDPerMillion: Decimal { rates.cachedInput }

    public var outputUSDPerMillion: Decimal { rates.output }

    // Keep each model's three rates together so future updates stay consistent.
    private var rates: (input: Decimal, cachedInput: Decimal, output: Decimal) {
        switch self {
        case .astra: (10, 1, 50)
        case .sol: (4, Decimal(4) / 10, 20)
        case .terra: (2, Decimal(2) / 10, 12)
        case .luna: (Decimal(2) / 10, Decimal(2) / 100, Decimal(12) / 10)
        }
    }
}

/// A transparent breakdown of the model-based USD estimate.
public struct TokenCostEstimate: Equatable, Sendable {
    public let uncachedInputUSD: Decimal
    public let cachedInputUSD: Decimal
    public let outputUSD: Decimal

    public init(
        uncachedInputUSD: Decimal,
        cachedInputUSD: Decimal,
        outputUSD: Decimal
    ) {
        self.uncachedInputUSD = uncachedInputUSD
        self.cachedInputUSD = cachedInputUSD
        self.outputUSD = outputUSD
    }

    public var totalUSD: Decimal {
        uncachedInputUSD + cachedInputUSD + outputUSD
    }
}

public enum TokenCostEstimator {
    public static let pricingReferenceDate = "2026-09-06"

    /// Estimates standard short-context text-token cost for one selected model.
    ///
    /// The Usage API reports cached input as a subset of `input_tokens`, so the
    /// cached portion is removed before applying the full input rate. Cached
    /// input is clamped to total input to defend against malformed aggregates.
    /// Monthly totals cannot identify per-request long-context pricing or cache
    /// writes. Those surcharges and non-standard service tiers are not included.
    public static func estimate(
        inputTokens: Int64,
        cachedInputTokens: Int64,
        outputTokens: Int64,
        model: PricingModel
    ) -> TokenCostEstimate {
        let input = max(inputTokens, 0)
        let cached = min(max(cachedInputTokens, 0), input)
        let uncached = input - cached
        let output = max(outputTokens, 0)
        let million = Decimal(1_000_000)

        return TokenCostEstimate(
            uncachedInputUSD: Decimal(uncached) * model.inputUSDPerMillion / million,
            cachedInputUSD: Decimal(cached) * model.cachedInputUSDPerMillion / million,
            outputUSD: Decimal(output) * model.outputUSDPerMillion / million
        )
    }
}
