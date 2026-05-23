#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${YELLOW}=== $1 ===${NC}"; }
ok() { echo -e "${GREEN}✓ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }

HARNESS_PID=""
HARNESS_APP="$ROOT_DIR/.build/PuntoHarness.app"
cleanup() {
    if [ -n "$HARNESS_PID" ]; then
        kill "$HARNESS_PID" >/dev/null 2>&1 || true
    fi
    pkill -f "$HARNESS_APP/Contents/MacOS/PuntoHarness" >/dev/null 2>&1 || true
}
trap cleanup EXIT

harness_command() {
    local command="$1"
    rm -f /tmp/punto_harness_command_done.txt
    printf "%s" "$command" > /tmp/punto_harness_command.txt
    for _ in {1..40}; do
        if [ "$(cat /tmp/punto_harness_command_done.txt 2>/dev/null || true)" = "$command" ]; then
            return 0
        fi
        sleep 0.05
    done
    fail "PuntoHarness did not acknowledge command '$command'"
}

wait_text_equals() {
    local file="$1"
    local expected="$2"
    local label="$3"
    for _ in {1..60}; do
        if [ "$(cat "$file" 2>/dev/null || true)" = "$expected" ]; then
            return 0
        fi
        sleep 0.05
    done
    fail "Timed out waiting for $label to become '$expected'"
}

wait_text_not_equals() {
    local file="$1"
    local previous="$2"
    local label="$3"
    for _ in {1..60}; do
        if [ "$(cat "$file" 2>/dev/null || true)" != "$previous" ]; then
            return 0
        fi
        sleep 0.05
    done
    fail "Timed out waiting for $label to change from '$previous'"
}

info "Deploy Punto"
"$ROOT_DIR/Scripts/deploy.sh" >/tmp/punto_harness_deploy.log
ok "Punto deployed"

info "Start PuntoHarness"
rm -f /tmp/punto_harness_ready \
    /tmp/punto_harness_command.txt \
    /tmp/punto_harness_command_done.txt \
    /tmp/punto_harness_stdout.log \
    /tmp/punto_harness_stderr.log
swift build --product PuntoHarness >/tmp/punto_harness_build.log
rm -rf "$HARNESS_APP"
mkdir -p "$HARNESS_APP/Contents/MacOS"
cp "$ROOT_DIR/.build/debug/PuntoHarness" "$HARNESS_APP/Contents/MacOS/PuntoHarness"
cat > "$HARNESS_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>PuntoHarness</string>
    <key>CFBundleIdentifier</key>
    <string>com.rshagiev.PuntoHarness</string>
    <key>CFBundleName</key>
    <string>PuntoHarness</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST
pkill -f "$HARNESS_APP/Contents/MacOS/PuntoHarness" >/dev/null 2>&1 || true
open -n "$HARNESS_APP"
for _ in {1..30}; do
    if [ -f /tmp/punto_harness_ready ]; then
        break
    fi
    sleep 0.2
done
[ -f /tmp/punto_harness_ready ] || fail "PuntoHarness did not report ready"
HARNESS_PID="$(pgrep -f "$HARNESS_APP/Contents/MacOS/PuntoHarness" | head -1 || true)"
harness_command ping
ok "PuntoHarness started"

info "Clear logs and type wrong-layout word"
> /tmp/punto.log
> /tmp/punto_harness_text.txt
harness_command setEnglishLayout
sleep 0.3
harness_command focusText
osascript <<'EOF'
tell application "System Events"
    delay 0.3
    key down command
    key code 0
    key up command
    delay 0.05
    key code 51
    delay 0.1
    -- g h b d t n = "привет" typed on English layout
    key code 5
    delay 0.04
    key code 4
    delay 0.04
    key code 11
    delay 0.04
    key code 2
    delay 0.04
    key code 17
    delay 0.04
    key code 45
    delay 0.1
end tell
EOF
sleep 0.5

before="$(cat /tmp/punto_harness_text.txt 2>/dev/null || true)"
[ -n "$before" ] || fail "Harness text file did not capture typed input"
ok "Harness captured before='$before'"

info "Trigger Punto hotkey"
harness_command focusText
osascript <<'EOF'
tell application "System Events"
    delay 0.2
    key down command
    key down option
    key down shift
    delay 0.15
    key up shift
    key up option
    key up command
end tell
EOF
wait_text_not_equals /tmp/punto_harness_text.txt "$before" "last-word conversion"

expected="$(grep "Converted to:" /tmp/punto.log | tail -1 | sed "s/.*Converted to: '\\(.*\\)'/\\1/" || true)"
[ -n "$expected" ] || fail "Could not parse expected converted text from Punto log"
original="$(grep "Converting last word:" /tmp/punto.log | tail -1 | sed "s/.*Converting last word: '\\(.*\\)'/\\1/" || true)"
[ -n "$original" ] || fail "Could not parse original converted word from Punto log"

after="$(cat /tmp/punto_harness_text.txt 2>/dev/null || true)"
if [ "$after" != "$expected" ]; then
    echo "Punto log tail:"
    tail -n 80 /tmp/punto.log || true
    fail "Expected harness text '$expected', got '$after'"
fi
ok "Harness converted text to '$after'"

grep -q "Converting last word:" /tmp/punto.log || fail "Punto log did not contain last-word conversion"
grep -q "replaceLastWord: completed" /tmp/punto.log || fail "Punto log did not contain replacement completion"
ok "Punto logs confirm conversion and replacement"

info "Test repeat hotkey undo"
> /tmp/punto.log
> /tmp/punto_harness_text.txt
harness_command setEnglishLayout
sleep 0.3
harness_command focusText
osascript <<'EOF'
tell application "System Events"
    delay 0.3
    key down command
    key code 0
    key up command
    delay 0.05
    key code 51
    delay 0.1
    key code 5
    delay 0.04
    key code 4
    delay 0.04
    key code 11
    delay 0.04
    key code 2
    delay 0.04
    key code 17
    delay 0.04
    key code 45
    delay 0.2

    -- Press twice inside one System Events run so the second trigger stays
    -- inside Punto's 3s undo window even on slow test machines.
    key down command
    key down option
    key down shift
    delay 0.15
    key up shift
    key up option
    key up command
    delay 1.1
    key down command
    key down option
    key down shift
    delay 0.15
    key up shift
    key up option
    key up command
end tell
EOF

undo_original="$(grep "Converting last word:" /tmp/punto.log | head -1 | sed "s/.*Converting last word: '\\(.*\\)'/\\1/" || true)"
[ -n "$undo_original" ] || fail "Could not parse undo original word from Punto log"
wait_text_equals /tmp/punto_harness_text.txt "$undo_original" "last-word undo"

undo_after="$(cat /tmp/punto_harness_text.txt 2>/dev/null || true)"
if [ "$undo_after" != "$undo_original" ]; then
    echo "Punto log tail:"
    tail -n 100 /tmp/punto.log || true
    fail "Expected undo text '$undo_original', got '$undo_after'"
fi
ok "Harness undo restored '$undo_after'"

grep -q "Undo: reverting" /tmp/punto.log || fail "Punto log did not contain undo"
ok "Punto logs confirm undo"

info "Test cancel layout change hotkey"
> /tmp/punto.log
> /tmp/punto_harness_text.txt
harness_command setEnglishLayout
sleep 0.3
harness_command focusText
osascript <<'EOF'
tell application "System Events"
    delay 0.3
    key down command
    key code 0
    key up command
    delay 0.05
    key code 51
    delay 0.1
    key code 5
    delay 0.04
    key code 4
    delay 0.04
    key code 11
    delay 0.04
    key code 2
    delay 0.04
    key code 17
    delay 0.04
    key code 45
    delay 0.1
end tell
EOF
sleep 0.5

cancel_before="$(cat /tmp/punto_harness_text.txt 2>/dev/null || true)"
[ -n "$cancel_before" ] || fail "Harness did not capture cancel-hotkey setup"

harness_command focusText
osascript <<'EOF'
tell application "System Events"
    delay 0.2
    key down command
    key down option
    key down shift
    delay 0.15
    key up shift
    key up option
    key up command
end tell
EOF
wait_text_not_equals /tmp/punto_harness_text.txt "$cancel_before" "cancel-hotkey setup conversion"

cancel_converted="$(cat /tmp/punto_harness_text.txt 2>/dev/null || true)"
if [ "$cancel_converted" = "$cancel_before" ]; then
    echo "Punto log tail:"
    tail -n 100 /tmp/punto.log || true
    fail "Cancel-hotkey setup did not convert text"
fi

harness_command focusText
osascript <<'EOF'
tell application "System Events"
    delay 0.2
    key down command
    key down option
    key code 51
    delay 0.05
    key up option
    key up command
end tell
EOF
wait_text_equals /tmp/punto_harness_text.txt "$cancel_before" "cancel layout change undo"

cancel_after="$(cat /tmp/punto_harness_text.txt 2>/dev/null || true)"
if [ "$cancel_after" != "$cancel_before" ]; then
    echo "Before cancel conversion text: $cancel_before"
    echo "After conversion text: $cancel_converted"
    echo "Punto log tail:"
    tail -n 140 /tmp/punto.log || true
    fail "Expected cancel layout change to restore '$cancel_before', got '$cancel_after'"
fi
ok "Harness cancel layout change restored '$cancel_after'"

grep -q "Cancel layout change hotkey matched" /tmp/punto.log || fail "Punto log did not contain cancel hotkey match"
grep -q "Undo: reverting" /tmp/punto.log || fail "Punto log did not contain cancel-triggered undo"
ok "Punto logs confirm cancel layout change undo"

info "Test selected editable text conversion"
> /tmp/punto.log
harness_command setEnglishLayout
sleep 0.3
harness_command focusText
osascript <<'EOF'
tell application "System Events"
    delay 0.2
    key down command
    key code 0
    key up command
    delay 0.05
    key code 51
    delay 0.1
    -- type two wrong-layout words and select the second one
    key code 5
    delay 0.03
    key code 4
    delay 0.03
    key code 11
    delay 0.03
    key code 2
    delay 0.03
    key code 17
    delay 0.03
    key code 45
    delay 0.03
    key code 49
    delay 0.03
    key code 13
    delay 0.03
    key code 14
    delay 0.03
    key code 15
    delay 0.03
    key code 13
    delay 0.1
    key down shift
    key code 123
    key code 123
    key code 123
    key code 123
    key up shift
    delay 0.1
end tell
EOF
sleep 0.5

selection_before="$(cat /tmp/punto_harness_text.txt 2>/dev/null || true)"
[ -n "$selection_before" ] || fail "Harness did not capture selected-text setup"

osascript <<'EOF'
tell application "System Events"
    delay 0.2
    key down command
    key down option
    key down shift
    delay 0.15
    key up shift
    key up option
    key up command
end tell
EOF
wait_text_not_equals /tmp/punto_harness_text.txt "$selection_before" "selected editable conversion"

selection_expected="$(grep "Converted to:" /tmp/punto.log | tail -1 | sed "s/.*Converted to: '\\(.*\\)'/\\1/" || true)"
[ -n "$selection_expected" ] || fail "Could not parse selected conversion from Punto log"
selection_original="$(grep "Converting captured text" /tmp/punto.log | tail -1 | sed "s/.*): '\\(.*\\)'/\\1/" || true)"
[ -n "$selection_original" ] || fail "Could not parse selected original text from Punto log"
selection_after="$(cat /tmp/punto_harness_text.txt 2>/dev/null || true)"
expected_selection_text="${selection_before%$selection_original}${selection_expected}"

if [ "$selection_after" != "$expected_selection_text" ]; then
    echo "Before selection text: $selection_before"
    echo "Selected original: $selection_original"
    echo "Expected selected replacement: $selection_expected"
    echo "Punto log tail:"
    tail -n 120 /tmp/punto.log || true
    fail "Expected selected conversion text '$expected_selection_text', got '$selection_after'"
fi
ok "Harness selected text conversion produced '$selection_after'"

grep -q "Converting captured text" /tmp/punto.log || fail "Punto log did not contain captured-text conversion"
grep -q "AX editable selection accepted" /tmp/punto.log || fail "Punto log did not confirm editable AX selection"
ok "Punto logs confirm selected editable AX conversion"

info "Trigger selected editable conversion undo"
harness_command focusText
osascript <<'EOF'
tell application "System Events"
    delay 0.2
    key down command
    key down option
    key down shift
    delay 0.15
    key up shift
    key up option
    key up command
end tell
EOF
wait_text_equals /tmp/punto_harness_text.txt "$selection_before" "selected editable undo"

selection_undo_after="$(cat /tmp/punto_harness_text.txt 2>/dev/null || true)"
if [ "$selection_undo_after" != "$selection_before" ]; then
    echo "Before selected conversion text: $selection_before"
    echo "After selected conversion text: $selection_after"
    echo "Punto log tail:"
    tail -n 120 /tmp/punto.log || true
    fail "Expected selected undo text '$selection_before', got '$selection_undo_after'"
fi
ok "Harness selected undo restored '$selection_undo_after'"

grep -q "Undo: reverting" /tmp/punto.log || fail "Punto log did not contain selected conversion undo"
ok "Punto logs confirm selected editable undo"

info "Test secure field conversion block"
> /tmp/punto.log
> /tmp/punto_harness_secure_text.txt
harness_command focusSecure
osascript <<'EOF'
tell application "System Events"
    delay 0.3
    key down command
    key code 0
    key up command
    delay 0.05
    key code 51
    delay 0.1
    key code 5
    delay 0.04
    key code 4
    delay 0.04
    key code 11
    delay 0.04
    key code 2
    delay 0.04
    key code 17
    delay 0.04
    key code 45
    delay 0.1
end tell
EOF
sleep 0.5

secure_before="$(cat /tmp/punto_harness_secure_text.txt 2>/dev/null || true)"
[ -n "$secure_before" ] || fail "Harness secure field did not capture typed input"

harness_command focusSecure
osascript <<'EOF'
tell application "System Events"
    delay 0.2
    key down command
    key down option
    key down shift
    delay 0.15
    key up shift
    key up option
    key up command
end tell
EOF
sleep 1

secure_after="$(cat /tmp/punto_harness_secure_text.txt 2>/dev/null || true)"
if [ "$secure_after" != "$secure_before" ]; then
    echo "Punto log tail:"
    tail -n 100 /tmp/punto.log || true
    fail "Secure field changed from '$secure_before' to '$secure_after'"
fi
ok "Harness secure field remained unchanged"

if ! grep -q "Secure Input enabled - conversion blocked\\|Password field detected - conversion blocked" /tmp/punto.log; then
    echo "Punto log tail:"
    tail -n 100 /tmp/punto.log || true
    fail "Punto log did not contain secure/password conversion block"
fi
ok "Punto logs confirm secure/password conversion block"
