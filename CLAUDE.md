# Punto — macOS Keyboard Layout Switcher

> **Domain:** macOS tool (Swift)
> **Location:** `~/Projects/Punto`
> **Tier:** 1 (Slim reference)
> **Maturity:** basic

## Quick Context
- Menu bar app for keyboard layout conversion (EN ↔ RU)
- Modifier-only hotkey: Cmd+Opt+Shift (no extra key needed)
- Uses Accessibility API for text manipulation
- Single-developer Swift project

## Quick Start
1. Build: `swift build -c release --arch arm64`
2. Deploy: `cp .build/arm64-apple-macosx/release/Punto /Applications/Punto.app/Contents/MacOS/`
3. Test: `swift run PuntoTest all`

---

## What is Punto?
macOS menu bar app for keyboard layout conversion (Russian ↔ English).

## Hotkeys
- **Cmd+Opt+Shift** (modifier-only, no extra key) → Convert layout
- **Cmd+Opt+Z** → Toggle case

## Key Files to Modify

| Task | File |
|------|------|
| Hotkey detection | `Sources/Punto/Core/HotkeyManager.swift` |
| Text get/set | `Sources/Punto/Core/TextAccessor.swift` |
| Character mapping | `Sources/Punto/Core/LayoutConverter.swift` |
| Word tracking | `Sources/Punto/Core/WordTracker.swift` |
| App lifecycle | `Sources/Punto/App/AppDelegate.swift` |
| Settings storage | `Sources/Punto/Settings/SettingsManager.swift` |
| Menu bar UI | `Sources/Punto/App/StatusBarController.swift` |

## Build & Run

```bash
# Quick build (arm64 only) and deploy to Applications
swift build -c release --arch arm64
cp .build/arm64-apple-macosx/release/Punto /Applications/Punto.app/Contents/MacOS/

# Full build (universal)
./Scripts/build.sh
open Release/Punto.app
```

**ВАЖНО:** После любых изменений кода — собрать release и скопировать в `/Applications/Punto.app/Contents/MacOS/`, заменяя старый бинарник.

## Debug

```bash
# View logs
tail -f /tmp/punto.log

# Run tests
swift run PuntoTest all

# Run diagnostics
swift run PuntoDiag all
```

## Critical Implementation Details

### 1. Modifier-Only Hotkey Detection
Uses `flagsChanged` events, not `keyDown`:
```swift
if type == .flagsChanged {
    if hasCmd && hasOpt && hasShift && !convertHotkeyTriggered {
        // Trigger conversion
    }
}
```

### 2. Prevent Re-Capture Bug
When typing replacement text, simulated key events get captured. Fix:
```swift
hotkeyManager.ignoreEvents = true
// ... do text replacement ...
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    hotkeyManager.ignoreEvents = false
}
```

### 3. Accessibility API
Must have permission. Check with:
```swift
AXIsProcessTrusted() // returns Bool
```

### 4. Text Replacement Strategy
1. **Selected text:** Use `kAXSelectedTextAttribute` or clipboard (Cmd+C/V)
2. **Last word:** Delete with backspaces, type replacement via `CGEvent`

## Common Issues

| Problem | Solution |
|---------|----------|
| Permissions not working | Run binary directly, not via `open` |
| Hotkey triggers multiple times | Check debounce (0.5s) and `convertHotkeyTriggered` flag |
| Text converts back | Ensure `ignoreEvents` is set during replacement |
| Event tap disabled | Re-enable on `tapDisabledByTimeout` event |
| WordTracker empty after conversion | Check `ignoreNextInputSourceChange` flag (see below) |

### 5. Input Source Change Handling
When Punto programmatically switches keyboard layout after conversion, it triggers `kTISNotifySelectedKeyboardInputSourceChanged` notification. Without protection, this clears WordTracker buffer and breaks undo.

**Solution:** Use `ignoreNextInputSourceChange` flag in `AppDelegate`:
```swift
// In switchLayoutIfEnabled():
ignoreNextInputSourceChange = true
inputSourceManager?.switchTo(.russian)

// In inputSourceChanged():
if ignoreNextInputSourceChange {
    ignoreNextInputSourceChange = false
    return  // Don't clear WordTracker
}
wordTracker?.clear()
```

### 6. WordTracker Mixed Layout Detection
WordTracker rejects words with mixed layouts (e.g., "heпo" = English + Russian). This prevents corruption when layout change notification arrives with delay.

```swift
// getLastWord() returns nil if buffer contains both EN and RU letters
if isMixedLayout(word) { clear(); return nil }
```

### 7. Safari/Browser Text Access
Safari web content doesn't expose `selectedText` via Accessibility API. Strategy:
1. Try `kAXSelectedTextAttribute` on focused element
2. Try `kAXFocusedUIElementAttribute` from app (for Electron/Safari)
3. Recursive search in children (maxDepth=5)
4. **Fallback:** Cmd+C clipboard method

## Character Mapping (partial)
```
EN → RU: q→й w→ц e→у r→к t→е y→н u→г i→ш o→щ p→з
         a→ф s→ы d→в f→а g→п h→р j→о k→л l→д
         z→я x→ч c→с v→м b→и n→т m→ь
```

## Full Spec
See `docs/TECHNICAL_SPEC.md` for complete documentation.

### 8. Terminal Support (Ghostty, iTerm2, Terminal.app)
Terminals handle keyboard input differently from GUI apps. Special handling:

**lineMode in WordTracker:**
- When terminal detected, `lineMode = true`
- Spaces are added to buffer instead of clearing it
- Whole line is tracked, not just last word

**Deletion:**
- Uses `Ctrl+U` (clear line) instead of backspaces
- More reliable than individual backspaces in terminals

**Selection:**
- Selected text conversion is skipped for terminals
- Only WordTracker-based conversion is used

**Supported terminals:**
- Ghostty (`com.mitchellh.ghostty`)
- iTerm2 (`com.googlecode.iterm2`)
- Terminal.app (`com.apple.Terminal`)
- Alacritty (`io.alacritty`)
- Kitty (`net.kovidgoyal.kitty`)

```swift
// Detection in TextAccessor.swift
func isTerminalApp() -> Bool

// lineMode in WordTracker.swift
var lineMode: Bool = false
```
