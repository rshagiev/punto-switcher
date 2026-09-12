#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app="${1:-Build/Punto Native.app}"
codesign --verify --deep --strict "$app"
python3 - "$app" <<'PY'
import sys,plistlib,hashlib
from pathlib import Path
app=Path(sys.argv[1]);info=plistlib.loads((app/'Contents/Info.plist').read_bytes())
assert info['CFBundleIdentifier']=='dev.rshagiev.PuntoNative'
assert info['LSMinimumSystemVersion']=='14.0'
assert 'PuntoReleaseCandidate' not in info, 'Private local update path in release'
resources=app/'Contents/Resources'
for source in [Path('Resources/ps.dat.txt'),Path('Resources/triggers.dat.txt'),*Path('Resources/Sounds').glob('*.wav')]:
 assert (resources/source.name).read_bytes()==source.read_bytes(), source
assert not list(app.rglob('settings.json'))
assert not list(app.rglob('auth.json'))
print('PASS: complete offline resources, bundle identity, no private update path or account settings')
PY
lipo -info "$app/Contents/MacOS/PuntoNative"

[[ "$(lipo -archs "$app/Contents/MacOS/PuntoNative")" == arm64 ]] || { echo 'Release must target Apple Silicon only' >&2; exit 1; }
