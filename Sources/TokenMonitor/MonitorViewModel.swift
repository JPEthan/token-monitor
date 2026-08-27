import AppKit
import Foundation
import TokenQuotaCore

enum RefreshCadence: Int, CaseIterable, Identifiable {
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900

    var id: Int { rawValue }

    func label(language: AppLanguage) -> String {
        switch self {
        case .oneMinute: L10n.text(.everyOneMinute, language: language)
        case .fiveMinutes: L10n.text(.everyFiveMinutes, language: language)
        case .fifteenMinutes: L10n.text(.everyFifteenMinutes, language: language)
        }
    }
}

enum WidgetBubbleContent: String, CaseIterable, Identifiable {
    case tokenUsage
    case estimatedCost

    var id: String { rawValue }

    func label(language: AppLanguage) -> String {
        switch self {
        case .tokenUsage: L10n.text(.bubbleTokenUsage, language: language)
        case .estimatedCost: L10n.text(.bubbleEstimatedCost, language: language)
        }
    }
}

private enum MonitorStatus {
    case needsKey
    case readingUsage
    case enterKey
    case keySaved
    case keyRemoved
    case syncingAPI
    case synced
    case error(String)
}

@MainActor
final class MonitorViewModel: ObservableObject {
    @Published private(set) var snapshot = TokenSnapshot.zero
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isRefreshing = false
    @Published private(set) var hasSavedAPIKey = false
    @Published private(set) var widgetBubbleVisible = true
    @Published private var status = MonitorStatus.needsKey
    @Published var statusIsError = false
    @Published var apiKeyInput = ""

    @Published var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Keys.language)
        }
    }

    @Published var soundEffectsEnabled: Bool {
        didSet {
            defaults.set(soundEffectsEnabled, forKey: Keys.soundEffectsEnabled)
        }
    }

    @Published var monthlyTokenLimit: Int64 {
        didSet {
            let clamped = max(monthlyTokenLimit, 1)
            if clamped != monthlyTokenLimit {
                monthlyTokenLimit = clamped
            }
            defaults.set(clamped, forKey: Keys.monthlyTokenLimit)
        }
    }

    @Published var refreshCadence: RefreshCadence {
        didSet {
            defaults.set(refreshCadence.rawValue, forKey: Keys.refreshCadence)
            restartAutomaticRefresh()
        }
    }

    @Published var pricingModel: PricingModel {
        didSet {
            defaults.set(pricingModel.rawValue, forKey: Keys.pricingModel)
        }
    }

    @Published var widgetBubbleContent: WidgetBubbleContent {
        didSet {
            defaults.set(widgetBubbleContent.rawValue, forKey: Keys.widgetBubbleContent)
        }
    }

    private enum Keys {
        static let monthlyTokenLimit = "monthlyTokenLimit"
        static let refreshCadence = "refreshCadence"
        static let language = "language"
        static let soundEffectsEnabled = "soundEffectsEnabled"
        static let pricingModel = "pricingModel"
        static let widgetBubbleContent = "widgetBubbleContent"
    }

    private let defaults: UserDefaults
    private let client: OpenAIUsageClient
    private let duckSoundPlayer = RubberDuckSoundPlayer()
    private var apiKey: String?
    private var refreshTask: Task<Void, Never>?
    private var bubbleTask: Task<Void, Never>?
    private var hasStarted = false

    init(defaults: UserDefaults = .standard, client: OpenAIUsageClient = OpenAIUsageClient()) {
        self.defaults = defaults
        self.client = client

        let savedLimit = defaults.object(forKey: Keys.monthlyTokenLimit) as? NSNumber
        self.monthlyTokenLimit = max(savedLimit?.int64Value ?? 10_000_000, 1)

        let savedCadence = defaults.integer(forKey: Keys.refreshCadence)
        self.refreshCadence = RefreshCadence(rawValue: savedCadence) ?? .oneMinute

        let savedLanguage = defaults.string(forKey: Keys.language)
        self.language = AppLanguage(rawValue: savedLanguage ?? "") ?? .traditionalChinese

        self.soundEffectsEnabled = defaults.object(forKey: Keys.soundEffectsEnabled) == nil
            ? true
            : defaults.bool(forKey: Keys.soundEffectsEnabled)

        let savedPricingModel = defaults.string(forKey: Keys.pricingModel)
        self.pricingModel = PricingModel(rawValue: savedPricingModel ?? "") ?? .terra

        let savedBubbleContent = defaults.string(forKey: Keys.widgetBubbleContent)
        self.widgetBubbleContent = WidgetBubbleContent(rawValue: savedBubbleContent ?? "")
            ?? .tokenUsage
    }

    var usedTokens: Int64 { snapshot.usedTokens }
    var remainingTokens: Int64 { max(monthlyTokenLimit - usedTokens, 0) }
    var overLimitTokens: Int64 { max(usedTokens - monthlyTokenLimit, 0) }
    var usageFraction: Double {
        min(max(Double(usedTokens) / Double(max(monthlyTokenLimit, 1)), 0), 1)
    }
    var estimatedCost: TokenCostEstimate {
        TokenCostEstimator.estimate(
            inputTokens: snapshot.inputTokens,
            cachedInputTokens: snapshot.cachedInputTokens,
            outputTokens: snapshot.outputTokens,
            model: pricingModel
        )
    }
    var estimatedCostText: String {
        USDFormat.amount(estimatedCost.totalUSD)
    }

    var menuBarText: String {
        guard hasSavedAPIKey else { return "Token --" }
        return "\(text(.remainingShort)) \(TokenFormat.compact(remainingTokens))"
    }

    var statusMessage: String {
        switch status {
        case .needsKey: text(.needsKey)
        case .readingUsage: text(.readingUsage)
        case .enterKey: text(.enterKey)
        case .keySaved: text(.keySaved)
        case .keyRemoved: text(.keyRemoved)
        case .syncingAPI: text(.syncingAPI)
        case .synced: text(.synced)
        case .error(let message): message
        }
    }

    var menuBarIcon: String {
        if statusIsError { return "exclamationmark.triangle" }
        if usageFraction >= 0.95 { return "gauge.high" }
        if usageFraction >= 0.75 { return "gauge.medium" }
        return "gauge.low"
    }

    func startIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true

        do {
            apiKey = try KeychainStore.loadAPIKey()
            hasSavedAPIKey = apiKey != nil
            if hasSavedAPIKey {
                status = .readingUsage
                await refresh()
            }
        } catch {
            setError(error.localizedDescription)
        }
        restartAutomaticRefresh()
    }

    func saveAPIKey() async {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            status = .enterKey
            statusIsError = true
            return
        }

        do {
            try KeychainStore.saveAPIKey(trimmed)
            apiKey = trimmed
            apiKeyInput = ""
            hasSavedAPIKey = true
            statusIsError = false
            status = .keySaved
            await refresh()
        } catch {
            setError(error.localizedDescription)
        }
    }

    func removeAPIKey() {
        do {
            try KeychainStore.deleteAPIKey()
            apiKey = nil
            hasSavedAPIKey = false
            snapshot = .zero
            lastUpdated = nil
            statusIsError = false
            status = .keyRemoved
        } catch {
            setError(error.localizedDescription)
        }
    }

    func refresh(revealWidget: Bool = false) async {
        if revealWidget {
            revealWidgetBubble()
        }
        guard !isRefreshing else { return }
        guard let apiKey else {
            status = .needsKey
            statusIsError = false
            return
        }

        isRefreshing = true
        statusIsError = false
        status = .syncingAPI
        defer { isRefreshing = false }

        do {
            snapshot = try await client.monthToDateTokens(apiKey: apiKey)
            lastUpdated = Date()
            status = .synced
        } catch {
            setError(error.localizedDescription)
        }
    }

    func revealWidgetBubble() {
        bubbleTask?.cancel()
        widgetBubbleVisible = true
        bubbleTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(8))
            } catch {
                return
            }
            guard let self else { return }
            self.widgetBubbleVisible = false
        }
    }

    func hideWidgetBubble() {
        bubbleTask?.cancel()
        bubbleTask = nil
        widgetBubbleVisible = false
    }

    func openUsageDashboard() {
        guard let url = URL(string: "https://platform.openai.com/usage") else { return }
        NSWorkspace.shared.open(url)
    }

    func openBundledLegalDocument(named name: String) {
        guard
            let url = Bundle.main.url(
                forResource: name,
                withExtension: "md",
                subdirectory: "Legal"
            )
        else { return }
        NSWorkspace.shared.open(url)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    func text(_ key: L10nKey) -> String {
        L10n.text(key, language: language)
    }

    func playDuckSound(force: Bool = false) {
        guard force || soundEffectsEnabled else { return }
        duckSoundPlayer.play()
    }

    private func restartAutomaticRefresh() {
        refreshTask?.cancel()
        let seconds = refreshCadence.rawValue
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(seconds))
                } catch {
                    return
                }
                guard let self else { return }
                await self.refresh()
            }
        }
    }

    private func setError(_ message: String) {
        statusIsError = true
        status = .error(message)
    }
}

enum TokenFormat {
    static func full(_ value: Int64) -> String {
        value.formatted(.number.grouping(.automatic))
    }

    static func compact(_ value: Int64) -> String {
        let absolute = Double(abs(value))
        let sign = value < 0 ? "-" : ""
        switch absolute {
        case 1_000_000_000...:
            return "\(sign)\(format(absolute / 1_000_000_000))B"
        case 1_000_000...:
            return "\(sign)\(format(absolute / 1_000_000))M"
        case 1_000...:
            return "\(sign)\(format(absolute / 1_000))K"
        default:
            return "\(value)"
        }
    }

    private static func format(_ value: Double) -> String {
        if value >= 100 { return String(format: "%.0f", value) }
        if value >= 10 { return String(format: "%.1f", value) }
        return String(format: "%.2f", value)
    }
}

enum USDFormat {
    static func amount(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: max(value, 0))
        let absolute = number.doubleValue
        let fractionDigits: Int
        switch absolute {
        case 0:
            fractionDigits = 2
        case ..<0.01:
            fractionDigits = 6
        case ..<1:
            fractionDigits = 4
        default:
            fractionDigits = 2
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return "US$\(formatter.string(from: number) ?? "0.00")"
    }

    static func rate(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "US$\(formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0.00")"
    }
}
