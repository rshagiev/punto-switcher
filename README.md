# Punto

Native macOS keyboard layout switcher. Pure Swift. No Yandex bloatware.

Typed `ghbdtn` instead of `привет`? Press **Cmd+Opt+Shift** — fixed.

## What It Does

- Converts last typed word between Russian ↔ English layouts
- Converts selected text if you have a selection
- Switches keyboard layout to match the converted text
- Undo with the same hotkey (within 3 seconds)

## Installation

```bash
# Build
swift build -c release --arch arm64

# Install
cp -r .build/arm64-apple-macosx/release/Punto.app /Applications/
```

Grant Accessibility permission when prompted (System Settings → Privacy & Security → Accessibility).

## Hotkeys

| Hotkey | Action |
|--------|--------|
| **Cmd+Opt+Shift** | Convert layout (modifier-only, no extra key needed) |
| **Cmd+Opt+Z** | Toggle case (HELLO ↔ hello) |

## How It Works

1. **WordTracker** — ring buffer captures every keystroke
2. **Press hotkey** — grabs last word from buffer (or selected text)
3. **LayoutConverter** — maps characters between QWERTY ↔ ЙЦУКЕН
4. **TextAccessor** — deletes old text, pastes converted via clipboard
5. **InputSourceManager** — switches system keyboard layout

No daemon. No analytics. No cloud. Just 6 Swift files doing one job.

## Architecture

```
Sources/Punto/
├── App/
│   ├── AppDelegate.swift      # Lifecycle, hotkey callbacks
│   └── StatusBarController.swift  # Menu bar icon
├── Core/
│   ├── HotkeyManager.swift    # CGEvent tap for global hotkeys
│   ├── TextAccessor.swift     # Accessibility API + clipboard fallback
│   ├── LayoutConverter.swift  # Character mapping tables
│   ├── WordTracker.swift      # Ring buffer for typed text
│   └── InputSourceManager.swift  # TIS API for layout switching
└── Settings/
    └── SettingsManager.swift  # UserDefaults wrapper
```

## Requirements

- macOS 13+
- Accessibility permission

## Why Not Original Punto Switcher?

| Punto Switcher | This |
|----------------|------|
| Yandex telemetry | None |
| 50+ MB | ~2 MB |
| Auto-update popups | Manual |
| Dictionary downloads | Built-in mapping |
| Closed source | MIT |

## Development

```bash
# Build & deploy
swift build -c release --arch arm64
cp .build/arm64-apple-macosx/release/Punto /Applications/Punto.app/Contents/MacOS/

# View logs
tail -f /tmp/punto.log

# Run tests
swift run PuntoDiag all
```

## License

MIT
