#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITERATIONS="${1:-10}"

cd "$ROOT_DIR"

echo "Punto test cycle: $ITERATIONS iteration(s)"
echo "Toolchain: $(swift --version | head -1)"

for ((i = 1; i <= ITERATIONS; i++)); do
    echo
    echo "=== iteration $i/$ITERATIONS: Punto Switcher reverse audit ==="
    ./Scripts/test-reverse-audit.sh

    echo
    echo "=== iteration $i/$ITERATIONS: Native bundle audit ==="
    ./Scripts/test-native-bundle-audit.sh

    echo
    echo "=== iteration $i/$ITERATIONS: PuntoCoreTest ==="
    swift run PuntoCoreTest

    echo
    echo "=== iteration $i/$ITERATIONS: PuntoTest all ==="
    swift run PuntoTest all

    echo
    echo "=== iteration $i/$ITERATIONS: PuntoDiag converter ==="
    swift run PuntoDiag converter

    echo
    echo "=== iteration $i/$ITERATIONS: PuntoDiag tracker ==="
    swift run PuntoDiag tracker

    echo
    echo "=== iteration $i/$ITERATIONS: PuntoDiag autocorrect ==="
    swift run PuntoDiag autocorrect

    echo
    echo "=== iteration $i/$ITERATIONS: PuntoDiag clipboard ==="
    swift run PuntoDiag clipboard
done

echo
echo "Punto test cycle passed: $ITERATIONS iteration(s)"
