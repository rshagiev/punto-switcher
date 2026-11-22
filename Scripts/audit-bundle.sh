#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app="${1:-Build/Punto Native.app}"
codesign --verify --deep --strict "$app"
python3 - "$app" <<'PY'
import base64,plistlib,re,sys
from urllib.parse import urlsplit
from pathlib import Path
app=Path(sys.argv[1]);info=plistlib.loads((app/'Contents/Info.plist').read_bytes())
assert info['CFBundleIdentifier']=='dev.rshagiev.PuntoNative'
assert info['LSMinimumSystemVersion']=='14.0'
assert 'PuntoReleaseCandidate' not in info, 'Private local update path in release'
if 'PuntoPostHogProjectToken' in info:
 assert re.fullmatch(r'phc_[A-Za-z0-9_-]+', info['PuntoPostHogProjectToken']), 'Expected a capture-only project token'
feed = info.get('SUFeedURL')
if feed is not None:
 url = urlsplit(feed)
 assert url.scheme == 'https' and url.hostname and not url.username and not url.password
 assert len(base64.b64decode(info['SUPublicEDKey'], validate=True)) == 32
 assert info['SUEnableAutomaticChecks'] is True
 assert info['SUScheduledCheckInterval'] == 21600
 assert info['SUAllowsAutomaticUpdates'] is False
 assert info['SUEnableSystemProfiling'] is False
 assert info['SUVerifyUpdateBeforeExtraction'] is True
 assert info['SURequireSignedFeed'] is True
 assert info['SUSignedFeedFailureExpirationInterval'] == 0
else:
 assert 'SUPublicEDKey' not in info
framework = app/'Contents/Frameworks/Sparkle.framework'
assert (framework/'Sparkle').is_file() and (framework/'Versions/Current').is_symlink()
assert (framework/'Versions/Current/Autoupdate').is_file()
assert (framework/'Versions/Current/Updater.app/Contents/Info.plist').is_file()
assert not (framework/'Versions/Current/XPCServices').exists()
resources=app/'Contents/Resources'
assert (resources/'Sparkle-LICENSE.txt').is_file()
for source in [Path('Resources/ps.dat.txt'),Path('Resources/triggers.dat.txt'),*Path('Resources/Sounds').glob('*.wav')]:
 assert (resources/source.name).read_bytes()==source.read_bytes(), source
assert not list(app.rglob('settings.json'))
assert not list(app.rglob('auth.json'))
print('PASS: complete offline resources, bundle identity, no private update path or account settings')
PY
lipo -info "$app/Contents/MacOS/PuntoNative"

[[ "$(lipo -archs "$app/Contents/MacOS/PuntoNative")" == arm64 ]] || { echo 'Release must target Apple Silicon only' >&2; exit 1; }
