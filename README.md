# Punto

**Native macOS keyboard layout converter. Pure Swift. No bloatware.**

Typed `ghbdtn` instead of `привет`? Press **Cmd+Opt+Shift** — fixed instantly.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Features

- **Instant conversion** — Russian ↔ English layout with one hotkey
- **Smart detection** — converts selected text or last typed word
- **Auto layout switch** — changes system keyboard to match converted text
- **Undo support** — press same hotkey within 3 seconds to revert
- **Case toggle** — switch between HELLO ↔ hello
- **Modifier-only hotkey** — no extra key needed, just Cmd+Opt+Shift
- **Privacy first** — no telemetry, no network, no cloud

## Installation

### From Release

Download `Punto.app` from [Releases](../../releases) and move to `/Applications`.

### Build from Source

```bash
# Clone
git clone https://github.com/yourusername/Punto.git
cd Punto

# Build (Apple Silicon)
swift build -c release --arch arm64

# Build (Universal binary)
./Scripts/build.sh

# Install
cp -r Release/Punto.app /Applications/
```

### First Launch

1. Open Punto from Applications
2. Grant **Accessibility** permission when prompted
   - System Settings → Privacy & Security → Accessibility → Enable Punto
3. The app appears in the menu bar (keyboard icon)

## Usage

| Hotkey | Action |
|--------|--------|
| **Cmd+Opt+Shift** | Convert layout (last word or selection) |
| **Cmd+Opt+Z** | Toggle case |

### Examples

| You typed | After Cmd+Opt+Shift |
|-----------|---------------------|
| `ghbdtn` | `привет` |
| `руддщ` | `hello` |
| `Vfrc` | `Макс` |

### Undo

Press the same hotkey again within 3 seconds to undo the conversion.

## How It Works

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  WordTracker    │────▶│  LayoutConverter │────▶│   TextAccessor  │
│  (ring buffer)  │     │  (QWERTY↔ЙЦУКЕН) │     │  (paste result) │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         ▲                                                │
         │                                                ▼
┌─────────────────┐                              ┌─────────────────┐
│  HotkeyManager  │                              │InputSourceManager│
│  (CGEvent tap)  │                              │ (switch layout) │
└─────────────────┘                              └─────────────────┘
```

1. **WordTracker** captures every keystroke in a ring buffer
2. **HotkeyManager** detects Cmd+Opt+Shift press
3. **LayoutConverter** maps characters between layouts
4. **TextAccessor** replaces text via Accessibility API or clipboard
5. **InputSourceManager** switches system keyboard layout

## Architecture

```
Sources/Punto/
├── App/
│   ├── main.swift                 # Entry point
│   ├── AppDelegate.swift          # App lifecycle, hotkey callbacks
│   └── StatusBarController.swift  # Menu bar icon & menu
├── Core/
│   ├── HotkeyManager.swift        # Global hotkey detection (CGEvent)
│   ├── TextAccessor.swift         # Get/set text via AX API + clipboard
│   ├── LayoutConverter.swift      # Character mapping tables
│   ├── WordTracker.swift          # Ring buffer for typed characters
│   └── InputSourceManager.swift   # macOS keyboard layout switching
├── Settings/
│   └── SettingsManager.swift      # UserDefaults persistence
└── UI/
    ├── SettingsWindowController.swift  # Settings window
    └── HotkeyRecorderView.swift        # Custom hotkey input
```

## Comparison

| Feature | Punto Switcher (Yandex) | Punto |
|---------|------------------------|-------|
| Telemetry | Yes | None |
| Size | ~50 MB | ~2 MB |
| Auto-updates | Forced popups | Manual |
| Source code | Closed | Open (MIT) |
| Dependencies | Many | Zero |
| Network access | Required | None |

## Requirements

- macOS 13.0+
- Accessibility permission (for keyboard monitoring)

## Development

```bash
# Quick build (arm64 only)
swift build -c release --arch arm64
cp .build/arm64-apple-macosx/release/Punto /Applications/Punto.app/Contents/MacOS/

# Full build (universal binary)
./Scripts/build.sh
open Release/Punto.app

# View logs
tail -f /tmp/punto.log

# Run tests
swift run PuntoTest all
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Hotkey doesn't work | Check Accessibility permission in System Settings |
| Converts wrong text | Wait for cursor to stop moving before pressing hotkey |
| Double conversion | Known issue in some apps, press Cmd+Z to undo |

## License

MIT License. See [LICENSE](LICENSE) for details.

---

**Made with frustration after typing in the wrong layout one too many times.**
