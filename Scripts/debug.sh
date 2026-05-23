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

    ./Scripts/test-cycle.sh 1
}

# Command: components
cmd_components() {
    print_header "Testing Individual Components"

    cd "$PROJECT_DIR"

    swift run PuntoCoreTest
    swift run PuntoDiag converter
    swift run PuntoDiag tracker
    swift run PuntoDiag autocorrect
    swift run PuntoDiag clipboard
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
