import Foundation

/// GPT-5.6 models supported by the monitor's what-if cost estimate.
///
/// Rates are OpenAI's standard short-context text-token prices published on
/// 2026-08-26. They are expressed in US dollars per one million tokens.
public enum PricingModel: String, CaseIterable, Identifiable, Sendable {
    case sol = "gpt-5.6-sol"
    case terra = "gpt-5.6-terra"
    case luna = "gpt-5.6-luna"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sol: "GPT-5.6 Sol"
        case .terra: "GPT-5.6 Terra"
        case .luna: "GPT-5.6 Luna"
        }
    }

    public var inputUSDPerMillion: Decimal {
        switch self {
        case .sol: 4
        case .terra: 2
        case .luna: Decimal(string: "0.20")!
        }
    }

    public var cachedInputUSDPerMillion: Decimal {
        switch self {
        case .sol: Decimal(string: "0.40")!
        case .terra: Decimal(string: "0.20")!
        case .luna: Decimal(string: "0.02")!
        }
    }

    public var outputUSDPerMillion: Decimal {
        switch self {
        case .sol: 20
        case .terra: 12
        case .luna: Decimal(string: "1.20")!
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
    public static let pricingReferenceDate = "2026-08-26"

    /// Estimates standard short-context text-token cost for one selected model.
    ///
    /// The Usage API reports cached input as a subset of `input_tokens`, so the
    /// cached portion is removed before applying the full input rate. Cached
    /// input is clamped to total input to defend against malformed aggregates.
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
