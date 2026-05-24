import Foundation

public enum WordBoundaryPolicy {
    public static let spaceKeyCode: UInt16 = 49

    private static let typedWordBoundaries: Set<Character> = [
        " ", "\n", "\t", "\r",
        "!",
        "(", ")",
        "\\", "|",
        "@", "#", "$", "%", "^", "&", "*",
        "+", "=", "-", "_"
    ]

    private static let commandSuffixBoundaries: Set<Character> = [
        "&", "|", ";",
        "(", ")",
        "<", ">",
        "=", "-"
    ]

    private static let terminalPromptMarkers: Set<Character> = [
        "%", "$", "#", ">",
        "➜", "❯", "λ",
        "✗", "✔", "±", "●"
    ]

    public static func isTypedWordBoundary(_ character: Character, keyCode: UInt16) -> Bool {
        isTypedWordBoundary(character, keyCode: keyCode, russianLayoutType: .windows)
    }

    public static func isTypedWordBoundary(
        _ character: Character,
        keyCode: UInt16,
        russianLayoutType: KeyboardLayoutType
    ) -> Bool {
        if keyCode == spaceKeyCode {
            return true
        }

        if isLayoutMappedPunctuation(character, russianLayoutType: russianLayoutType) {
            return false
        }

        return typedWordBoundaries.contains(character)
    }

    public static func isLayoutMappedPunctuation(_ character: Character) -> Bool {
        isLayoutMappedPunctuation(character, russianLayoutType: .windows)
    }

    public static func isLayoutMappedPunctuation(
        _ character: Character,
        russianLayoutType: KeyboardLayoutType
    ) -> Bool {
        KeyboardLayoutMappingPolicy.isLayoutMappedPunctuation(
            character,
            russianLayoutType: russianLayoutType
        )
    }

    public static func isCommandSuffixBoundary(_ character: Character) -> Bool {
        character.isWhitespace || commandSuffixBoundaries.contains(character)
    }

    public static func hasCommandSuffixBoundary(beforeSuffix suffix: String, in text: String) -> Bool {
        guard text.hasSuffix(suffix) else {
            return false
        }

        guard text.count > suffix.count else {
            return true
        }

        let boundaryIndex = text.index(text.endIndex, offsetBy: -suffix.count)
        let preceding = text[text.index(before: boundaryIndex)]
        return isCommandSuffixBoundary(preceding)
    }

    public static func isTerminalPromptMarker(_ character: Character) -> Bool {
        terminalPromptMarkers.contains(character)
    }
}
