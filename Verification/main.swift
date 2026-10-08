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

    try run("GPT-6 Astra 既有估價保持不變") {
        let astra = TokenCostEstimator.estimate(
            inputTokens: 1_000_000,
            cachedInputTokens: 200_000,
            outputTokens: 100_000,
            model: .astra
        )

        try expect(astra.uncachedInputUSD == 8, "Astra 非快取輸入應為 US$8.00")
        try expect(astra.cachedInputUSD == Decimal(string: "0.20"), "Astra 快取輸入應為 US$0.20")
        try expect(astra.outputUSD == 5, "Astra 輸出應為 US$5.00")
        try expect(astra.totalUSD == Decimal(string: "13.20"), "Astra 估價應為 US$13.20")
    }

    try run("GPT-6 Sol、GPT-6 Luna、GPT-6.1 Sol 混合及全快取用量計費正確") {
        let cases: [(model: PricingModel, input: String, cached: String, output: String, total: String)] = [
            (.sol6, "2", "0.20", "10", "2.64"),
            (.luna6, "0.10", "0.01", "0.50", "0.132"),
            (.sol61, "2", "0.10", "10", "2.62"),
        ]
        for item in cases {
            try expect(item.model.inputUSDPerMillion == Decimal(string: item.input), "\(item.model) 輸入單價錯誤")
            try expect(item.model.cachedInputUSDPerMillion == Decimal(string: item.cached), "\(item.model) 快取單價錯誤")
            try expect(item.model.outputUSDPerMillion == Decimal(string: item.output), "\(item.model) 輸出單價錯誤")
            let mixed = TokenCostEstimator.estimate(
                inputTokens: 1_000_000, cachedInputTokens: 200_000,
                outputTokens: 100_000, model: item.model
            )
            try expect(mixed.totalUSD == Decimal(string: item.total), "\(item.model) 混合用量估價錯誤")
            let cachedOnly = TokenCostEstimator.estimate(
                inputTokens: 1_000_000, cachedInputTokens: 1_000_000,
                outputTokens: 0, model: item.model
            )
            try expect(cachedOnly.uncachedInputUSD == 0, "全快取不應另計普通輸入費用")
            try expect(cachedOnly.totalUSD == Decimal(string: item.cached), "\(item.model) 全快取估價錯誤")
            let invalid = TokenCostEstimator.estimate(
                inputTokens: -100, cachedInputTokens: 500, outputTokens: -20, model: item.model
            )
            try expect(invalid.totalUSD == 0, "異常用量不應產生費用")
        }
    }

    try run("僅保留四個 GPT-6、GPT-6.1 模型，既有選項可還原") {
        let cases: [(id: String, model: PricingModel, name: String)] = [
            ("gpt-6-astra", .astra, "GPT-6 Astra"),
            ("gpt-6.1-sol", .sol61, "GPT-6.1 Sol"),
            ("gpt-6-sol", .sol6, "GPT-6 Sol"),
            ("gpt-6-luna", .luna6, "GPT-6 Luna"),
        ]
        try expect(PricingModel.allCases.count == cases.count, "選單應有四個模型")
        for item in cases {
            try expect(PricingModel(rawValue: item.id) == item.model, "\(item.id) 無法還原")
            try expect(item.model.rawValue == item.id, "\(item.id) 儲存值錯誤")
            try expect(item.model.displayName == item.name, "\(item.id) 顯示名稱錯誤")
            try expect(PricingModel.allCases.contains(item.model), "選單缺少 \(item.id)")
            try expect(PricingModel.restoredSelection(item.id) == item.model, "已保存選項應保持不變")
        }
    }

    try run("舊版 GPT-5.6、未知及未設定模型回退至 GPT-6.1 Sol") {
        for id: String? in [nil, "", "unknown", "gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna"] {
            try expect(PricingModel.restoredSelection(id) == .sol61, "舊選項應遷移至 Sol 6.1")
            try expect(PricingModel(rawValue: id ?? "") == nil, "不應保留舊版計費模型")
        }
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
