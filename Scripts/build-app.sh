#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
feed_url="${SPARKLE_FEED_URL:-}"
public_key="${SPARKLE_PUBLIC_KEY:-}"
if [[ -n "$feed_url" || -n "$public_key" ]]; then
    if [[ ! "$feed_url" =~ ^https://[^[:space:]]+$ || ! "$public_key" =~ ^[A-Za-z0-9+/]{43}=$ ]]; then
        echo 'Configure both an HTTPS SPARKLE_FEED_URL and a Sparkle EdDSA SPARKLE_PUBLIC_KEY.' >&2
        exit 1
    fi
fi
version="${PUNTO_VERSION:-2.0.8}"
analytics_token="${PUNTO_POSTHOG_PROJECT_TOKEN:-}"
if [[ -n "$analytics_token" && ! "$analytics_token" =~ ^phc_[A-Za-z0-9_-]+$ ]]; then
    echo 'PUNTO_POSTHOG_PROJECT_TOKEN must be a PostHog project capture token.' >&2
    exit 1
fi
build_number="${PUNTO_BUILD_NUMBER:-$(date -u +%Y%m%d%H%M%S)}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || ! "$build_number" =~ ^[0-9]+$ ]]; then
    echo 'Expected PUNTO_VERSION as major.minor.patch and PUNTO_BUILD_NUMBER as an integer.' >&2
    exit 1
fi

swift build -c release
bin_dir="$(swift build -c release --show-bin-path)"
app="$PWD/Build/Punto Native.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" "$app/Contents/Frameworks"
sparkle_artifact="$PWD/.build/artifacts/sparkle/Sparkle"
framework="$app/Contents/Frameworks/Sparkle.framework"
ditto "$sparkle_artifact/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework" "$framework"
cp "$sparkle_artifact/LICENSE" "$app/Contents/Resources/Sparkle-LICENSE.txt"
# Punto is unsandboxed and uses Sparkle's default in-process downloader and installer launcher.
rm -rf "$framework/Versions/Current/XPCServices" "$framework/XPCServices"
cp "$bin_dir/PuntoNative" "$app/Contents/MacOS/PuntoNative"
cp Resources/AppIcon.icns Resources/*.dat.txt Resources/oracle-resources.json "$app/Contents/Resources/"
cp Resources/Sounds/*.wav "$app/Contents/Resources/"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>dev.rshagiev.PuntoNative</string>
<key>CFBundleName</key><string>Punto Native</string>
<key>CFBundleDisplayName</key><string>Punto Native</string>
<key>CFBundleExecutable</key><string>PuntoNative</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.0.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSAppleEventsUsageDescription</key><string>Punto Native converts text in your applications.</string>
</dict></plist>
PLIST
plist="$app/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$version" "$plist"
plutil -replace CFBundleVersion -string "$build_number" "$plist"
if [[ -n "$analytics_token" ]]; then
    plutil -insert PuntoPostHogProjectToken -string "$analytics_token" "$plist"
fi
if [[ -n "$feed_url" ]]; then
    plutil -insert SUFeedURL -string "$feed_url" "$plist"
    plutil -insert SUPublicEDKey -string "$public_key" "$plist"
    plutil -insert SUEnableAutomaticChecks -bool YES "$plist"
    plutil -insert SUScheduledCheckInterval -integer 21600 "$plist"
    plutil -insert SUAllowsAutomaticUpdates -bool NO "$plist"
    plutil -insert SUEnableSystemProfiling -bool NO "$plist"
    plutil -insert SUVerifyUpdateBeforeExtraction -bool YES "$plist"
    plutil -insert SURequireSignedFeed -bool YES "$plist"
    plutil -insert SUSignedFeedFailureExpirationInterval -integer 0 "$plist"
fi
if [[ -f LICENSE ]]; then cp LICENSE "$app/Contents/Resources/"; fi

identity="${CODE_SIGN_IDENTITY:--}"
signing=(--force --sign "$identity")
if [[ "$identity" == 'Developer ID Application: '* ]]; then
    signing+=(--options runtime --timestamp)
fi
codesign "${signing[@]}" "$framework/Versions/Current/Autoupdate"
codesign "${signing[@]}" "$framework/Versions/Current/Updater.app"
codesign "${signing[@]}" "$framework"
codesign "${signing[@]}" --identifier dev.rshagiev.PuntoNative "$app"
printf '%s\n' "$app"
