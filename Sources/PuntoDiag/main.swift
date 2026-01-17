#!/usr/bin/env swift
//
// PuntoDiag - Diagnostic tool for Punto
//
// Usage: swift run PuntoDiag [command]
//
// Commands:
//   all          - Run all diagnostics
//   permissions  - Check accessibility permissions
//   eventTap     - Test CGEvent tap creation
//   converter    - Test LayoutConverter
//   tracker      - Test WordTracker
//   hotkeys      - Interactive hotkey detection test
//   clipboard    - Test clipboard operations
//   accessibility - Test Accessibility API

import Foundation
import ApplicationServices
import AppKit

// MARK: - Colors

enum Color: String {
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[1;33m"
    case blue = "\u{001B}[0;34m"
    case reset = "\u{001B}[0m"
}

func color(_ text: String, _ c: Color) -> String {
    return "\(c.rawValue)\(text)\(Color.reset.rawValue)"
}

func printSuccess(_ msg: String) { print(color("✓ \(msg)", .green)) }
func printError(_ msg: String) { print(color("✗ \(msg)", .red)) }
func printWarning(_ msg: String) { print(color("⚠ \(msg)", .yellow)) }
func printHeader(_ msg: String) {
    print("")
    print(color("═══════════════════════════════════════════════════", .blue))
    print(color("  \(msg)", .blue))
    print(color("═══════════════════════════════════════════════════", .blue))
}

// MARK: - LayoutConverter (Copy for testing)

final class LayoutConverter {
    private let enToRu: [Character: Character] = [
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
        "@": "\"", "#": "№", "$": ";", "^": ":", "&": "?"
    ]

    private var ruToEn: [Character: Character] = [:]

    init() {
        for (en, ru) in enToRu { ruToEn[ru] = en }
        ruToEn["№"] = "#"
    }

    func convert(_ text: String) -> String {
        let layout = detectLayout(text)
        switch layout {
        case .english: return convertToRussian(text)
        case .russian: return convertToEnglish(text)
        case .mixed, .unknown: return convertBasedOnMajority(text)
        }
    }

    func convertToRussian(_ text: String) -> String {
        return String(text.map { enToRu[$0] ?? $0 })
    }

    func convertToEnglish(_ text: String) -> String {
        return String(text.map { ruToEn[$0] ?? $0 })
    }

    enum DetectedLayout: String { case english, russian, mixed, unknown }

    func detectLayout(_ text: String) -> DetectedLayout {
        var en = 0, ru = 0
        for char in text {
            let s = char.unicodeScalars.first!.value
            if (s >= 0x41 && s <= 0x5A) || (s >= 0x61 && s <= 0x7A) { en += 1 }
            else if (s >= 0x410 && s <= 0x44F) || s == 0x401 || s == 0x451 { ru += 1 }
        }
        let total = en + ru
        if total == 0 { return .unknown }
        let ratio = Double(en) / Double(total)
        if ratio > 0.8 { return .english }
        if ratio < 0.2 { return .russian }
        return .mixed
    }

    private func convertBasedOnMajority(_ text: String) -> String {
        var enToRuCount = 0, ruToEnCount = 0
        for char in text {
            if enToRu[char] != nil { enToRuCount += 1 }
            if ruToEn[char] != nil { ruToEnCount += 1 }
        }
        return enToRuCount >= ruToEnCount ? convertToRussian(text) : convertToEnglish(text)
    }
}

// MARK: - WordTracker (Copy for testing)

final class WordTracker {
    private let maxSize: Int
    private var buffer: [Character]
    private var head: Int = 0
    private var count: Int = 0

    private let wordBoundaries: Set<Character> = [
        " ", "\n", "\t", "\r", ".", ",", "!", "?", ";", ":",
        "(", ")", "[", "]", "{", "}", "\"", "'", "`",
        "/", "\\", "|", "<", ">", "@", "#", "$", "%", "^", "&", "*",
        "+", "=", "-", "_", "~"
    ]

    init(maxSize: Int = 50) {
        self.maxSize = maxSize
        self.buffer = [Character](repeating: " ", count: maxSize)
    }

    func trackKeyPress(keyCode: UInt16, characters: String?) {
        if keyCode == 51 { removeLastCharacter(); return }
        if [123, 124, 125, 126, 115, 119, 116, 121, 117].contains(keyCode) { clear(); return }
        guard let chars = characters, let firstChar = chars.first else { return }
        if keyCode == 49 || wordBoundaries.contains(firstChar) { clear(); return }
        addCharacter(firstChar)
    }

    func getLastWord() -> String? {
        guard count > 0 else { return nil }
        var result = [Character]()
        for i in 0..<count {
            let index = (head - count + i + maxSize) % maxSize
            result.append(buffer[index])
        }
        return String(result)
    }

    func clear() { count = 0 }

    private func addCharacter(_ char: Character) {
        buffer[head] = char
        head = (head + 1) % maxSize
        if count < maxSize { count += 1 }
    }

    private func removeLastCharacter() {
        guard count > 0 else { return }
        head = (head - 1 + maxSize) % maxSize
        count -= 1
    }
}

// MARK: - Diagnostic Commands

func testPermissions() {
    printHeader("Accessibility Permissions")

    let trusted = AXIsProcessTrusted()
    if trusted {
        printSuccess("Accessibility: GRANTED")
    } else {
        printError("Accessibility: NOT GRANTED")
        print("")
        print("  To fix:")
        print("  1. Open System Settings → Privacy & Security → Accessibility")
        print("  2. Add Punto.app (or PuntoDiag) to the list")
        print("  3. Make sure the checkbox is enabled")
    }
}

func testEventTap() {
    printHeader("CGEvent Tap Test")

    let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

    guard let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .listenOnly,
        eventsOfInterest: eventMask,
        callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
        userInfo: nil
    ) else {
        printError("Failed to create event tap!")
        print("  This usually means accessibility permissions are not granted")
        return
    }

    printSuccess("Event tap created successfully")
    CFMachPortInvalidate(tap)
}

func testConverter() {
    printHeader("LayoutConverter Tests")

    let converter = LayoutConverter()
    var passed = 0
    var failed = 0

    let tests: [(input: String, expected: String, description: String)] = [
        ("ghbdtn", "привет", "EN→RU: ghbdtn → привет"),
        ("привет", "ghbdtn", "RU→EN: привет → ghbdtn"),
        ("hello", "руддщ", "EN→RU: hello → руддщ"),
        ("руддщ", "hello", "RU→EN: руддщ → hello"),
        ("Ghbdtn", "Привет", "EN→RU with caps"),
        ("GHBDTN", "ПРИВЕТ", "EN→RU all caps"),
        ("123", "123", "Numbers unchanged"),
        ("hello world", "руддщ цщкдв", "EN→RU with space"),
        ("", "", "Empty string"),
        ("ghbdtn vbh", "привет мир", "EN→RU: ghbdtn vbh → привет мир"),
        ("ыекштп", "string", "RU→EN: ыекштп → string"),
    ]

    for test in tests {
        let result = converter.convert(test.input)
        if result == test.expected {
            printSuccess(test.description)
            passed += 1
        } else {
            printError("\(test.description)")
            print("    Expected: '\(test.expected)'")
            print("    Got:      '\(result)'")
            failed += 1
        }
    }

    print("")
    print("Layout detection:")
    let detectionTests: [(input: String, expected: LayoutConverter.DetectedLayout)] = [
        ("hello", .english),
        ("привет", .russian),
        ("hello привет", .mixed),
        ("12345", .unknown),
    ]

    for test in detectionTests {
        let result = converter.detectLayout(test.input)
        if result == test.expected {
            printSuccess("'\(test.input)' → \(result.rawValue)")
            passed += 1
        } else {
            printError("'\(test.input)' expected \(test.expected.rawValue), got \(result.rawValue)")
            failed += 1
        }
    }

    print("")
    print("Summary: \(passed) passed, \(failed) failed")
}

func testTracker() {
    printHeader("WordTracker Tests")

    var passed = 0
    var failed = 0

    // Test 1: Basic word tracking
    let tracker1 = WordTracker()
    tracker1.trackKeyPress(keyCode: 4, characters: "h")
    tracker1.trackKeyPress(keyCode: 14, characters: "e")
    tracker1.trackKeyPress(keyCode: 37, characters: "l")
    tracker1.trackKeyPress(keyCode: 37, characters: "l")
    tracker1.trackKeyPress(keyCode: 31, characters: "o")

    if tracker1.getLastWord() == "hello" {
        printSuccess("Basic word tracking: 'hello'")
        passed += 1
    } else {
        printError("Basic word tracking failed, got: '\(tracker1.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test 2: Backspace
    tracker1.trackKeyPress(keyCode: 51, characters: nil)
    if tracker1.getLastWord() == "hell" {
        printSuccess("Backspace removes last char: 'hell'")
        passed += 1
    } else {
        printError("Backspace failed, got: '\(tracker1.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test 3: Space clears
    tracker1.trackKeyPress(keyCode: 49, characters: " ")
    if tracker1.getLastWord() == nil {
        printSuccess("Space clears buffer")
        passed += 1
    } else {
        printError("Space should clear, got: '\(tracker1.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test 4: Cyrillic input
    let tracker2 = WordTracker()
    tracker2.trackKeyPress(keyCode: 35, characters: "п")
    tracker2.trackKeyPress(keyCode: 15, characters: "р")
    tracker2.trackKeyPress(keyCode: 34, characters: "и")
    tracker2.trackKeyPress(keyCode: 9, characters: "в")
    tracker2.trackKeyPress(keyCode: 14, characters: "е")
    tracker2.trackKeyPress(keyCode: 17, characters: "т")

    if tracker2.getLastWord() == "привет" {
        printSuccess("Cyrillic tracking: 'привет'")
        passed += 1
    } else {
        printError("Cyrillic tracking failed, got: '\(tracker2.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test 5: Punctuation clears
    let tracker3 = WordTracker()
    tracker3.trackKeyPress(keyCode: 4, characters: "t")
    tracker3.trackKeyPress(keyCode: 14, characters: "e")
    tracker3.trackKeyPress(keyCode: 1, characters: "s")
    tracker3.trackKeyPress(keyCode: 17, characters: "t")
    tracker3.trackKeyPress(keyCode: 47, characters: ".")

    if tracker3.getLastWord() == nil {
        printSuccess("Punctuation clears buffer")
        passed += 1
    } else {
        printError("Punctuation should clear, got: '\(tracker3.getLastWord() ?? "nil")'")
        failed += 1
    }

    print("")
    print("Summary: \(passed) passed, \(failed) failed")
}

func testHotkeysInteractive() {
    printHeader("Interactive Hotkey Detection")

    print("")
    print("This test will listen for keyboard events.")
    print("Press any keys to see them detected.")
    print("Press Ctrl+C to exit.")
    print("")
    print("Try these hotkeys:")
    print("  ⌥⇧⌘Space - Convert Layout")
    print("  ⌥⌘Z      - Toggle Case")
    print("")

    let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

    guard let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .listenOnly,
        eventsOfInterest: eventMask,
        callback: { (_, type, event, _) -> Unmanaged<CGEvent>? in
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags

            var mods = ""
            if flags.contains(.maskControl) { mods += "⌃" }
            if flags.contains(.maskAlternate) { mods += "⌥" }
            if flags.contains(.maskShift) { mods += "⇧" }
            if flags.contains(.maskCommand) { mods += "⌘" }

            let keyNames: [Int64: String] = [
                0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
                8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
                16: "Y", 17: "T", 49: "Space", 36: "Return", 51: "Delete", 53: "Escape"
            ]

            let keyName = keyNames[keyCode] ?? "key(\(keyCode))"
            print("Detected: \(mods)\(keyName) (keyCode=\(keyCode))")

            // Check for default hotkeys
            if flags.contains(.maskCommand) && flags.contains(.maskAlternate) {
                if flags.contains(.maskShift) && keyCode == 49 {
                    print(color("  → Convert Layout hotkey!", .green))
                }
                if !flags.contains(.maskShift) && keyCode == 6 {
                    print(color("  → Toggle Case hotkey!", .green))
                }
            }

            return Unmanaged.passUnretained(event)
        },
        userInfo: nil
    ) else {
        printError("Failed to create event tap!")
        return
    }

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    printSuccess("Listening for keyboard events...")
    CFRunLoopRun()
}

func testClipboard() {
    printHeader("Clipboard Tests")

    let pasteboard = NSPasteboard.general

    // Save current contents
    let original = pasteboard.string(forType: .string)

    // Test write
    let testString = "Punto test: привет hello 123"
    pasteboard.clearContents()
    pasteboard.setString(testString, forType: .string)

    // Test read
    if let read = pasteboard.string(forType: .string), read == testString {
        printSuccess("Write and read: '\(testString)'")
    } else {
        printError("Clipboard write/read failed")
    }

    // Restore original
    pasteboard.clearContents()
    if let orig = original {
        pasteboard.setString(orig, forType: .string)
        printSuccess("Restored original clipboard contents")
    }
}

func testAccessibility() {
    printHeader("Accessibility API Test")

    let systemWide = AXUIElementCreateSystemWide()

    var focusedApp: AnyObject?
    let result = AXUIElementCopyAttributeValue(
        systemWide,
        kAXFocusedApplicationAttribute as CFString,
        &focusedApp
    )

    if result == .success {
        printSuccess("Can get focused application")

        // Try to get focused element
        let appElement = focusedApp as! AXUIElement
        var focusedElement: AnyObject?
        let elementResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        if elementResult == .success {
            printSuccess("Can get focused UI element")

            // Try to get selected text
            let element = focusedElement as! AXUIElement
            var selectedText: AnyObject?
            let textResult = AXUIElementCopyAttributeValue(
                element,
                kAXSelectedTextAttribute as CFString,
                &selectedText
            )

            if textResult == .success {
                if let text = selectedText as? String {
                    printSuccess("Can read selected text: '\(text)'")
                } else {
                    printWarning("Selected text is empty or nil")
                }
            } else {
                printWarning("Cannot read selected text (error: \(textResult.rawValue))")
                print("  This is normal if no text is selected")
            }
        } else {
            printWarning("Cannot get focused element (error: \(elementResult.rawValue))")
        }
    } else {
        printError("Cannot get focused application (error: \(result.rawValue))")
        print("  Make sure accessibility permissions are granted")
    }
}

func runAll() {
    testPermissions()
    testEventTap()
    testConverter()
    testTracker()
    testClipboard()
    testAccessibility()

    printHeader("Summary")
    print("All diagnostic tests completed.")
    print("Run './Scripts/debug.sh run' to test the full app with logging.")
}

// MARK: - Main

let args = CommandLine.arguments
let command = args.count > 1 ? args[1] : "all"

switch command {
case "all":
    runAll()
case "permissions", "perm":
    testPermissions()
case "eventTap", "tap":
    testEventTap()
case "converter", "conv":
    testConverter()
case "tracker", "track":
    testTracker()
case "hotkeys", "hk":
    testHotkeysInteractive()
case "clipboard", "clip":
    testClipboard()
case "accessibility", "ax":
    testAccessibility()
case "help", "-h", "--help":
    print("PuntoDiag - Diagnostic tool for Punto")
    print("")
    print("Usage: swift run PuntoDiag [command]")
    print("")
    print("Commands:")
    print("  all           Run all diagnostics (default)")
    print("  permissions   Check accessibility permissions")
    print("  eventTap      Test CGEvent tap creation")
    print("  converter     Test LayoutConverter")
    print("  tracker       Test WordTracker")
    print("  hotkeys       Interactive hotkey detection")
    print("  clipboard     Test clipboard operations")
    print("  accessibility Test Accessibility API")
    print("  help          Show this help")
default:
    print("Unknown command: \(command)")
    print("Run 'swift run PuntoDiag help' for usage")
    exit(1)
}
