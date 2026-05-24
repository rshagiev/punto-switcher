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

    private static let dvorakOutputByQwertyKey: [Character: Character] = [
        "q": "'", "w": ",", "e": ".", "r": "p", "t": "y", "y": "f", "u": "g",
        "i": "c", "o": "r", "p": "l", "[": "/", "]": "=", "a": "a", "s": "o",
        "d": "e", "f": "u", "g": "i", "h": "d", "j": "h", "k": "t", "l": "n",
        ";": "s", "'": "-", "z": ";", "x": "q", "c": "j", "v": "k", "b": "x",
        "n": "b", "m": "m", ",": "w", ".": "v", "/": "z",

        "Q": "\"", "W": "<", "E": ">", "R": "P", "T": "Y", "Y": "F", "U": "G",
        "I": "C", "O": "R", "P": "L", "{": "?", "}": "+", "A": "A", "S": "O",
        "D": "E", "F": "U", "G": "I", "H": "D", "J": "H", "K": "T", "L": "N",
        ":": "S", "\"": "_", "Z": ":", "X": "Q", "C": "J", "V": "K", "B": "X",
        "N": "B", "M": "M", "<": "W", ">": "V", "?": "Z"
    ]

    public static func enToRuMapping(for layoutType: KeyboardLayoutType) -> [Character: Character] {
        enToRuMapping(for: .qwerty, russianLayoutType: layoutType)
    }

    public static func enToRuMapping(
        for englishLayoutVariant: KeyboardLayoutVariant,
        russianLayoutType layoutType: KeyboardLayoutType
    ) -> [Character: Character] {
        switch layoutType {
        case .mac:
            return englishLayoutVariant == .dvorak
                ? remappedEnglishOutputMapping(from: macEnToRu)
                : macEnToRu
        case .windows:
            return englishLayoutVariant == .dvorak
                ? remappedEnglishOutputMapping(from: windowsEnToRu)
                : windowsEnToRu
        }
    }

    public static func ruToEnMapping(for layoutType: KeyboardLayoutType) -> [Character: Character] {
        ruToEnMapping(for: .qwerty, russianLayoutType: layoutType)
    }

    public static func ruToEnMapping(
        for englishLayoutVariant: KeyboardLayoutVariant,
        russianLayoutType layoutType: KeyboardLayoutType
    ) -> [Character: Character] {
        var mapping = reversedMapping(from: enToRuMapping(
            for: englishLayoutVariant,
            russianLayoutType: layoutType
        ))
        switch layoutType {
        case .mac:
            assignReverseAmbiguityFixes(
                &mapping,
                [
                    "\"": "@",
                    "№": "#",
                    "%": "$",
                    ":": "%",
                    ",": "^",
                    ".": "&",
                    ";": "*"
                ],
                englishLayoutVariant: englishLayoutVariant
            )
        case .windows:
            assignReverseAmbiguityFixes(
                &mapping,
                [
                    "\"": "@",
                    ";": "$",
                    ":": "^",
                    "?": "&",
                    "№": "#"
                ],
                englishLayoutVariant: englishLayoutVariant
            )
        }
        return mapping
    }

    public static func isLayoutMappedPunctuation(
        _ character: Character,
        russianLayoutType: KeyboardLayoutType
    ) -> Bool {
        isLayoutMappedPunctuation(
            character,
            englishLayoutVariant: .qwerty,
            russianLayoutType: russianLayoutType
        )
    }

    public static func isLayoutMappedPunctuation(
        _ character: Character,
        englishLayoutVariant: KeyboardLayoutVariant,
        russianLayoutType: KeyboardLayoutType
    ) -> Bool {
        if russianLayoutType == .windows, character == "|" {
            return false
        }
        guard !LayoutDetectionPolicy.isEnglishLetter(character),
              !LayoutDetectionPolicy.isRussianLetter(character) else {
            return false
        }
        return enToRuMapping(
            for: englishLayoutVariant,
            russianLayoutType: russianLayoutType
        )[character].map { $0 != character } ?? false
    }

    private static func reversedMapping(from mapping: [Character: Character]) -> [Character: Character] {
        var reversed = [Character: Character]()
        for (en, ru) in mapping {
            reversed[ru] = en
        }
        return reversed
    }

    private static func remappedEnglishOutputMapping(
        from qwertyMapping: [Character: Character]
    ) -> [Character: Character] {
        var remapped = [Character: Character]()
        for (qwertyKey, ruOutput) in qwertyMapping {
            let englishOutput = dvorakOutputByQwertyKey[qwertyKey] ?? qwertyKey
            remapped[englishOutput] = ruOutput
        }
        return remapped
    }

    private static func assignReverseAmbiguityFixes(
        _ mapping: inout [Character: Character],
        _ qwertyFixes: [Character: Character],
        englishLayoutVariant: KeyboardLayoutVariant
    ) {
        for (ruOutput, qwertyKey) in qwertyFixes {
            mapping[ruOutput] = englishOutput(forQwertyKey: qwertyKey, variant: englishLayoutVariant)
        }
    }

    private static func englishOutput(
        forQwertyKey qwertyKey: Character,
        variant: KeyboardLayoutVariant
    ) -> Character {
        switch variant {
        case .qwerty:
            return qwertyKey
        case .dvorak:
            return dvorakOutputByQwertyKey[qwertyKey] ?? qwertyKey
        }
    }
}
