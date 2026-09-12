#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release
bin_dir="$(swift build -c release --show-bin-path)"
app="$PWD/Build/Punto Native.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
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
<key>CFBundleShortVersionString</key><string>2.0.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSAppleEventsUsageDescription</key><string>Punto Native converts text in your applications.</string>
</dict></plist>
PLIST
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(date +%Y%m%d%H%M%S)" "$app/Contents/Info.plist"
if [[ "${LOCAL_UPDATE_CHANNEL:-0}" == 1 ]]; then
    /usr/libexec/PlistBuddy -c "Add :PuntoReleaseCandidate string $PWD/Build/Punto Native.app" "$app/Contents/Info.plist"
fi
if [[ -f LICENSE ]]; then cp LICENSE "$app/Contents/Resources/"; fi
if [[ -f RESOURCE-NOTICES.md ]]; then cp RESOURCE-NOTICES.md "$app/Contents/Resources/"; fi
codesign --force --sign "${CODE_SIGN_IDENTITY:--}" --identifier dev.rshagiev.PuntoNative "$app"
printf '%s\n' "$app"
