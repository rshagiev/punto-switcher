#!/bin/bash
# Full automated integration test for terminal support in Punto
# Uses key codes instead of keystroke for proper WordTracker capture
# Usage: ./Scripts/test-terminal.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() { echo -e "\n${YELLOW}=== $1 ===${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "  $1"; }
pass_test() { TESTS_PASSED=$((TESTS_PASSED + 1)); }
fail_test() { TESTS_FAILED=$((TESTS_FAILED + 1)); }
tail_for_last_word() {
    case "$1" in
        world) echo "hello world" ;;
        цщкдв) echo "руддщ цщкдв" ;;
        *) echo "hello $1" ;;
    esac
}

TESTS_PASSED=0
TESTS_FAILED=0
HARNESS_WINDOW_OPENED=0
cleanup() {
    if [ "$HARNESS_WINDOW_OPENED" -eq 1 ]; then
        osascript << 'EOF' >/dev/null 2>&1 || true
tell application "Ghostty" to activate
delay 0.1
tell application "System Events"
    tell process "Ghostty"
        try
            click menu item "Close Window" of menu "File" of menu bar 1
        end try
    end tell
end tell
EOF
    fi
}
trap cleanup EXIT

# Key codes reference:
# h=4 e=14 l=37 o=31 w=13 r=15 d=2 t=17 s=1 space=49

print_header "Step 1: Build and deploy Punto"
"$(dirname "$0")/deploy.sh"
sleep 1
print_success "Punto deployed and started"

print_header "Step 2: Switch to English keyboard layout"

# Switch to English layout using Punto's input source manager or system
# Try Ctrl+Space which is common shortcut, or use select input source
osascript << 'EOF'
tell application "System Events"
    -- Try to select ABC/US English input source
    tell process "SystemUIServer"
        try
            tell (menu bar item 1 of menu bar 1 whose description contains "input")
                click
                delay 0.2
                click menu item "ABC" of menu 1
            end tell
        end try
    end tell
end tell
EOF
sleep 0.3
print_success "Attempted to switch to English layout"

print_header "Step 3: Open new Ghostty window"

osascript << 'EOF'
tell application "Ghostty" to activate
delay 0.5
tell application "System Events"
    tell process "Ghostty"
        click menu item "New Window" of menu "File" of menu bar 1
    end tell
end tell
delay 0.5
EOF

print_success "Ghostty window opened"
HARNESS_WINDOW_OPENED=1

# ============================================
# TEST 1: Last word conversion (no selection)
# ============================================

print_header "TEST 1: Last word conversion (no selection)"

# Check current input source
CURRENT_LAYOUT=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null | grep "KeyboardLayout Name" | head -1 || echo "unknown")
print_info "Current layout: $CURRENT_LAYOUT"

if [[ "$CURRENT_LAYOUT" != *"ABC"* ]] && [[ "$CURRENT_LAYOUT" != *"U.S."* ]]; then
    print_info "WARNING: Layout may not be English. Test expects QWERTY layout."
    print_info "Please switch to English (ABC) layout manually if tests fail."
fi

> /tmp/punto.log
print_info "Logs cleared"

print_info "Typing 'hello world test' using key codes..."

osascript << 'EOF'
tell application "System Events"
    -- h e l l o
    key code 4
    delay 0.03
    key code 14
    delay 0.03
    key code 37
    delay 0.03
    key code 37
    delay 0.03
    key code 31
    delay 0.03
    -- space
    key code 49
    delay 0.03
    -- w o r l d
    key code 13
    delay 0.03
    key code 31
    delay 0.03
    key code 15
    delay 0.03
    key code 37
    delay 0.03
    key code 2
    delay 0.03
    -- space
    key code 49
    delay 0.03
    -- t e s t
    key code 17
    delay 0.03
    key code 14
    delay 0.03
    key code 1
    delay 0.03
    key code 17
    delay 0.1
end tell
EOF

sleep 0.3

# Verify WordTracker has something (layout-agnostic check)
# With English: 'test', with Russian: 'еуые' (same key codes)
LAST_BUFFER=$(grep "buffer now" /tmp/punto.log | tail -1 | sed "s/.*buffer now '\\(.*\\)'/\\1/")
if [ -n "$LAST_BUFFER" ]; then
    print_success "WordTracker captured: '$LAST_BUFFER'"
else
    print_error "WordTracker buffer check failed"
    grep "WordTracker" /tmp/punto.log | tail -3
fi

print_info "Triggering Cmd+Opt+Shift hotkey..."

osascript << 'EOF'
tell application "System Events"
    key down {command, option, shift}
    delay 0.15
    key up {command, option, shift}
end tell
EOF

sleep 0.5

# Check for any conversion (layout-agnostic)
# With English layout: 'test', with Russian layout: 'еу|ые'
if grep -q "Converting last word:" /tmp/punto.log; then
    CONVERTED_WORD=$(grep "Converting last word:" /tmp/punto.log | tail -1 | sed "s/.*Converting last word: '\\(.*\\)'/\\1/")
    print_success "TEST 1 PASSED: Last word converted"
    print_info "Converted: '$CONVERTED_WORD'"
    pass_test
else
    print_error "TEST 1 FAILED: No conversion happened"
    grep -E "Converting|No text" /tmp/punto.log | tail -3
    fail_test
fi

# ============================================
# TEST 2: Dirty clipboard without selection
# ============================================

print_header "TEST 2: Dirty clipboard without selection"
print_info "Reusing the same Ghostty window and clearing screen"

osascript << 'EOF'
tell application "Ghostty" to activate
delay 0.2
tell application "System Events"
    key code 53
    delay 0.1
    keystroke "clear"
    delay 0.1
    key code 36
    delay 0.5
end tell
EOF

> /tmp/punto.log
print_info "Logs cleared"

print_info "Typing 'hello world' using key codes..."

osascript << 'EOF'
tell application "System Events"
    -- h e l l o space w o r l d
    key code 4
    delay 0.03
    key code 14
    delay 0.03
    key code 37
    delay 0.03
    key code 37
    delay 0.03
    key code 31
    delay 0.03
    key code 49
    delay 0.03
    key code 13
    delay 0.03
    key code 31
    delay 0.03
    key code 15
    delay 0.03
    key code 37
    delay 0.03
    key code 2
    delay 0.1
end tell
EOF

sleep 0.2

LAST_WORD=$(grep "buffer now" /tmp/punto.log | tail -1 | sed "s/.*buffer now '\\(.*\\)'/\\1/")
EXPECTED_TAIL=$(tail_for_last_word "$LAST_WORD")
print_info "Detected tracked word '$LAST_WORD', expected typed tail '$EXPECTED_TAIL'"

# Verify that prompt-prefixed/stale clipboard content is rejected when there is
# no real selection. This catches the failure mode that can delete too much text.
printf "user@host %% %s" "$EXPECTED_TAIL" | pbcopy
print_info "Seeded dirty clipboard tail: 'user@host % $EXPECTED_TAIL'"

print_info "Triggering Cmd+Opt+Shift hotkey with dirty clipboard..."

osascript << 'EOF'
tell application "System Events"
    key down {command, option, shift}
    delay 0.15
    key up {command, option, shift}
end tell
EOF

sleep 0.5

if grep -q "Converting captured text" /tmp/punto.log; then
    print_error "TEST 2 FAILED: Dirty clipboard was accepted as terminal selection"
    grep -E "Converting captured text|getPassiveClipboardTailSelection" /tmp/punto.log | tail -5
    fail_test
else
    if grep -q "Converting last word:" /tmp/punto.log; then
        print_success "TEST 2 PASSED: Dirty clipboard rejected, fell back to last word"
        pass_test
    else
        print_error "TEST 2 FAILED: Dirty clipboard rejected but no last-word fallback happened"
        grep -E "Converting|No text|clipboard" /tmp/punto.log | tail -8
        fail_test
    fi
fi

print_header "TEST 3: AX terminal selection extracts typed tail"
print_info "Reusing the same Ghostty window and clearing screen"

osascript << 'EOF'
tell application "Ghostty" to activate
delay 0.2
tell application "System Events"
    key code 53
    delay 0.1
    keystroke "clear"
    delay 0.1
    key code 36
    delay 0.5
end tell
EOF

> /tmp/punto.log
print_info "Logs cleared"

print_info "Typing 'hello world' using key codes..."

osascript << 'EOF'
tell application "System Events"
    -- h e l l o space w o r l d
    key code 4
    delay 0.03
    key code 14
    delay 0.03
    key code 37
    delay 0.03
    key code 37
    delay 0.03
    key code 31
    delay 0.03
    key code 49
    delay 0.03
    key code 13
    delay 0.03
    key code 31
    delay 0.03
    key code 15
    delay 0.03
    key code 37
    delay 0.03
    key code 2
    delay 0.1
end tell
EOF

sleep 0.2

LAST_WORD=$(grep "buffer now" /tmp/punto.log | tail -1 | sed "s/.*buffer now '\\(.*\\)'/\\1/")
EXPECTED_TAIL=$(tail_for_last_word "$LAST_WORD")
print_info "Detected tracked word '$LAST_WORD', expected typed tail '$EXPECTED_TAIL'"

# Ghostty exposes terminal selection through AX but that selection often
# includes prompt/log garbage. Keep a dirty clipboard and require Punto to
# extract only the tracked typed tail from the non-settable AX selection.
printf "stale clipboard %s" "$LAST_WORD" | pbcopy
print_info "Seeded stale clipboard to prove AX tail extraction wins"

print_info "Selecting terminal buffer with Cmd+A..."

osascript << 'EOF'
tell application "Ghostty" to activate
delay 0.2
tell application "System Events"
    keystroke "a" using command down
    delay 0.3
end tell
EOF

sleep 0.3

print_info "Triggering Cmd+Opt+Shift hotkey..."

osascript << 'EOF'
tell application "System Events"
    key down {command, option, shift}
    delay 0.15
    key up {command, option, shift}
end tell
EOF

sleep 0.5

# Analyze results
print_info "--- Analysis ---"

if grep -q "Converting captured text" /tmp/punto.log; then
    CONVERTED=$(grep "Converting captured text" /tmp/punto.log | tail -1 | sed "s/.*Converting captured text[^:]*: '\\(.*\\)'/\\1/" | tr -d '\n')
    print_info "Converted selected text: '$CONVERTED'"

    # Check if it converted more than just one word
    WORD_COUNT=$(echo "$CONVERTED" | wc -w | tr -d ' ')
    if [ "$WORD_COUNT" -gt 1 ]; then
        if grep -q "AX non-settable command-tail selection" /tmp/punto.log; then
            print_success "TEST 3 PASSED: AX selection extracted typed tail ($WORD_COUNT words)"
            pass_test
        else
            print_error "TEST 3 FAILED: Multiple words converted, but not through AX tail extraction"
            grep -E "Converting captured text|passive clipboard|AX non-settable" /tmp/punto.log | tail -8
            fail_test
        fi
    else
        print_error "TEST 3 FAILED: Only 1 word converted, expected multiple"
        fail_test
    fi
elif grep -q "Converting last word:" /tmp/punto.log; then
    CONVERTED=$(grep "Converting last word:" /tmp/punto.log | tail -1 | sed "s/.*Converting last word: '\\(.*\\)'/\\1/")
    print_error "TEST 3 FAILED: Selection not captured, only last word converted"
    print_info "Last word: '$CONVERTED'"
    fail_test
else
    print_error "TEST 3 FAILED: No conversion happened"
    grep -E "Converting|No text|clipboard" /tmp/punto.log | tail -5
    fail_test
fi

# ============================================
# Summary
# ============================================

print_header "Test Summary"
echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"
echo ""
echo "Full log: /tmp/punto.log"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed${NC}"
    exit 1
fi
