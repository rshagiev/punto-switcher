import Foundation

public enum KeyboardLayoutVariantPolicy {
    public static let observedIsAppleLayoutSelector = "isAppleLayout"
    public static let observedIsDvorakSelector = "isDvorak"
    public static let observedWindowsLayoutUsedSelector = "windowsLayoutUsed"
    public static let observedFixStringSelector = "fixString:isEnglish:isApple:"
    public static let observedCreateMacToPcMappingSelector = "createMacToPcMappingWithString:pcLayoutA:pcLayoutB:"
    public static let observedConvertStringLayoutSelector = "convertStringLayout:withMode:isPCLayout:"

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

    private static func normalizedTokens(_ sourceID: String) -> Set<String> {
        Set(sourceID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init))
    }
}
