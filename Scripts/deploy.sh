#!/bin/bash

# Build, install, sign, and restart the local Punto app bundle.

set -euo pipefail

APP_NAME="Punto"
DEFAULT_SIGN_IDENTITY="Punto Local Code Signing"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_BUNDLE="/Applications/$APP_NAME.app"
RELEASE_BINARY="$PROJECT_DIR/.build/arm64-apple-macosx/release/$APP_NAME"
INSTALLED_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
ENTITLEMENTS="$PROJECT_DIR/Resources/Punto.entitlements"
INFO_PLIST="$PROJECT_DIR/Resources/Info.plist"
SOUND_RESOURCES="$PROJECT_DIR/Resources/Sounds"
SIGN_IDENTITY="${PUNTO_SIGN_IDENTITY:-$DEFAULT_SIGN_IDENTITY}"

cd "$PROJECT_DIR"

echo "Building $APP_NAME release arm64..."
swift build -c release --arch arm64

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: $APP_BUNDLE does not exist. Run ./Scripts/build.sh once to create the app bundle."
    exit 1
fi

echo "Installing binary..."
cp "$RELEASE_BINARY" "$INSTALLED_BINARY"

echo "Installing bundle metadata..."
cp "$INFO_PLIST" "$APP_BUNDLE/Contents/Info.plist"
cp "$ENTITLEMENTS" "$APP_BUNDLE/Contents/Punto.entitlements"

if [ -d "$SOUND_RESOURCES" ]; then
    echo "Installing sound feedback resources..."
    mkdir -p "$APP_BUNDLE/Contents/Resources/Sounds"
    cp "$SOUND_RESOURCES"/*.wav "$APP_BUNDLE/Contents/Resources/Sounds/"
fi

echo "Signing app bundle..."
if security find-identity -v -p codesigning | grep -Fq "\"$SIGN_IDENTITY\""; then
    codesign --force --deep --sign "$SIGN_IDENTITY" --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
else
    echo "Warning: code-signing identity '$SIGN_IDENTITY' not found; falling back to ad-hoc signing."
    echo "Ad-hoc signing changes the designated requirement on every build and may require re-adding Accessibility permission."
    codesign --force --deep --sign - --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
fi
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "Restarting $APP_NAME..."
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5
open "$APP_BUNDLE" || {
    sleep 1
    open "$APP_BUNDLE"
}

echo "Build binary before signing:"
shasum -a 256 "$RELEASE_BINARY"

echo "Installed binary after bundle signing:"
shasum -a 256 "$INSTALLED_BINARY"
