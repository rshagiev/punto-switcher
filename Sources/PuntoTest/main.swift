import Foundation

// MARK: - Test Harness for Punto

/// Simulates the WordTracker
class TestWordTracker {
    private var buffer: [Character] = []
    private let maxLength = 50

    func trackKeyPress(character: Character) {
        // Word boundaries
        if character == " " || character == "\n" || character == "\t" ||
           character == "." || character == "," || character == "!" ||
           character == "?" || character == ":" || character == ";" {
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

/// Layout converter (same logic as main app)
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
        "`": "ё", "~": "Ё"
    ]

    private var ruToEn: [Character: Character] = [:]

    init() {
        // Build reverse mapping
        for (en, ru) in enToRu {
            ruToEn[ru] = en
        }
    }

    func convert(_ text: String) -> String {
        var result = ""
        for char in text {
            if let converted = enToRu[char] {
                result.append(converted)
            } else if let converted = ruToEn[char] {
                result.append(converted)
            } else {
                result.append(char)
            }
        }
        return result
    }
}

// MARK: - Test Cases

struct TestCase {
    let name: String
    let input: String
    let expected: String
}

let conversionTests: [TestCase] = [
    // EN -> RU
    TestCase(name: "ghbdtn -> привет", input: "ghbdtn", expected: "привет"),
    TestCase(name: "hello -> руддщ", input: "hello", expected: "руддщ"),
    TestCase(name: "world -> цщкдв", input: "world", expected: "цщкдв"),
    TestCase(name: "test -> еу|е", input: "test", expected: "еу|е"),

    // RU -> EN
    TestCase(name: "привет -> ghbdtn", input: "привет", expected: "ghbdtn"),
    TestCase(name: "руддщ -> hello", input: "руддщ", expected: "hello"),
    TestCase(name: "мир -> vbh", input: "мир", expected: "vbh"),

    // Mixed - should pass through unchanged
    TestCase(name: "hello123 -> руддщ123", input: "hello123", expected: "руддщ123"),
    TestCase(name: "Test! -> Еу|е!", input: "Test!", expected: "Еу|е!"),

    // Edge cases
    TestCase(name: "empty string", input: "", expected: ""),
    TestCase(name: "single char q -> й", input: "q", expected: "й"),
    TestCase(name: "single char й -> q", input: "й", expected: "q"),
]

// MARK: - Word Tracking Tests

struct WordTrackingTest {
    let name: String
    let keystrokes: String
    let expectedWord: String
}

let wordTrackingTests: [WordTrackingTest] = [
    WordTrackingTest(name: "Simple word", keystrokes: "hello", expectedWord: "hello"),
    WordTrackingTest(name: "Word with space clears", keystrokes: "hello world", expectedWord: "world"),
    WordTrackingTest(name: "Backspace removes char", keystrokes: "hello\u{7F}", expectedWord: "hell"),
    WordTrackingTest(name: "Period clears", keystrokes: "hello.", expectedWord: ""),
    WordTrackingTest(name: "Multiple words", keystrokes: "one two three", expectedWord: "three"),
    WordTrackingTest(name: "Russian word", keystrokes: "привет", expectedWord: "привет"),
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
    case "bugs", "hunt":
        runBugHunt()
    case "all":
        runConversionTests()
        runWordTrackingTests()
        runSimulation()
        runStressTest()
        runBugHunt()
    default:
        print("Unknown command: \(args[1])")
        print("Usage: PuntoTest [convert|track|sim|stress|bugs|all]")
    }
} else {
    print("Usage: PuntoTest [convert|track|sim|stress|bugs|all]")
    print("\nRunning all tests by default...\n")
    runConversionTests()
    runWordTrackingTests()
    runSimulation()
    runStressTest()
    runBugHunt()
}
