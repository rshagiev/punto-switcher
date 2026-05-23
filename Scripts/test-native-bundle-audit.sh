#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
INSTALLED_INFO_PLIST="/Applications/Punto.app/Contents/Info.plist"
CHECK_INSTALLED="${PUNTO_AUDIT_INSTALLED_BUNDLE:-0}"

check_plist() {
    local plist="$1"
    local label="$2"

    if [[ ! -f "$plist" ]]; then
        echo "native bundle audit skipped $label: missing $plist"
        return 0
    fi

    /usr/bin/python3 - "$plist" "$label" <<'PY'
import plistlib
import sys

path, label = sys.argv[1], sys.argv[2]
with open(path, "rb") as handle:
    data = plistlib.load(handle)

checks = [
    ("CFBundlePackageType", data.get("CFBundlePackageType"), "APPL"),
    ("NSPrincipalClass", data.get("NSPrincipalClass"), "NSApplication"),
    ("LSApplicationCategoryType", data.get("LSApplicationCategoryType"), "public.app-category.productivity"),
    ("LSUIElement", data.get("LSUIElement"), True),
    ("NSUIElement", data.get("NSUIElement"), True),
    ("NSSupportsSuddenTermination", data.get("NSSupportsSuddenTermination"), False),
]

for name, actual, expected in checks:
    if actual != expected:
        raise SystemExit(
            f"native bundle audit failed {label}: {name}: expected {expected!r}, got {actual!r}"
        )
    print(f"PASS {label} {name}")
PY
}

echo "Native Punto bundle audit"
check_plist "$SOURCE_INFO_PLIST" "source"
if [[ "$CHECK_INSTALLED" == "1" ]]; then
    check_plist "$INSTALLED_INFO_PLIST" "installed"
else
    echo "SKIP installed bundle metadata (set PUNTO_AUDIT_INSTALLED_BUNDLE=1 after deploy)"
fi
echo "Native Punto bundle audit passed"
