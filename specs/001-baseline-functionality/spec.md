# Feature Specification: Baseline Punto Functionality

**Feature Branch**: `001-baseline-functionality`
**Created**: 2026-01-17
**Status**: Draft
**Input**: User description: "Baseline specification of Punto core functionality - keyboard layout conversion between Russian and English"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Convert Last Typed Word (Priority: P1)

A user types text in the wrong keyboard layout (e.g., types "ghbdtn" when they meant to type "привет" in Russian). Without selecting anything, they press the conversion hotkey to convert the last typed word to the correct layout.

**Why this priority**: This is the most frequent use case. Users often realize they're typing in the wrong layout only after completing a word. Converting the last word without selection is the fastest correction method.

**Independent Test**: Type any word in wrong layout, press Cmd+Opt+Shift (modifier-only, release to trigger), verify the word converts correctly while cursor position is maintained.

**Acceptance Scenarios**:

1. **Given** user has typed "ghbdtn" (Russian word in English layout), **When** user presses and releases Cmd+Opt+Shift, **Then** the text is replaced with "привет"
2. **Given** user has typed "руддщ" (English word in Russian layout), **When** user presses and releases Cmd+Opt+Shift, **Then** the text is replaced with "hello"
3. **Given** user has typed nothing (empty buffer), **When** user presses Cmd+Opt+Shift, **Then** nothing happens and no error occurs
4. **Given** user has typed a word and then pressed space, **When** user presses Cmd+Opt+Shift, **Then** nothing happens because word buffer was cleared by space
5. **Given** user just converted a word (within 3 seconds), **When** user presses Cmd+Opt+Shift again, **Then** the conversion is undone (text reverts to original)

---

### User Story 2 - Convert Selected Text (Priority: P2)

A user selects a portion of text that was typed in the wrong keyboard layout and wants to convert it to the correct layout.

**Why this priority**: Selection-based conversion is less frequent but essential for correcting text already committed (after spaces, line breaks, or in existing documents).

**Independent Test**: Select any text, press Cmd+Opt+Shift, verify selected text converts while selection is preserved.

**Acceptance Scenarios**:

1. **Given** user has selected "hello" in a text field, **When** user presses Cmd+Opt+Shift, **Then** the selection is replaced with "руддщ"
2. **Given** user has selected mixed text "hello мир", **When** user presses Cmd+Opt+Shift, **Then** each character converts based on majority of convertible characters
3. **Given** user has selected text containing numbers and symbols "hello123!", **When** user presses Cmd+Opt+Shift, **Then** letters convert but numbers and non-mapped symbols remain unchanged
4. **Given** user just converted selected text (within 3 seconds), **When** user presses Cmd+Opt+Shift again, **Then** the conversion is undone

---

### User Story 3 - Toggle Text Case (Priority: P3)

A user has selected text and wants to toggle between uppercase and lowercase without changing the keyboard layout.

**Why this priority**: Case toggling is a convenience feature that complements layout conversion but is used less frequently.

**Independent Test**: Select any text, press Cmd+Opt+Z, verify case toggles correctly.

**Acceptance Scenarios**:

1. **Given** user has selected "hello", **When** user presses Cmd+Opt+Z, **Then** the selection becomes "HELLO"
2. **Given** user has selected "HELLO", **When** user presses Cmd+Opt+Z, **Then** the selection becomes "hello"
3. **Given** user has selected "HeLLo" (mixed case, majority uppercase), **When** user presses Cmd+Opt+Z, **Then** the selection becomes "hello"
4. **Given** user has selected "привет", **When** user presses Cmd+Opt+Z, **Then** the selection becomes "ПРИВЕТ"

---

### User Story 4 - Automatic Layout Switch After Conversion (Priority: P4)

When enabled, after converting text the system keyboard layout automatically switches to match the converted text language.

**Why this priority**: Convenience feature that reduces additional manual actions after conversion.

**Independent Test**: Enable setting, convert EN→RU text, verify system keyboard switches to Russian.

**Acceptance Scenarios**:

1. **Given** setting "Switch layout after conversion" is enabled AND user converts "ghbdtn" to "привет", **When** conversion completes, **Then** system keyboard layout switches to Russian
2. **Given** setting "Switch layout after conversion" is disabled, **When** user converts text, **Then** system keyboard layout remains unchanged
3. **Given** conversion result is mixed/unknown layout, **When** conversion completes, **Then** system keyboard layout remains unchanged

---

### Edge Cases

- What happens when user rapidly presses the hotkey multiple times?
  - Debouncing (0.5s) prevents multiple conversions; text converts once
- How does system handle apps that block Accessibility API (Chrome, Safari, Electron)?
  - Multi-fallback strategy for GET: (1) Direct AX on focused element, (2) AX via app's focusedUIElement, (3) Recursive child search (depth 5), (4) Cmd+C clipboard with polling (20ms intervals, max 200ms)
  - Clipboard fallback sends Cmd+C via `cgAnnotatedSessionEventTap` first, then `cghidEventTap` after 60ms if no response
  - Original clipboard restored asynchronously after 0.3s via DispatchQueue.main.asyncAfter
- What if AX returns empty string vs fails?
  - Empty string = nothing selected, skip clipboard fallback (use WordTracker instead)
  - AX failure = try clipboard fallback for browsers
  - No focused element = try clipboard fallback (some apps like VS Code extension host don't expose AX but support Cmd+C)
- What happens when the event tap is disabled by macOS?
  - System re-enables the tap automatically on `tapDisabledByTimeout` or `tapDisabledByUserInput` events
- What happens when user holds modifier keys without releasing?
  - Conversion triggers only when ALL modifiers are released (not just some); only triggers once until all modifiers released
- What happens when user presses a regular key while modifiers are held (e.g., Cmd+Opt+V)?
  - The modifier-only detection is cancelled; regular key shortcut proceeds normally
- What happens when Punto's settings window is active?
  - Hotkeys are not intercepted (detected by checking if our app is frontmost with a key window different from main window)
- What about undo functionality?
  - Pressing hotkey within 3 seconds of conversion reverts to original text
  - Any other key press clears undo history (protected by `isConversionInProgress` flag to prevent race condition)
  - Converted text stays selected after conversion for easy re-conversion
- What happens when user switches keyboard layout while typing?
  - WordTracker subscribes to `kTISNotifySelectedKeyboardInputSourceChanged` and clears buffer on layout change
  - Mixed-layout words (containing both EN and RU letters) are rejected and buffer is cleared
  - Programmatic layout switches (after conversion with "switch layout" enabled) are ignored via `ignoreNextInputSourceChange` flag
- What happens when user types Cmd+C or other shortcuts while typing a word?
  - Keys with modifiers (except Shift) are not tracked by WordTracker to avoid corrupting the buffer
- What happens in password fields or secure input mode?
  - System checks `IsSecureEventInputEnabled()` and blocks conversion for security
- What happens when Accessibility API returns success but doesn't actually change text (Safari bug)?
  - System verifies text actually changed after AX set; falls back to clipboard if unchanged
- What happens when AX API temporarily returns error -25212?
  - getFocusedElement retries up to 3 times with 50ms delay between attempts
- How does backward selection work after clipboard paste (for undo support)?
  - Always character-by-character Shift+Left (word-based Opt+Shift+Left can overshoot)

## Requirements *(mandatory)*

### Functional Requirements

#### Hotkey Detection
- **FR-001**: System MUST detect modifier-only hotkey (Cmd+Opt+Shift) via CGEvent tap on `flagsChanged` events, triggering on modifiers release
- **FR-002**: System MUST detect key-based hotkey (Cmd+Opt+Z) via CGEvent tap on `keyDown` events
- **FR-003**: System MUST cancel modifier-only detection if any regular key is pressed while modifiers are held
- **FR-004**: System MUST implement 0.5s debouncing between conversion triggers via `lastTriggerTime` timestamp
- **FR-005**: System MUST skip hotkey interception when Punto's own settings window is focused (for hotkey recording)

#### Word Tracking
- **FR-006**: System MUST track last typed word in a ring buffer (max 50 characters). Only track keys without modifiers (except Shift for capital letters)
- **FR-007**: System MUST clear word buffer on word boundaries: space, tab, newline, and separators (`! ? ( ) / \ | @ # $ % ^ & * + = - _`). Note: punctuation that maps to Russian letters (`;'[],.`) is NOT a boundary
- **FR-008**: System MUST clear word buffer on navigation keys (arrows, Home, End, Page Up/Down, Forward Delete)
- **FR-009**: System MUST handle Delete/Backspace by removing last character from buffer
- **FR-009a**: System MUST clear word buffer when system keyboard layout changes (via `kTISNotifySelectedKeyboardInputSourceChanged`), but ignore programmatic layout switches triggered by conversion (via `ignoreNextInputSourceChange` flag)
- **FR-009b**: System MUST reject mixed-layout words (containing both EN and RU letters) and clear buffer

#### Layout Conversion
- **FR-010**: System MUST convert text between Russian (ЙЦУКЕН) and English (QWERTY) layouts bidirectionally using character mapping tables
- **FR-011**: System MUST auto-detect source layout: >80% English letters → English, <20% English letters → Russian, otherwise mixed
- **FR-012**: System MUST handle mixed text by converting based on majority of mappable characters
- **FR-013**: System MUST preserve unmapped characters (numbers, symbols not in mapping) unchanged

#### Text Access
- **FR-014**: System MUST access selected text via multi-level Accessibility API strategy:
  - (1) Direct `kAXSelectedTextAttribute` on focused element (with retry: 3 attempts, 50ms delay)
  - (2) Via application's `kAXFocusedUIElementAttribute` (for Safari/Electron)
  - (3) Recursive search in child elements (max depth 5)
- **FR-015**: System MUST fall back to clipboard method when all AX strategies fail:
  - (1) Cmd+C via `cgAnnotatedSessionEventTap` (works for browsers)
  - (2) Poll clipboard every 20ms (max 10 iterations = 200ms total)
  - (3) After 60ms without response, also send Cmd+C via `cghidEventTap` as HID fallback
- **FR-015a**: System MUST track which method (AX or clipboard) was used for get, and use matching method for set
- **FR-015b**: System MUST verify AX set actually changed text (Safari returns success but doesn't change); fall back to clipboard if unchanged
- **FR-016**: System MUST restore original clipboard content after clipboard fallback operations (0.3s delay)
- **FR-017**: System MUST replace last word using character-by-character Backspace + Cmd+V (paste from clipboard). Note: Opt+Backspace doesn't work reliably in browsers
- **FR-018**: System MUST set `ignoreEvents` flag (thread-safe via DispatchQueue) during text replacement to prevent re-capture (0.3s duration)
- **FR-018a**: System MUST block conversion when `IsSecureEventInputEnabled()` returns true (password fields)
- **FR-018b**: System MUST use AXGetResult enum to distinguish between: text found, empty selection, no focus, AX failure
- **FR-018c**: System MUST select converted text after clipboard paste using character-by-character backward selection (Shift+Left). Note: word-based selection (Opt+Shift+Left) can overshoot

#### Undo Functionality
- **FR-019**: System MUST store last conversion info (original text, converted text, timestamp, selection flag)
- **FR-020**: System MUST revert to original text if hotkey pressed within 3 seconds of previous conversion
- **FR-021**: System MUST clear undo history on any regular key press (protected by `isConversionInProgress` flag to prevent race condition with async key events)
- **FR-021a**: System MUST keep converted text selected after conversion (via `keepSelection` parameter) to enable quick undo/re-conversion
- **FR-021b**: System MUST clear undo history when keyboard layout changes

#### Case Toggle
- **FR-022**: System MUST toggle case based on majority analysis (>=50% uppercase → lowercase, else → uppercase)
- **FR-023**: Case toggle MUST only work on selected text (not last word)

#### UI & Settings
- **FR-024**: System MUST display as menu bar application with custom icon (loaded from `MenuBarIcon` asset)
- **FR-025**: System MUST hide dock icon (LSUIElement)
- **FR-026**: System MUST provide Enable/Disable toggle in menu bar dropdown
- **FR-027**: System MUST display current hotkeys in menu bar dropdown
- **FR-028**: System MUST persist settings via UserDefaults: isEnabled, launchAtLogin, hotkeys, switchLayoutAfterConversion
- **FR-029**: System MUST support configurable hotkeys via settings window with live recording
- **FR-030**: System MUST flash menu bar icon briefly (0.15s accent color) on successful conversion

#### Permissions & Onboarding
- **FR-031**: System MUST check `AXIsProcessTrusted()` on startup
- **FR-032**: System MUST show onboarding alert on first launch explaining required permissions
- **FR-033**: System MUST show permission alert if Accessibility not granted, with button to open System Settings
- **FR-034**: System MUST periodically check permissions (2s interval) until granted

#### Optional Features
- **FR-035**: System MAY switch system keyboard layout after conversion (when `switchLayoutAfterConversion` enabled)
- **FR-036**: System MAY support launch at login via SMAppService (macOS 13+) or SMLoginItemSetEnabled (older)

### Key Entities

- **Word Buffer**: Ring buffer (array-based, size 50) storing typed characters, with head pointer and count; cleared on word boundaries and layout changes; validates for mixed-layout corruption
- **Character Mapping**: Two dictionaries (EN→RU, RU→EN) covering lowercase, uppercase, Shift+number symbols, and special characters; handles ambiguous RU→EN mappings (e.g., `"` → `@`, `;` → `$`)
- **Hotkey**: Struct with keyCode (UInt16), command/option/shift/control flags (Bool); special `modifierOnlyKeyCode` (UInt16.max) for modifier-only hotkeys
- **Settings**: UserDefaults-backed properties: isEnabled, isFirstLaunch, showInMenuBar, launchAtLogin, convertLayoutHotkey, toggleCaseHotkey, switchLayoutAfterConversion
- **LastConversion**: Struct tracking originalText, convertedText, timestamp, wasSelection for undo support
- **InputSourceManager**: TIS API wrapper for detecting and switching between English/Russian keyboard layouts
- **TextAccessor**: Manages text access with AX API multi-level strategy + clipboard fallback; tracks `lastGetUsedClipboard` to match get/set methods; detects secure input mode; uses AXGetResult enum for granular result handling
- **AXGetResult**: Enum distinguishing AX API outcomes: `.text(String)` for selected text, `.empty` for no selection, `.noFocus` for no focused element (try clipboard fallback), `.failed` for AX failure (try clipboard fallback)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can convert a mistyped word in under 1 second (hotkey press to visual result)
- **SC-002**: Layout conversion works correctly in at least 95% of macOS applications (multi-level AX strategy + clipboard fallback chain)
- **SC-003**: App responds to hotkey within 50ms of modifier release
- **SC-004**: App uses less than 50MB memory during normal operation
- **SC-005**: App uses less than 1% CPU when idle (no typing activity)
- **SC-006**: Users can complete first-time setup (grant permissions, verify functionality) within 2 minutes
- **SC-007**: Rapid hotkey presses (within 0.5s) result in exactly one conversion due to debouncing
- **SC-008**: Text never converts back to original immediately after conversion (thread-safe ignoreEvents flag prevents re-capture)
- **SC-009**: Undo works reliably within 3-second window when no other keys pressed (race condition protected by isConversionInProgress)
- **SC-010**: Menu bar icon flash provides visible feedback on every successful conversion
- **SC-011**: Conversion never occurs in password/secure input fields
- **SC-012**: Word buffer never contains mixed-layout characters (cleared on layout switch or rejected on detection)
