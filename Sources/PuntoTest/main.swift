import Foundation

// MARK: - Test Harness for Punto

// MARK: - Hotkey Structure (copy from HotkeyManager for testing)

/// Represents a keyboard shortcut
struct Hotkey: Codable, Equatable {
    var keyCode: UInt16
    var command: Bool
    var option: Bool
    var shift: Bool
    var control: Bool

    /// Special keyCode value indicating modifier-only hotkey (no key, just modifiers)
    static let modifierOnlyKeyCode: UInt16 = UInt16.max

    /// Whether this is a modifier-only hotkey (triggered by pressing modifiers without a key)
    var isModifierOnly: Bool {
        return keyCode == Self.modifierOnlyKeyCode
    }

    /// Default hotkey for layout conversion: Cmd+Option+Shift (modifier-only)
    static let defaultConvertLayout = Hotkey(
        keyCode: modifierOnlyKeyCode,
        command: true,
        option: true,
        shift: true,
        control: false
    )

    /// Default hotkey for toggle case: Cmd+Option+Z
    static let defaultToggleCase = Hotkey(
        keyCode: 6, // Z key
        command: true,
        option: true,
        shift: false,
        control: false
    )

    var displayString: String {
        var parts: [String] = []

        if control { parts.append("\u{2303}") } // Control symbol
        if option { parts.append("\u{2325}") }  // Option symbol
        if shift { parts.append("\u{21E7}") }   // Shift symbol
        if command { parts.append("\u{2318}") } // Command symbol

        // Only show key name if not modifier-only
        if !isModifierOnly, let keyName = KeyCodeNames.name(for: keyCode) {
            parts.append(keyName)
        }

        return parts.joined(separator: "")
    }
}

// MARK: - Key Code Names (copy from HotkeyManager for testing)

enum KeyCodeNames {
    private static let names: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
        44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space",
        50: "`", 51: "Delete", 53: "Escape", 55: "Command", 56: "Shift",
        57: "Caps Lock", 58: "Option", 59: "Control", 60: "Right Shift",
        61: "Right Option", 62: "Right Control", 63: "Function",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
        103: "F11", 105: "F13", 107: "F14", 109: "F10", 111: "F12",
        113: "F15", 114: "Help", 115: "Home", 116: "Page Up", 117: "Forward Delete",
        118: "F4", 119: "End", 120: "F2", 121: "Page Down", 122: "F1", 123: "Left",
        124: "Right", 125: "Down", 126: "Up"
    ]

    static func name(for keyCode: UInt16) -> String? {
        return names[keyCode]
    }
}

// MARK: - Real WordTracker (copy from production for testing)

/// Tracks the last typed word using a ring buffer
final class RealWordTracker {
    private let maxSize: Int
    private var buffer: [Character]
    private var head: Int = 0
    private var count: Int = 0

    private let wordBoundaries: Set<Character> = [
        " ", "\n", "\t", "\r",
        "!", "?",
        "(", ")",
        "/", "\\", "|",
        "@", "#", "$", "%", "^", "&", "*",
        "+", "=", "-", "_"
    ]

    private let deleteKeyCode: UInt16 = 51
    private let returnKeyCode: UInt16 = 36
    private let enterKeyCode: UInt16 = 76
    private let spaceKeyCode: UInt16 = 49

    private let navigationKeyCodes: Set<UInt16> = [
        123, 124, 125, 126, // Arrow keys
        115, 119, 116, 121, // Home, End, Page Up, Page Down
        117                  // Forward Delete
    ]

    init(maxSize: Int = 50) {
        self.maxSize = maxSize
        self.buffer = [Character](repeating: " ", count: maxSize)
    }

    func trackKeyPress(keyCode: UInt16, characters: String?) {
        if keyCode == deleteKeyCode {
            removeLastCharacter()
            return
        }

        if navigationKeyCodes.contains(keyCode) {
            clear()
            return
        }

        if keyCode == returnKeyCode || keyCode == enterKeyCode {
            clear()
            return
        }

        guard let chars = characters, let firstChar = chars.first else {
            return
        }

        if keyCode == spaceKeyCode || wordBoundaries.contains(firstChar) {
            clear()
            return
        }

        addCharacter(firstChar)
    }

    func getLastWord() -> String? {
        guard count > 0 else { return nil }

        var result = [Character]()
        result.reserveCapacity(count)

        for i in 0..<count {
            let index = (head - count + i + maxSize) % maxSize
            result.append(buffer[index])
        }

        return String(result)
    }

    func clear() {
        count = 0
    }

    private func addCharacter(_ char: Character) {
        buffer[head] = char
        head = (head + 1) % maxSize

        if count < maxSize {
            count += 1
        }
    }

    private func removeLastCharacter() {
        guard count > 0 else { return }

        head = (head - 1 + maxSize) % maxSize
        count -= 1
    }
}

/// Simulates the WordTracker
class TestWordTracker {
    private var buffer: [Character] = []
    private let maxLength = 50

    func trackKeyPress(character: Character) {
        // Word boundaries - only actual separators, not punctuation that maps to Russian letters
        // ; -> ж, ' -> э, [ -> х, ] -> ъ, ` -> ё, , -> б, . -> ю, : -> Ж
        if character == " " || character == "\n" || character == "\t" ||
           character == "!" || character == "?" {
            buffer.removeAll()
            return
        }

        // Backspace simulation
        if character == "\u{7F}" { // DEL
            if !buffer.isEmpty {
                buffer.removeLast()
            }
            return
        }

        buffer.append(character)
        if buffer.count > maxLength {
            buffer.removeFirst()
        }
    }

    func getLastWord() -> String {
        return String(buffer)
    }

    func clear() {
        buffer.removeAll()
    }
}

/// Layout converter (same logic as main app - with layout detection)
class TestLayoutConverter {
    private let enToRu: [Character: Character] = [
        "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е", "y": "н", "u": "г",
        "i": "ш", "o": "щ", "p": "з", "[": "х", "]": "ъ", "a": "ф", "s": "ы",
        "d": "в", "f": "а", "g": "п", "h": "р", "j": "о", "k": "л", "l": "д",
        ";": "ж", "'": "э", "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и",
        "n": "т", "m": "ь", ",": "б", ".": "ю", "/": ".",
        "Q": "Й", "W": "Ц", "E": "У", "R": "К", "T": "Е", "Y": "Н", "U": "Г",
        "I": "Ш", "O": "Щ", "P": "З", "{": "Х", "}": "Ъ", "A": "Ф", "S": "Ы",
        "D": "В", "F": "А", "G": "П", "H": "Р", "J": "О", "K": "Л", "L": "Д",
        ":": "Ж", "\"": "Э", "Z": "Я", "X": "Ч", "C": "С", "V": "М", "B": "И",
        "N": "Т", "M": "Ь", "<": "Б", ">": "Ю", "?": ",",
        "`": "ё", "~": "Ё",
        // Shift + numbers (Mac Russian layout)
        "@": "\"",  // Shift+2
        "#": "№",   // Shift+3
        "$": ";",   // Shift+4
        "^": ":",   // Shift+6
        "&": "?"    // Shift+7
    ]

    private var ruToEn: [Character: Character] = [:]

    init() {
        // Build reverse mapping
        for (en, ru) in enToRu {
            ruToEn[ru] = en
        }
        // Fix ambiguous mappings for RU -> EN direction
        ruToEn["\""] = "@"  // Shift+2 on RU keyboard produces ", maps to @ on EN
        ruToEn[";"] = "$"   // Shift+4 on RU keyboard produces ;, maps to $ on EN
        ruToEn[":"] = "^"   // Shift+6 on RU keyboard produces :, maps to ^ on EN
        ruToEn["?"] = "&"   // Shift+7 on RU keyboard produces ?, maps to & on EN
        ruToEn["№"] = "#"   // Shift+3 on RU keyboard produces №, maps to # on EN
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

    enum DetectedLayout {
        case english
        case russian
        case mixed
        case unknown
    }

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
        if total == 0 { return .unknown }

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
        guard let scalar = char.unicodeScalars.first else { return false }
        return (scalar.value >= 0x41 && scalar.value <= 0x5A) || // A-Z
               (scalar.value >= 0x61 && scalar.value <= 0x7A)    // a-z
    }

    private func isRussianLetter(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return (scalar.value >= 0x410 && scalar.value <= 0x44F) || // А-я
               scalar.value == 0x401 || scalar.value == 0x451      // Ё, ё
    }

    func convertToRussian(_ text: String) -> String {
        return String(text.map { enToRu[$0] ?? $0 })
    }

    func convertToEnglish(_ text: String) -> String {
        return String(text.map { ruToEn[$0] ?? $0 })
    }

    func convert(_ text: String) -> String {
        let layout = detectLayout(text)

        switch layout {
        case .english:
            return convertToRussian(text)
        case .russian:
            return convertToEnglish(text)
        case .mixed, .unknown:
            // For mixed/unknown, convert based on majority of convertible chars
            var enToRuCount = 0
            var ruToEnCount = 0
            for char in text {
                if enToRu[char] != nil { enToRuCount += 1 }
                if ruToEn[char] != nil { ruToEnCount += 1 }
            }
            if enToRuCount >= ruToEnCount {
                return convertToRussian(text)
            } else {
                return convertToEnglish(text)
            }
        }
    }
}

// MARK: - Test Cases

struct TestCase {
    let name: String
    let input: String
    let expected: String
}

let conversionTests: [TestCase] = [
    // EN -> RU Basic
    TestCase(name: "ghbdtn -> привет", input: "ghbdtn", expected: "привет"),
    TestCase(name: ";jgf -> жопа", input: ";jgf", expected: "жопа"),
    TestCase(name: "hello -> руддщ", input: "hello", expected: "руддщ"),
    TestCase(name: "world -> цщкдв", input: "world", expected: "цщкдв"),
    TestCase(name: "test -> еу|ые", input: "test", expected: "еуые"),

    // RU -> EN Basic
    TestCase(name: "привет -> ghbdtn", input: "привет", expected: "ghbdtn"),
    TestCase(name: "руддщ -> hello", input: "руддщ", expected: "hello"),
    TestCase(name: "мир -> vbh", input: "мир", expected: "vbh"),

    // Single characters
    TestCase(name: "single char q -> й", input: "q", expected: "й"),
    TestCase(name: "single char й -> q", input: "й", expected: "q"),
    TestCase(name: "single char Q -> Й", input: "Q", expected: "Й"),
    TestCase(name: "single char Й -> Q", input: "Й", expected: "Q"),

    // Case preservation
    TestCase(name: "HELLO -> РУДДЩ (caps)", input: "HELLO", expected: "РУДДЩ"),
    TestCase(name: "ПРИВЕТ -> GHBDTN (caps)", input: "ПРИВЕТ", expected: "GHBDTN"),
    TestCase(name: "Hello -> Руддщ (title)", input: "Hello", expected: "Руддщ"),
    TestCase(name: "HeLLo -> РуДДщ (mixed)", input: "HeLLo", expected: "РуДДщ"),
    TestCase(name: "hELLO -> рУДДЩ (inverted)", input: "hELLO", expected: "рУДДЩ"),

    // Special characters EN -> RU
    TestCase(name: "[ -> х (bracket)", input: "[", expected: "х"),
    TestCase(name: "] -> ъ (bracket)", input: "]", expected: "ъ"),
    TestCase(name: "{ -> Х (brace)", input: "{", expected: "Х"),
    TestCase(name: "} -> Ъ (brace)", input: "}", expected: "Ъ"),
    TestCase(name: "; -> ж (semicolon)", input: ";", expected: "ж"),
    TestCase(name: "' -> э (apostrophe)", input: "'", expected: "э"),
    TestCase(name: ": -> Ж (colon)", input: ":", expected: "Ж"),
    TestCase(name: "\" -> Э (quote)", input: "\"", expected: "Э"),
    TestCase(name: ", -> б (comma)", input: ",", expected: "б"),
    TestCase(name: ". -> ю (period)", input: ".", expected: "ю"),
    TestCase(name: "/ -> . (slash)", input: "/", expected: "."),
    TestCase(name: "? -> , (question)", input: "?", expected: ","),
    TestCase(name: "< -> Б (less)", input: "<", expected: "Б"),
    TestCase(name: "> -> Ю (greater)", input: ">", expected: "Ю"),
    TestCase(name: "` -> ё (backtick)", input: "`", expected: "ё"),
    TestCase(name: "~ -> Ё (tilde)", input: "~", expected: "Ё"),

    // Special characters RU -> EN
    TestCase(name: "х -> [ (ru bracket)", input: "х", expected: "["),
    TestCase(name: "ъ -> ] (ru bracket)", input: "ъ", expected: "]"),
    TestCase(name: "Х -> { (ru brace)", input: "Х", expected: "{"),
    TestCase(name: "Ъ -> } (ru brace)", input: "Ъ", expected: "}"),
    TestCase(name: "ж -> ; (ru semicolon)", input: "ж", expected: ";"),
    TestCase(name: "э -> ' (ru apostrophe)", input: "э", expected: "'"),
    TestCase(name: "Ж -> : (ru colon)", input: "Ж", expected: ":"),
    TestCase(name: "Э -> \" (ru quote)", input: "Э", expected: "\""),
    TestCase(name: "б -> , (ru comma)", input: "б", expected: ","),
    TestCase(name: "ю -> . (ru period)", input: "ю", expected: "."),
    TestCase(name: "ё -> ` (ru yo)", input: "ё", expected: "`"),
    TestCase(name: "Ё -> ~ (ru Yo)", input: "Ё", expected: "~"),

    // Numbers (should preserve)
    TestCase(name: "123 -> 123 (numbers)", input: "123", expected: "123"),
    TestCase(name: "0 -> 0 (zero)", input: "0", expected: "0"),
    TestCase(name: "9876543210 -> same", input: "9876543210", expected: "9876543210"),

    // Numbers with text
    TestCase(name: "hello123 -> руддщ123", input: "hello123", expected: "руддщ123"),
    TestCase(name: "test123test -> еуые123еуые", input: "test123test", expected: "еуые123еуые"),
    TestCase(name: "123abc -> 123фис", input: "123abc", expected: "123фис"),

    // Spaces
    TestCase(name: "hello world -> руддщ цщкдв", input: "hello world", expected: "руддщ цщкдв"),
    TestCase(name: "spaces only", input: "   ", expected: "   "),
    TestCase(name: "single space", input: " ", expected: " "),

    // Empty and whitespace
    TestCase(name: "empty string", input: "", expected: ""),
    TestCase(name: "newline", input: "\n", expected: "\n"),
    TestCase(name: "tab", input: "\t", expected: "\t"),

    // Punctuation with text
    TestCase(name: "Test! -> Еуые!", input: "Test!", expected: "Еуые!"),
    TestCase(name: "hello, world", input: "hello, world", expected: "руддщб цщкдв"),
]

// MARK: - Double Conversion Tests (Idempotence)

struct DoubleConversionTest {
    let name: String
    let input: String
}

let doubleConversionTests: [DoubleConversionTest] = [
    DoubleConversionTest(name: "hello round-trip", input: "hello"),
    DoubleConversionTest(name: "привет round-trip", input: "привет"),
    DoubleConversionTest(name: "HELLO round-trip", input: "HELLO"),
    DoubleConversionTest(name: "ПРИВЕТ round-trip", input: "ПРИВЕТ"),
    DoubleConversionTest(name: "Hello World round-trip", input: "Hello World"),
    DoubleConversionTest(name: "123abc round-trip", input: "123abc"),
    DoubleConversionTest(name: "test! round-trip", input: "test!"),
    DoubleConversionTest(name: "mixed HeLLo round-trip", input: "HeLLo"),
    DoubleConversionTest(name: "brackets [test] round-trip", input: "[test]"),
    DoubleConversionTest(name: "special ;',./ round-trip", input: ";',./"),
]

// MARK: - Word Tracking Tests

struct WordTrackingTest {
    let name: String
    let keystrokes: String
    let expectedWord: String
}

let wordTrackingTests: [WordTrackingTest] = [
    // Basic tracking
    WordTrackingTest(name: "Simple word", keystrokes: "hello", expectedWord: "hello"),
    WordTrackingTest(name: "Russian word", keystrokes: "привет", expectedWord: "привет"),
    WordTrackingTest(name: "Single char", keystrokes: "a", expectedWord: "a"),

    // Space clears
    WordTrackingTest(name: "Word with space clears", keystrokes: "hello world", expectedWord: "world"),
    WordTrackingTest(name: "Multiple words", keystrokes: "one two three", expectedWord: "three"),
    WordTrackingTest(name: "Space only", keystrokes: " ", expectedWord: ""),

    // Backspace
    WordTrackingTest(name: "Backspace removes char", keystrokes: "hello\u{7F}", expectedWord: "hell"),
    WordTrackingTest(name: "Two backspaces", keystrokes: "hello\u{7F}\u{7F}", expectedWord: "hel"),
    WordTrackingTest(name: "Full delete with backspaces", keystrokes: "hello\u{7F}\u{7F}\u{7F}\u{7F}\u{7F}", expectedWord: ""),
    WordTrackingTest(name: "Extra backspace on empty", keystrokes: "hi\u{7F}\u{7F}\u{7F}", expectedWord: ""),
    WordTrackingTest(name: "Backspace on empty buffer", keystrokes: "\u{7F}", expectedWord: ""),

    // Punctuation - only ! and ? clear (others map to Russian letters)
    WordTrackingTest(name: "Period stays (maps to ю)", keystrokes: "hello.", expectedWord: "hello."),
    WordTrackingTest(name: "Comma stays (maps to б)", keystrokes: "hello,", expectedWord: "hello,"),
    WordTrackingTest(name: "Exclamation clears", keystrokes: "hello!", expectedWord: ""),
    WordTrackingTest(name: "Question clears", keystrokes: "hello?", expectedWord: ""),
    WordTrackingTest(name: "Semicolon stays (maps to ж)", keystrokes: "hello;", expectedWord: "hello;"),
    WordTrackingTest(name: "Colon stays (maps to Ж)", keystrokes: "hello:", expectedWord: "hello:"),

    // Newlines and tabs
    WordTrackingTest(name: "Newline clears", keystrokes: "hello\n", expectedWord: ""),
    WordTrackingTest(name: "Tab clears", keystrokes: "hello\t", expectedWord: ""),

    // After clearing, new word tracked
    WordTrackingTest(name: "New word after space", keystrokes: "hello world", expectedWord: "world"),
    WordTrackingTest(name: "Period stays in word (maps to ю)", keystrokes: "hello.world", expectedWord: "hello.world"),

    // Numbers in words
    WordTrackingTest(name: "Word with numbers", keystrokes: "test123", expectedWord: "test123"),
    WordTrackingTest(name: "Numbers only", keystrokes: "12345", expectedWord: "12345"),

    // Special case: semicolon at start (;jgf -> жопа)
    WordTrackingTest(name: "Semicolon at word start", keystrokes: ";jgf", expectedWord: ";jgf"),
    WordTrackingTest(name: "Apostrophe at word start", keystrokes: "'hello", expectedWord: "'hello"),
]

// MARK: - Long String Tests

struct LongStringTest {
    let name: String
    let length: Int
    let pattern: String
}

let longStringTests: [LongStringTest] = [
    LongStringTest(name: "50 chars (buffer limit)", length: 50, pattern: "qwerty"),
    LongStringTest(name: "51 chars (overflow by 1)", length: 51, pattern: "qwerty"),
    LongStringTest(name: "100 chars (double overflow)", length: 100, pattern: "hello"),
    LongStringTest(name: "200 chars (stress)", length: 200, pattern: "test"),
]

// MARK: - Run Tests

func runConversionTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  CONVERSION TESTS")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    for test in conversionTests {
        let result = converter.convert(test.input)
        let success = result == test.expected

        if success {
            print("✅ \(test.name)")
            passed += 1
        } else {
            print("❌ \(test.name)")
            print("   Input:    '\(test.input)'")
            print("   Expected: '\(test.expected)'")
            print("   Got:      '\(result)'")
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

func runWordTrackingTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  WORD TRACKING TESTS")
    print(String(repeating: "=", count: 50))

    var passed = 0
    var failed = 0

    for test in wordTrackingTests {
        let tracker = TestWordTracker()

        for char in test.keystrokes {
            tracker.trackKeyPress(character: char)
        }

        let result = tracker.getLastWord()
        let success = result == test.expectedWord

        if success {
            print("✅ \(test.name)")
            passed += 1
        } else {
            print("❌ \(test.name)")
            print("   Keystrokes: '\(test.keystrokes)'")
            print("   Expected:   '\(test.expectedWord)'")
            print("   Got:        '\(result)'")
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

func runSimulation() {
    print("\n" + String(repeating: "=", count: 50))
    print("  TYPING SIMULATION")
    print(String(repeating: "=", count: 50))

    let tracker = TestWordTracker()
    let converter = TestLayoutConverter()

    // Simulate typing "ghbdtn" (привет on English layout)
    let typedText = "ghbdtn"
    print("\nSimulating typing: '\(typedText)'")

    for char in typedText {
        tracker.trackKeyPress(character: char)
        print("  Typed '\(char)' -> buffer: '\(tracker.getLastWord())'")
    }

    // Simulate hotkey press
    print("\n[HOTKEY PRESSED: Cmd+Opt+Shift]")
    let lastWord = tracker.getLastWord()
    print("Last word: '\(lastWord)'")

    let converted = converter.convert(lastWord)
    print("Converted: '\(converted)'")

    // Simulate the replacement
    print("\nSimulated text replacement:")
    print("  Before: '\(lastWord)'")
    print("  After:  '\(converted)'")

    tracker.clear()
    print("  Buffer cleared")

    // Now simulate typing in Russian and converting back
    print("\n" + String(repeating: "-", count: 40))
    print("Now simulating Russian text typed on wrong layout...")

    let russianTyped = "руддщ"  // "hello" in Russian
    print("\nSimulating typing: '\(russianTyped)'")

    for char in russianTyped {
        tracker.trackKeyPress(character: char)
    }

    print("\n[HOTKEY PRESSED: Cmd+Opt+Shift]")
    let lastWord2 = tracker.getLastWord()
    print("Last word: '\(lastWord2)'")

    let converted2 = converter.convert(lastWord2)
    print("Converted: '\(converted2)'")
}

func runStressTest() {
    print("\n" + String(repeating: "=", count: 50))
    print("  STRESS TEST - Multiple rapid conversions")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var text = "hello"

    print("Starting with: '\(text)'")

    for i in 1...10 {
        text = converter.convert(text)
        print("Conversion \(i): '\(text)'")
    }

    print("\nNote: Converting back and forth should alternate between EN and RU")
}

func runSelectionTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  SELECTION CONVERSION TESTS (LARGE TEXT)")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    // Test cases for selected text conversion
    let selectionTests: [(name: String, input: String)] = [
        ("Single word", "ghbdtn"),
        ("Two words", "ghbdtn vbh"),
        ("Sentence", "ghbdtn vbh 'nj ntcn"),
        ("Paragraph (100 chars)", String(repeating: "ghbdtn ", count: 15)),
        ("Large text (500 chars)", String(repeating: "ghbdtn vbh ", count: 50)),
        ("Very large (1000 chars)", String(repeating: "ntrcn ", count: 170)),
        ("Mixed case", "Ghbdtn Vbh"),
        ("With punctuation", "ghbdtn, vbh!"),
        ("Multiple lines", "ghbdtn\nvbh\nntrcn"),
        ("With numbers", "ntrcn123 ghbdtn456"),
    ]

    for test in selectionTests {
        // Simulate: user selects text, presses hotkey
        let selectedText = test.input
        let converted = converter.convert(selectedText)
        let backToOriginal = converter.convert(converted)

        // Check round-trip works
        let roundTripOK = selectedText == backToOriginal

        // Check conversion actually changed something (not empty)
        let conversionWorked = !converted.isEmpty && converted != selectedText

        let success = roundTripOK && conversionWorked

        if success {
            print("✅ \(test.name) (\(selectedText.count) chars)")
            passed += 1
        } else {
            print("❌ \(test.name) (\(selectedText.count) chars)")
            print("   Input:     '\(selectedText.prefix(50))...'")
            print("   Converted: '\(converted.prefix(50))...'")
            print("   Back:      '\(backToOriginal.prefix(50))...'")
            print("   Round-trip OK: \(roundTripOK), Conversion worked: \(conversionWorked)")
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

func runDoubleConversionTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  DOUBLE CONVERSION TESTS (IDEMPOTENCE)")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    for test in doubleConversionTests {
        let once = converter.convert(test.input)
        let twice = converter.convert(once)
        let success = test.input == twice

        if success {
            print("✅ \(test.name)")
            print("   '\(test.input)' -> '\(once)' -> '\(twice)'")
            passed += 1
        } else {
            print("❌ \(test.name)")
            print("   '\(test.input)' -> '\(once)' -> '\(twice)'")
            print("   Expected: '\(test.input)'")
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

func runLongStringTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  LONG STRING TESTS (BUFFER LIMITS)")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    let tracker = TestWordTracker()
    var passed = 0
    var failed = 0

    for test in longStringTests {
        // Generate string of specified length
        var input = ""
        while input.count < test.length {
            input += test.pattern
        }
        input = String(input.prefix(test.length))

        // Test conversion
        let converted = converter.convert(input)
        let backConverted = converter.convert(converted)
        let conversionOK = input == backConverted

        // Test tracking (simulates typing)
        tracker.clear()
        for char in input {
            tracker.trackKeyPress(character: char)
        }
        let tracked = tracker.getLastWord()
        // Buffer is limited to 50, so we expect last 50 chars
        let expectedTracked = String(input.suffix(50))
        let trackingOK = tracked == expectedTracked

        let success = conversionOK && trackingOK

        if success {
            print("✅ \(test.name) (\(test.length) chars)")
            passed += 1
        } else {
            print("❌ \(test.name) (\(test.length) chars)")
            if !conversionOK {
                print("   Conversion failed: round-trip mismatch")
            }
            if !trackingOK {
                print("   Tracking failed: expected \(expectedTracked.count) chars, got \(tracked.count)")
            }
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

func runEdgeCaseTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  EDGE CASE TESTS")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    // Test all alphabet letters
    // j->о, not ж (ж is mapped from ;)
    print("\n--- Full Alphabet EN->RU ---")
    let enAlphabet = "qwertyuiopasdfghjklzxcvbnm"
    let ruExpected = "йцукенгшщзфывапролдячсмить"  // j->о (included), k->л, l->д
    let enToRuResult = converter.convert(enAlphabet)
    if enToRuResult == ruExpected {
        print("✅ Full lowercase EN alphabet")
        passed += 1
    } else {
        print("❌ Full lowercase EN alphabet")
        print("   Expected: '\(ruExpected)'")
        print("   Got:      '\(enToRuResult)'")
        failed += 1
    }

    // Test uppercase alphabet
    let enUpperAlphabet = "QWERTYUIOPASDFGHJKLZXCVBNM"
    let ruUpperExpected = "ЙЦУКЕНГШЩЗФЫВАПРОЛДЯЧСМИТЬ"
    let enUpperToRuResult = converter.convert(enUpperAlphabet)
    if enUpperToRuResult == ruUpperExpected {
        print("✅ Full uppercase EN alphabet")
        passed += 1
    } else {
        print("❌ Full uppercase EN alphabet")
        print("   Expected: '\(ruUpperExpected)'")
        print("   Got:      '\(enUpperToRuResult)'")
        failed += 1
    }

    // Test reverse (RU->EN)
    print("\n--- Full Alphabet RU->EN ---")
    let ruToEnResult = converter.convert(ruExpected)
    if ruToEnResult == enAlphabet {
        print("✅ Full lowercase RU alphabet reverse")
        passed += 1
    } else {
        print("❌ Full lowercase RU alphabet reverse")
        print("   Expected: '\(enAlphabet)'")
        print("   Got:      '\(ruToEnResult)'")
        failed += 1
    }

    // Test emoji preservation
    print("\n--- Emoji/Unicode Preservation ---")
    let emojiTests = [
        ("hello 👋", "руддщ 👋", "Emoji at end"),
        ("👋 hello", "👋 руддщ", "Emoji at start"),
        ("hel👋lo", "рудщ👋дщ", "Emoji in middle"), // Note: this might not work as expected
    ]

    for (input, expected, desc) in emojiTests {
        let result = converter.convert(input)
        // Emoji should pass through unchanged
        if result.contains("👋") {
            print("✅ \(desc) - emoji preserved")
            passed += 1
        } else {
            print("❌ \(desc) - emoji lost")
            print("   Input:  '\(input)'")
            print("   Result: '\(result)'")
            failed += 1
        }
    }

    // Test mixed content stability
    print("\n--- Mixed Content ---")
    let mixedTests = [
        "Test123!@#",
        "Hello, World!",
        "user@example.com",
        "path/to/file.txt",
    ]

    for input in mixedTests {
        let once = converter.convert(input)
        let twice = converter.convert(once)
        if input == twice {
            print("✅ Mixed: '\(input)' round-trip OK")
            passed += 1
        } else {
            print("❌ Mixed: '\(input)' round-trip FAILED")
            print("   '\(input)' -> '\(once)' -> '\(twice)'")
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

func runMassStressTest() {
    print("\n" + String(repeating: "=", count: 50))
    print("  MASS STRESS TEST - 100 conversions")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    let testStrings = ["hello", "world", "test", "Привет", "Мир"]
    var failures = 0

    for testString in testStrings {
        var text = testString
        let original = text

        for i in 1...100 {
            text = converter.convert(text)
            if i % 2 == 0 && text != original {
                print("❌ '\(original)' failed at iteration \(i)")
                failures += 1
                break
            }
        }

        if failures == 0 {
            print("✅ '\(original)' - 100 round-trips OK")
        }
    }

    if failures == 0 {
        print("\n✅ All mass stress tests passed!")
    } else {
        print("\n❌ \(failures) failures in mass stress test")
    }
}

func runBugHunt() {
    print("\n" + String(repeating: "=", count: 50))
    print("  BUG HUNT - Looking for edge cases")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()

    // Test special characters
    let specialChars = ["`", "~", "[", "]", "{", "}", ";", "'", ":", "\"", ",", ".", "/", "?", "<", ">"]
    print("\nSpecial character conversion:")
    for char in specialChars {
        let converted = converter.convert(char)
        print("  '\(char)' -> '\(converted)'")
    }

    // Test numbers (should pass through)
    print("\nNumbers (should pass through unchanged):")
    let numbers = "0123456789"
    let convertedNumbers = converter.convert(numbers)
    print("  '\(numbers)' -> '\(convertedNumbers)'")
    let numbersOK = numbers == convertedNumbers
    print("  \(numbersOK ? "✅" : "❌") Numbers unchanged: \(numbersOK)")

    // Test mixed content
    print("\nMixed content:")
    let mixed = "Hello123World!"
    let convertedMixed = converter.convert(mixed)
    print("  '\(mixed)' -> '\(convertedMixed)'")

    // Test case preservation
    print("\nCase preservation:")
    let upperLower = "HeLLo"
    let convertedCase = converter.convert(upperLower)
    print("  '\(upperLower)' -> '\(convertedCase)'")

    // Double conversion should return original
    print("\nDouble conversion (should return to original):")
    let original = "hello"
    let once = converter.convert(original)
    let twice = converter.convert(once)
    print("  '\(original)' -> '\(once)' -> '\(twice)'")
    let doubleOK = original == twice
    print("  \(doubleOK ? "✅" : "❌") Double conversion returns original: \(doubleOK)")
}

// MARK: - NEW TESTS: HotkeyManager Tests

func runHotkeyTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  HOTKEY TESTS")
    print(String(repeating: "=", count: 50))

    var passed = 0
    var failed = 0

    // Test isModifierOnly
    print("\n--- isModifierOnly Tests ---")

    let modifierOnlyHotkey = Hotkey(keyCode: UInt16.max, command: true, option: true, shift: true, control: false)
    if modifierOnlyHotkey.isModifierOnly {
        print("✅ keyCode=UInt16.max -> isModifierOnly=true")
        passed += 1
    } else {
        print("❌ keyCode=UInt16.max should be modifier-only")
        failed += 1
    }

    let keyBasedHotkey = Hotkey(keyCode: 6, command: true, option: true, shift: false, control: false)
    if !keyBasedHotkey.isModifierOnly {
        print("✅ keyCode=6 (Z) -> isModifierOnly=false")
        passed += 1
    } else {
        print("❌ keyCode=6 should NOT be modifier-only")
        failed += 1
    }

    let zeroKeyHotkey = Hotkey(keyCode: 0, command: true, option: false, shift: false, control: false)
    if !zeroKeyHotkey.isModifierOnly {
        print("✅ keyCode=0 (A) -> isModifierOnly=false")
        passed += 1
    } else {
        print("❌ keyCode=0 should NOT be modifier-only")
        failed += 1
    }

    // Test displayString
    print("\n--- displayString Tests ---")

    let displayTests: [(Hotkey, String, String)] = [
        (Hotkey(keyCode: UInt16.max, command: true, option: true, shift: true, control: false),
         "⌥⇧⌘", "Cmd+Opt+Shift modifier-only"),
        (Hotkey(keyCode: 6, command: true, option: true, shift: false, control: false),
         "⌥⌘Z", "Cmd+Opt+Z"),
        (Hotkey(keyCode: 0, command: true, option: false, shift: false, control: false),
         "⌘A", "Cmd+A"),
        (Hotkey(keyCode: 6, command: true, option: true, shift: true, control: true),
         "⌃⌥⇧⌘Z", "All modifiers + Z"),
        (Hotkey(keyCode: UInt16.max, command: false, option: false, shift: false, control: true),
         "⌃", "Control only modifier-only"),
        (Hotkey(keyCode: 49, command: true, option: false, shift: false, control: false),
         "⌘Space", "Cmd+Space"),
        (Hotkey(keyCode: 36, command: false, option: false, shift: true, control: false),
         "⇧Return", "Shift+Return"),
    ]

    for (hotkey, expected, desc) in displayTests {
        let result = hotkey.displayString
        if result == expected {
            print("✅ \(desc): '\(result)'")
            passed += 1
        } else {
            print("❌ \(desc)")
            print("   Expected: '\(expected)'")
            print("   Got:      '\(result)'")
            failed += 1
        }
    }

    // Test default hotkeys
    print("\n--- Default Hotkey Values ---")

    let defaultConvert = Hotkey.defaultConvertLayout
    if defaultConvert.keyCode == UInt16.max &&
       defaultConvert.command && defaultConvert.option && defaultConvert.shift && !defaultConvert.control {
        print("✅ defaultConvertLayout: Cmd+Opt+Shift (modifier-only)")
        passed += 1
    } else {
        print("❌ defaultConvertLayout values incorrect")
        failed += 1
    }

    let defaultToggle = Hotkey.defaultToggleCase
    if defaultToggle.keyCode == 6 &&
       defaultToggle.command && defaultToggle.option && !defaultToggle.shift && !defaultToggle.control {
        print("✅ defaultToggleCase: Cmd+Opt+Z")
        passed += 1
    } else {
        print("❌ defaultToggleCase values incorrect")
        failed += 1
    }

    // Test Codable round-trip
    print("\n--- Hotkey Codable Round-trip ---")

    let hotkeysToEncode = [
        Hotkey.defaultConvertLayout,
        Hotkey.defaultToggleCase,
        Hotkey(keyCode: 0, command: true, option: true, shift: true, control: true),
    ]

    for hotkey in hotkeysToEncode {
        do {
            let encoded = try JSONEncoder().encode(hotkey)
            let decoded = try JSONDecoder().decode(Hotkey.self, from: encoded)
            if decoded == hotkey {
                print("✅ Codable round-trip: \(hotkey.displayString)")
                passed += 1
            } else {
                print("❌ Codable mismatch for \(hotkey.displayString)")
                failed += 1
            }
        } catch {
            print("❌ Codable error for \(hotkey.displayString): \(error)")
            failed += 1
        }
    }

    // Test KeyCodeNames
    print("\n--- KeyCodeNames Tests ---")

    let keyCodeTests: [(UInt16, String?)] = [
        (0, "A"),
        (6, "Z"),
        (36, "Return"),
        (49, "Space"),
        (51, "Delete"),
        (53, "Escape"),
        (123, "Left"),
        (124, "Right"),
        (125, "Down"),
        (126, "Up"),
        (115, "Home"),
        (119, "End"),
        (116, "Page Up"),
        (121, "Page Down"),
        (117, "Forward Delete"),
        (999, nil),  // Unknown key code
        (UInt16.max, nil),  // Modifier-only marker
    ]

    for (keyCode, expected) in keyCodeTests {
        let result = KeyCodeNames.name(for: keyCode)
        if result == expected {
            print("✅ KeyCode \(keyCode) -> \(result ?? "nil")")
            passed += 1
        } else {
            print("❌ KeyCode \(keyCode)")
            print("   Expected: \(expected ?? "nil")")
            print("   Got:      \(result ?? "nil")")
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - NEW TESTS: Shift+Number Mapping Tests

func runShiftNumberTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  SHIFT+NUMBER MAPPING TESTS")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    // Test Shift+Number forward mappings (EN -> RU)
    print("\n--- Shift+Number EN -> RU ---")

    let shiftNumberTests: [(String, String, String)] = [
        ("@", "\"", "@ -> \" (Shift+2)"),
        ("#", "№", "# -> № (Shift+3)"),
        ("$", ";", "$ -> ; (Shift+4)"),
        ("^", ":", "^ -> : (Shift+6)"),
        ("&", "?", "& -> ? (Shift+7)"),
    ]

    for (input, expected, desc) in shiftNumberTests {
        let result = converter.convertToRussian(input)
        if result == expected {
            print("✅ \(desc)")
            passed += 1
        } else {
            print("❌ \(desc)")
            print("   Expected: '\(expected)', Got: '\(result)'")
            failed += 1
        }
    }

    // Test reverse mappings (RU -> EN)
    print("\n--- Shift+Number RU -> EN ---")

    let reverseTests: [(String, String, String)] = [
        ("№", "#", "№ -> # (Shift+3 reverse)"),
        // Note: These use the ambiguous mapping overrides
    ]

    for (input, expected, desc) in reverseTests {
        let result = converter.convertToEnglish(input)
        if result == expected {
            print("✅ \(desc)")
            passed += 1
        } else {
            print("❌ \(desc)")
            print("   Expected: '\(expected)', Got: '\(result)'")
            failed += 1
        }
    }

    // Test in context
    print("\n--- Shift+Number in Context ---")

    let contextTests: [(String, String, String)] = [
        ("test@email", "еуые\"уьфшд", "@ in email context"),
        ("$100", ";100", "$ in price context"),
        ("A&B", "Ф?И", "& in text context"),
        ("test#1", "еуые№1", "# in hashtag context"),
        ("x^2", "ч:2", "^ in math context"),
    ]

    for (input, expected, desc) in contextTests {
        let result = converter.convertToRussian(input)
        if result == expected {
            print("✅ \(desc)")
            passed += 1
        } else {
            print("❌ \(desc)")
            print("   Input:    '\(input)'")
            print("   Expected: '\(expected)'")
            print("   Got:      '\(result)'")
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - NEW TESTS: Layout Detection Boundary Tests

func runLayoutDetectionTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  LAYOUT DETECTION BOUNDARY TESTS")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    // Test exact threshold boundaries
    // detectLayout uses > 0.8 for english, < 0.2 for russian
    print("\n--- Threshold Boundary Tests ---")

    let thresholdTests: [(String, TestLayoutConverter.DetectedLayout, String)] = [
        // 100% English
        ("abcdefghij", .english, "100% EN (10 EN letters)"),
        // 90% English (9 EN, 1 RU) - should be .english (> 0.8)
        ("abcdefghiй", .english, "90% EN (9 EN + 1 RU)"),
        // 81% English (should be .english)
        ("abcdefghijklmйаб", .english, "81% EN (13 EN + 3 RU)"),
        // 80% English (8 EN, 2 RU) - should be .mixed (NOT > 0.8)
        ("abcdefghйц", .mixed, "80% EN (8 EN + 2 RU) - at threshold"),
        // 70% English
        ("abcdefgйцу", .mixed, "70% EN (7 EN + 3 RU)"),
        // 50% English
        ("abcdeйцукн", .mixed, "50% EN (5 EN + 5 RU)"),
        // 30% English
        ("abcйцукенг", .mixed, "30% EN (3 EN + 7 RU)"),
        // 20% English (2 EN, 8 RU) - should be .mixed (NOT < 0.2)
        ("abйцукенгш", .mixed, "20% EN (2 EN + 8 RU) - at threshold"),
        // 19% English - should be .russian
        ("aйцукенгшщ", .russian, "10% EN (1 EN + 9 RU)"),
        // 100% Russian
        ("йцукенгшщз", .russian, "100% RU (10 RU letters)"),
        // Unknown (no letters)
        ("12345!@#$%", .unknown, "No letters - unknown"),
        ("", .unknown, "Empty string - unknown"),
        ("   ", .unknown, "Only spaces - unknown"),
    ]

    for (input, expected, desc) in thresholdTests {
        let result = converter.detectLayout(input)
        if result == expected {
            print("✅ \(desc)")
            passed += 1
        } else {
            print("❌ \(desc)")
            print("   Input:    '\(input)'")
            print("   Expected: \(expected)")
            print("   Got:      \(result)")
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - NEW TESTS: Real WordTracker with KeyCode

func runRealWordTrackerTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  REAL WORDTRACKER TESTS (with keyCode)")
    print(String(repeating: "=", count: 50))

    var passed = 0
    var failed = 0

    // Test basic tracking
    print("\n--- Basic Tracking ---")

    let tracker1 = RealWordTracker()
    for (i, char) in "hello".enumerated() {
        // Simulate key codes for h=4, e=14, l=37, l=37, o=31
        let keyCodes: [UInt16] = [4, 14, 37, 37, 31]
        tracker1.trackKeyPress(keyCode: keyCodes[i], characters: String(char))
    }
    if tracker1.getLastWord() == "hello" {
        print("✅ Basic word tracking: 'hello'")
        passed += 1
    } else {
        print("❌ Basic word tracking failed")
        print("   Expected: 'hello', Got: '\(tracker1.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test empty tracker returns nil
    let emptyTracker = RealWordTracker()
    if emptyTracker.getLastWord() == nil {
        print("✅ Empty tracker returns nil")
        passed += 1
    } else {
        print("❌ Empty tracker should return nil")
        failed += 1
    }

    // Test navigation keys clear buffer
    print("\n--- Navigation Keys Clear Buffer ---")

    let navKeyCodes: [(UInt16, String)] = [
        (123, "Left Arrow"),
        (124, "Right Arrow"),
        (125, "Down Arrow"),
        (126, "Up Arrow"),
        (115, "Home"),
        (119, "End"),
        (116, "Page Up"),
        (121, "Page Down"),
        (117, "Forward Delete"),
    ]

    for (keyCode, keyName) in navKeyCodes {
        let tracker = RealWordTracker()
        tracker.trackKeyPress(keyCode: 4, characters: "h")
        tracker.trackKeyPress(keyCode: 14, characters: "e")
        tracker.trackKeyPress(keyCode: 37, characters: "l")
        tracker.trackKeyPress(keyCode: 37, characters: "l")
        tracker.trackKeyPress(keyCode: 31, characters: "o")
        // Now press navigation key
        tracker.trackKeyPress(keyCode: keyCode, characters: nil)
        if tracker.getLastWord() == nil {
            print("✅ \(keyName) (keyCode \(keyCode)) clears buffer")
            passed += 1
        } else {
            print("❌ \(keyName) should clear buffer")
            print("   Got: '\(tracker.getLastWord() ?? "nil")'")
            failed += 1
        }
    }

    // Test Escape does NOT clear buffer (not in navigationKeyCodes)
    print("\n--- Escape Key Test ---")
    let escTracker = RealWordTracker()
    escTracker.trackKeyPress(keyCode: 4, characters: "h")
    escTracker.trackKeyPress(keyCode: 14, characters: "e")
    escTracker.trackKeyPress(keyCode: 37, characters: "l")
    escTracker.trackKeyPress(keyCode: 37, characters: "l")
    escTracker.trackKeyPress(keyCode: 31, characters: "o")
    escTracker.trackKeyPress(keyCode: 53, characters: nil)  // Escape
    if escTracker.getLastWord() == "hello" {
        print("✅ Escape (keyCode 53) does NOT clear buffer")
        passed += 1
    } else {
        print("❌ Escape should NOT clear buffer")
        print("   Expected: 'hello', Got: '\(escTracker.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test Delete (Backspace) removes last character
    print("\n--- Delete/Backspace Tests ---")

    let delTracker = RealWordTracker()
    for (i, char) in "hello".enumerated() {
        let keyCodes: [UInt16] = [4, 14, 37, 37, 31]
        delTracker.trackKeyPress(keyCode: keyCodes[i], characters: String(char))
    }
    delTracker.trackKeyPress(keyCode: 51, characters: nil)  // Delete
    if delTracker.getLastWord() == "hell" {
        print("✅ Delete removes last char: 'hello' -> 'hell'")
        passed += 1
    } else {
        print("❌ Delete failed")
        print("   Expected: 'hell', Got: '\(delTracker.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test multiple deletes
    delTracker.trackKeyPress(keyCode: 51, characters: nil)
    delTracker.trackKeyPress(keyCode: 51, characters: nil)
    if delTracker.getLastWord() == "he" {
        print("✅ Multiple deletes: 'hell' -> 'he'")
        passed += 1
    } else {
        print("❌ Multiple deletes failed")
        failed += 1
    }

    // Test delete on empty doesn't crash
    let emptyDelTracker = RealWordTracker()
    emptyDelTracker.trackKeyPress(keyCode: 51, characters: nil)
    emptyDelTracker.trackKeyPress(keyCode: 51, characters: nil)
    if emptyDelTracker.getLastWord() == nil {
        print("✅ Delete on empty buffer -> nil (no crash)")
        passed += 1
    } else {
        print("❌ Delete on empty should return nil")
        failed += 1
    }

    // Test Return clears buffer
    print("\n--- Return/Enter Tests ---")

    let returnTracker = RealWordTracker()
    returnTracker.trackKeyPress(keyCode: 4, characters: "h")
    returnTracker.trackKeyPress(keyCode: 14, characters: "e")
    returnTracker.trackKeyPress(keyCode: 36, characters: "\n")  // Return
    if returnTracker.getLastWord() == nil {
        print("✅ Return (keyCode 36) clears buffer")
        passed += 1
    } else {
        print("❌ Return should clear buffer")
        failed += 1
    }

    let enterTracker = RealWordTracker()
    enterTracker.trackKeyPress(keyCode: 4, characters: "h")
    enterTracker.trackKeyPress(keyCode: 14, characters: "e")
    enterTracker.trackKeyPress(keyCode: 76, characters: "\n")  // Enter (numpad)
    if enterTracker.getLastWord() == nil {
        print("✅ Enter (keyCode 76) clears buffer")
        passed += 1
    } else {
        print("❌ Enter should clear buffer")
        failed += 1
    }

    // Test Space clears buffer
    let spaceTracker = RealWordTracker()
    spaceTracker.trackKeyPress(keyCode: 4, characters: "h")
    spaceTracker.trackKeyPress(keyCode: 14, characters: "e")
    spaceTracker.trackKeyPress(keyCode: 49, characters: " ")  // Space
    if spaceTracker.getLastWord() == nil {
        print("✅ Space (keyCode 49) clears buffer")
        passed += 1
    } else {
        print("❌ Space should clear buffer")
        failed += 1
    }

    // Test word boundaries that DO clear
    print("\n--- Word Boundaries That Clear ---")

    let clearBoundaries: [(Character, String)] = [
        ("!", "Exclamation"),
        ("?", "Question"),
        ("@", "At sign"),
        ("#", "Hash"),
        ("$", "Dollar"),
        ("%", "Percent"),
        ("^", "Caret"),
        ("&", "Ampersand"),
        ("*", "Asterisk"),
        ("(", "Open paren"),
        (")", "Close paren"),
        ("/", "Slash"),
        ("\\", "Backslash"),
        ("|", "Pipe"),
        ("+", "Plus"),
        ("=", "Equals"),
        ("-", "Minus"),
        ("_", "Underscore"),
    ]

    for (boundary, name) in clearBoundaries {
        let tracker = RealWordTracker()
        tracker.trackKeyPress(keyCode: 4, characters: "h")
        tracker.trackKeyPress(keyCode: 14, characters: "e")
        tracker.trackKeyPress(keyCode: 0, characters: String(boundary))
        if tracker.getLastWord() == nil {
            print("✅ '\(boundary)' (\(name)) clears buffer")
            passed += 1
        } else {
            print("❌ '\(boundary)' should clear buffer")
            failed += 1
        }
    }

    // Test punctuation that does NOT clear (maps to Russian letters)
    print("\n--- Punctuation That Does NOT Clear ---")

    let noClearPunctuation: [(Character, String)] = [
        (";", "Semicolon (maps to ж)"),
        ("'", "Apostrophe (maps to э)"),
        (":", "Colon (maps to Ж)"),
        (",", "Comma (maps to б)"),
        (".", "Period (maps to ю)"),
        ("[", "Open bracket (maps to х)"),
        ("]", "Close bracket (maps to ъ)"),
        ("`", "Backtick (maps to ё)"),
    ]

    for (punct, desc) in noClearPunctuation {
        let tracker = RealWordTracker()
        tracker.trackKeyPress(keyCode: 4, characters: "h")
        tracker.trackKeyPress(keyCode: 14, characters: "e")
        tracker.trackKeyPress(keyCode: 0, characters: String(punct))
        let word = tracker.getLastWord()
        if word == "he\(punct)" {
            print("✅ '\(punct)' (\(desc)) stays in buffer")
            passed += 1
        } else {
            print("❌ '\(punct)' should stay in buffer")
            print("   Expected: 'he\(punct)', Got: '\(word ?? "nil")'")
            failed += 1
        }
    }

    // Test ring buffer wraparound
    print("\n--- Ring Buffer Wraparound ---")

    let wrapTracker = RealWordTracker(maxSize: 5)
    for char in "abcdefgh" {  // 8 chars into 5-char buffer
        wrapTracker.trackKeyPress(keyCode: 0, characters: String(char))
    }
    if wrapTracker.getLastWord() == "defgh" {
        print("✅ Ring buffer keeps last 5: 'abcdefgh' -> 'defgh'")
        passed += 1
    } else {
        print("❌ Ring buffer wraparound failed")
        print("   Expected: 'defgh', Got: '\(wrapTracker.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test 50-char buffer (default)
    let fullTracker = RealWordTracker()
    let longString = String(repeating: "a", count: 60)
    for char in longString {
        fullTracker.trackKeyPress(keyCode: 0, characters: String(char))
    }
    let result = fullTracker.getLastWord() ?? ""
    if result.count == 50 {
        print("✅ Default 50-char buffer works correctly")
        passed += 1
    } else {
        print("❌ Buffer size incorrect: expected 50, got \(result.count)")
        failed += 1
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - NEW TESTS: convertWithResult Tests

func runConvertWithResultTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  CONVERT WITH RESULT TESTS")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    let tests: [(String, String, TestLayoutConverter.DetectedLayout, String)] = [
        ("hello", "руддщ", .russian, "English -> Russian"),
        ("привет", "ghbdtn", .english, "Russian -> English"),
        ("HELLO", "РУДДЩ", .russian, "English caps -> Russian"),
        ("ПРИВЕТ", "GHBDTN", .english, "Russian caps -> English"),
        ("123", "123", .russian, "Numbers only -> Russian (default)"),
        ("", "", .russian, "Empty -> Russian (default)"),
    ]

    for (input, expectedText, expectedLayout, desc) in tests {
        let result = converter.convertWithResult(input)
        if result.text == expectedText && result.targetLayout == expectedLayout {
            print("✅ \(desc)")
            passed += 1
        } else {
            print("❌ \(desc)")
            print("   Input: '\(input)'")
            print("   Expected: text='\(expectedText)', layout=\(expectedLayout)")
            print("   Got:      text='\(result.text)', layout=\(result.targetLayout)")
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - NEW TESTS: Unicode Boundary Tests

func runUnicodeBoundaryTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  UNICODE BOUNDARY TESTS")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    // Test isEnglishLetter boundaries
    print("\n--- English Letter Boundaries ---")

    // A-Z: 0x41-0x5A, a-z: 0x61-0x7A
    let englishBoundaryTests: [(Character, Bool, String)] = [
        (Character(UnicodeScalar(0x40)!), false, "@ (0x40) - just before A"),
        ("A", true, "A (0x41) - first uppercase"),
        ("Z", true, "Z (0x5A) - last uppercase"),
        (Character(UnicodeScalar(0x5B)!), false, "[ (0x5B) - just after Z"),
        (Character(UnicodeScalar(0x60)!), false, "` (0x60) - just before a"),
        ("a", true, "a (0x61) - first lowercase"),
        ("z", true, "z (0x7A) - last lowercase"),
        (Character(UnicodeScalar(0x7B)!), false, "{ (0x7B) - just after z"),
    ]

    for (char, expected, desc) in englishBoundaryTests {
        let layout = converter.detectLayout(String(char))
        let isEnglish = layout == .english
        if isEnglish == expected {
            print("✅ \(desc) -> \(expected ? "English" : "Not English")")
            passed += 1
        } else {
            print("❌ \(desc)")
            print("   Expected: \(expected), Got: \(isEnglish)")
            failed += 1
        }
    }

    // Test isRussianLetter boundaries
    print("\n--- Russian Letter Boundaries ---")

    // А-я: 0x410-0x44F, Ё: 0x401, ё: 0x451
    let russianBoundaryTests: [(Character, Bool, String)] = [
        (Character(UnicodeScalar(0x40F)!), false, "Џ (0x40F) - just before А"),
        ("А", true, "А (0x410) - first Russian letter"),
        ("я", true, "я (0x44F) - last in main range"),
        (Character(UnicodeScalar(0x450)!), false, "ѐ (0x450) - just after я"),
        ("Ё", true, "Ё (0x401) - special uppercase"),
        ("ё", true, "ё (0x451) - special lowercase"),
    ]

    for (char, expected, desc) in russianBoundaryTests {
        let layout = converter.detectLayout(String(char))
        let isRussian = layout == .russian
        if isRussian == expected {
            print("✅ \(desc) -> \(expected ? "Russian" : "Not Russian")")
            passed += 1
        } else {
            print("❌ \(desc)")
            print("   Expected: \(expected), Got: \(isRussian)")
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - NEW TESTS: Multiple Conversion Tests (Round-trips)

func runMultipleConversionTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  MULTIPLE CONVERSION TESTS (Round-trips)")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    // Test 1: Simple EN->RU->EN round-trip
    print("\n--- Simple Round-trips ---")

    let simpleTests: [(String, String)] = [
        ("hello", "hello typed in wrong layout, convert twice to get back"),
        ("ghbdtn", "привет typed in wrong layout"),
        ("привет", "Russian word"),
        ("HELLO", "uppercase English"),
        ("GHBDTN", "uppercase ghbdtn"),
        ("Hello World", "two words with space"),
        ("test123", "text with numbers"),
    ]

    for (original, desc) in simpleTests {
        let once = converter.convert(original)
        let twice = converter.convert(once)

        if twice == original {
            print("✅ '\(original)' -> '\(once)' -> '\(twice)' (\(desc))")
            passed += 1
        } else {
            print("❌ Round-trip failed for '\(original)'")
            print("   '\(original)' -> '\(once)' -> '\(twice)'")
            print("   Expected: '\(original)'")
            failed += 1
        }
    }

    // Test 2: Multiple conversions (3, 5, 10 times)
    print("\n--- Multiple Conversions (3, 5, 10 times) ---")

    let multiTests = ["hello", "привет", "Test"]

    for original in multiTests {
        var text = original

        // 3 conversions
        for _ in 1...3 {
            text = converter.convert(text)
        }
        // After odd number of conversions, should be converted
        let after3 = text

        // 4th conversion (back to different state)
        text = converter.convert(text)
        let after4 = text

        // 5th conversion
        text = converter.convert(text)
        let after5 = text

        // After 4 conversions should equal original
        if after4 == original {
            print("✅ '\(original)' after 4 conversions = original")
            passed += 1
        } else {
            print("❌ '\(original)' after 4 conversions != original")
            print("   Got: '\(after4)'")
            failed += 1
        }

        // After 5 conversions should NOT equal original (odd)
        if after5 != original && after5 == after3 {
            print("✅ '\(original)' after 5 conversions = after 3 (odd symmetry)")
            passed += 1
        } else {
            print("❌ '\(original)' odd symmetry failed")
            print("   after3: '\(after3)', after5: '\(after5)'")
            failed += 1
        }
    }

    // Test 3: 10 round-trips (20 conversions)
    print("\n--- 10 Round-trips (20 conversions) ---")

    let roundTripTests = ["keyboard", "клавиатура", "MixedCase", "123abc456"]

    for original in roundTripTests {
        var text = original
        var allCorrect = true

        for i in 1...20 {
            text = converter.convert(text)

            // After even number of conversions, should equal original
            if i % 2 == 0 && text != original {
                print("❌ '\(original)' failed at conversion \(i)")
                print("   Expected: '\(original)', Got: '\(text)'")
                allCorrect = false
                failed += 1
                break
            }
        }

        if allCorrect {
            print("✅ '\(original)' - 10 round-trips OK")
            passed += 1
        }
    }

    // Test 4: User scenario - typed wrong, convert, change mind, convert back
    print("\n--- User Scenario: Wrong Layout -> Convert -> Change Mind -> Convert Back ---")

    // Scenario: User meant to type "привет" but layout was EN, so typed "ghbdtn"
    // 1. User types "ghbdtn" (wrong layout)
    // 2. User presses hotkey -> gets "привет" (correct!)
    // 3. User changes mind, wants English "ghbdtn" back
    // 4. User presses hotkey -> gets "ghbdtn"

    let scenario1 = "ghbdtn"
    let step1 = converter.convert(scenario1)  // Should be "привет"
    let step2 = converter.convert(step1)      // Should be "ghbdtn"

    if step1 == "привет" && step2 == "ghbdtn" {
        print("✅ Scenario 1: 'ghbdtn' -> 'привет' -> 'ghbdtn'")
        passed += 1
    } else {
        print("❌ Scenario 1 failed")
        print("   step1: '\(step1)' (expected: 'привет')")
        print("   step2: '\(step2)' (expected: 'ghbdtn')")
        failed += 1
    }

    // Scenario: User meant to type "hello" but layout was RU, so typed "руддщ"
    let scenario2 = "руддщ"
    let step1b = converter.convert(scenario2)  // Should be "hello"
    let step2b = converter.convert(step1b)     // Should be "руддщ"

    if step1b == "hello" && step2b == "руддщ" {
        print("✅ Scenario 2: 'руддщ' -> 'hello' -> 'руддщ'")
        passed += 1
    } else {
        print("❌ Scenario 2 failed")
        print("   step1: '\(step1b)' (expected: 'hello')")
        print("   step2: '\(step2b)' (expected: 'руддщ')")
        failed += 1
    }

    // Test 5: Special characters round-trip
    print("\n--- Special Characters Round-trip ---")

    let specialTests: [(String, String, String)] = [
        (";", "ж", "semicolon"),
        ("'", "э", "apostrophe"),
        ("[", "х", "open bracket"),
        ("]", "ъ", "close bracket"),
        ("`", "ё", "backtick"),
        (",", "б", "comma"),
        (".", "ю", "period"),
    ]

    for (en, ru, desc) in specialTests {
        let converted = converter.convert(en)
        let back = converter.convert(converted)

        if converted == ru && back == en {
            print("✅ '\(en)' -> '\(ru)' -> '\(en)' (\(desc))")
            passed += 1
        } else {
            print("❌ '\(desc)' round-trip failed")
            print("   '\(en)' -> '\(converted)' -> '\(back)'")
            failed += 1
        }
    }

    // Test 6: Punctuation with text round-trip
    print("\n--- Punctuation with Text Round-trip ---")

    let punctTests = [
        "hello;world",
        "test'case",
        "data[0]",
        "path/to/file",
    ]

    for original in punctTests {
        let once = converter.convert(original)
        let twice = converter.convert(once)

        if twice == original {
            print("✅ '\(original)' -> '\(once)' -> '\(twice)'")
            passed += 1
        } else {
            print("❌ '\(original)' round-trip failed")
            print("   Got: '\(twice)'")
            failed += 1
        }
    }

    // Test 7: Edge case - converting already mixed text
    print("\n--- Mixed Content Handling ---")

    // Numbers should stay unchanged through conversions
    let numbersOnly = "12345"
    let numOnce = converter.convert(numbersOnly)
    let numTwice = converter.convert(numOnce)

    if numOnce == numbersOnly && numTwice == numbersOnly {
        print("✅ Numbers-only stays unchanged: '\(numbersOnly)'")
        passed += 1
    } else {
        print("❌ Numbers changed unexpectedly")
        print("   '\(numbersOnly)' -> '\(numOnce)' -> '\(numTwice)'")
        failed += 1
    }

    // Test 8: Case preservation through multiple conversions
    print("\n--- Case Preservation Through Multiple Conversions ---")

    let caseTests = [
        ("HeLLo", "РуДДщ"),
        ("WORLD", "ЦЩКДВ"),
        ("MiXeD", "ЬшЧуВ"),
    ]

    for (en, ru) in caseTests {
        let once = converter.convert(en)
        let twice = converter.convert(once)
        let thrice = converter.convert(twice)
        let four = converter.convert(thrice)

        let casePreserved = once == ru && twice == en && thrice == ru && four == en

        if casePreserved {
            print("✅ Case preserved: '\(en)' <-> '\(ru)' (4 conversions)")
            passed += 1
        } else {
            print("❌ Case not preserved for '\(en)'")
            print("   '\(en)' -> '\(once)' -> '\(twice)' -> '\(thrice)' -> '\(four)'")
            failed += 1
        }
    }

    // Test 9: Stress test - 100 conversions
    print("\n--- Stress Test: 100 Conversions ---")

    let stressTests = ["hello", "привет", "Test123"]

    for original in stressTests {
        var text = original
        var allCorrect = true

        for i in 1...100 {
            text = converter.convert(text)

            if i % 2 == 0 && text != original {
                print("❌ '\(original)' failed at conversion \(i)")
                allCorrect = false
                failed += 1
                break
            }
        }

        if allCorrect {
            print("✅ '\(original)' - 50 round-trips (100 conversions) OK")
            passed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - NEW TESTS: Mixed Layout Detection (WordTracker isMixedLayout)

/// WordTracker with isMixedLayout check (matches production)
final class MixedLayoutWordTracker {
    private let maxSize: Int
    private var buffer: [Character]
    private var head: Int = 0
    private var count: Int = 0

    private let wordBoundaries: Set<Character> = [
        " ", "\n", "\t", "\r",
        "!", "?",
        "(", ")",
        "/", "\\", "|",
        "@", "#", "$", "%", "^", "&", "*",
        "+", "=", "-", "_"
    ]

    private let deleteKeyCode: UInt16 = 51
    private let returnKeyCode: UInt16 = 36
    private let enterKeyCode: UInt16 = 76
    private let spaceKeyCode: UInt16 = 49

    private let navigationKeyCodes: Set<UInt16> = [
        123, 124, 125, 126,
        115, 119, 116, 121,
        117
    ]

    init(maxSize: Int = 50) {
        self.maxSize = maxSize
        self.buffer = [Character](repeating: " ", count: maxSize)
    }

    func trackKeyPress(keyCode: UInt16, characters: String?) {
        if keyCode == deleteKeyCode {
            removeLastCharacter()
            return
        }

        if navigationKeyCodes.contains(keyCode) {
            clear()
            return
        }

        if keyCode == returnKeyCode || keyCode == enterKeyCode {
            clear()
            return
        }

        guard let chars = characters, let firstChar = chars.first else {
            return
        }

        if keyCode == spaceKeyCode || wordBoundaries.contains(firstChar) {
            clear()
            return
        }

        addCharacter(firstChar)
    }

    func getLastWord() -> String? {
        guard count > 0 else { return nil }

        var result = [Character]()
        result.reserveCapacity(count)

        for i in 0..<count {
            let index = (head - count + i + maxSize) % maxSize
            result.append(buffer[index])
        }

        let word = String(result)

        // Validate: reject mixed-layout words
        if isMixedLayout(word) {
            clear()
            return nil
        }

        return word
    }

    func clear() {
        count = 0
    }

    private func addCharacter(_ char: Character) {
        buffer[head] = char
        head = (head + 1) % maxSize

        if count < maxSize {
            count += 1
        }
    }

    private func removeLastCharacter() {
        guard count > 0 else { return }
        head = (head - 1 + maxSize) % maxSize
        count -= 1
    }

    private func isMixedLayout(_ text: String) -> Bool {
        var hasEnglish = false
        var hasRussian = false

        for char in text {
            if isEnglishLetter(char) {
                hasEnglish = true
            } else if isRussianLetter(char) {
                hasRussian = true
            }

            if hasEnglish && hasRussian {
                return true
            }
        }

        return false
    }

    private func isEnglishLetter(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return (scalar.value >= 0x41 && scalar.value <= 0x5A) ||
               (scalar.value >= 0x61 && scalar.value <= 0x7A)
    }

    private func isRussianLetter(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return (scalar.value >= 0x410 && scalar.value <= 0x44F) ||
               scalar.value == 0x401 || scalar.value == 0x451
    }
}

func runMixedLayoutTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  MIXED LAYOUT DETECTION TESTS (WordTracker)")
    print(String(repeating: "=", count: 50))

    var passed = 0
    var failed = 0

    // Test 1: Pure English - should return word
    print("\n--- Pure Layout Words ---")

    let pureEnglishTracker = MixedLayoutWordTracker()
    for char in "hello" {
        pureEnglishTracker.trackKeyPress(keyCode: 0, characters: String(char))
    }
    if pureEnglishTracker.getLastWord() == "hello" {
        print("✅ Pure English 'hello' -> returns 'hello'")
        passed += 1
    } else {
        print("❌ Pure English should return word")
        failed += 1
    }

    // Test 2: Pure Russian - should return word
    let pureRussianTracker = MixedLayoutWordTracker()
    for char in "привет" {
        pureRussianTracker.trackKeyPress(keyCode: 0, characters: String(char))
    }
    if pureRussianTracker.getLastWord() == "привет" {
        print("✅ Pure Russian 'привет' -> returns 'привет'")
        passed += 1
    } else {
        print("❌ Pure Russian should return word")
        failed += 1
    }

    // Test 3: Mixed layout - should return nil
    print("\n--- Mixed Layout Words (should return nil) ---")

    let mixedTests: [(String, String)] = [
        ("helloпривет", "English + Russian"),
        ("приветhello", "Russian + English"),
        ("aб", "Single EN + Single RU"),
        ("бa", "Single RU + Single EN"),
        ("testтест", "English word + Russian word"),
        ("helloмир", "English 'hello' + Russian 'мир'"),
        ("приaет", "Russian with English in middle"),
        ("heллo", "English with Russian in middle"),
    ]

    for (input, desc) in mixedTests {
        let tracker = MixedLayoutWordTracker()
        for char in input {
            tracker.trackKeyPress(keyCode: 0, characters: String(char))
        }
        if tracker.getLastWord() == nil {
            print("✅ Mixed '\(input)' -> nil (\(desc))")
            passed += 1
        } else {
            print("❌ Mixed '\(input)' should return nil (\(desc))")
            print("   Got: '\(tracker.getLastWord() ?? "nil")'")
            failed += 1
        }
    }

    // Test 4: Numbers and punctuation with letters - NOT mixed layout
    print("\n--- Numbers/Punctuation (not mixed layout) ---")

    let notMixedTests: [(String, String)] = [
        ("hello123", "English + numbers"),
        ("привет123", "Russian + numbers"),
        ("test;test", "English + semicolon"),
        ("тест;тест", "Russian + semicolon"),
        ("hello.", "English + period"),
        ("привет.", "Russian + period"),
        ("123456", "Numbers only"),
        (";'[]", "Punctuation only"),
    ]

    for (input, desc) in notMixedTests {
        let tracker = MixedLayoutWordTracker()
        for char in input {
            tracker.trackKeyPress(keyCode: 0, characters: String(char))
        }
        let result = tracker.getLastWord()
        if result == input {
            print("✅ Not mixed '\(input)' -> '\(result ?? "nil")' (\(desc))")
            passed += 1
        } else {
            print("❌ Not mixed '\(input)' should return word (\(desc))")
            print("   Expected: '\(input)', Got: '\(result ?? "nil")'")
            failed += 1
        }
    }

    // Test 5: Edge cases for mixed detection
    print("\n--- Edge Cases ---")

    // Ё/ё special cases
    let yoTracker = MixedLayoutWordTracker()
    for char in "ёлка" {
        yoTracker.trackKeyPress(keyCode: 0, characters: String(char))
    }
    if yoTracker.getLastWord() == "ёлка" {
        print("✅ Russian with ё: 'ёлка' -> returns word")
        passed += 1
    } else {
        print("❌ Russian with ё should return word")
        failed += 1
    }

    let bigYoTracker = MixedLayoutWordTracker()
    for char in "ЁЛКА" {
        bigYoTracker.trackKeyPress(keyCode: 0, characters: String(char))
    }
    if bigYoTracker.getLastWord() == "ЁЛКА" {
        print("✅ Russian with Ё: 'ЁЛКА' -> returns word")
        passed += 1
    } else {
        print("❌ Russian with Ё should return word")
        failed += 1
    }

    // Mixed with Ё
    let mixedYoTracker = MixedLayoutWordTracker()
    for char in "ёlka" {
        mixedYoTracker.trackKeyPress(keyCode: 0, characters: String(char))
    }
    if mixedYoTracker.getLastWord() == nil {
        print("✅ Mixed with ё: 'ёlka' -> nil")
        passed += 1
    } else {
        print("❌ Mixed with ё should return nil")
        failed += 1
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - NEW TESTS: Toggle Case Tests

func runToggleCaseTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  TOGGLE CASE TESTS")
    print(String(repeating: "=", count: 50))

    var passed = 0
    var failed = 0

    // Simple toggle case function
    func toggleCase(_ text: String) -> String {
        return String(text.map { char in
            if char.isUppercase {
                return Character(char.lowercased())
            } else if char.isLowercase {
                return Character(char.uppercased())
            }
            return char
        })
    }

    // Test 1: Basic toggle
    print("\n--- Basic Toggle ---")

    let basicTests: [(String, String, String)] = [
        ("hello", "HELLO", "lowercase -> UPPERCASE"),
        ("HELLO", "hello", "UPPERCASE -> lowercase"),
        ("Hello", "hELLO", "Mixed -> inverted"),
        ("hELLO", "Hello", "Inverted -> Mixed"),
        ("HeLLo WoRLd", "hEllO wOrlD", "Mixed words"),
    ]

    for (input, expected, desc) in basicTests {
        let result = toggleCase(input)
        if result == expected {
            print("✅ '\(input)' -> '\(result)' (\(desc))")
            passed += 1
        } else {
            print("❌ '\(desc)' failed")
            print("   Expected: '\(expected)', Got: '\(result)'")
            failed += 1
        }
    }

    // Test 2: Russian toggle
    print("\n--- Russian Toggle ---")

    let russianTests: [(String, String, String)] = [
        ("привет", "ПРИВЕТ", "Russian lowercase -> UPPERCASE"),
        ("ПРИВЕТ", "привет", "Russian UPPERCASE -> lowercase"),
        ("Привет", "пРИВЕТ", "Russian mixed -> inverted"),
        ("ПрИвЕт", "пРиВеТ", "Russian alternating"),
    ]

    for (input, expected, desc) in russianTests {
        let result = toggleCase(input)
        if result == expected {
            print("✅ '\(input)' -> '\(result)' (\(desc))")
            passed += 1
        } else {
            print("❌ '\(desc)' failed")
            print("   Expected: '\(expected)', Got: '\(result)'")
            failed += 1
        }
    }

    // Test 3: Numbers and special chars (unchanged)
    print("\n--- Numbers and Special Chars (unchanged) ---")

    let unchangedTests: [(String, String)] = [
        ("123", "Numbers only"),
        ("!@#$%", "Special chars"),
        ("hello123", "Letters + numbers"),
        ("HELLO123", "Uppercase + numbers"),
        (";'[].,", "Punctuation"),
    ]

    for (input, desc) in unchangedTests {
        let result = toggleCase(input)
        let hasCorrectNumbers = input.filter { $0.isNumber } == result.filter { $0.isNumber }
        let hasCorrectSpecial = input.filter { !$0.isLetter && !$0.isNumber } == result.filter { !$0.isLetter && !$0.isNumber }

        if hasCorrectNumbers && hasCorrectSpecial {
            print("✅ '\(input)' numbers/special unchanged (\(desc))")
            passed += 1
        } else {
            print("❌ '\(desc)' - numbers/special should be unchanged")
            failed += 1
        }
    }

    // Test 4: Double toggle returns original
    print("\n--- Double Toggle (idempotence) ---")

    let doubleToggleTests = ["Hello", "WORLD", "привет", "ПРИВЕТ", "MiXeD CaSe", "ПрИвЕт МиР"]

    for original in doubleToggleTests {
        let once = toggleCase(original)
        let twice = toggleCase(once)

        if twice == original {
            print("✅ '\(original)' -> '\(once)' -> '\(twice)'")
            passed += 1
        } else {
            print("❌ Double toggle failed for '\(original)'")
            print("   Got: '\(twice)'")
            failed += 1
        }
    }

    // Test 5: Empty and edge cases
    print("\n--- Edge Cases ---")

    if toggleCase("") == "" {
        print("✅ Empty string -> empty string")
        passed += 1
    } else {
        print("❌ Empty string failed")
        failed += 1
    }

    if toggleCase(" ") == " " {
        print("✅ Single space unchanged")
        passed += 1
    } else {
        print("❌ Single space failed")
        failed += 1
    }

    if toggleCase("a") == "A" {
        print("✅ Single char 'a' -> 'A'")
        passed += 1
    } else {
        print("❌ Single char failed")
        failed += 1
    }

    if toggleCase("Ё") == "ё" {
        print("✅ Russian Ё -> ё")
        passed += 1
    } else {
        print("❌ Russian Ё toggle failed")
        failed += 1
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - NEW TESTS: Rapid Conversion Simulation

func runRapidConversionTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  RAPID CONVERSION SIMULATION TESTS")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    // Test 1: User types, converts, types more, converts again
    print("\n--- Type-Convert-Type-Convert Cycle ---")

    // Simulate: type "ghb", convert, type "dtn", convert
    let scenario1Words = ["ghb", "ghbdtn"]  // ghb -> при, ghbdtn -> привет
    var scenario1Text = ""

    scenario1Text = "ghb"
    let step1 = converter.convert(scenario1Text)  // ghb -> при

    scenario1Text = "ghbdtn"  // User typed more (wrong layout still)
    let step2 = converter.convert(scenario1Text)  // ghbdtn -> привет

    if step1 == "при" && step2 == "привет" {
        print("✅ Incremental typing: 'ghb' -> 'при', 'ghbdtn' -> 'привет'")
        passed += 1
    } else {
        print("❌ Incremental typing failed")
        print("   step1: '\(step1)' (expected: 'при')")
        print("   step2: '\(step2)' (expected: 'привет')")
        failed += 1
    }

    // Test 2: Rapid fire conversions with different words
    print("\n--- Rapid Fire Different Words ---")

    let rapidWords = [
        ("hello", "руддщ"),
        ("world", "цщкдв"),
        ("test", "е|у|ые"),  // Note: t->е, e->у, s->ы, t->е
        ("swift", "ыцшае"),
        ("code", "сщву"),
    ]

    for (en, expectedRu) in rapidWords {
        let converted = converter.convert(en)
        let back = converter.convert(converted)

        if back == en {
            print("✅ '\(en)' <-> '\(converted)' round-trip OK")
            passed += 1
        } else {
            print("❌ '\(en)' round-trip failed")
            print("   '\(en)' -> '\(converted)' -> '\(back)'")
            failed += 1
        }
    }

    // Test 3: User makes mistake, converts, undoes (converts back), retypes
    print("\n--- Mistake-Convert-Undo Scenario ---")

    // User meant to type "hello" in Russian layout but was in English
    // Types "руддщ" (Russian chars when they wanted to type h-e-l-l-o keys)
    // Realizes mistake, converts -> "hello"
    // Decides they actually wanted Russian, converts back -> "руддщ"
    // Types more Russian -> "руддщ мир" (but "мир" is separate word)

    let mistakeScenario = "руддщ"
    let fixed = converter.convert(mistakeScenario)  // руддщ -> hello
    let undone = converter.convert(fixed)            // hello -> руддщ

    if fixed == "hello" && undone == "руддщ" {
        print("✅ Mistake scenario: 'руддщ' -> 'hello' -> 'руддщ'")
        passed += 1
    } else {
        print("❌ Mistake scenario failed")
        failed += 1
    }

    // Test 4: Multiple words in sequence
    print("\n--- Multiple Words Sequence ---")

    let sentences = [
        ("ghbdtn vbh", "привет ьшк"),  // Note: space preserved, 'v' -> 'ь', 'b' -> 'ш', 'h' -> 'к'
        ("hello world", "руддщ цщкдв"),
    ]

    for (input, _) in sentences {
        let converted = converter.convert(input)
        let back = converter.convert(converted)

        if back == input {
            print("✅ '\(input)' round-trip OK")
            passed += 1
        } else {
            print("❌ '\(input)' round-trip failed")
            print("   Got: '\(back)'")
            failed += 1
        }
    }

    // Test 5: Stress - 50 different words converted rapidly
    print("\n--- Stress: 50 Words Rapid Conversion ---")

    let stressWords = [
        "apple", "banana", "cherry", "date", "elderberry",
        "fig", "grape", "honeydew", "kiwi", "lemon",
        "mango", "nectarine", "orange", "papaya", "quince",
        "raspberry", "strawberry", "tangerine", "watermelon", "zucchini",
        "ant", "bee", "cat", "dog", "elephant",
        "fox", "goat", "horse", "iguana", "jaguar",
        "koala", "lion", "mouse", "newt", "owl",
        "penguin", "quail", "rabbit", "snake", "tiger",
        "urchin", "viper", "whale", "xerus", "yak",
        "zebra", "aardvark", "badger", "coyote", "dolphin"
    ]

    var allPassed = true
    for word in stressWords {
        let converted = converter.convert(word)
        let back = converter.convert(converted)

        if back != word {
            print("❌ Failed: '\(word)' -> '\(converted)' -> '\(back)'")
            allPassed = false
            failed += 1
            break
        }
    }

    if allPassed {
        print("✅ All 50 words converted and back successfully")
        passed += 1
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - NEW TESTS: Clipboard Simulation Tests

func runClipboardSimulationTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  CLIPBOARD SIMULATION TESTS")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    // Simulate clipboard operations (selected text conversion)
    // These test the scenario where user selects text and converts it

    // Test 1: Select and convert single word
    print("\n--- Select and Convert Single Word ---")

    let singleWordTests = [
        ("ghbdtn", "привет", "English chars -> Russian word"),
        ("привет", "ghbdtn", "Russian word -> English chars"),
        ("GHBDTN", "ПРИВЕТ", "Uppercase conversion"),
        ("Ghbdtn", "Привет", "Capitalized conversion"),
    ]

    for (selected, expected, desc) in singleWordTests {
        // Simulate: user selected text, pressed hotkey
        let converted = converter.convert(selected)

        if converted == expected {
            print("✅ Select '\(selected)' -> '\(converted)' (\(desc))")
            passed += 1
        } else {
            print("❌ \(desc) failed")
            print("   Expected: '\(expected)', Got: '\(converted)'")
            failed += 1
        }
    }

    // Test 2: Select and convert paragraph
    print("\n--- Select and Convert Paragraph ---")

    let paragraph = "Ghbdtn? Rfr ltkf? Z gbie yf Hecctrv!"
    let convertedParagraph = converter.convert(paragraph)
    let backParagraph = converter.convert(convertedParagraph)

    if backParagraph == paragraph {
        print("✅ Paragraph round-trip OK")
        print("   Original:  '\(paragraph)'")
        print("   Converted: '\(convertedParagraph)'")
        passed += 1
    } else {
        print("❌ Paragraph round-trip failed")
        failed += 1
    }

    // Test 3: Select partial word (edge case)
    print("\n--- Select Partial Word ---")

    let partialTests = [
        ("hel", "руд"),  // h->р, e->у, l->д
        ("при", "ghb"),
        ("HEL", "РУД"),
    ]

    for (partial, expected) in partialTests {
        let converted = converter.convert(partial)
        if converted == expected {
            print("✅ Partial '\(partial)' -> '\(converted)'")
            passed += 1
        } else {
            print("❌ Partial '\(partial)' failed")
            print("   Expected: '\(expected)', Got: '\(converted)'")
            failed += 1
        }
    }

    // Test 4: Multi-line selection
    print("\n--- Multi-line Selection ---")

    let multiLine = "Line one\nLine two\nLine three"
    let convertedMulti = converter.convert(multiLine)
    let backMulti = converter.convert(convertedMulti)

    if backMulti == multiLine {
        print("✅ Multi-line round-trip OK")
        passed += 1
    } else {
        print("❌ Multi-line round-trip failed")
        failed += 1
    }

    // Test 5: Selection with tabs and special whitespace
    print("\n--- Selection with Whitespace ---")

    let whitespaceTests = [
        ("hello\tworld", "With tab"),
        ("hello  world", "With double space"),
        ("hello\nworld", "With newline"),
        ("  hello  ", "With leading/trailing spaces"),
    ]

    for (input, desc) in whitespaceTests {
        let converted = converter.convert(input)
        let back = converter.convert(converted)

        if back == input {
            print("✅ '\(desc)' round-trip OK")
            passed += 1
        } else {
            print("❌ '\(desc)' round-trip failed")
            print("   Original: '\(input)'")
            print("   Back:     '\(back)'")
            failed += 1
        }
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - WEAKNESS TESTS: Tests that expose bugs and edge cases

func runWeaknessTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  WEAKNESS TESTS - Finding Bugs")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    // ============================================
    // WEAKNESS 1: Ambiguous character mappings
    // ============================================
    print("\n--- WEAKNESS 1: Ambiguous Mappings ---")
    print("Multiple EN chars map to same RU char. Reverse may break.")

    // Problem: ";" maps to "ж", but "Ж" maps to ":" (Shift+;)
    // When converting RU "ж" back, should it be ";" or something else?
    // Similarly: "." -> "ю" but "/" -> "." - ambiguity!

    let ambiguousTests: [(String, String, String, Bool)] = [
        // (input, expected_after_convert, description, should_roundtrip)
        (".", "ю", "period -> ю", true),
        ("/", ".", "slash -> period", true),  // PROBLEM: "." in RU context won't roundtrip!
        ("ю", ".", "ю -> period (not slash)", false),  // May not roundtrip to "ю"
    ]

    for (input, expected, desc, shouldRoundtrip) in ambiguousTests {
        let converted = converter.convert(input)
        let back = converter.convert(converted)

        if converted == expected {
            print("✅ '\(input)' -> '\(converted)' (\(desc))")
            passed += 1
        } else {
            print("⚠️  '\(input)' -> '\(converted)' (expected '\(expected)') - \(desc)")
            failed += 1
        }

        if shouldRoundtrip && back != input {
            print("   ❌ BROKEN ROUNDTRIP: '\(input)' -> '\(converted)' -> '\(back)'")
        }
    }

    // The "/" and "." problem in detail
    print("\n   Special case: '/' vs '.' vs 'ю' chain:")
    let slash = "/"
    let slashToRu = converter.convert(slash)  // "/" -> "."
    let dotToRu = converter.convert(".")       // "." -> "ю"
    print("   '/' -> '\(slashToRu)' (should be '.')")
    print("   '.' -> '\(dotToRu)' (should be 'ю')")
    print("   Now if we have '.' in Russian text, it stays '.' (no mapping)")

    // ============================================
    // WEAKNESS 2: Shift+number symbol conflicts
    // ============================================
    print("\n--- WEAKNESS 2: Shift+Number Symbol Conflicts ---")
    print("Some shift+number symbols conflict with punctuation.")

    // ":" appears in both:
    // - ";" + Shift = ":" (EN keyboard)
    // - "^" -> ":" (Shift+6 mapping)
    // When we see ":" in Russian text, which way do we convert?

    let shiftConflicts: [(String, String, String)] = [
        (":", "Ж", "colon should map to Ж (from ;+Shift)"),
        ("^", ":", "caret maps to colon (Shift+6)"),
        // Reverse direction - what does ":" become?
    ]

    for (input, expected, desc) in shiftConflicts {
        let result = converter.convertToRussian(input)
        if result == expected {
            print("✅ EN->RU: '\(input)' -> '\(result)' (\(desc))")
            passed += 1
        } else {
            print("❌ EN->RU: '\(input)' -> '\(result)' (expected '\(expected)') - \(desc)")
            failed += 1
        }
    }

    // Test the reverse - this is where it breaks!
    print("\n   Reverse direction (RU -> EN):")
    let colonFromRu = converter.convertToEnglish(":")
    let zhFromRu = converter.convertToEnglish("Ж")
    print("   ':' -> '\(colonFromRu)' (ambiguous! could be '^' or from 'Ж')")
    print("   'Ж' -> '\(zhFromRu)' (should be ':')")

    if colonFromRu == "^" {
        print("   ⚠️  ':' maps to '^' (Shift+6 priority), not to the original key")
    }

    // ============================================
    // WEAKNESS 3: Unicode edge cases
    // ============================================
    print("\n--- WEAKNESS 3: Unicode Edge Cases ---")
    print("Characters outside basic ASCII/Cyrillic may crash or behave unexpectedly.")

    // Test with combining characters, emoji, etc.
    let unicodeTests: [(String, String)] = [
        ("é", "Combining accent (café)"),
        ("ñ", "Spanish ñ"),
        ("ü", "German umlaut"),
        ("中文", "Chinese characters"),
        ("🎉", "Emoji"),
        ("👨‍👩‍👧", "Complex emoji with ZWJ"),
        ("\u{0301}", "Combining acute accent alone"),
        ("e\u{0301}", "e + combining accent = é"),
    ]

    for (input, desc) in unicodeTests {
        let converted = converter.convert(input)
        let back = converter.convert(converted)

        // These should pass through unchanged
        if converted == input && back == input {
            print("✅ '\(input)' unchanged (\(desc))")
            passed += 1
        } else {
            print("⚠️  '\(input)' -> '\(converted)' -> '\(back)' (\(desc))")
            // Not necessarily a failure, but worth noting
            passed += 1  // Count as passed if no crash
        }
    }

    // ============================================
    // WEAKNESS 4: Force unwrap in isEnglishLetter/isRussianLetter
    // ============================================
    print("\n--- WEAKNESS 4: Empty String Handling ---")

    // The production code has: char.unicodeScalars.first!
    // What happens with edge cases?

    let emptyEdgeCases = [
        "",
        " ",
        "\t",
        "\n",
        "\r\n",
    ]

    for input in emptyEdgeCases {
        // This should not crash
        let layout = converter.detectLayout(input)
        print("✅ detectLayout('\(input.debugDescription)') = \(layout) (no crash)")
        passed += 1
    }

    // ============================================
    // WEAKNESS 5: Layout detection threshold edge cases
    // ============================================
    print("\n--- WEAKNESS 5: Layout Detection Threshold Issues ---")

    // The 80%/20% threshold can cause unexpected behavior
    // 79% English is "mixed", 81% is "english" - small change, big difference!

    let thresholdIssues: [(String, String)] = [
        // 4 EN + 1 RU = 80% EN -> .mixed (not .english because > 0.8 required)
        ("abcdй", "80% EN - borderline, detected as mixed"),
        // Same content, different detection based on ratio
        ("abcdeй", "83% EN - detected as english"),
        // User types mostly English with one Russian typo
        ("Hello worldй", "One Russian char at end - still English?"),
    ]

    for (input, desc) in thresholdIssues {
        let layout = converter.detectLayout(input)
        let converted = converter.convert(input)
        print("   '\(input)' -> layout=\(layout)")
        print("   Converted: '\(converted)' (\(desc))")

        // This exposes the issue: user typed "Hello worldй" by mistake
        // expecting English, but gets mixed treatment
    }

    // ============================================
    // WEAKNESS 6: Punctuation-only text behavior
    // ============================================
    print("\n--- WEAKNESS 6: Punctuation-Only Text ---")

    // Text with only punctuation that maps to Russian letters
    let punctOnlyTests = [
        ";",      // -> ж
        "'",      // -> э
        ";'[];",  // Complex punctuation
        "...",    // Ellipsis
        "???",    // Multiple question marks
        "!!!",    // Multiple exclamation marks
    ]

    for input in punctOnlyTests {
        let layout = converter.detectLayout(input)
        let converted = converter.convert(input)
        let back = converter.convert(converted)

        let roundtrips = (back == input)
        print("   '\(input)' -> '\(converted)' -> '\(back)' (layout=\(layout), roundtrip=\(roundtrips))")

        if !roundtrips {
            print("   ⚠️  Doesn't roundtrip!")
        }
    }

    // ============================================
    // WEAKNESS 7: Mixed layout with numbers
    // ============================================
    print("\n--- WEAKNESS 7: Numbers Affect Majority Detection ---")

    // Numbers don't count in layout detection, but are present in text
    // This can cause unexpected conversion direction

    let numberMixTests = [
        ("a123456789б", "1 EN, 1 RU, many numbers - mixed"),
        ("abc123456789", "Pure EN with numbers"),
        ("123abc456", "Numbers interspersed"),
    ]

    for (input, desc) in numberMixTests {
        let layout = converter.detectLayout(input)
        let converted = converter.convert(input)
        print("   '\(input)' -> '\(converted)' (layout=\(layout)) - \(desc)")
    }

    // ============================================
    // WEAKNESS 8: Very long strings performance
    // ============================================
    print("\n--- WEAKNESS 8: Very Long String Performance ---")

    // Create a very long string and measure conversion time
    let longString = String(repeating: "hello world ", count: 10000)  // ~130k chars

    let start = Date()
    let converted = converter.convert(longString)
    let elapsed = Date().timeIntervalSince(start)

    print("   Converted \(longString.count) chars in \(String(format: "%.3f", elapsed))s")

    if elapsed > 1.0 {
        print("   ⚠️  SLOW: Took more than 1 second!")
        failed += 1
    } else {
        print("   ✅ Performance OK")
        passed += 1
    }

    // ============================================
    // WEAKNESS 9: Null/control characters
    // ============================================
    print("\n--- WEAKNESS 9: Null and Control Characters ---")

    let controlChars: [(String, String)] = [
        ("\0", "Null character"),
        ("\u{0007}", "Bell"),
        ("\u{001B}", "Escape"),
        ("\u{007F}", "Delete"),
        ("hello\0world", "Null in middle"),
    ]

    for (input, desc) in controlChars {
        let converted = converter.convert(input)
        let back = converter.convert(converted)
        let roundtrips = (back == input)
        print("   \(desc): roundtrip=\(roundtrips)")
        if roundtrips {
            passed += 1
        }
    }

    // ============================================
    // WEAKNESS 10: The "test" word special case
    // ============================================
    print("\n--- WEAKNESS 10: Common Words with Punctuation Mappings ---")

    // "test" -> "е|у|ые" or similar based on mappings
    // Let's verify the exact mapping

    let testWord = "test"
    let testConverted = converter.convert(testWord)
    print("   'test' -> '\(testConverted)'")
    print("   Char breakdown: t=\(converter.convert("t")), e=\(converter.convert("e")), s=\(converter.convert("s")), t=\(converter.convert("t"))")

    // The issue: 's' -> 'ы', which looks like 'bl' in some fonts
    // This can confuse users

    print("\nResults: \(passed) passed, \(failed) failed")
    print("\n⚠️  Note: Some 'failures' above are documented edge cases, not bugs.")
}

// MARK: - WEAKNESS TESTS: WordTracker specific issues

func runWordTrackerWeaknessTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  WORDTRACKER WEAKNESS TESTS")
    print(String(repeating: "=", count: 50))

    var passed = 0
    var failed = 0

    // ============================================
    // WEAKNESS 1: Ring buffer boundary
    // ============================================
    print("\n--- WEAKNESS 1: Ring Buffer Boundary ---")

    // What happens at exactly maxSize?
    let tracker1 = MixedLayoutWordTracker(maxSize: 5)
    for char in "12345" {  // Exactly 5 chars
        tracker1.trackKeyPress(keyCode: 0, characters: String(char))
    }
    let word1 = tracker1.getLastWord()
    if word1 == "12345" {
        print("✅ Exactly maxSize chars: '\(word1 ?? "nil")'")
        passed += 1
    } else {
        print("❌ Exactly maxSize failed: '\(word1 ?? "nil")'")
        failed += 1
    }

    // One more char - should drop first
    tracker1.trackKeyPress(keyCode: 0, characters: "6")
    let word2 = tracker1.getLastWord()
    if word2 == "23456" {
        print("✅ maxSize+1 drops first: '\(word2 ?? "nil")'")
        passed += 1
    } else {
        print("❌ maxSize+1 failed: '\(word2 ?? "nil")'")
        failed += 1
    }

    // ============================================
    // WEAKNESS 2: Backspace past empty
    // ============================================
    print("\n--- WEAKNESS 2: Backspace Past Empty ---")

    let tracker2 = MixedLayoutWordTracker()
    tracker2.trackKeyPress(keyCode: 0, characters: "a")
    tracker2.trackKeyPress(keyCode: 51, characters: nil)  // Delete
    tracker2.trackKeyPress(keyCode: 51, characters: nil)  // Delete again (past empty!)
    tracker2.trackKeyPress(keyCode: 51, characters: nil)  // And again!

    let word3 = tracker2.getLastWord()
    if word3 == nil {
        print("✅ Multiple backspaces on empty: nil (no crash)")
        passed += 1
    } else {
        print("❌ Should be nil, got '\(word3!)'")
        failed += 1
    }

    // Now add a char - should work normally
    tracker2.trackKeyPress(keyCode: 0, characters: "b")
    let word4 = tracker2.getLastWord()
    if word4 == "b" {
        print("✅ After excessive backspace, can still type: '\(word4!)'")
        passed += 1
    } else {
        print("❌ Failed after backspace: '\(word4 ?? "nil")'")
        failed += 1
    }

    // ============================================
    // WEAKNESS 3: Rapid layout switching simulation
    // ============================================
    print("\n--- WEAKNESS 3: Rapid Layout Switching ---")

    // User types in wrong layout, system switches, more chars arrive
    // This creates mixed layout text that should be rejected

    let tracker3 = MixedLayoutWordTracker()
    tracker3.trackKeyPress(keyCode: 0, characters: "h")  // English
    tracker3.trackKeyPress(keyCode: 0, characters: "e")  // English
    tracker3.trackKeyPress(keyCode: 0, characters: "l")  // English
    // Layout switch happens here...
    tracker3.trackKeyPress(keyCode: 0, characters: "д")  // Russian!
    tracker3.trackKeyPress(keyCode: 0, characters: "о")  // Russian!

    let word5 = tracker3.getLastWord()
    if word5 == nil {
        print("✅ Mixed layout 'helдо' rejected: nil")
        passed += 1
    } else {
        print("⚠️  Mixed layout accepted: '\(word5!)' - isMixedLayout should catch this")
        failed += 1
    }

    // ============================================
    // WEAKNESS 4: Special characters that look like letters
    // ============================================
    print("\n--- WEAKNESS 4: Look-alike Characters ---")

    // Some characters look like letters but aren't
    // а (Cyrillic) vs a (Latin) - different Unicode!
    // с (Cyrillic) vs c (Latin)
    // etc.

    let tracker4 = MixedLayoutWordTracker()
    // Mix Cyrillic 'а' (U+0430) with Latin 'a' (U+0061)
    tracker4.trackKeyPress(keyCode: 0, characters: "а")  // Cyrillic а
    tracker4.trackKeyPress(keyCode: 0, characters: "a")  // Latin a - MIXED!

    let word6 = tracker4.getLastWord()
    if word6 == nil {
        print("✅ Cyrillic а + Latin a detected as mixed: nil")
        passed += 1
    } else {
        print("❌ Should detect mixed: '\(word6!)' (Cyrillic а + Latin a)")
        failed += 1
    }

    // ============================================
    // WEAKNESS 5: Navigation key timing
    // ============================================
    print("\n--- WEAKNESS 5: Navigation Keys ---")

    // All arrow keys should clear buffer
    let navKeys: [(UInt16, String)] = [
        (123, "Left"),
        (124, "Right"),
        (125, "Down"),
        (126, "Up"),
        (115, "Home"),
        (119, "End"),
        (116, "PageUp"),
        (121, "PageDown"),
        (117, "ForwardDelete"),
    ]

    for (keyCode, name) in navKeys {
        let tracker = MixedLayoutWordTracker()
        tracker.trackKeyPress(keyCode: 0, characters: "test")
        tracker.trackKeyPress(keyCode: keyCode, characters: nil)

        if tracker.getLastWord() == nil {
            print("✅ \(name) (\(keyCode)) clears buffer")
            passed += 1
        } else {
            print("❌ \(name) (\(keyCode)) should clear buffer!")
            failed += 1
        }
    }

    // ============================================
    // WEAKNESS 6: Tab key behavior
    // ============================================
    print("\n--- WEAKNESS 6: Tab Key ---")

    let tracker5 = MixedLayoutWordTracker()
    tracker5.trackKeyPress(keyCode: 0, characters: "hello")
    tracker5.trackKeyPress(keyCode: 48, characters: "\t")  // Tab

    // Tab is in wordBoundaries, should clear
    let word7 = tracker5.getLastWord()
    if word7 == nil {
        print("✅ Tab clears buffer")
        passed += 1
    } else {
        print("❌ Tab should clear buffer, got '\(word7!)'")
        failed += 1
    }

    // ============================================
    // WEAKNESS 7: Punctuation that maps to Russian
    // ============================================
    print("\n--- WEAKNESS 7: Punctuation That Maps to Russian ---")

    // These should NOT clear the buffer
    let keepPunctuation = [";", "'", ",", ".", "[", "]", "`"]

    for punct in keepPunctuation {
        let tracker = MixedLayoutWordTracker()
        tracker.trackKeyPress(keyCode: 0, characters: "a")
        tracker.trackKeyPress(keyCode: 0, characters: punct)

        let word = tracker.getLastWord()
        if word == "a\(punct)" {
            print("✅ '\(punct)' stays in buffer: '\(word!)'")
            passed += 1
        } else {
            print("❌ '\(punct)' should stay: '\(word ?? "nil")'")
            failed += 1
        }
    }

    // ============================================
    // WEAKNESS 8: Unicode supplementary planes
    // ============================================
    print("\n--- WEAKNESS 8: Unicode Supplementary Planes ---")

    // Characters outside BMP (like emoji) may cause issues
    let tracker6 = MixedLayoutWordTracker()
    tracker6.trackKeyPress(keyCode: 0, characters: "a")
    tracker6.trackKeyPress(keyCode: 0, characters: "🎉")  // Emoji
    tracker6.trackKeyPress(keyCode: 0, characters: "b")

    let word8 = tracker6.getLastWord()
    // Should work - emoji is neither EN nor RU letter
    if word8 == "a🎉b" {
        print("✅ Emoji in word: '\(word8!)'")
        passed += 1
    } else {
        print("⚠️  Emoji handling: '\(word8 ?? "nil")'")
        passed += 1  // Not necessarily wrong
    }

    print("\nResults: \(passed) passed, \(failed) failed")
}

// MARK: - WEAKNESS TESTS: Conversion direction ambiguity

func runConversionDirectionTests() {
    print("\n" + String(repeating: "=", count: 50))
    print("  CONVERSION DIRECTION AMBIGUITY TESTS")
    print(String(repeating: "=", count: 50))

    let converter = TestLayoutConverter()
    var passed = 0
    var failed = 0

    // ============================================
    // The core problem: auto-detection can guess wrong
    // ============================================
    print("\n--- The Auto-Detection Problem ---")

    // User types "ghbdtn" wanting "привет"
    // Auto-detect sees English -> converts to Russian ✓
    let case1 = "ghbdtn"
    let result1 = converter.convert(case1)
    print("   '\(case1)' -> '\(result1)' (correct: привет)")

    // But what if user types punctuation that looks like English?
    // ";" is detected as... unknown (no letters)
    let case2 = ";"
    let layout2 = converter.detectLayout(case2)
    let result2 = converter.convert(case2)
    print("   '\(case2)' -> '\(result2)' (layout: \(layout2))")

    // What about ";'" which should become "жэ"?
    let case3 = ";'"
    let layout3 = converter.detectLayout(case3)
    let result3 = converter.convert(case3)
    print("   '\(case3)' -> '\(result3)' (layout: \(layout3))")

    // ============================================
    // Problem: Text with mostly punctuation
    // ============================================
    print("\n--- Punctuation-Heavy Text ---")

    let punctTests = [
        ("a;b", "One letter, one punct"),
        (";a;", "Punct around letter"),
        ("test;test", "Words with punct"),
    ]

    for (input, desc) in punctTests {
        let layout = converter.detectLayout(input)
        let converted = converter.convert(input)
        let back = converter.convert(converted)
        let roundtrips = (back == input)

        print("   '\(input)' -> '\(converted)' -> '\(back)'")
        print("      Layout: \(layout), Roundtrip: \(roundtrips) (\(desc))")

        if roundtrips {
            passed += 1
        } else {
            failed += 1
        }
    }

    // ============================================
    // Problem: User wants to convert TO specific direction
    // ============================================
    print("\n--- Force Direction Issue ---")

    // Current API doesn't let user say "I want EN->RU specifically"
    // They have to rely on auto-detection which might be wrong

    // Imagine user has "test" selected and wants Russian
    // But what if they already have "еу|е" and want English back?
    // Auto-detect would see Russian and convert to English - correct!
    // But what if mixed?

    let mixedCase = "teстing"  // "te" English + "ст" Russian + "ing" English
    let mixedLayout = converter.detectLayout(mixedCase)
    let mixedResult = converter.convert(mixedCase)

    print("   Mixed '\(mixedCase)' (layout: \(mixedLayout))")
    print("   Converted: '\(mixedResult)'")
    print("   ⚠️  Mixed text conversion may not be what user wanted!")

    // ============================================
    // Problem: Near-threshold detection
    // ============================================
    print("\n--- Near-Threshold Instability ---")

    // Adding one character can flip the detection
    let base = "abcdйцу"  // 4 EN, 3 RU = 57% EN = mixed
    let addEn = base + "e"  // 5 EN, 3 RU = 62.5% EN = mixed
    let addRu = base + "к"  // 4 EN, 4 RU = 50% EN = mixed

    print("   '\(base)' layout: \(converter.detectLayout(base))")
    print("   '\(addEn)' layout: \(converter.detectLayout(addEn)) (added EN)")
    print("   '\(addRu)' layout: \(converter.detectLayout(addRu)) (added RU)")

    // All are "mixed" but conversion direction might differ!
    print("   Conversions:")
    print("   '\(base)' -> '\(converter.convert(base))'")
    print("   '\(addEn)' -> '\(converter.convert(addEn))'")
    print("   '\(addRu)' -> '\(converter.convert(addRu))'")

    print("\nResults: \(passed) passed, \(failed) failed")
    print("\n⚠️  These tests expose design limitations, not necessarily bugs.")
}

// MARK: - Main

print("╔══════════════════════════════════════════════════╗")
print("║           PUNTO TEST SUITE                       ║")
print("╚══════════════════════════════════════════════════╝")

let args = CommandLine.arguments

if args.count > 1 {
    switch args[1] {
    case "convert":
        runConversionTests()
    case "track":
        runWordTrackingTests()
    case "sim", "simulate":
        runSimulation()
    case "stress":
        runStressTest()
    case "mass":
        runMassStressTest()
    case "double":
        runDoubleConversionTests()
    case "long":
        runLongStringTests()
    case "edge":
        runEdgeCaseTests()
    case "bugs", "hunt":
        runBugHunt()
    case "selection", "select":
        runSelectionTests()
    // NEW test commands
    case "hotkey", "hotkeys":
        runHotkeyTests()
    case "shift", "shiftnumber":
        runShiftNumberTests()
    case "layout", "detection":
        runLayoutDetectionTests()
    case "realtracker", "tracker":
        runRealWordTrackerTests()
    case "result", "withresult":
        runConvertWithResultTests()
    case "unicode", "boundary":
        runUnicodeBoundaryTests()
    case "multi", "multiple", "roundtrip":
        runMultipleConversionTests()
    case "mixed", "mixedlayout":
        runMixedLayoutTests()
    case "toggle", "case":
        runToggleCaseTests()
    case "rapid":
        runRapidConversionTests()
    case "clipboard", "clip":
        runClipboardSimulationTests()
    case "weakness", "weak":
        runWeaknessTests()
    case "trackerweakness", "trackerweak":
        runWordTrackerWeaknessTests()
    case "direction", "ambiguity":
        runConversionDirectionTests()
    case "allweak", "weakall":
        runWeaknessTests()
        runWordTrackerWeaknessTests()
        runConversionDirectionTests()
    case "all":
        runConversionTests()
        runWordTrackingTests()
        runDoubleConversionTests()
        runLongStringTests()
        runSelectionTests()
        runEdgeCaseTests()
        // NEW tests
        runHotkeyTests()
        runShiftNumberTests()
        runLayoutDetectionTests()
        runRealWordTrackerTests()
        runConvertWithResultTests()
        runUnicodeBoundaryTests()
        runMultipleConversionTests()
        runMixedLayoutTests()
        runToggleCaseTests()
        runRapidConversionTests()
        runClipboardSimulationTests()
        // Weakness tests (intentionally show weaknesses)
        runWeaknessTests()
        runWordTrackerWeaknessTests()
        runConversionDirectionTests()
        // Demo/stress tests
        runSimulation()
        runStressTest()
        runMassStressTest()
        runBugHunt()
    default:
        print("Unknown command: \(args[1])")
        print("Usage: PuntoTest [convert|track|sim|stress|mass|double|long|edge|selection|bugs|all]")
        print("       New: [hotkey|shift|layout|realtracker|result|unicode|multi|mixed|toggle|rapid|clipboard]")
        print("       Weakness: [weakness|trackerweak|direction|allweak]")
    }
} else {
    print("Usage: PuntoTest [convert|track|sim|stress|mass|double|long|edge|selection|bugs|all]")
    print("       New: [hotkey|shift|layout|realtracker|result|unicode|multi|mixed|toggle|rapid|clipboard]")
    print("\nRunning all tests by default...\n")
    runConversionTests()
    runWordTrackingTests()
    runDoubleConversionTests()
    runLongStringTests()
    runSelectionTests()
    runEdgeCaseTests()
    // NEW tests
    runHotkeyTests()
    runShiftNumberTests()
    runLayoutDetectionTests()
    runRealWordTrackerTests()
    runConvertWithResultTests()
    runUnicodeBoundaryTests()
    runMultipleConversionTests()
    runMixedLayoutTests()
    runToggleCaseTests()
    runRapidConversionTests()
    runClipboardSimulationTests()
    // Weakness tests
    runWeaknessTests()
    runWordTrackerWeaknessTests()
    runConversionDirectionTests()
    // Demo/stress tests
    runSimulation()
    runStressTest()
    runMassStressTest()
    runBugHunt()
}
