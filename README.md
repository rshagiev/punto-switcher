# Punto

**Native macOS keyboard layout converter. Pure Swift. No bloatware.**

Typed `ghbdtn` instead of `привет`? Press **Cmd+Opt+Shift** — fixed instantly.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Quick Start (5 minutes)

### Step 1: Download

**Option A — Ready-to-use app:**
1. Go to [Releases](../../releases)
2. Download `Punto.app.zip`
3. Unzip and drag `Punto.app` to `/Applications`

**Option B — Build yourself:**
```bash
git clone https://github.com/rshagiev/punto-switcher.git
cd punto-switcher
./Scripts/build.sh
cp -r Release/Punto.app /Applications/
```

### Step 2: Grant Accessibility Permission

Punto needs Accessibility permission to read and replace text. **Without this, nothing will work.**

1. Open `Punto.app` from Applications
2. macOS will show a permission dialog — click **Open System Settings**
3. In **Privacy & Security → Accessibility**, find **Punto** and toggle it **ON**
4. If Punto doesn't appear in the list:
   - Click the **+** button
   - Navigate to `/Applications/Punto.app` and add it
5. **Restart Punto** (quit from menu bar, open again)

<details>
<summary>Screenshot: How to enable Accessibility</summary>

System Settings → Privacy & Security → Accessibility → Toggle Punto ON

```
┌─────────────────────────────────────────────────┐
│ Privacy & Security                              │
├─────────────────────────────────────────────────┤
│ Accessibility                                   │
│                                                 │
│ Allow the apps below to control your computer.  │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ ☑ Punto                              [ON]  │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```
</details>

### Step 3: Use It

1. Open any app (Notes, browser, Telegram, etc.)
2. Type something in the wrong layout, e.g. `ghbdtn`
3. Press **Cmd+Opt+Shift** (all three together, then release)
4. Text converts to `привет`

**That's it. You're done.**

---

## Features

- **Instant conversion** — Russian ↔ English layout with one hotkey
- **Smart detection** — converts selected text or last typed word
- **Auto layout switch** — changes system keyboard to match converted text
- **Undo support** — press same hotkey within 3 seconds to revert
- **Case toggle** — switch between HELLO ↔ hello
- **Modifier-only hotkey** — no extra key needed, just Cmd+Opt+Shift
- **Privacy first** — no telemetry, no network, no cloud

---

## Hotkeys

| Hotkey | Action |
|--------|--------|
| **Cmd+Opt+Shift** | Convert layout (last word or selection) |
| **Cmd+Opt+Z** | Toggle case (HELLO ↔ hello) |

### Examples

| You typed | After Cmd+Opt+Shift |
|-----------|---------------------|
| `ghbdtn` | `привет` |
| `руддщ` | `hello` |
| `Vfrc` | `Макс` |
| `Rhfcbdj!` | `Красиво!` |

### Two Modes

**1. Last word mode (default):**
- Just type, no need to select anything
- Press hotkey — last word gets converted
- Works in any text field

**2. Selection mode:**
- Select text with mouse or Shift+arrows
- Press hotkey — selected text gets converted
- Works for multiple words, sentences, paragraphs

### Undo

Press the same hotkey again within 3 seconds to undo the conversion.

---

## Troubleshooting

### Hotkey doesn't work

1. **Check Accessibility permission** — most common issue
   - System Settings → Privacy & Security → Accessibility
   - Make sure Punto is enabled (toggle ON)
   - If you moved the app, remove old entry and add new one

2. **Restart Punto** after changing permissions
   - Click menu bar icon → Quit
   - Open Punto.app again

3. **Check if Punto is running**
   - Look for keyboard icon in menu bar (top right)
   - If not there, open Punto.app

### Text doesn't convert correctly

1. **Wait for cursor to stop** — don't press hotkey while text is still being typed
2. **Check keyboard layouts** — make sure you have both English and Russian layouts in System Settings → Keyboard → Input Sources
3. **Some special characters** may not convert (emojis, math symbols, etc.)

### Converts wrong text

1. **Word boundaries** — Punto tracks the last word since you typed Space, Tab, or Enter
2. **Selection takes priority** — if you have text selected, it converts that instead of last word

### App keeps asking for permission

1. Remove Punto from Accessibility list
2. Quit Punto completely
3. Add Punto back to Accessibility
4. Open Punto again

---

## Comparison with Punto Switcher (Yandex)

| Feature | Punto Switcher (Yandex) | This Punto |
|---------|------------------------|------------|
| Telemetry | Yes (sends data to Yandex) | None |
| Size | ~50 MB | ~2 MB |
| Auto-updates | Forced popups | Manual |
| Source code | Closed | Open (MIT) |
| Dependencies | Many | Zero |
| Network access | Required | None |
| Price | Free (you're the product) | Free (actually free) |

---

## Advanced

### Settings

Click the menu bar icon → **Settings** to customize:
- Enable/disable the app
- Change hotkeys
- Auto-start on login
- Auto-switch keyboard layout after conversion

### Building from Source

Requirements:
- macOS 13.0+
- Xcode Command Line Tools (`xcode-select --install`)

```bash
# Clone repository
git clone https://github.com/rshagiev/punto-switcher.git
cd punto-switcher

# Build universal binary (arm64 + x86_64)
./Scripts/build.sh

# Or build for Apple Silicon only (faster)
swift build -c release --arch arm64

# Install
cp -r Release/Punto.app /Applications/
```

### Logs

For debugging, check the log file:
```bash
tail -f /tmp/punto.log
```

### Uninstall

1. Quit Punto (menu bar icon → Quit)
2. Delete `/Applications/Punto.app`
3. Optionally, remove from Accessibility in System Settings

---

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
2. **HotkeyManager** detects Cmd+Opt+Shift press via CGEvent tap
3. **LayoutConverter** maps characters between QWERTY and ЙЦУКЕН layouts
4. **TextAccessor** replaces text via Accessibility API (or clipboard fallback)
5. **InputSourceManager** switches macOS keyboard layout to match converted text

---

## Technical Highlights

Built from scratch in Swift. ~7000 lines of code. Zero dependencies.

### Low-Level macOS Integration

| Component | Challenge | Solution |
|-----------|-----------|----------|
| **CGEvent Tap** | Global hotkey interception at system level | Event tap with `kCGEventTapOptionDefault`, handles `flagsChanged` for modifier-only detection |
| **Accessibility API** | Read/replace text in any app | `kAXSelectedTextAttribute` with fallback to clipboard for Safari/Electron |
| **Input Source API** | Programmatic keyboard switch | `TISSelectInputSource` with notification filtering |

### Non-Trivial Problems Solved

**Modifier-only hotkeys** — Most apps require Cmd+Opt+Shift+*Key*. Punto triggers on Cmd+Opt+Shift alone via `flagsChanged` event tracking. Requires careful state machine to avoid false triggers.

**Self-capture prevention** — When Punto types replacement text, those keystrokes would be captured by its own event tap. Solved with `ignoreEvents` flag and 300ms cooldown window.

**Layout switch echo** — Switching keyboard layout fires `kTISNotifySelectedKeyboardInputSourceChanged`, which normally clears the word buffer. `ignoreNextInputSourceChange` flag prevents clearing after programmatic switch.

**Mixed layout detection** — WordTracker rejects words containing both Cyrillic and Latin characters (e.g., "heпо"). This catches race conditions when layout change notification arrives with delay.

**Safari/Electron compatibility** — Web content doesn't expose `selectedText` via Accessibility. TextAccessor performs recursive AX tree traversal (depth 5) before falling back to Cmd+C clipboard method.

**Password field protection** — Detects `kAXSecureTextField` role and blocks conversion in password inputs.

**Ring buffer word tracking** — Efficient fixed-size buffer tracks last 100 characters. Handles backspace, word boundaries (Space, Tab, Enter), and special keys (Cmd+V clears buffer).

### Architecture

```
Sources/Punto/
├── Core/
│   ├── HotkeyManager.swift    # CGEvent tap, modifier detection
│   ├── TextAccessor.swift     # AX API, clipboard fallback (800+ lines)
│   ├── LayoutConverter.swift  # QWERTY ↔ ЙЦУКЕН mapping
│   ├── WordTracker.swift      # Ring buffer, word boundaries
│   ├── InputSourceManager.swift
│   └── Logger.swift
├── App/
│   ├── AppDelegate.swift      # Lifecycle, component orchestration
│   └── StatusBarController.swift
├── UI/
│   ├── SettingsWindowController.swift
│   └── OnboardingWindowController.swift
└── Settings/
    └── SettingsManager.swift
```

---

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permission

---

## License

MIT License. Do whatever you want with it.

---

**Made with frustration after typing in the wrong layout one too many times.**
