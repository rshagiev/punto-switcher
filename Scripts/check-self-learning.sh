#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

check_dir="$(mktemp -d "${TMPDIR:-/tmp}/punto-self-learning.XXXXXX")"
trap 'rm -rf -- "$check_dir"' EXIT

swiftc -emit-library -static -emit-module -module-name PuntoCore \
    -emit-module-path "$check_dir/PuntoCore.swiftmodule" \
    Sources/PuntoCore/*.swift -o "$check_dir/libPuntoCore.a"
swiftc -I "$check_dir" -L "$check_dir" -lPuntoCore \
    Sources/PuntoNative/{ConversionFeedback,KeyboardEngine,Layouts,LocalActivity,LunaClient,Settings,TextAccess}.swift \
    Scripts/ConversionChord.swift Tests/PuntoNativeTests/SelfLearningChecks.swift -o "$check_dir/check"
"$check_dir/check" "$check_dir" "$PWD/Resources"
