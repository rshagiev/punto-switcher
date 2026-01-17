#!/bin/bash

# Debug and diagnostic script for Punto
# Usage: ./Scripts/debug.sh [command]
#
# Commands:
#   test        - Run all unit tests
#   permissions - Check accessibility permissions
#   run         - Run app with verbose logging
#   logs        - Show recent logs
#   diagnose    - Full diagnostic report
#   components  - Test individual components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_BUNDLE="$PROJECT_DIR/Release/Punto.app"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "  $1"
}

# Check if app is built
check_app_built() {
    if [ ! -d "$APP_BUNDLE" ]; then
        print_error "App not built. Run ./Scripts/build.sh first"
        exit 1
    fi
}

# Command: permissions
cmd_permissions() {
    print_header "Checking Accessibility Permissions"

    # Check if tccutil can show us anything
    echo "Current accessibility status:"

    # Try to create a test event tap
    swift - << 'EOF'
import ApplicationServices
import Foundation

let trusted = AXIsProcessTrusted()
if trusted {
    print("✓ Accessibility: GRANTED")
} else {
    print("✗ Accessibility: NOT GRANTED")
    print("")
    print("To fix:")
    print("1. Open System Settings → Privacy & Security → Accessibility")
    print("2. Add Punto.app to the list")
    print("3. Make sure the checkbox is enabled")
    print("4. If already added, remove and re-add after rebuilding")
}

// Try to create an event tap to verify
let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
if let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .listenOnly,
    eventsOfInterest: eventMask,
    callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
    userInfo: nil
) {
    print("✓ Event Tap: CAN CREATE")
    CFMachPortInvalidate(tap)
} else {
    print("✗ Event Tap: CANNOT CREATE")
    print("  This usually means accessibility permissions are not granted")
}
EOF
}

# Command: test
cmd_test() {
    print_header "Running Unit Tests"

    cd "$PROJECT_DIR"

    # Build and run tests
    swift test 2>&1 || {
        print_warning "Swift test target not configured. Running inline tests..."
        cmd_components
    }
}

# Command: components
cmd_components() {
    print_header "Testing Individual Components"

    cd "$PROJECT_DIR"

    swift - << 'EOF'
import Foundation

// ==================== LayoutConverter Tests ====================

print("\n--- LayoutConverter Tests ---\n")

// Inline LayoutConverter for testing
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
        for (en, ru) in enToRu {
            ruToEn[ru] = en
        }
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

    enum DetectedLayout { case english, russian, mixed, unknown }

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

let converter = LayoutConverter()

// Test cases
let tests: [(input: String, expected: String, description: String)] = [
    ("ghbdtn", "привет", "EN→RU: ghbdtn → привет"),
    ("привет", "ghbdtn", "RU→EN: привет → ghbdtn"),
    ("hello", "руддщ", "EN→RU: hello → руддщ"),
    ("руддщ", "hello", "RU→EN: руддщ → hello"),
    ("Ghbdtn", "Привет", "EN→RU with caps: Ghbdtn → Привет"),
    ("GHBDTN", "ПРИВЕТ", "EN→RU all caps: GHBDTN → ПРИВЕТ"),
    ("123", "123", "Numbers unchanged"),
    ("hello world", "руддщ цщкдв", "EN→RU with space"),
    ("", "", "Empty string"),
]

var passed = 0
var failed = 0

for test in tests {
    let result = converter.convert(test.input)
    if result == test.expected {
        print("✓ \(test.description)")
        passed += 1
    } else {
        print("✗ \(test.description)")
        print("  Expected: '\(test.expected)'")
        print("  Got:      '\(result)'")
        failed += 1
    }
}

print("\nLayout detection tests:")
let detectionTests: [(input: String, expected: LayoutConverter.DetectedLayout)] = [
    ("hello", .english),
    ("привет", .russian),
    ("hello привет", .mixed),
    ("12345", .unknown),
]

for test in detectionTests {
    let result = converter.detectLayout(test.input)
    if result == test.expected {
        print("✓ '\(test.input)' detected as \(result)")
        passed += 1
    } else {
        print("✗ '\(test.input)' expected \(test.expected), got \(result)")
        failed += 1
    }
}

// ==================== WordTracker Tests ====================

print("\n--- WordTracker Tests ---\n")

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

    private let deleteKeyCode: UInt16 = 51
    private let spaceKeyCode: UInt16 = 49
    private let navigationKeyCodes: Set<UInt16> = [123, 124, 125, 126, 115, 119, 116, 121, 117]

    init(maxSize: Int = 50) {
        self.maxSize = maxSize
        self.buffer = [Character](repeating: " ", count: maxSize)
    }

    func trackKeyPress(keyCode: UInt16, characters: String?) {
        if keyCode == deleteKeyCode { removeLastCharacter(); return }
        if navigationKeyCodes.contains(keyCode) { clear(); return }
        guard let chars = characters, let firstChar = chars.first else { return }
        if keyCode == spaceKeyCode || wordBoundaries.contains(firstChar) { clear(); return }
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

let tracker = WordTracker()

// Test basic tracking
tracker.trackKeyPress(keyCode: 4, characters: "h")  // h
tracker.trackKeyPress(keyCode: 14, characters: "e") // e
tracker.trackKeyPress(keyCode: 37, characters: "l") // l
tracker.trackKeyPress(keyCode: 37, characters: "l") // l
tracker.trackKeyPress(keyCode: 31, characters: "o") // o

if tracker.getLastWord() == "hello" {
    print("✓ Basic word tracking: 'hello'")
    passed += 1
} else {
    print("✗ Basic word tracking failed, got: '\(tracker.getLastWord() ?? "nil")'")
    failed += 1
}

// Test backspace
tracker.trackKeyPress(keyCode: 51, characters: nil) // delete
if tracker.getLastWord() == "hell" {
    print("✓ Backspace removes last char: 'hell'")
    passed += 1
} else {
    print("✗ Backspace failed, got: '\(tracker.getLastWord() ?? "nil")'")
    failed += 1
}

// Test space clears
tracker.trackKeyPress(keyCode: 49, characters: " ")
if tracker.getLastWord() == nil {
    print("✓ Space clears buffer")
    passed += 1
} else {
    print("✗ Space should clear, got: '\(tracker.getLastWord() ?? "nil")'")
    failed += 1
}

// ==================== Summary ====================

print("\n" + String(repeating: "=", count: 50))
print("SUMMARY: \(passed) passed, \(failed) failed")
if failed == 0 {
    print("All tests passed! ✓")
} else {
    print("Some tests failed! ✗")
    exit(1)
}
EOF
}

# Command: run
cmd_run() {
    print_header "Running Punto with Verbose Logging"

    check_app_built

    # Kill existing instance
    pkill -f "Punto.app" 2>/dev/null || true
    sleep 0.5

    print_info "Starting Punto..."
    print_info "Press Ctrl+C to stop"
    print_info ""

    # Run with logging
    "$APP_BUNDLE/Contents/MacOS/Punto" 2>&1 | while read line; do
        if [[ "$line" == *"error"* ]] || [[ "$line" == *"Error"* ]] || [[ "$line" == *"failed"* ]] || [[ "$line" == *"Failed"* ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ "$line" == *"success"* ]] || [[ "$line" == *"Success"* ]] || [[ "$line" == *"granted"* ]] || [[ "$line" == *"matched"* ]]; then
            echo -e "${GREEN}$line${NC}"
        elif [[ "$line" == *"warning"* ]] || [[ "$line" == *"Warning"* ]]; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo "$line"
        fi
    done
}

# Command: diagnose
cmd_diagnose() {
    print_header "Full Diagnostic Report"

    echo ""
    echo "System Info:"
    echo "  macOS: $(sw_vers -productVersion)"
    echo "  Arch:  $(uname -m)"
    echo ""

    echo "Build Status:"
    if [ -d "$APP_BUNDLE" ]; then
        print_success "App bundle exists: $APP_BUNDLE"
        echo "  Binary: $(file "$APP_BUNDLE/Contents/MacOS/Punto" | cut -d: -f2)"
    else
        print_error "App bundle not found"
    fi
    echo ""

    echo "Process Status:"
    if pgrep -f "Punto.app" > /dev/null; then
        print_success "Punto is running (PID: $(pgrep -f 'Punto.app'))"
    else
        print_warning "Punto is not running"
    fi
    echo ""

    cmd_permissions

    echo ""
    print_header "Running Component Tests"
    cmd_components
}

# Command: logs
cmd_logs() {
    print_header "Recent Punto Logs"

    # Check Console for recent logs
    log show --predicate 'process == "Punto"' --last 5m 2>/dev/null || {
        print_warning "No system logs found. Run with ./Scripts/debug.sh run to see live output"
    }
}

# Command: build-test
cmd_build_test() {
    print_header "Build and Test"

    cd "$PROJECT_DIR"

    echo "Building..."
    swift build -c release 2>&1

    echo ""
    echo "Running build.sh..."
    ./Scripts/build.sh

    echo ""
    cmd_components

    echo ""
    cmd_permissions
}

# Command: hotkey-test
cmd_hotkey_test() {
    print_header "Hotkey Detection Test"

    swift - << 'EOF'
import Foundation
import ApplicationServices

print("Testing CGEvent tap creation...")

let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

var eventCount = 0

guard let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .listenOnly,  // Listen only, don't block
    eventsOfInterest: eventMask,
    callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        let hasCmd = flags.contains(.maskCommand)
        let hasOpt = flags.contains(.maskAlternate)
        let hasShift = flags.contains(.maskShift)
        let hasCtrl = flags.contains(.maskControl)

        var mods = ""
        if hasCtrl { mods += "⌃" }
        if hasOpt { mods += "⌥" }
        if hasShift { mods += "⇧" }
        if hasCmd { mods += "⌘" }

        print("Key pressed: keyCode=\(keyCode) modifiers=\(mods.isEmpty ? "none" : mods)")

        return Unmanaged.passUnretained(event)
    },
    userInfo: nil
) else {
    print("✗ Failed to create event tap!")
    print("  Make sure Accessibility permissions are granted")
    exit(1)
}

print("✓ Event tap created successfully")
print("")
print("Press any keys to test detection (Ctrl+C to exit)...")
print("Try pressing: ⌥⇧⌘Space (Convert Layout) or ⌥⌘Z (Toggle Case)")
print("")

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

CFRunLoopRun()
EOF
}

# Main
case "${1:-help}" in
    test)
        cmd_test
        ;;
    permissions|perm)
        cmd_permissions
        ;;
    run)
        cmd_run
        ;;
    logs)
        cmd_logs
        ;;
    diagnose|diag)
        cmd_diagnose
        ;;
    components|comp)
        cmd_components
        ;;
    build-test|bt)
        cmd_build_test
        ;;
    hotkey-test|ht)
        cmd_hotkey_test
        ;;
    help|*)
        echo "Punto Debug Tool"
        echo ""
        echo "Usage: ./Scripts/debug.sh [command]"
        echo ""
        echo "Commands:"
        echo "  test, t          Run all unit tests"
        echo "  permissions, perm  Check accessibility permissions"
        echo "  run              Run app with verbose logging"
        echo "  logs             Show recent system logs"
        echo "  diagnose, diag   Full diagnostic report"
        echo "  components, comp Test individual components"
        echo "  build-test, bt   Build and run all tests"
        echo "  hotkey-test, ht  Interactive hotkey detection test"
        echo "  help             Show this help"
        ;;
esac
