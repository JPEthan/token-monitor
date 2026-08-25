import Foundation

@main
enum LocalizationCheck {
    static func main() {
        for language in AppLanguage.allCases {
            precondition(!language.displayName.isEmpty)
            for key in L10nKey.allCases {
                precondition(!L10n.text(key, language: language).isEmpty)
            }
        }

        precondition(L10n.text(.appTitle, language: .traditionalChinese) == "Token Monitor")
        precondition(L10n.text(.appTitle, language: .simplifiedChinese) == "Token Monitor")
        precondition(L10n.text(.appTitle, language: .english) == "Token Monitor")
        precondition(L10n.text(.duckSound, language: .english) == "Rubber-duck sound")

        print("✓ 三種顯示語言的所有介面字串完整")
    }
}
