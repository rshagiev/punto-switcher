#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

check_dir="$(mktemp -d "${TMPDIR:-/tmp}/punto-keyboard-setup.XXXXXX")"
trap 'rm -rf -- "$check_dir"' EXIT
swiftc Sources/PuntoNative/KeyboardPermission.swift Tests/PuntoNativeTests/KeyboardSetupChecks.swift -o "$check_dir/check"
"$check_dir/check"
