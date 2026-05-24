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
import PuntoCore
import PuntoRuntime

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

// MARK: - Diagnostic Commands

struct AutoCorrectionHarnessCase {
    let name: String
    let typedText: String
    let expectedText: String
}

func simulateAutoCorrectionTyping(
    _ text: String,
    rules: [AutoCorrectionRule]
) -> (finalText: String, corrections: [String], undoRecords: [ConversionRecord]) {
    let engine = AutoCorrectionEngine(rules: rules)
    let session = ConversionSession()
    var finalText = ""
    var currentWord = ""
    var corrections: [String] = []
    var undoRecords: [ConversionRecord] = []

    for character in text {
        finalText.append(character)

        let isSeparator = character == " "
            || character == "\n"
            || character == "\t"
            || character == "\r"

        if isSeparator {
            if let decision = engine.correction(for: currentWord) {
                let original = decision.original + String(character)
                let replacement = decision.replacement + String(character)
                finalText.removeLast(original.count)
                finalText.append(replacement)
                session.record(
                    originalText: original,
                    convertedText: replacement,
                    replacementMethod: .keyboardBackspacePaste,
                    origin: .autoCorrection(rule: decision.rule)
                )
                if let record = session.undoCandidate() {
                    undoRecords.append(record)
                }
                corrections.append("\(decision.original)->\(decision.replacement)")
            }
            currentWord = ""
        } else {
            currentWord.append(character)
        }
    }

    return (finalText, corrections, undoRecords)
}

func testAutoCorrectionHarness() {
    printHeader("Auto-correction Runtime Harness")

    let rules = AutoCorrectionStarterCatalog.rules

    let issues = AutoCorrectionRuleCatalog.validationIssues(for: rules)
    if issues.isEmpty {
        printSuccess("Rule catalog validation passed")
    } else {
        printError("Rule catalog validation found \(issues.count) issue(s)")
        for issue in issues {
            print("  row \(issue.ruleIndex + 1): \(issue.severity.rawValue) \(issue.message)")
        }
        return
    }

    let cases = [
        AutoCorrectionHarnessCase(
            name: "wrong-layout typed word",
            typedText: "ghbdtn ",
            expectedText: "привет "
        ),
        AutoCorrectionHarnessCase(
            name: "preserve title case",
            typedText: "Teh quick test",
            expectedText: "The quick test"
        ),
        AutoCorrectionHarnessCase(
            name: "multiple corrections",
            typedText: "teh cat adn dog ",
            expectedText: "the cat and dog "
        ),
        AutoCorrectionHarnessCase(
            name: "starter wrong-layout common word",
            typedText: "cgfcb,j ",
            expectedText: "спасибо "
        ),
        AutoCorrectionHarnessCase(
            name: "newline separator",
            typedText: "TEH\nnext",
            expectedText: "THE\nnext"
        )
    ]

    var failures = 0
    for testCase in cases {
        let result = simulateAutoCorrectionTyping(testCase.typedText, rules: rules)
        if result.finalText == testCase.expectedText {
            printSuccess("\(testCase.name): '\(testCase.typedText)' -> '\(result.finalText)'")
            if result.corrections.isEmpty {
                printWarning("  no corrections recorded")
            } else {
                print("  corrections: \(result.corrections.joined(separator: ", "))")
            }
            if result.undoRecords.count != result.corrections.count {
                printWarning("  undo records \(result.undoRecords.count) != corrections \(result.corrections.count)")
            }
        } else {
            failures += 1
            printError("\(testCase.name): expected '\(testCase.expectedText)', got '\(result.finalText)'")
        }
    }

    let filtered = AutoCorrectionRuleCatalog.filteredRuleIndexes(in: rules, query: "the")
    if filtered.contains(where: { rules[$0].replacement == "the" }) {
        printSuccess("Rule search returned an expected rule for 'the'")
    } else {
        failures += 1
        printError("Rule search did not return the 'the' replacement, got \(filtered)")
    }

    if failures == 0 {
        printSuccess("Auto-correction harness passed")
    } else {
        printError("Auto-correction harness failed: \(failures) failure(s)")
        exit(1)
    }
}

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
            printSuccess("'\(test.input)' → \(result)")
            passed += 1
        } else {
            printError("'\(test.input)' expected \(test.expected), got \(result)")
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

    // Test 5: Punctuation that maps through the keyboard layout should NOT clear buffer
    // Period (.) maps to ю, slash (/) maps to period, etc.
    let tracker3 = WordTracker()
    tracker3.trackKeyPress(keyCode: 4, characters: "t")
    tracker3.trackKeyPress(keyCode: 14, characters: "e")
    tracker3.trackKeyPress(keyCode: 1, characters: "s")
    tracker3.trackKeyPress(keyCode: 17, characters: "t")
    tracker3.trackKeyPress(keyCode: 47, characters: ".")  // Period - should NOT clear (maps to ю)

    if tracker3.getLastWord() == "test." {
        printSuccess("Period does NOT clear buffer (maps to ю): 'test.'")
        passed += 1
    } else {
        printError("Period should NOT clear, got: '\(tracker3.getLastWord() ?? "nil")'")
        failed += 1
    }

    let slashTracker = WordTracker()
    for char in "test/" {
        slashTracker.trackKeyPress(keyCode: 0, characters: String(char))
    }

    if slashTracker.getLastWord() == "test/" {
        printSuccess("Slash does NOT clear buffer (maps to period): 'test/'")
        passed += 1
    } else {
        printError("Slash should NOT clear, got: '\(slashTracker.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test 6: Navigation keys clear buffer
    let tracker4 = WordTracker()
    tracker4.trackKeyPress(keyCode: 4, characters: "t")
    tracker4.trackKeyPress(keyCode: 14, characters: "e")
    tracker4.trackKeyPress(keyCode: 1, characters: "s")
    tracker4.trackKeyPress(keyCode: 17, characters: "t")
    tracker4.trackKeyPress(keyCode: 123, characters: nil)  // Left arrow

    if tracker4.getLastWord() == nil {
        printSuccess("Navigation key (Left arrow) clears buffer")
        passed += 1
    } else {
        printError("Navigation should clear, got: '\(tracker4.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test 7: Return/Enter clears buffer
    let tracker5 = WordTracker()
    tracker5.trackKeyPress(keyCode: 4, characters: "t")
    tracker5.trackKeyPress(keyCode: 14, characters: "e")
    tracker5.trackKeyPress(keyCode: 1, characters: "s")
    tracker5.trackKeyPress(keyCode: 17, characters: "t")
    tracker5.trackKeyPress(keyCode: 36, characters: "\n")  // Return

    if tracker5.getLastWord() == nil {
        printSuccess("Return key clears buffer")
        passed += 1
    } else {
        printError("Return should clear, got: '\(tracker5.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test 8: Mixed layout detection - should return nil
    let tracker6 = WordTracker()
    tracker6.trackKeyPress(keyCode: 4, characters: "h")
    tracker6.trackKeyPress(keyCode: 14, characters: "e")
    tracker6.trackKeyPress(keyCode: 35, characters: "п")  // Russian п
    tracker6.trackKeyPress(keyCode: 31, characters: "o")

    if tracker6.getLastWord() == nil {
        printSuccess("Mixed layout (heпo) returns nil")
        passed += 1
    } else {
        printError("Mixed layout should return nil, got: '\(tracker6.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test 9: Clear method works
    let tracker7 = WordTracker()
    tracker7.trackKeyPress(keyCode: 4, characters: "t")
    tracker7.trackKeyPress(keyCode: 14, characters: "e")
    tracker7.trackKeyPress(keyCode: 1, characters: "s")
    tracker7.trackKeyPress(keyCode: 17, characters: "t")
    tracker7.clear()

    if tracker7.getLastWord() == nil {
        printSuccess("Manual clear() works")
        passed += 1
    } else {
        printError("Clear should empty buffer, got: '\(tracker7.getLastWord() ?? "nil")'")
        failed += 1
    }

    // Test 10: Pure punctuation word boundaries
    let tracker8 = WordTracker()
    tracker8.trackKeyPress(keyCode: 4, characters: "t")
    tracker8.trackKeyPress(keyCode: 14, characters: "e")
    tracker8.trackKeyPress(keyCode: 1, characters: "s")
    tracker8.trackKeyPress(keyCode: 17, characters: "t")
    tracker8.trackKeyPress(keyCode: 0, characters: "!")  // Exclamation - word boundary

    if tracker8.getLastWord() == nil {
        printSuccess("Exclamation mark clears buffer (word boundary)")
        passed += 1
    } else {
        printError("Exclamation should clear, got: '\(tracker8.getLastWord() ?? "nil")'")
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

    let snapshot = PasteboardSnapshot(pasteboard)
    defer {
        snapshot.restore(to: pasteboard)
        printSuccess("Restored original clipboard snapshot")
    }

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

    // Test multi-item, multi-type snapshot restoration. This matches the runtime
    // clipboard contract used around Cmd+C/Cmd+V fallbacks.
    let richItem = NSPasteboardItem()
    richItem.setString("plain text", forType: .string)
    richItem.setData(Data("<b>rich text</b>".utf8), forType: .html)

    let fileItem = NSPasteboardItem()
    fileItem.setString("file:///tmp/punto-test.txt", forType: .fileURL)

    pasteboard.clearContents()
    pasteboard.writeObjects([richItem, fileItem])
    let richSnapshot = PasteboardSnapshot(pasteboard)

    pasteboard.clearContents()
    pasteboard.setString("replacement", forType: .string)
    richSnapshot.restore(to: pasteboard)

    let restoredItems = pasteboard.pasteboardItems ?? []
    let restoredPlain = restoredItems.first?.string(forType: .string)
    let restoredHTML = restoredItems.first?.data(forType: .html)
    let restoredFileURL = restoredItems.dropFirst().first?.string(forType: .fileURL)

    if restoredItems.count == 2,
       restoredPlain == "plain text",
       restoredHTML == Data("<b>rich text</b>".utf8),
       restoredFileURL == "file:///tmp/punto-test.txt" {
        printSuccess("Full pasteboard snapshot restores multiple items and types")
    } else {
        printError("Full pasteboard snapshot restore failed")
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
    testAutoCorrectionHarness()

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
case "autocorrect", "ac":
    testAutoCorrectionHarness()
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
    print("  autocorrect   Test auto-correction rule runtime harness")
    print("  help          Show this help")
default:
    print("Unknown command: \(command)")
    print("Run 'swift run PuntoDiag help' for usage")
    exit(1)
}
