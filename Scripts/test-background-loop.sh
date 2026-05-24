#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/Scripts/test-background-loop.sh"
DURATION_MINUTES="${1:-120}"
SLEEP_SECONDS="${2:-30}"
LOG_FILE="${PUNTO_BG_TEST_LOG:-/tmp/punto-background-tests.log}"
PID_FILE="${PUNTO_BG_TEST_PID:-/tmp/punto-background-tests.pid}"
LAUNCH_LABEL="${PUNTO_BG_TEST_LABEL:-com.rshagiev.punto.background-tests}"

cd "$ROOT_DIR"

if [[ "${1:-}" == "status" ]]; then
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "running pid=$(cat "$PID_FILE") log=$LOG_FILE"
    else
        echo "not running log=$LOG_FILE"
    fi
    exit 0
fi

if [[ "${1:-}" == "stop" ]]; then
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        kill "$(cat "$PID_FILE")"
        echo "stopped pid=$(cat "$PID_FILE")"
    else
        echo "not running"
    fi
    launchctl remove "$LAUNCH_LABEL" >/dev/null 2>&1 || true
    rm -f "$PID_FILE"
    exit 0
fi

run_loop() {
    local start_ts end_ts iteration
    start_ts="$(date +%s)"
    end_ts=$((start_ts + DURATION_MINUTES * 60))
    iteration=1

    echo "Punto background test loop started at $(date)"
    echo "duration_minutes=$DURATION_MINUTES sleep_seconds=$SLEEP_SECONDS"
    echo "toolchain=$(swift --version | head -1)"
    echo

    while [[ "$(date +%s)" -lt "$end_ts" ]]; do
        echo "=== iteration ${iteration} started at $(date) ==="
        ./Scripts/test-reverse-audit.sh
        ./Scripts/test-legacy-boundary.sh
        ./Scripts/test-native-bundle-audit.sh
        swift run PuntoCoreTest
        swift run PuntoSettingsTest
        swift run PuntoParityTest
        swift run PuntoDiag converter
        swift run PuntoDiag tracker
        swift run PuntoDiag autocorrect
        swift run PuntoDiag clipboard
        echo "=== iteration ${iteration} passed at $(date) ==="
        echo
        iteration=$((iteration + 1))
        sleep "$SLEEP_SECONDS"
    done

    echo "Punto background test loop finished at $(date)"
}

if [[ "${PUNTO_BG_TEST_CHILD:-}" == "1" ]]; then
    echo "$$" > "$PID_FILE"
    exec >> "$LOG_FILE" 2>&1
    trap 'rm -f "$PID_FILE"' EXIT
    run_loop
    launchctl remove "$LAUNCH_LABEL" >/dev/null 2>&1 || true
    exit 0
fi

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "already running pid=$(cat "$PID_FILE") log=$LOG_FILE" >&2
    exit 1
fi

launchctl remove "$LAUNCH_LABEL" >/dev/null 2>&1 || true
launchctl submit -l "$LAUNCH_LABEL" -- /usr/bin/env \
    PUNTO_BG_TEST_CHILD=1 \
    PUNTO_BG_TEST_LOG="$LOG_FILE" \
    PUNTO_BG_TEST_PID="$PID_FILE" \
    PUNTO_BG_TEST_LABEL="$LAUNCH_LABEL" \
    "$SCRIPT_PATH" "$DURATION_MINUTES" "$SLEEP_SECONDS"

echo "started label=$LAUNCH_LABEL log=$LOG_FILE"
