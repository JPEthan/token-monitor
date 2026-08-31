import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case traditionalChinese = "zh-Hant"
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .traditionalChinese: "繁體中文"
        case .simplifiedChinese: "简体中文"
        case .english: "English"
        }
    }
}

enum L10nKey: CaseIterable {
    case appTitle
    case monthlyUsage
    case settings
    case closeSettings
    case remainingToken
    case overLimit
    case used
    case quota
    case input
    case output
    case cachedInput
    case requests
    case estimatedCost
    case estimatedShort
    case pricingModel
    case pricePerMillion
    case bubbleDisplay
    case bubbleTokenUsage
    case bubbleEstimatedCost
    case mascotSize
    case mascotSizeHelp
    case pricingDisclaimer
    case updated
    case syncing
    case refreshAndShow
    case refreshHelp
    case officialUsage
    case quit
    case apiKeyStoredPlaceholder
    case save
    case replace
    case keychainNotice
    case acknowledgeAdminKeyRisk
    case monthlyQuota
    case automaticSync
    case everyOneMinute
    case everyFiveMinutes
    case everyFifteenMinutes
    case removeKey
    case language
    case duckSound
    case duckSoundHelp
    case previewSound
    case calculation
    case calculationDetails
    case needsKey
    case readingUsage
    case enterKey
    case keySaved
    case keyRemoved
    case syncingAPI
    case synced
    case remainingShort
    case notConfigured
    case enterAdminKey
    case syncFailed
    case mascotAccessibility
    case mascotHelp
    case refresh
    case close
    case hideBubble
    case legalTitle
    case legalSummary
    case openDisclaimer
    case openPrivacy
}

enum L10n {
    static func text(_ key: L10nKey, language: AppLanguage) -> String {
        switch language {
        case .traditionalChinese:
            traditionalChinese(key)
        case .simplifiedChinese:
            simplifiedChinese(key)
        case .english:
            english(key)
        }
    }

    private static func traditionalChinese(_ key: L10nKey) -> String {
        switch key {
        case .appTitle: "Token Monitor"
        case .monthlyUsage: "OpenAI API · 本月用量"
        case .settings: "設定"
        case .closeSettings: "關閉設定"
        case .remainingToken: "剩餘 Token"
        case .overLimit: "已超出"
        case .used: "已用"
        case .quota: "額度"
        case .input: "輸入"
        case .output: "輸出"
        case .cachedInput: "其中快取輸入"
        case .requests: "請求次數"
        case .estimatedCost: "本月預估花銷"
        case .estimatedShort: "預估花銷"
        case .pricingModel: "估價模型"
        case .pricePerMillion: "每 100 萬 Token 的標準價格"
        case .bubbleDisplay: "人物氣泡顯示"
        case .bubbleTokenUsage: "Token 使用量"
        case .bubbleEstimatedCost: "預估花銷（美元）"
        case .mascotSize: "龍娘大小"
        case .mascotSizeHelp: "拖動滑塊可即時調整桌面人物大小；設定會自動保存。"
        case .pricingDisclaimer: "依所選模型的 OpenAI API 標準短上下文文字價格估算（價格基準：2026-08-26）。假設本月全部 Token 都使用此模型；不包含長上下文加價、Batch／Flex／Priority、區域處理、Cache Write、工具呼叫或其他費用。價格可能變動，請以 OpenAI 正式帳單為準。"
        case .updated: "更新"
        case .syncing: "同步中…"
        case .refreshAndShow: "刷新並顯示"
        case .refreshHelp: "更新資料並將角色小工具顯示在桌面最上層"
        case .officialUsage: "官方用量頁"
        case .quit: "結束"
        case .apiKeyStoredPlaceholder: "已儲存在 Keychain；輸入可替換"
        case .save: "儲存"
        case .replace: "替換"
        case .keychainNotice: "這是組織層級的高權限憑證。本 App 只以它讀取用量；金鑰只存於 macOS Keychain。從 App 移除不等於在 OpenAI 撤銷。"
        case .acknowledgeAdminKeyRisk: "我了解此金鑰權限很高，且我已獲授權使用"
        case .monthlyQuota: "每月 Token 額度"
        case .automaticSync: "自動同步"
        case .everyOneMinute: "每 1 分鐘"
        case .everyFiveMinutes: "每 5 分鐘"
        case .everyFifteenMinutes: "每 15 分鐘"
        case .removeKey: "移除已儲存的金鑰"
        case .language: "顯示語言"
        case .duckSound: "橡皮鴨音效"
        case .duckSoundHelp: "點擊人物或手動刷新時播放"
        case .previewSound: "試聽"
        case .calculation: "計算方式"
        case .calculationDetails: "剩餘 Token = 自訂月度額度 − 輸入 − 輸出。預估花銷 = 非快取輸入 × Input 單價 + 快取輸入 × Cached Input 單價 + 輸出 × Output 單價。快取輸入已包含在總輸入中，計算時會先拆分，不會重複收費。這是 OpenAI API 估算，不是 ChatGPT Plus／Pro 訂閱費用。"
        case .needsKey: "請先設定 OpenAI Admin API Key。"
        case .readingUsage: "正在讀取本月 Token 用量…"
        case .enterKey: "請輸入 OpenAI Admin API Key。"
        case .keySaved: "金鑰已安全儲存在 macOS Keychain。"
        case .keyRemoved: "已移除金鑰。"
        case .syncingAPI: "正在同步 OpenAI Usage API…"
        case .synced: "已同步；統計期間為本月 1 日 00:00 UTC 至目前。"
        case .remainingShort: "剩"
        case .notConfigured: "尚未設定"
        case .enterAdminKey: "請先輸入 Admin API Key"
        case .syncFailed: "同步失敗，請開啟選單查看"
        case .mascotAccessibility: "白紫色龍娘 Q 版桌面角色，點擊刷新 Token 用量"
        case .mascotHelp: "點擊刷新；拖曳可移動並吸附螢幕邊緣"
        case .refresh: "重新整理"
        case .close: "關閉"
        case .hideBubble: "點擊收起氣泡"
        case .legalTitle: "免責與隱私"
        case .legalSummary: "非 OpenAI 官方產品。剩餘值是自訂估算，不是帳單或官方限額；本軟體按現狀提供。Admin API Key 權限很高，請只使用可信任或已審查的版本。"
        case .openDisclaimer: "查看免責聲明"
        case .openPrivacy: "查看隱私說明"
        }
    }

    private static func simplifiedChinese(_ key: L10nKey) -> String {
        switch key {
        case .appTitle: "Token Monitor"
        case .monthlyUsage: "OpenAI API · 本月用量"
        case .settings: "设置"
        case .closeSettings: "关闭设置"
        case .remainingToken: "剩余 Token"
        case .overLimit: "已超出"
        case .used: "已用"
        case .quota: "额度"
        case .input: "输入"
        case .output: "输出"
        case .cachedInput: "其中缓存输入"
        case .requests: "请求次数"
        case .estimatedCost: "本月预估花销"
        case .estimatedShort: "预估花销"
        case .pricingModel: "估价模型"
        case .pricePerMillion: "每 100 万 Token 的标准价格"
        case .bubbleDisplay: "人物气泡显示"
        case .bubbleTokenUsage: "Token 使用量"
        case .bubbleEstimatedCost: "预估花销（美元）"
        case .mascotSize: "龙娘大小"
        case .mascotSizeHelp: "拖动滑块可实时调整桌面人物大小；设置会自动保存。"
        case .pricingDisclaimer: "按所选模型的 OpenAI API 标准短上下文文字价格估算（价格基准：2026-08-26）。假设本月全部 Token 都使用该模型；不包含长上下文加价、Batch／Flex／Priority、区域处理、Cache Write、工具调用或其他费用。价格可能变动，请以 OpenAI 正式账单为准。"
        case .updated: "更新"
        case .syncing: "同步中…"
        case .refreshAndShow: "刷新并显示"
        case .refreshHelp: "更新数据并将角色小工具显示在桌面最上层"
        case .officialUsage: "官方用量页"
        case .quit: "退出"
        case .apiKeyStoredPlaceholder: "已储存在 Keychain；输入可替换"
        case .save: "保存"
        case .replace: "替换"
        case .keychainNotice: "这是组织级高权限凭证。本 App 仅用它读取用量；密钥只存于 macOS Keychain。从 App 移除不等于在 OpenAI 撤销。"
        case .acknowledgeAdminKeyRisk: "我了解此密钥权限很高，且我已获授权使用"
        case .monthlyQuota: "每月 Token 额度"
        case .automaticSync: "自动同步"
        case .everyOneMinute: "每 1 分钟"
        case .everyFiveMinutes: "每 5 分钟"
        case .everyFifteenMinutes: "每 15 分钟"
        case .removeKey: "移除已储存的密钥"
        case .language: "显示语言"
        case .duckSound: "橡皮鸭音效"
        case .duckSoundHelp: "点击人物或手动刷新时播放"
        case .previewSound: "试听"
        case .calculation: "计算方式"
        case .calculationDetails: "剩余 Token = 自定义月度额度 − 输入 − 输出。预估花销 = 非缓存输入 × Input 单价 + 缓存输入 × Cached Input 单价 + 输出 × Output 单价。缓存输入已包含在总输入中，计算时会先拆分，不会重复收费。这是 OpenAI API 估算，不是 ChatGPT Plus／Pro 订阅费用。"
        case .needsKey: "请先设置 OpenAI Admin API Key。"
        case .readingUsage: "正在读取本月 Token 用量…"
        case .enterKey: "请输入 OpenAI Admin API Key。"
        case .keySaved: "密钥已安全储存在 macOS Keychain。"
        case .keyRemoved: "已移除密钥。"
        case .syncingAPI: "正在同步 OpenAI Usage API…"
        case .synced: "已同步；统计期间为本月 1 日 00:00 UTC 至当前时间。"
        case .remainingShort: "剩"
        case .notConfigured: "尚未设置"
        case .enterAdminKey: "请先输入 Admin API Key"
        case .syncFailed: "同步失败，请打开菜单查看"
        case .mascotAccessibility: "白紫色龙娘 Q 版桌面角色，点击刷新 Token 用量"
        case .mascotHelp: "点击刷新；拖动可移动并吸附屏幕边缘"
        case .refresh: "刷新"
        case .close: "关闭"
        case .hideBubble: "点击收起气泡"
        case .legalTitle: "免责声明与隐私"
        case .legalSummary: "非 OpenAI 官方产品。剩余值是自定义估算，不是账单或官方限额；本软件按现状提供。Admin API Key 权限很高，请仅使用可信或已审查的版本。"
        case .openDisclaimer: "查看免责声明"
        case .openPrivacy: "查看隐私说明"
        }
    }

    private static func english(_ key: L10nKey) -> String {
        switch key {
        case .appTitle: "Token Monitor"
        case .monthlyUsage: "OpenAI API · Monthly usage"
        case .settings: "Settings"
        case .closeSettings: "Close settings"
        case .remainingToken: "Tokens remaining"
        case .overLimit: "Over limit by"
        case .used: "Used"
        case .quota: "Limit"
        case .input: "Input"
        case .output: "Output"
        case .cachedInput: "Cached input"
        case .requests: "Requests"
        case .estimatedCost: "Estimated monthly cost"
        case .estimatedShort: "Estimated cost"
        case .pricingModel: "Pricing model"
        case .pricePerMillion: "Standard price per 1M tokens"
        case .bubbleDisplay: "Character bubble"
        case .bubbleTokenUsage: "Token usage"
        case .bubbleEstimatedCost: "Estimated cost (USD)"
        case .mascotSize: "Character size"
        case .mascotSizeHelp: "Drag the slider to resize the desktop character instantly. Your setting is saved automatically."
        case .pricingDisclaimer: "Estimated from the selected model's standard short-context OpenAI API text-token prices (pricing reference: 2026-08-26). It assumes all monthly tokens used that model and excludes long-context uplifts, Batch/Flex/Priority, regional processing, cache writes, tool calls, and other charges. Prices may change; the OpenAI invoice is authoritative."
        case .updated: "Updated"
        case .syncing: "Syncing…"
        case .refreshAndShow: "Refresh & Show"
        case .refreshHelp: "Refresh data and show the character above other desktop windows"
        case .officialUsage: "Official Usage"
        case .quit: "Quit"
        case .apiKeyStoredPlaceholder: "Stored in Keychain; enter to replace"
        case .save: "Save"
        case .replace: "Replace"
        case .keychainNotice: "This is a highly privileged organization credential. The app uses it only to read usage and stores it only in macOS Keychain. Removing it here does not revoke it at OpenAI."
        case .acknowledgeAdminKeyRisk: "I understand the risk and am authorized to use this key"
        case .monthlyQuota: "Monthly token limit"
        case .automaticSync: "Auto refresh"
        case .everyOneMinute: "Every minute"
        case .everyFiveMinutes: "Every 5 minutes"
        case .everyFifteenMinutes: "Every 15 minutes"
        case .removeKey: "Remove saved key"
        case .language: "Display language"
        case .duckSound: "Rubber-duck sound"
        case .duckSoundHelp: "Plays when the character or manual refresh is clicked"
        case .previewSound: "Preview"
        case .calculation: "How it is calculated"
        case .calculationDetails: "Remaining tokens = custom monthly limit − input − output. Estimated cost = uncached input × input rate + cached input × cached-input rate + output × output rate. Cached input is already included in total input, so it is split out instead of charged twice. This is an OpenAI API estimate, not a ChatGPT Plus/Pro subscription charge."
        case .needsKey: "Set an OpenAI Admin API Key first."
        case .readingUsage: "Reading this month's token usage…"
        case .enterKey: "Enter an OpenAI Admin API Key."
        case .keySaved: "The key is securely stored in macOS Keychain."
        case .keyRemoved: "The saved key was removed."
        case .syncingAPI: "Syncing the OpenAI Usage API…"
        case .synced: "Synced. The period runs from 00:00 UTC on the first day of this month to now."
        case .remainingShort: "Left"
        case .notConfigured: "Not configured"
        case .enterAdminKey: "Enter an Admin API Key first"
        case .syncFailed: "Sync failed; open the menu for details"
        case .mascotAccessibility: "White-and-purple chibi dragon desktop character; click to refresh token usage"
        case .mascotHelp: "Click to refresh; drag to move and snap to a screen edge"
        case .refresh: "Refresh"
        case .close: "Close"
        case .hideBubble: "Click to hide the bubble"
        case .legalTitle: "Disclaimer & Privacy"
        case .legalSummary: "Unofficial third-party software. Remaining values are custom estimates, not billing or official limits. Provided as-is. An Admin API Key is highly privileged; use only a trusted or reviewed build."
        case .openDisclaimer: "View Disclaimer"
        case .openPrivacy: "View Privacy Notice"
        }
    }
}
