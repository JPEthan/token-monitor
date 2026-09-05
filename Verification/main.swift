import Darwin
import Foundation

enum VerificationFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): message
        }
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw VerificationFailure.failed(message)
    }
}

func run(_ name: String, _ body: () throws -> Void) throws {
    try body()
    print("✓ \(name)")
}

do {
    try run("解析官方 Usage API JSON 與分頁欄位") {
        let json = #"""
        {
          "object": "page",
          "data": [{
            "object": "bucket",
            "start_time": 1722470400,
            "end_time": 1722556800,
            "results": [{
              "object": "organization.usage.completions.result",
              "input_tokens": 1200,
              "output_tokens": 300,
              "input_cached_tokens": 800,
              "num_model_requests": 7
            }]
          }],
          "has_more": true,
          "next_page": "page_2"
        }
        """#.data(using: .utf8)!

        let page = try JSONDecoder().decode(CompletionsUsagePage.self, from: json)
        try expect(page.hasMore, "has_more 應為 true")
        try expect(page.nextPage == "page_2", "next_page 未正確解析")
        try expect(page.data.first?.results.first?.inputCachedTokens == 800, "快取 Token 未正確解析")
    }

    try run("快取輸入不會被重複加入總使用量") {
        let totals = UsageTotals(
            inputTokens: 1_200,
            outputTokens: 300,
            inputCachedTokens: 800,
            modelRequests: 7
        )
        try expect(totals.totalUsedTokens == 1_500, "總使用量應為 input + output")
    }

    try run("GPT-6 Astra、Sol、Terra、Luna 美元估價會分開計算快取輸入") {
        let astra = TokenCostEstimator.estimate(
            inputTokens: 1_000_000,
            cachedInputTokens: 200_000,
            outputTokens: 100_000,
            model: .astra
        )
        let sol = TokenCostEstimator.estimate(
            inputTokens: 1_000_000,
            cachedInputTokens: 200_000,
            outputTokens: 100_000,
            model: .sol
        )
        let terra = TokenCostEstimator.estimate(
            inputTokens: 1_000_000,
            cachedInputTokens: 200_000,
            outputTokens: 100_000,
            model: .terra
        )
        let luna = TokenCostEstimator.estimate(
            inputTokens: 1_000_000,
            cachedInputTokens: 200_000,
            outputTokens: 100_000,
            model: .luna
        )

        try expect(astra.uncachedInputUSD == 8, "Astra 非快取輸入應為 US$8.00")
        try expect(astra.cachedInputUSD == Decimal(string: "0.20"), "Astra 快取輸入應為 US$0.20")
        try expect(astra.outputUSD == 5, "Astra 輸出應為 US$5.00")
        try expect(astra.totalUSD == Decimal(string: "13.20"), "Astra 估價應為 US$13.20")
        try expect(sol.totalUSD == Decimal(string: "5.28"), "Sol 估價應為 US$5.28")
        try expect(terra.totalUSD == Decimal(string: "2.84"), "Terra 估價應為 US$2.84")
        try expect(luna.totalUSD == Decimal(string: "0.284"), "Luna 估價應為 US$0.284")
    }

    try run("GPT-6 Astra 全快取輸入與異常用量計費正確") {
        let cachedOnly = TokenCostEstimator.estimate(
            inputTokens: 1_000_000,
            cachedInputTokens: 1_000_000,
            outputTokens: 0,
            model: .astra
        )
        try expect(cachedOnly.uncachedInputUSD == 0, "全快取輸入不應另計普通輸入費用")
        try expect(cachedOnly.totalUSD == 1, "Astra 一百萬全快取輸入應為 US$1.00")

        let invalid = TokenCostEstimator.estimate(
            inputTokens: -100,
            cachedInputTokens: 500,
            outputTokens: -20,
            model: .astra
        )
        try expect(invalid.totalUSD == 0, "異常用量不應產生負費用或超額快取費用")
        try expect(PricingModel(rawValue: "gpt-6-astra") == .astra, "已儲存的 Astra 選項應可還原")
        try expect(PricingModel.allCases.contains(.astra), "設定選單應包含 Astra")
    }

    try run("剩餘 Token 與超額狀態正確") {
        let under = TokenQuotaSnapshot(
            limit: 2_000,
            totals: UsageTotals(inputTokens: 1_200, outputTokens: 300)
        )
        try expect(under.remainingTokens == 500, "剩餘量應為 500")
        try expect(abs(under.usedFraction - 0.75) < 0.000_001, "比例應為 75%")

        let over = TokenQuotaSnapshot(
            limit: 1_000,
            totals: UsageTotals(inputTokens: 1_200, outputTokens: 300)
        )
        try expect(over.remainingTokens == 0, "超額時剩餘量應截斷為 0")
        try expect(over.isLimitExceeded, "應標記為已超額")
    }

    try run("UTC 月份區間正確處理閏年") {
        let parser = ISO8601DateFormatter()
        let reference = parser.date(from: "2024-02-20T12:00:00Z")!
        let range = UTCMonthRange.containing(reference)
        try expect(range.start == parser.date(from: "2024-02-01T00:00:00Z"), "二月起點錯誤")
        try expect(range.endExclusive == parser.date(from: "2024-03-01T00:00:00Z"), "閏年二月終點錯誤")
    }

    try run("分頁重疊資料不會重複累加") {
        let result = CompletionsUsageResult(
            inputTokens: 100,
            outputTokens: 20,
            inputCachedTokens: 80,
            numModelRequests: 2
        )
        let bucket = CompletionsUsageBucket(
            startTime: 1_722_470_400,
            endTime: 1_722_556_800,
            results: [result]
        )
        let first = CompletionsUsagePage(data: [bucket], hasMore: true, nextPage: "page_2")
        let repeated = CompletionsUsagePage(data: [bucket], hasMore: false, nextPage: nil)

        var accumulator = UsagePageAccumulator()
        let firstAppend = accumulator.append(first)
        let secondAppend = accumulator.append(repeated, requestedCursor: firstAppend.nextPage)

        try expect(firstAppend.addedResultCount == 1, "第一頁應新增一筆")
        try expect(secondAppend.duplicateResultCount == 1, "第二頁應辨識一筆重複資料")
        try expect(accumulator.totals.totalUsedTokens == 120, "重疊分頁不得重複累加")
    }

    print("\n所有核心驗證通過。")
} catch {
    fputs("✗ 驗證失敗：\(error)\n", stderr)
    exit(1)
}
