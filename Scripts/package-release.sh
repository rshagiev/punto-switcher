#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash Scripts/build-app.sh
bash Scripts/audit-bundle.sh 'Build/Punto Native.app'
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' 'Build/Punto Native.app/Contents/Info.plist')
mkdir -p Release
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
ditto 'Build/Punto Native.app' "$stage/PuntoNative.app"
ln -s /Applications "$stage/Applications"
cp README.md LICENSE CHANGELOG.md "$stage/"
cp -R docs "$stage/"
output="Release/PuntoNative-v${version}-arm64.dmg"
hdiutil create -volname 'Punto Native' -srcfolder "$stage" -ov -format UDZO "$output"
hdiutil verify "$output"
shasum -a 256 "$output" > "$output.sha256"
echo "$output"
