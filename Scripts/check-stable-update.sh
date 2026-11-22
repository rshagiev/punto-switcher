#!/bin/bash
set -euo pipefail

stage="$1"
releases="$2"
curl_flags=(--fail --silent --show-error --location --proto '=https' --proto-redir '=https' --retry 2 --max-time 30)
curl "${curl_flags[@]}" "$releases/latest/download/appcast.xml" -o "$stage/published-appcast.xml"

archive_url=$(python3 - "$stage/published-appcast.xml" "$releases" <<'PYTHON'
import re
import sys
import xml.etree.ElementTree as ET

try:
    item, = ET.parse(sys.argv[1]).findall("./channel/item")
    version = item.findtext("{http://www.andymatuschak.org/xml-namespaces/sparkle}shortVersionString")
    if version is None or not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise ValueError("the latest item has no valid release version")
    url = f"{sys.argv[2]}/download/v{version}/PuntoNative-v{version}-arm64.zip"
except (ET.ParseError, ValueError) as error:
    sys.exit(f"Cannot identify the published stable update: {error}")
enclosure = item.find("enclosure")
if enclosure is None or enclosure.get("url") != url:
    sys.exit("Published appcast does not point to its versioned Punto Native ZIP.")
print(url)
PYTHON
)
curl "${curl_flags[@]}" "$archive_url" -o "$stage/published.zip"
unzip -p "$stage/published.zip" PuntoNative.app/Contents/Info.plist > "$stage/published-info.plist"

python3 - "$stage/published-info.plist" "$stage/published-appcast.xml" <<'PYTHON'
import os
import plistlib
import re
import sys
import xml.etree.ElementTree as ET

with open(sys.argv[1], "rb") as plist:
    published = plistlib.load(plist)
item = ET.parse(sys.argv[2]).find("./channel/item")
published_build = published.get("CFBundleVersion", "")
candidate_build = os.environ["PUNTO_BUILD_NUMBER"]
if published.get("CFBundleIdentifier") != "dev.rshagiev.PuntoNative":
    sys.exit("Unexpected bundle identifier in the published stable ZIP.")
if not re.fullmatch(r"[0-9]+", published_build) or published_build != item.findtext(
    "{http://www.andymatuschak.org/xml-namespaces/sparkle}version"
):
    sys.exit("Published Sparkle build number does not match the ZIP.")
if os.environ["SPARKLE_PUBLIC_KEY"] != published.get("SUPublicEDKey"):
    sys.exit("Candidate Sparkle public key differs from the installed stable release.")
if not re.fullmatch(r"[0-9]+", candidate_build) or int(candidate_build) <= int(published_build):
    sys.exit(f"PUNTO_BUILD_NUMBER must be greater than the published build {published_build}.")
print(f"Stable OTA baseline verified. Candidate build {candidate_build} is newer than {published_build}.")
PYTHON
