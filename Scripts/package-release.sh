#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

identity="${CODE_SIGN_IDENTITY:--}"
notary_profile="${PUNTO_NOTARY_PROFILE:-}"
if [[ "$identity" == 'Developer ID Application: '* ]]; then
    : "${notary_profile:?Set PUNTO_NOTARY_PROFILE to a notarytool Keychain profile.}"
elif [[ -n "$notary_profile" ]]; then
    echo 'Notarization requires a Developer ID Application signing identity.' >&2
    exit 1
fi
if [[ -n "${SPARKLE_FEED_URL:-}" ]]; then
    : "${PUNTO_VERSION:?Set PUNTO_VERSION to the intended release version.}"
    : "${PUNTO_BUILD_NUMBER:?Set PUNTO_BUILD_NUMBER to a build number greater than the previous release.}"
    : "${SPARKLE_RELEASE_NOTES:?Set SPARKLE_RELEASE_NOTES to the Markdown notes for this release.}"
    : "${SPARKLE_DOWNLOAD_PREFIX:?Set SPARKLE_DOWNLOAD_PREFIX to the HTTPS asset directory for this release tag.}"
    [[ -s "$SPARKLE_RELEASE_NOTES" && "$SPARKLE_DOWNLOAD_PREFIX" =~ ^https://[^[:space:]]+/$ ]] || {
        echo 'OTA packaging requires a nonempty notes file and an HTTPS download prefix ending in /.' >&2
        exit 1
    }
fi

bash Scripts/build-app.sh
app='Build/Punto Native.app'
bash Scripts/audit-bundle.sh "$app"
version=$(plutil -extract CFBundleShortVersionString raw "$app/Contents/Info.plist")
mkdir -p Release
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

if [[ -n "$notary_profile" ]]; then
    ditto -c -k --keepParent "$app" "$stage/notary.zip"
    xcrun notarytool submit "$stage/notary.zip" --keychain-profile "$notary_profile" --wait
    xcrun stapler staple "$app"
    xcrun stapler validate "$app"
fi

if [[ -n "${SPARKLE_FEED_URL:-}" ]]; then
    tools="$PWD/.build/artifacts/sparkle/Sparkle/bin"
    signing_key=(--account "${SPARKLE_KEY_ACCOUNT:-punto-native}")
    if [[ -n "${SPARKLE_ED_KEY_FILE:-}" ]]; then
        if [[ ! -f "$SPARKLE_ED_KEY_FILE" ]]; then
            echo 'SPARKLE_ED_KEY_FILE must be a regular file.' >&2
            exit 1
        fi
        signing_key=(--ed-key-file "$SPARKLE_ED_KEY_FILE")
    fi
    archive="PuntoNative-v${version}-arm64"
    mkdir "$stage/ota"
    ditto "$app" "$stage/PuntoNative.app"
    ditto -c -k --keepParent "$stage/PuntoNative.app" "$stage/ota/$archive.zip"
    cp "$SPARKLE_RELEASE_NOTES" "$stage/ota/$archive.md"
    "$tools/generate_appcast" "${signing_key[@]}" --maximum-deltas 0 --embed-release-notes \
        --download-url-prefix "$SPARKLE_DOWNLOAD_PREFIX" -o "$stage/ota/appcast.xml" "$stage/ota"
    signature=$(python3 - "$stage/ota/appcast.xml" "$SPARKLE_DOWNLOAD_PREFIX$archive.zip" <<'PYTHON'
import sys
import xml.etree.ElementTree as ET

appcast = ET.parse(sys.argv[1])
enclosures = appcast.findall("./channel/item/enclosure")
assert len(enclosures) == 1 and enclosures[0].get("url") == sys.argv[2]
print(enclosures[0].attrib["{http://www.andymatuschak.org/xml-namespaces/sparkle}edSignature"])
PYTHON
    )
    "$tools/sign_update" "${signing_key[@]}" --verify "$stage/ota/appcast.xml"
    "$tools/sign_update" "${signing_key[@]}" --verify "$stage/ota/$archive.zip" "$signature"
fi

mkdir "$stage/dmg"
ditto "$app" "$stage/dmg/PuntoNative.app"
ln -s /Applications "$stage/dmg/Applications"
cp README.md LICENSE CHANGELOG.md "$stage/dmg/"
cp -R docs "$stage/dmg/"
output="Release/PuntoNative-v${version}-arm64.dmg"
hdiutil create -volname 'Punto Native' -srcfolder "$stage/dmg" -format UDZO "$stage/release.dmg"
if [[ -n "$notary_profile" ]]; then
    codesign --sign "$identity" --timestamp "$stage/release.dmg"
    xcrun notarytool submit "$stage/release.dmg" --keychain-profile "$notary_profile" --wait
    xcrun stapler staple "$stage/release.dmg"
    xcrun stapler validate "$stage/release.dmg"
fi
hdiutil verify "$stage/release.dmg"
mv -f "$stage/release.dmg" "$output"
(cd Release && shasum -a 256 "${output##*/}") > "$output.sha256"
echo "$output"

if [[ -n "${SPARKLE_FEED_URL:-}" ]]; then
    mkdir -p "Release/ota-v$version"
    mv -f "$stage/ota/$archive.zip" "$stage/ota/appcast.xml" "Release/ota-v$version/"
    echo "Release/ota-v$version/"
fi
