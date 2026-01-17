import Foundation

/// Converts text between Russian and English keyboard layouts
final class LayoutConverter {

    // MARK: - Character Mappings

    /// English to Russian mapping (based on standard QWERTY and ЙЦУКЕН layouts on Mac)
    private let enToRu: [Character: Character] = [
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

        // Shift + numbers: EN -> RU (Mac Russian layout)
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

    /// Russian to English mapping (reverse of enToRu)
    private var ruToEn: [Character: Character] = [:]

    init() {
        // Build reverse mapping
        for (en, ru) in enToRu {
            ruToEn[ru] = en
        }

        // Fix ambiguous mappings for RU -> EN direction
        // These are cases where multiple EN keys map to the same RU character
        // We choose the mapping based on Mac Russian keyboard Shift+number positions
        ruToEn["\""] = "@"  // Shift+2 on RU keyboard produces ", maps to @ on EN
        ruToEn[";"] = "$"   // Shift+4 on RU keyboard produces ;, maps to $ on EN
        ruToEn[":"] = "^"   // Shift+6 on RU keyboard produces :, maps to ^ on EN
        ruToEn["?"] = "&"   // Shift+7 on RU keyboard produces ?, maps to & on EN
        ruToEn["№"] = "#"   // Shift+3 on RU keyboard produces №, maps to # on EN
        // Note: "," maps to both "б" (letter) and Shift+/ result. We keep "б" -> "," mapping
        // as it's more common for text conversion. Shift symbols are edge cases.
    }

    // MARK: - Conversion

    /// Converts text between layouts, auto-detecting the source layout
    func convert(_ text: String) -> String {
        let layout = detectLayout(text)

        switch layout {
        case .english:
            return convertToRussian(text)
        case .russian:
            return convertToEnglish(text)
        case .mixed, .unknown:
            // For mixed or unknown, try to convert based on majority
            return convertBasedOnMajority(text)
        }
    }

    /// Converts English text to Russian layout
    func convertToRussian(_ text: String) -> String {
        return String(text.map { enToRu[$0] ?? $0 })
    }

    /// Converts Russian text to English layout
    func convertToEnglish(_ text: String) -> String {
        return String(text.map { ruToEn[$0] ?? $0 })
    }

    // MARK: - Layout Detection

    enum DetectedLayout {
        case english
        case russian
        case mixed
        case unknown
    }

    /// Результат конвертации с информацией о направлении
    struct ConversionResult {
        let text: String
        let targetLayout: DetectedLayout
    }

    /// Конвертирует текст и возвращает результат с направлением
    func convertWithResult(_ text: String) -> ConversionResult {
        let sourceLayout = detectLayout(text)

        switch sourceLayout {
        case .english:
            return ConversionResult(text: convertToRussian(text), targetLayout: .russian)
        case .russian:
            return ConversionResult(text: convertToEnglish(text), targetLayout: .english)
        case .mixed, .unknown:
            var enToRuCount = 0, ruToEnCount = 0
            for char in text {
                if enToRu[char] != nil { enToRuCount += 1 }
                if ruToEn[char] != nil { ruToEnCount += 1 }
            }
            if enToRuCount >= ruToEnCount {
                return ConversionResult(text: convertToRussian(text), targetLayout: .russian)
            } else {
                return ConversionResult(text: convertToEnglish(text), targetLayout: .english)
            }
        }
    }

    /// Detects the keyboard layout of the given text
    func detectLayout(_ text: String) -> DetectedLayout {
        var englishCount = 0
        var russianCount = 0

        for char in text {
            if isEnglishLetter(char) {
                englishCount += 1
            } else if isRussianLetter(char) {
                russianCount += 1
            }
        }

        let total = englishCount + russianCount

        if total == 0 {
            return .unknown
        }

        let englishRatio = Double(englishCount) / Double(total)

        if englishRatio > 0.8 {
            return .english
        } else if englishRatio < 0.2 {
            return .russian
        } else {
            return .mixed
        }
    }

    private func isEnglishLetter(_ char: Character) -> Bool {
        let scalar = char.unicodeScalars.first!
        return (scalar.value >= 0x41 && scalar.value <= 0x5A) || // A-Z
               (scalar.value >= 0x61 && scalar.value <= 0x7A)    // a-z
    }

    private func isRussianLetter(_ char: Character) -> Bool {
        let scalar = char.unicodeScalars.first!
        return (scalar.value >= 0x410 && scalar.value <= 0x44F) || // А-я
               scalar.value == 0x401 || scalar.value == 0x451      // Ё, ё
    }

    private func convertBasedOnMajority(_ text: String) -> String {
        // Count convertible characters in each direction
        var enToRuCount = 0
        var ruToEnCount = 0

        for char in text {
            if enToRu[char] != nil {
                enToRuCount += 1
            }
            if ruToEn[char] != nil {
                ruToEnCount += 1
            }
        }

        // Convert based on which mapping has more matches
        if enToRuCount >= ruToEnCount {
            return convertToRussian(text)
        } else {
            return convertToEnglish(text)
        }
    }
}
