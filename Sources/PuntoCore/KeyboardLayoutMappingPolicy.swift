import Foundation

public enum KeyboardLayoutMappingPolicy {
    /// English to Russian mapping for Russian-PC/Windows ЙЦУКЕН layout.
    /// This preserves Punto's historical conversion table and remains the
    /// default for source-compatible converter calls that do not pass settings.
    private static let windowsEnToRu: [Character: Character] = [
        "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е", "y": "н", "u": "г",
        "i": "ш", "o": "щ", "p": "з", "[": "х", "]": "ъ", "a": "ф", "s": "ы",
        "d": "в", "f": "а", "g": "п", "h": "р", "j": "о", "k": "л", "l": "д",
        ";": "ж", "'": "э", "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и",
        "n": "т", "m": "ь", ",": "б", ".": "ю", "/": ".",
        "`": "ё",

        "Q": "Й", "W": "Ц", "E": "У", "R": "К", "T": "Е", "Y": "Н", "U": "Г",
        "I": "Ш", "O": "Щ", "P": "З", "{": "Х", "}": "Ъ", "A": "Ф", "S": "Ы",
        "D": "В", "F": "А", "G": "П", "H": "Р", "J": "О", "K": "Л", "L": "Д",
        ":": "Ж", "\"": "Э", "Z": "Я", "X": "Ч", "C": "С", "V": "М", "B": "И",
        "N": "Т", "M": "Ь", "<": "Б", ">": "Ю", "?": ",",
        "~": "Ё",

        "@": "\"",
        "#": "№",
        "$": ";",
        "^": ":",
        "&": "?",

        "\\": "\\", "|": "/"
    ]

    /// English to Russian mapping for macOS `com.apple.keylayout.Russian`.
    /// The punctuation rows match the local TIS/UCKeyTranslate output for the
    /// built-in Apple Russian layout.
    private static let macEnToRu: [Character: Character] = [
        "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е", "y": "н", "u": "г",
        "i": "ш", "o": "щ", "p": "з", "[": "х", "]": "ъ", "a": "ф", "s": "ы",
        "d": "в", "f": "а", "g": "п", "h": "р", "j": "о", "k": "л", "l": "д",
        ";": "ж", "'": "э", "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и",
        "n": "т", "m": "ь", ",": "б", ".": "ю", "/": "/",
        "`": "]", "\\": "ё",

        "Q": "Й", "W": "Ц", "E": "У", "R": "К", "T": "Е", "Y": "Н", "U": "Г",
        "I": "Ш", "O": "Щ", "P": "З", "{": "Х", "}": "Ъ", "A": "Ф", "S": "Ы",
        "D": "В", "F": "А", "G": "П", "H": "Р", "J": "О", "K": "Л", "L": "Д",
        ":": "Ж", "\"": "Э", "Z": "Я", "X": "Ч", "C": "С", "V": "М", "B": "И",
        "N": "Т", "M": "Ь", "<": "Б", ">": "Ю", "?": "?",
        "~": "[", "|": "Ё",

        "@": "\"",
        "#": "№",
        "$": "%",
        "%": ":",
        "^": ",",
        "&": ".",
        "*": ";"
    ]

    public static func enToRuMapping(for layoutType: KeyboardLayoutType) -> [Character: Character] {
        switch layoutType {
        case .mac:
            return macEnToRu
        case .windows:
            return windowsEnToRu
        }
    }

    public static func ruToEnMapping(for layoutType: KeyboardLayoutType) -> [Character: Character] {
        var mapping = reversedMapping(from: enToRuMapping(for: layoutType))
        switch layoutType {
        case .mac:
            mapping["\""] = "@"
            mapping["№"] = "#"
            mapping["%"] = "$"
            mapping[":"] = "%"
            mapping[","] = "^"
            mapping["."] = "&"
            mapping[";"] = "*"
        case .windows:
            mapping["\""] = "@"
            mapping[";"] = "$"
            mapping[":"] = "^"
            mapping["?"] = "&"
            mapping["№"] = "#"
        }
        return mapping
    }

    public static func isLayoutMappedPunctuation(
        _ character: Character,
        russianLayoutType: KeyboardLayoutType
    ) -> Bool {
        if russianLayoutType == .windows, character == "|" {
            return false
        }
        guard !LayoutDetectionPolicy.isEnglishLetter(character),
              !LayoutDetectionPolicy.isRussianLetter(character) else {
            return false
        }
        return enToRuMapping(for: russianLayoutType)[character].map { $0 != character } ?? false
    }

    private static func reversedMapping(from mapping: [Character: Character]) -> [Character: Character] {
        var reversed = [Character: Character]()
        for (en, ru) in mapping {
            reversed[ru] = en
        }
        return reversed
    }
}
