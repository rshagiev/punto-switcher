import Foundation

public enum KeyboardLayoutVariantPolicy {
    public static let defaultEnglishLayoutVariant: KeyboardLayoutVariant = .qwerty

    public static func isDefaultEnglishSource(_ sourceID: String) -> Bool {
        let tokens = normalizedTokens(sourceID)
        return tokens.contains("abc") || tokens.contains("us")
    }

    public static func isDvorakEnglishSource(_ sourceID: String) -> Bool {
        normalizedTokens(sourceID).contains("dvorak")
    }

    public static func isAppleRussianSource(_ sourceID: String) -> Bool {
        let tokens = normalizedTokens(sourceID)
        return tokens.contains("russian") && !tokens.contains("russianwin")
    }

    public static func isWindowsRussianSource(_ sourceID: String) -> Bool {
        normalizedTokens(sourceID).contains("russianwin")
    }

    public static func englishLayoutVariant(for sourceID: String?) -> KeyboardLayoutVariant {
        guard let sourceID else {
            return defaultEnglishLayoutVariant
        }
        if isDvorakEnglishSource(sourceID) {
            return .dvorak
        }
        return defaultEnglishLayoutVariant
    }

    public static func effectiveEnglishLayoutVariant(
        currentSourceID: String?,
        selectedEnglishSourceID: String?,
        preferredEnglishSourceID: String?
    ) -> KeyboardLayoutVariant {
        if isDvorakEnglishSource(currentSourceID ?? "") {
            return .dvorak
        }
        return englishLayoutVariant(for: selectedEnglishSourceID ?? preferredEnglishSourceID)
    }

    private static func normalizedTokens(_ sourceID: String) -> Set<String> {
        Set(sourceID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init))
    }
}
