# Punto — Quick Reference for Claude Agents

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

## Character Mapping (partial)
```
EN → RU: q→й w→ц e→у r→к t→е y→н u→г i→ш o→щ p→з
         a→ф s→ы d→в f→а g→п h→р j→о k→л l→д
         z→я x→ч c→с v→м b→и n→т m→ь
```

## Full Spec
See `TECHNICAL_SPEC.md` for complete documentation.
