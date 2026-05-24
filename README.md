# Punto

Native macOS keyboard layout switcher for English and Russian text.

Punto fixes text typed in the wrong keyboard layout. Type `ghbdtn`, press
`Cmd+Option+Shift`, and Punto replaces it with `привет`.

## Download

The easiest way to install Punto is from GitHub Releases:

1. Open the [latest release](https://github.com/rshagiev/punto-switcher/releases/latest).
2. Download `Punto-v1.0.2.dmg`.
3. Open the disk image.
4. Drag `Punto.app` to `Applications`.
5. Open `Punto.app` from `/Applications`.

macOS may warn that the app was downloaded from the internet. If needed, open it
from Finder with right click -> Open.

## Required Permission

Punto needs macOS Accessibility permission. Without it, global hotkeys and text
replacement cannot work.

After first launch:

1. Open System Settings.
2. Go to Privacy & Security -> Accessibility.
3. Enable Punto.
4. Restart Punto from `/Applications`.

If Punto is missing from the list, add `/Applications/Punto.app` manually with
the plus button.

## Usage

Punto runs in the menu bar.

| Hotkey | Action |
| --- | --- |
| `Cmd+Option+Shift` | Convert selected text or the last typed word |
| Repeat `Cmd+Option+Shift` within 3 seconds | Undo the last conversion |
| `Cmd+Option+Z` | Toggle text case |
| `Cmd+Option+A` | Toggle auto-correction |
| `Cmd+Option+Delete` | Cancel the last conversion |

Examples:

| Wrong layout | Fixed text |
| --- | --- |
| `ghbdtn` | `привет` |
| `руддщ` | `hello` |
| `Vfrc` | `Макс` |

Punto can convert:

- selected text;
- the last typed word;
- terminal command tails when direct Accessibility replacement is not safe.

## Privacy

Punto is local-only software.

- No telemetry.
- No analytics.
- No network requests for text processing.
- No cloud sync.
- Clipboard fallback is used only for local text capture/replacement when an app
  does not expose a safe Accessibility text API.

The app still needs Accessibility permission because macOS requires it for
global hotkeys, reading selected text, and replacing text in other apps.

## Supported macOS Versions

Punto targets macOS 12 or newer. The release artifact is a universal macOS app
bundle with `arm64` and `x86_64` slices.

## Terminal And Browser Behavior

Punto does not rely on a hardcoded terminal app list for replacement safety.
Instead, it checks what the active text surface can actually do:

- direct Accessibility replacement for editable selected text;
- clipboard-backed selected text replacement for browser/content surfaces;
- backspace plus paste for tracked terminal command tails;
- no-op when the target cannot be verified safely.

This is intentional. A missed conversion is better than deleting or pasting into
the wrong text field.

## Build From Source

Requirements:

- macOS 12 or newer;
- Xcode Command Line Tools.

Build a release app:

```bash
./Scripts/build.sh
open Release/Punto.app
```

For local development on Apple Silicon, build, sign, install, and restart:

```bash
./Scripts/deploy.sh
```

`deploy.sh` updates `/Applications/Punto.app` and re-signs the bundle. This is
important because macOS Accessibility permission is tied to the app identity.

## Tests

Run the main regression cycle:

```bash
./Scripts/test-cycle.sh 1
```

Focused test entry points:

```bash
swift run PuntoCoreTest
swift run PuntoSettingsTest
swift run PuntoParityTest
```

Useful installed-app checks:

```bash
PUNTO_AUDIT_INSTALLED_BUNDLE=1 ./Scripts/test-native-bundle-audit.sh
codesign --verify --deep --strict --verbose=2 /Applications/Punto.app
tail -f /tmp/punto.log
```

## Troubleshooting

### The hotkey does nothing

Check Accessibility permission first. Then quit Punto from the menu bar and open
it again from `/Applications`.

### Text is not replaced in a specific app

Some apps do not expose selected text through Accessibility. Punto falls back to
clipboard or keyboard-tail replacement only when it can verify the target safely.
If the target is not verifiable, Punto skips the conversion.

### The wrong word is converted

Selected text has priority. If nothing is selected, Punto uses its tracked last
typed word. Clicking somewhere else clears that tracking state.

### Logs

Punto writes a local diagnostic log:

```bash
tail -f /tmp/punto.log
```

Do not attach logs publicly without reviewing them first; they can contain app
names and short snippets of text involved in a conversion.

## Project Layout

| Path | Purpose |
| --- | --- |
| `Sources/PuntoCore` | Pure conversion, policy, tracking, and testable domain logic |
| `Sources/PuntoRuntime` | macOS Accessibility, clipboard, keyboard, and input-source adapters |
| `Sources/PuntoSettings` | Native settings and Punto Switcher import fallbacks |
| `Sources/Punto` | App lifecycle, menu bar UI, and runtime coordinators |
| `Scripts` | Build, deploy, diagnostics, and regression scripts |
| `docs` | Architecture notes and behavior documentation |

## Notes

Punto is an independent native Swift implementation. Reverse-engineering notes in
this repository are used only to document behavior and compatibility boundaries;
the implementation is native Swift code.
