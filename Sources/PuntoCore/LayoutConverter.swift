import Foundation

/// Converts text between Russian and English keyboard layouts
public final class LayoutConverter {

    // MARK: - Character Mappings

    /// English to Russian mapping for Russian-PC/Windows ЙЦУКЕН layout.
    /// This preserves Punto's historical conversion table and remains the
    /// default for source-compatible converter calls that do not pass settings.
    private let windowsEnToRu: [Character: Character] = [
        // Lowercase letters
        "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е", "y": "н", "u": "г",
        "i": "ш", "o": "щ", "p": "з", "[": "х", "]": "ъ", "a": "ф", "s": "ы",
        "d": "в", "f": "а", "g": "п", "h": "р", "j": "о", "k": "л", "l": "д",
        ";": "ж", "'": "э", "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и",
        "n": "т", "m": "ь", ",": "б", ".": "ю", "/": ".",
        "`": "ё",

        // Uppercase letters (Shift + letter)
        "Q": "Й", "W": "Ц", "E": "У", "R": "К", "T": "Е", "Y": "Н", "U": "Г",
        "I": "Ш", "O": "Щ", "P": "З", "{": "Х", "}": "Ъ", "A": "Ф", "S": "Ы",
        "D": "В", "F": "А", "G": "П", "H": "Р", "J": "О", "K": "Л", "L": "Д",
        ":": "Ж", "\"": "Э", "Z": "Я", "X": "Ч", "C": "С", "V": "М", "B": "И",
        "N": "Т", "M": "Ь", "<": "Б", ">": "Ю", "?": ",",
        "~": "Ё",

        // Shift + numbers: EN -> RU (Russian-PC/Windows layout)
        // Shift+1: ! -> ! (same)
        // Shift+2: @ -> "
        "@": "\"",
        // Shift+3: # -> №
        "#": "№",
        // Shift+4: $ -> ;
        "$": ";",
        // Shift+5: % -> % (same)
        // Shift+6: ^ -> :
        "^": ":",
        // Shift+7: & -> ?
        "&": "?",
        // Shift+8: * -> * (same)
        // Shift+9: ( -> ( (same)
        // Shift+0: ) -> ) (same)

        // Special characters
        "\\": "\\", "|": "/"
    ]

    /// English to Russian mapping for macOS `com.apple.keylayout.Russian`.
    /// The punctuation rows match the local TIS/UCKeyTranslate output for the
    /// built-in Apple Russian layout.
    private let macEnToRu: [Character: Character] = [
        // Lowercase letters
        "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е", "y": "н", "u": "г",
        "i": "ш", "o": "щ", "p": "з", "[": "х", "]": "ъ", "a": "ф", "s": "ы",
        "d": "в", "f": "а", "g": "п", "h": "р", "j": "о", "k": "л", "l": "д",
        ";": "ж", "'": "э", "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и",
        "n": "т", "m": "ь", ",": "б", ".": "ю", "/": "/",
        "`": "]", "\\": "ё",

        // Uppercase letters (Shift + letter)
        "Q": "Й", "W": "Ц", "E": "У", "R": "К", "T": "Е", "Y": "Н", "U": "Г",
        "I": "Ш", "O": "Щ", "P": "З", "{": "Х", "}": "Ъ", "A": "Ф", "S": "Ы",
        "D": "В", "F": "А", "G": "П", "H": "Р", "J": "О", "K": "Л", "L": "Д",
        ":": "Ж", "\"": "Э", "Z": "Я", "X": "Ч", "C": "С", "V": "М", "B": "И",
        "N": "Т", "M": "Ь", "<": "Б", ">": "Ю", "?": "?",
        "~": "[", "|": "Ё",

        // Shift + numbers: EN -> RU (Apple Russian layout)
        // Shift+1: ! -> ! (same)
        // Shift+2: @ -> "
        "@": "\"",
        // Shift+3: # -> №
        "#": "№",
        // Shift+4: $ -> %
        "$": "%",
        // Shift+5: % -> :
        "%": ":",
        // Shift+6: ^ -> ,
        "^": ",",
        // Shift+7: & -> .
        "&": ".",
        // Shift+8: * -> ;
        "*": ";"
        // Shift+9/0, -/_, =/+ are unchanged.
    ]

    /// Russian to English mappings (reverse of layout-specific EN -> RU maps).
    private var windowsRuToEn: [Character: Character] = [:]
    private var macRuToEn: [Character: Character] = [:]

    public init() {
        windowsRuToEn = Self.reversedMapping(from: windowsEnToRu)
        macRuToEn = Self.reversedMapping(from: macEnToRu)

        // Fix ambiguous mappings for RU -> EN direction
        // These are cases where multiple EN keys map to the same RU character
        // We choose the mapping based on the selected Russian keyboard layout.
        windowsRuToEn["\""] = "@"  // Shift+2 on RU keyboard produces ", maps to @ on EN
        windowsRuToEn[";"] = "$"   // Shift+4 on RU keyboard produces ;, maps to $ on EN
        windowsRuToEn[":"] = "^"   // Shift+6 on RU keyboard produces :, maps to ^ on EN
        windowsRuToEn["?"] = "&"   // Shift+7 on RU keyboard produces ?, maps to & on EN
        windowsRuToEn["№"] = "#"   // Shift+3 on RU keyboard produces №, maps to # on EN
        macRuToEn["\""] = "@"
        macRuToEn["№"] = "#"
        macRuToEn["%"] = "$"
        macRuToEn[":"] = "%"
        macRuToEn[","] = "^"
        macRuToEn["."] = "&"
        macRuToEn[";"] = "*"
        // Note: "," maps to both "б" (letter) and Shift+/ result. We keep "б" -> "," mapping
        // as it's more common for text conversion. Shift symbols are edge cases.
    }

    // MARK: - Conversion

    /// Converts text between layouts, auto-detecting the source layout.
    /// Mixed English/Russian text is left unchanged; punctuation-only text can
    /// still use the physical-key majority fallback.
    public func convert(_ text: String) -> String {
        convertWithResult(text).text
    }

    public func convert(_ text: String, russianLayoutType: KeyboardLayoutType) -> String {
        convertWithResult(text, russianLayoutType: russianLayoutType).text
    }

    /// Converts English text to Russian layout
    public func convertToRussian(_ text: String) -> String {
        convertToRussian(text, russianLayoutType: .windows)
    }

    public func convertToRussian(_ text: String, russianLayoutType: KeyboardLayoutType) -> String {
        let mapping = enToRuMapping(for: russianLayoutType)
        return String(text.map { mapping[$0] ?? $0 })
    }

    /// Converts Russian text to English layout
    public func convertToEnglish(_ text: String) -> String {
        convertToEnglish(text, russianLayoutType: .windows)
    }

    public func convertToEnglish(_ text: String, russianLayoutType: KeyboardLayoutType) -> String {
        let mapping = ruToEnMapping(for: russianLayoutType)
        return String(text.map { mapping[$0] ?? $0 })
    }

    // MARK: - Layout Detection

    public enum DetectedLayout {
        case english
        case russian
        case mixed
        case unknown
    }

    /// Результат конвертации с информацией о направлении
    public struct ConversionResult {
        public let text: String
        public let targetLayout: DetectedLayout

        public var shouldApply: Bool {
            targetLayout != .unknown
        }
    }

    /// Конвертирует текст и возвращает результат с направлением
    public func convertWithResult(_ text: String) -> ConversionResult {
        convertWithResult(text, russianLayoutType: .windows)
    }

    public func convertWithResult(
        _ text: String,
        russianLayoutType: KeyboardLayoutType
    ) -> ConversionResult {
        let sourceLayout = detectLayout(text)

        switch sourceLayout {
        case .english:
            return ConversionResult(
                text: convertToRussian(text, russianLayoutType: russianLayoutType),
                targetLayout: .russian
            )
        case .russian:
            return ConversionResult(
                text: convertToEnglish(text, russianLayoutType: russianLayoutType),
                targetLayout: .english
            )
        case .mixed:
            return ConversionResult(text: text, targetLayout: .unknown)
        case .unknown:
            let direction = majorityConversionDirection(for: text, russianLayoutType: russianLayoutType)
            switch direction {
            case .toRussian:
                return ConversionResult(
                    text: convertToRussian(text, russianLayoutType: russianLayoutType),
                    targetLayout: .russian
                )
            case .toEnglish:
                return ConversionResult(
                    text: convertToEnglish(text, russianLayoutType: russianLayoutType),
                    targetLayout: .english
                )
            case .none:
                return ConversionResult(text: text, targetLayout: .unknown)
            }
        }
    }

    /// Detects the keyboard layout of the given text
    public func detectLayout(_ text: String) -> DetectedLayout {
        var englishCount = 0
        var russianCount = 0

        for char in text {
            if isEnglishLetter(char) {
                englishCount += 1
            } else if isRussianLetter(char) {
                russianCount += 1
            }
        }

        return LayoutDetectionPolicy.detectedLayout(
            englishCount: englishCount,
            russianCount: russianCount
        )
    }

    private func isEnglishLetter(_ char: Character) -> Bool {
        LayoutDetectionPolicy.isEnglishLetter(char)
    }

    private func isRussianLetter(_ char: Character) -> Bool {
        LayoutDetectionPolicy.isRussianLetter(char)
    }

    private enum ConversionDirection {
        case toRussian
        case toEnglish
        case none
    }

    private func majorityConversionDirection(
        for text: String,
        russianLayoutType: KeyboardLayoutType
    ) -> ConversionDirection {
        var enToRuCount = 0
        var ruToEnCount = 0
        let enToRu = enToRuMapping(for: russianLayoutType)
        let ruToEn = ruToEnMapping(for: russianLayoutType)

        for char in text {
            if let converted = enToRu[char], converted != char {
                enToRuCount += 1
            }
            if let converted = ruToEn[char], converted != char {
                ruToEnCount += 1
            }
        }

        guard enToRuCount > 0 || ruToEnCount > 0 else {
            return .none
        }

        if enToRuCount >= ruToEnCount {
            return .toRussian
        } else {
            return .toEnglish
        }
    }

    private func enToRuMapping(for layoutType: KeyboardLayoutType) -> [Character: Character] {
        switch layoutType {
        case .mac:
            return macEnToRu
        case .windows:
            return windowsEnToRu
        }
    }

    private func ruToEnMapping(for layoutType: KeyboardLayoutType) -> [Character: Character] {
        switch layoutType {
        case .mac:
            return macRuToEn
        case .windows:
            return windowsRuToEn
        }
    }

    private static func reversedMapping(from mapping: [Character: Character]) -> [Character: Character] {
        var reversed = [Character: Character]()
        for (en, ru) in mapping {
            reversed[ru] = en
        }
        return reversed
    }
}
