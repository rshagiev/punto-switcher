#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "${1:-}" != --install-built ]]; then bash Scripts/build-app.sh; fi
app="$PWD/Build/Punto Native.app"
installed=/Applications/PuntoNative.app
codesign --verify --deep --strict "$app"
# Quit the native app only. Do not touch the original or other historical builds.
if pgrep -x PuntoNative >/dev/null; then
    osascript -e 'tell application id "dev.rshagiev.PuntoNative" to quit'
    for i in {1..50}; do pgrep -x PuntoNative >/dev/null || break; sleep 0.1; done
    if pgrep -x PuntoNative >/dev/null; then echo 'Punto Native is still running' >&2; exit 1; fi
fi
if [[ -d "$installed" ]]; then
    backup="$HOME/Library/Application Support/PuntoNative/Previous-$(date +%Y%m%d%H%M%S).app"
    mkdir -p "$(dirname "$backup")"
    mv "$installed" "$backup"
fi
if ! ditto "$app" "$installed"; then
    [[ -z "${backup:-}" ]] || mv "$backup" "$installed"
    exit 1
fi
codesign --verify --deep --strict "$installed"
open "$installed"
