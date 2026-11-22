#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

check_dir="$(mktemp -d "${TMPDIR:-/tmp}/punto-conversion-chord.XXXXXX")"
trap 'rm -rf -- "$check_dir"' EXIT

swiftc -parse-as-library -D POST_CONVERSION_CHORD Scripts/ConversionChord.swift -o "$check_dir/press-conversion-chord"
"$check_dir/press-conversion-chord" "$@"
