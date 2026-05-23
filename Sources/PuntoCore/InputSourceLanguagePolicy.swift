import Foundation

public enum InputSourceLanguagePolicy {
    public static func isEnglishInputSource(sourceID: String, languages: [String]) -> Bool {
        normalizedLanguages(languages).contains(where: { languageMatches($0, primaryLanguage: "en") })
            || hasLayoutToken(sourceID, tokens: ["abc", "us", "usinternational", "usextended", "dvorak", "colemak", "british", "australian"])
    }

    public static func isRussianInputSource(sourceID: String, languages: [String]) -> Bool {
        normalizedLanguages(languages).contains(where: { languageMatches($0, primaryLanguage: "ru") })
            || hasLayoutToken(sourceID, tokens: ["russian", "russianwin"])
    }

    private static func normalizedLanguages(_ languages: [String]) -> Set<String> {
        Set(languages.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
    }

    private static func languageMatches(_ language: String, primaryLanguage: String) -> Bool {
        language == primaryLanguage
            || language.hasPrefix("\(primaryLanguage)-")
            || language.hasPrefix("\(primaryLanguage)_")
    }

    private static func hasLayoutToken(_ sourceID: String, tokens: Set<String>) -> Bool {
        let normalized = sourceID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return false
        }

        return normalized
            .split { !$0.isLetter && !$0.isNumber }
            .contains { tokens.contains(String($0)) }
    }
}
