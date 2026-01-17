# Punto — Technical Specification

## Overview

Punto is a native macOS menu bar application for keyboard layout conversion between Russian (ЙЦУКЕН) and English (QWERTY) layouts. It runs as a background process with a menu bar icon.

**Bundle ID:** `com.rshagiev.Punto`
**Minimum macOS:** 12.0 (Monterey)
**Architecture:** Universal Binary (arm64 + x86_64)

---

## Core Functionality

### 1. Layout Conversion (Cmd+Opt+Shift)
- Triggered by pressing all three modifier keys simultaneously (no additional key required)
- **With selected text:** Converts the selection in place
- **Without selection:** Converts the last typed word (tracked in a ring buffer)

### 2. Case Toggle (Cmd+Opt+Z)
- Converts selected text between UPPERCASE and lowercase
- If majority is uppercase → converts to lowercase
- If majority is lowercase → converts to uppercase

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AppDelegate                               │
│  - Application lifecycle                                         │
│  - Permission checking                                           │
│  - Component orchestration                                       │
└─────────────────────────────────────────────────────────────────┘
          │
          ├──────────────────┬──────────────────┬─────────────────┐
          ▼                  ▼                  ▼                 ▼
┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐  ┌──────────────┐
│  HotkeyManager  │  │  TextAccessor   │  │LayoutConverter│  │ WordTracker  │
│                 │  │                 │  │              │  │              │
│ - CGEvent Tap   │  │ - Get selected  │  │ - EN↔RU map  │  │ - Ring buffer│
│ - Modifier-only │  │ - Set selected  │  │ - Auto-detect│  │ - 50 chars   │
│   hotkey detect │  │ - Replace word  │  │   layout     │  │ - Key codes  │
└─────────────────┘  └─────────────────┘  └──────────────┘  └──────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    StatusBarController                           │
│  - Menu bar icon (keyboard symbol)                               │
│  - Dropdown menu (Enable/Disable, Settings, Quit)                │
│  - Visual feedback (icon flash on conversion)                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. HotkeyManager (`Sources/Punto/Core/HotkeyManager.swift`)

**Purpose:** Captures global keyboard events using CGEvent Tap.

**Event Mask:**
```swift
let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
                              (1 << CGEventType.flagsChanged.rawValue)
```

**Key Features:**
- **Modifier-only hotkey detection:** Detects when Cmd+Opt+Shift are all pressed via `flagsChanged` events
- **Debouncing:** 0.5 second minimum between modifier-only conversions (Cmd+Opt+Shift). Note: Key-based hotkeys like Cmd+Opt+Z have no debounce
- **ignoreEvents flag:** Temporarily disables event capture during text replacement to prevent re-capture of simulated keystrokes

**Critical Code Flow:**
```
CGEvent Tap callback
    │
    ├─► If ignoreEvents == true → pass through
    │
    ├─► If tapDisabledByTimeout → re-enable tap
    │
    ├─► If flagsChanged:
    │       └─► If Cmd+Opt+Shift all pressed AND not recently triggered
    │               └─► Call onConvertLayout()
    │
    └─► If keyDown:
            ├─► Check for Cmd+Opt+Z → Call onToggleCase()
            └─► Track character in WordTracker
```

**State Variables:**
- `modifiersWerePressed: Bool` — Tracks if all modifiers were pressed for modifier-only hotkey
- `lastConvertTime: Date` — For debouncing (0.5s minimum interval)
- `ignoreEvents: Bool` — Set by AppDelegate during text replacement

---

### 2. TextAccessor (`Sources/Punto/Core/TextAccessor.swift`)

**Purpose:** Gets and sets text in the focused application.

**Strategy 1: Accessibility API (preferred)**
```swift
AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute, &selectedText)
AXUIElementSetAttributeValue(focusedElement, kAXSelectedTextAttribute, newText)
```

**Strategy 2: Clipboard Fallback (for Electron apps, Chrome, etc.)**
```swift
// Get: Simulate Cmd+C, read clipboard
// Set: Write to clipboard, simulate Cmd+V
```

**Replace Last Word Algorithm:**
```swift
func replaceLastWord(wordLength: Int, with replacement: String) {
    // 1. Send `wordLength` backspace key events (no delay between)
    // 2. Wait 0.02s for backspaces to take effect
    // 3. Paste replacement via clipboard + Cmd+V
    // 4. Restore original clipboard after 0.3s
}
```

**Timing:**
- No delay between backspaces (sent immediately)
- 0.02s delay after backspaces before paste
- 0.03s delay after Cmd+V paste
- 0.3s delay before restoring original clipboard

---

### 3. LayoutConverter (`Sources/Punto/Core/LayoutConverter.swift`)

**Purpose:** Converts text between EN↔RU keyboard layouts.

**Character Mapping (QWERTY → ЙЦУКЕН):**
```
q→й  w→ц  e→у  r→к  t→е  y→н  u→г  i→ш  o→щ  p→з  [→х  ]→ъ
a→ф  s→ы  d→в  f→а  g→п  h→р  j→о  k→л  l→д  ;→ж  '→э
z→я  x→ч  c→с  v→м  b→и  n→т  m→ь  ,→б  .→ю  /→.
`→ё  (uppercase variants exist)
```

**Layout Detection Algorithm:**
```swift
func detectLayout(_ text: String) -> DetectedLayout {
    // Count English letters (a-z, A-Z)
    // Count Russian letters (а-я, А-Я, ё, Ё)
    // If >80% English → .english
    // If >80% Russian → .russian
    // Else → .mixed (convert based on majority of mappable chars)
}
```

**Conversion Rules:**
- Characters in mapping → converted
- Characters not in mapping → passed through unchanged
- Numbers, punctuation not in mapping → unchanged

---

### 4. WordTracker (`Sources/Punto/Core/WordTracker.swift`)

**Purpose:** Tracks the last typed word in a ring buffer for "convert last word" feature.

**Ring Buffer Implementation:**
```swift
private let maxSize: Int = 50
private var buffer: [Character]
private var head: Int = 0
private var count: Int = 0
```

**Word Boundaries (clear buffer):**
- Space, Tab, Newline
- Separators: `!` `?` `(` `)` `/` `\` `|` `@` `#` `$` `%` `^` `&` `*` `+` `=` `-` `_`
- Navigation keys: Arrow keys, Home, End, Page Up/Down, Forward Delete

**Note:** Punctuation that maps to Russian letters is NOT a boundary: `;` `'` `[` `]` `` ` `` `,` `.`

**Key Code Handling:**
- Delete (keyCode 51): Remove last character from buffer
- Return (36), Enter (76): Clear buffer
- Arrow keys (123-126): Clear buffer (cursor moved)

**trackKeyPress Flow:**
```
trackKeyPress(keyCode, characters)
    │
    ├─► If Delete → removeLastCharacter()
    ├─► If Navigation key → clear()
    ├─► If Return/Enter → clear()
    ├─► If Space or punctuation → clear()
    └─► Else → addCharacter(firstChar)
```

---

### 5. SettingsManager (`Sources/Punto/Settings/SettingsManager.swift`)

**Stored in:** `UserDefaults.standard` with Bundle ID prefix

**Settings:**
| Key | Type | Default |
|-----|------|---------|
| `isEnabled` | Bool | true |
| `isFirstLaunch` | Bool | true |
| `launchAtLogin` | Bool | false |
| `convertLayoutHotkey` | Hotkey (Codable) | Cmd+Opt+Shift+Space* |
| `toggleCaseHotkey` | Hotkey (Codable) | Cmd+Opt+Z |

*Note: The stored hotkey includes Space key, but actual detection uses modifier-only

**Hotkey Structure:**
```swift
struct Hotkey: Codable, Equatable {
    var keyCode: UInt16
    var command: Bool
    var option: Bool
    var shift: Bool
    var control: Bool
}
```

---

### 6. StatusBarController (`Sources/Punto/App/StatusBarController.swift`)

**Menu Structure:**
```
┌─────────────────────────────┐
│  ✓ Enabled                  │  ← Toggle on/off
│  ─────────────────────────  │
│  Settings...                │  ← Opens settings window
│  ─────────────────────────  │
│  Quit Punto                 │
└─────────────────────────────┘
```

**Icon:** SF Symbol `keyboard` or Unicode `⌨`

**Flash Animation:** Brief icon highlight on successful conversion (0.15s accent color tint)

---

### 7. InputSourceManager (`Sources/Punto/Core/InputSourceManager.swift`)

**Purpose:** Manages system keyboard layout switching via TIS API.

**Layout Detection:**
- Finds English layout by: `languages.contains("en")` OR sourceId contains "US"/"ABC"
- Finds Russian layout by: `languages.contains("ru")` OR sourceId contains "Russian"

**API:**
```swift
class InputSourceManager {
    func switchTo(_ language: KeyboardLanguage) -> Bool
    func refreshInputSources()
}
```

**Usage:** Called by AppDelegate when `switchLayoutAfterConversion` setting is enabled. The switch happens after successful text conversion.

**Note:** When Punto programmatically switches layout, it sets `ignoreNextInputSourceChange` flag in AppDelegate to prevent the system notification from clearing WordTracker buffer.

---

## Data Flow

### Conversion Flow (Last Word)

```
1. User types "ghbdtn"
   │
   ▼
2. HotkeyManager captures keyDown events
   │
   ▼
3. WordTracker.trackKeyPress() adds each character to ring buffer
   Buffer: ['g', 'h', 'b', 'd', 't', 'n']
   │
   ▼
4. User presses Cmd+Opt+Shift (all together)
   │
   ▼
5. HotkeyManager detects flagsChanged with all 3 modifiers
   │
   ▼
6. AppDelegate.handleConvertLayout() called
   │
   ├─► hotkeyManager.ignoreEvents = true (prevent re-capture)
   │
   ▼
7. TextAccessor.getSelectedText() returns nil (nothing selected)
   │
   ▼
8. WordTracker.getLastWord() returns "ghbdtn"
   │
   ▼
9. LayoutConverter.convert("ghbdtn") returns "привет"
   │
   ▼
10. TextAccessor.replaceLastWord(6, "привет")
    │
    ├─► Send 6 backspace events (no delay between)
    ├─► Wait 0.02s
    ├─► Paste "привет" via clipboard + Cmd+V
    └─► Restore original clipboard after 0.3s
   │
   ▼
11. WordTracker.clear()
    │
    ▼
12. After 0.3s delay: hotkeyManager.ignoreEvents = false
```

### Conversion Flow (Selected Text)

```
1. User selects text "hello" in any app
   │
   ▼
2. User presses Cmd+Opt+Shift
   │
   ▼
3. AppDelegate.handleConvertLayout() called
   │
   ▼
4. TextAccessor.getSelectedText() returns "hello"
   (via Accessibility API or Clipboard fallback)
   │
   ▼
5. LayoutConverter.convert("hello") returns "руддщ"
   │
   ▼
6. TextAccessor.setSelectedText("руддщ")
   (via Accessibility API or Cmd+V)
```

---

## Known Issues & Solutions

### Issue 1: Converted text gets re-captured
**Problem:** After converting "hello" → "руддщ", the simulated typing generates CGEvents that get captured by WordTracker, causing the next conversion to convert "руддщ" back to "hello".

**Solution:** `ignoreEvents` flag in HotkeyManager, set true during replacement, re-enabled after 0.3s delay.

### Issue 2: Multiple rapid triggers
**Problem:** Modifier-only hotkey fires multiple times while modifiers are held.

**Solution:**
1. `convertHotkeyTriggered` flag prevents re-trigger while modifiers held
2. 0.5s debounce via `lastConvertTime`
3. Reset only when ALL modifiers released

### Issue 3: Accessibility permissions not detected after rebuild
**Problem:** macOS caches permissions by code signature. After rebuild, permissions may not be recognized.

**Solution:**
1. Run binary directly: `Release/Punto.app/Contents/MacOS/Punto`
2. Or toggle permission off/on in System Settings
3. Or remove and re-add app to Accessibility list

### Issue 4: Event tap disabled by system
**Problem:** macOS can disable event tap under heavy load or for security.

**Solution:** Check for `tapDisabledByTimeout` and `tapDisabledByUserInput` events, re-enable tap:
```swift
if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
    CGEvent.tapEnable(tap: tap, enable: true)
}
```

---

## File Structure

```
Punto/
├── Package.swift                 # SPM manifest
├── Sources/
│   ├── Punto/
│   │   ├── main.swift            # Entry point (NSApplicationMain)
│   │   ├── App/
│   │   │   ├── AppDelegate.swift           # Lifecycle, permissions, orchestration
│   │   │   └── StatusBarController.swift   # Menu bar UI
│   │   ├── Core/
│   │   │   ├── HotkeyManager.swift         # CGEvent tap, hotkey detection
│   │   │   ├── TextAccessor.swift          # Get/set text via Accessibility
│   │   │   ├── LayoutConverter.swift       # EN↔RU character mapping
│   │   │   ├── WordTracker.swift           # Ring buffer for last word
│   │   │   └── Logger.swift                # File-based logging (/tmp/punto.log)
│   │   ├── UI/
│   │   │   ├── SettingsWindowController.swift
│   │   │   ├── HotkeyRecorderView.swift
│   │   │   ├── OnboardingAlert.swift
│   │   │   └── Styles.swift
│   │   └── Settings/
│   │       └── SettingsManager.swift       # UserDefaults persistence
│   ├── PuntoDiag/
│   │   └── main.swift            # Diagnostic tool
│   └── PuntoTest/
│       └── main.swift            # Test suite
├── Resources/
│   ├── Info.plist
│   ├── Punto.entitlements
│   └── Assets.xcassets/
├── Scripts/
│   ├── build.sh                  # Build universal binary + app bundle
│   └── debug.sh                  # Debug utilities
└── Release/
    └── Punto.app/                # Built application
```

---

## Build Process

```bash
# Build for both architectures
swift build -c release --arch arm64
swift build -c release --arch x86_64

# Create universal binary
lipo -create \
    .build/arm64-apple-macosx/release/Punto \
    .build/x86_64-apple-macosx/release/Punto \
    -output .build/universal/Punto

# Create app bundle
mkdir -p Release/Punto.app/Contents/{MacOS,Resources}
cp .build/universal/Punto Release/Punto.app/Contents/MacOS/
cp Resources/Info.plist Release/Punto.app/Contents/

# Sign (ad-hoc for local use)
codesign --force --deep --sign - Release/Punto.app
```

---

## Required Permissions

### Accessibility (mandatory)
- Required for: CGEvent Tap, reading/writing text in other apps
- Location: System Settings → Privacy & Security → Accessibility
- API: `AXIsProcessTrusted()`

### Input Monitoring (may be required)
- Required for: Some apps block CGEvent Tap without this
- Location: System Settings → Privacy & Security → Input Monitoring

---

## Logging

**Log File:** `/tmp/punto.log`

**Log Format:**
```
[HH:mm:ss.SSS] [FileName:Line] LEVEL: Message
```

**Log Levels:**
- `INFO` — Important events (startup, hotkey triggers, conversions)
- `DEBUG` — Detailed events (key presses, event types)
- `ERROR` — Failures (permissions, event tap creation)

**View Logs:**
```bash
tail -f /tmp/punto.log
```

---

## Testing

### Run Test Suite
```bash
swift run PuntoTest all
```

### Test Commands
- `convert` — Test layout conversion logic
- `track` — Test word tracking
- `sim` — Simulate typing and conversion
- `stress` — Rapid conversion stress test
- `bugs` — Edge case bug hunting

### Manual Testing Checklist
1. [ ] Type "ghbdtn" → Cmd+Opt+Shift → should become "привет"
2. [ ] Type "привет" → Cmd+Opt+Shift → should become "ghbdtn"
3. [ ] Select "hello" → Cmd+Opt+Shift → should become "руддщ"
4. [ ] Select "HELLO" → Cmd+Opt+Z → should become "hello"
5. [ ] Rapid hotkey presses should not cause back-and-forth conversion
6. [ ] Works in: TextEdit, Notes, VS Code, Chrome, Terminal

---

## Key Constants

```swift
// Key Codes
let spaceKeyCode: UInt16 = 49
let deleteKeyCode: UInt16 = 51
let returnKeyCode: UInt16 = 36
let zKeyCode: UInt16 = 6

// Timing
let debounceInterval: TimeInterval = 0.5      // Between modifier-only hotkey triggers
let ignoreEventsDelay: TimeInterval = 0.3     // After text replacement
let postBackspaceDelay: TimeInterval = 0.02   // After all backspaces, before paste
let postPasteDelay: TimeInterval = 0.03       // After Cmd+V paste
let clipboardRestoreDelay: TimeInterval = 0.3 // Before restoring original clipboard

// Buffer
let maxWordLength: Int = 50                 // Ring buffer size
```

---

## Troubleshooting

### App doesn't start
1. Check Console.app for crash logs
2. Run directly: `./Release/Punto.app/Contents/MacOS/Punto`
3. Check logs: `cat /tmp/punto.log`

### Hotkeys don't work
1. Verify Accessibility permission granted
2. Check logs for "Event tap created successfully"
3. Run `swift run PuntoDiag permissions`

### Conversion doesn't appear in app
1. Check if Accessibility API works: look for "Converting selected text" in logs
2. If using clipboard fallback: check if Cmd+V is blocked by app
3. Try different app (TextEdit is most reliable)

### Text converts back immediately
1. Should be fixed with `ignoreEvents` flag
2. Check logs for rapid successive conversions
3. Increase `ignoreEventsDelay` if needed

---

## API Reference

### HotkeyManager
```swift
class HotkeyManager {
    var ignoreEvents: Bool
    func start()
    func stop()
}
```

### TextAccessor
```swift
class TextAccessor {
    func getSelectedText() -> String?
    func setSelectedText(_ text: String)
    func replaceLastWord(wordLength: Int, with replacement: String)
}
```

### LayoutConverter
```swift
class LayoutConverter {
    func convert(_ text: String) -> String
    func convertToRussian(_ text: String) -> String
    func convertToEnglish(_ text: String) -> String
    func detectLayout(_ text: String) -> DetectedLayout
}
```

### WordTracker
```swift
class WordTracker {
    func trackKeyPress(keyCode: UInt16, characters: String?)
    func getLastWord() -> String?
    func clear()
}
```

### SettingsManager
```swift
class SettingsManager {
    var isEnabled: Bool
    var isFirstLaunch: Bool
    var launchAtLogin: Bool
    var convertLayoutHotkey: Hotkey
    var toggleCaseHotkey: Hotkey
}
```
