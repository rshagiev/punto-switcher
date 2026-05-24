# Punto - Comprehensive Test Cases

This document contains all test cases for the Punto keyboard layout converter.

## 1. Basic EN to RU Conversions

| Input | Expected | Description | Status |
|-------|----------|-------------|--------|
| `ghbdtn` | `привет` | Standard word | - |
| `hello` | `руддщ` | English word | - |
| `world` | `цщкдв` | English word | - |
| `q` | `й` | Single letter | - |
| `GHBDTN` | `ПРИВЕТ` | All caps | - |
| `Ghbdtn` | `Привет` | First letter capitalized | - |
| `test` | `еуые` | Common word | - |

## 2. Basic RU to EN Conversions

| Input | Expected | Description | Status |
|-------|----------|-------------|--------|
| `привет` | `ghbdtn` | Russian word | - |
| `руддщ` | `hello` | Russian word | - |
| `мир` | `vbh` | Russian word | - |
| `й` | `q` | Single letter | - |
| `ПРИВЕТ` | `GHBDTN` | All caps | - |
| `Привет` | `Ghbdtn` | First letter capitalized | - |

## 3. Special Characters EN to RU

| Input | Expected | Description | Status |
|-------|----------|-------------|--------|
| `[` | `х` | Open bracket | - |
| `]` | `ъ` | Close bracket | - |
| `{` | `Х` | Open brace | - |
| `}` | `Ъ` | Close brace | - |
| `;` | `ж` | Semicolon | - |
| `'` | `э` | Apostrophe | - |
| `:` | `Ж` | Colon | - |
| `"` | `Э` | Double quote | - |
| `,` | `б` | Comma | - |
| `.` | `ю` | Period | - |
| `/` | `.` | Slash | - |
| `?` | `,` | Question mark | - |
| `<` | `Б` | Less than | - |
| `>` | `Ю` | Greater than | - |
| `` ` `` | `ё` | Backtick | - |
| `~` | `Ё` | Tilde | - |

## 4. Special Characters RU to EN

| Input | Expected | Description | Status |
|-------|----------|-------------|--------|
| `х` | `[` | Russian х | - |
| `ъ` | `]` | Russian ъ | - |
| `Х` | `{` | Russian Х | - |
| `Ъ` | `}` | Russian Ъ | - |
| `ж` | `;` | Russian ж | - |
| `э` | `'` | Russian э | - |
| `Ж` | `:` | Russian Ж | - |
| `Э` | `"` | Russian Э | - |
| `б` | `,` | Russian б | - |
| `ю` | `.` | Russian ю | - |
| `ё` | `` ` `` | Russian ё | - |
| `Ё` | `~` | Russian Ё | - |

## 5. Numbers and Spaces (Should Preserve)

| Input | Expected | Description | Status |
|-------|----------|-------------|--------|
| `123` | `123` | Numbers only | - |
| `hello 123` | `руддщ 123` | Text + numbers | - |
| `test123test` | `еуые123еуые` | Numbers inside word | - |
| `   ` | `   ` | Only spaces | - |
| `hello world` | `руддщ цщкдв` | Two words | - |
| `0` | `0` | Single zero | - |
| `9876543210` | `9876543210` | All digits | - |

## 6. Case Preservation

| Input | Expected | Description | Status |
|-------|----------|-------------|--------|
| `HeLLo` | `РуДДщ` | Mixed case | - |
| `HELLO` | `РУДДЩ` | Full caps | - |
| `hello` | `руддщ` | Lowercase | - |
| `Hello World` | `Руддщ Цщкдв` | Title case | - |
| `hELLO` | `рУДДЩ` | Inverted case | - |
| `Q` | `Й` | Single uppercase | - |
| `Й` | `Q` | Single uppercase RU | - |

## 7. Empty and Boundary Cases

| Input | Expected | Description | Status |
|-------|----------|-------------|--------|
| `` | `` | Empty string | - |
| ` ` | ` ` | Single space | - |
| `\n` | `\n` | Newline | - |
| `\t` | `\t` | Tab | - |
| `\r` | `\r` | Carriage return | - |

## 8. Long Strings (Buffer Tests)

| Input Length | Description | Status |
|--------------|-------------|--------|
| 50 chars | Ring buffer boundary | - |
| 51 chars | Ring buffer overflow | - |
| 100 chars | Double overflow | - |
| 1000 chars | Stress test | - |

Test strings:
- 50 chars: `qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvb`
- 51 chars: `qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbn`

## 9. WordTracker Edge Cases

**IMPORTANT**: Many punctuation marks map to Russian letters and should NOT clear the buffer!

| Action | Expected Buffer | Description | Status |
|--------|-----------------|-------------|--------|
| Type `hello` | `hello` | Basic tracking | - |
| `hello` + Space | `` | Space clears | - |
| `hello` + `.` | `hello.` | Period STAYS (maps to ю) | - |
| `hello` + Backspace | `hell` | Remove last | - |
| 5x Backspace on `hello` | `` | Full delete | - |
| 6x Backspace on `hello` | `` | Extra backspace | - |
| `hello world` | `world` | Only last word | - |
| Left arrow | `` | Navigation clears | - |
| Return/Enter | `` | Enter clears | - |
| `hello` + `,` | `hello,` | Comma STAYS (maps to б) | - |
| `hello` + `!` | `` | Exclamation clears | - |
| `hello` + `?` | `hello?` | Question mark STAYS (maps to comma) | - |
| `hello` + `:` | `hello:` | Colon STAYS (maps to Ж) | - |
| `hello` + `;` | `hello;` | Semicolon STAYS (maps to ж) | - |
| `hello` + `'` | `hello'` | Apostrophe STAYS (maps to э) | - |
| `hello` + `[` | `hello[` | Bracket STAYS (maps to х) | - |
| `hello` + `` ` `` | ``hello` `` | Backtick STAYS (maps to ё) | - |

## 10. Special KeyCodes

| KeyCode | Key | Action | Status |
|---------|-----|--------|--------|
| 49 | Space | Clears buffer | - |
| 36 | Return | Clears buffer | - |
| 76 | Enter (numpad) | Clears buffer | - |
| 51 | Backspace | Removes last char | - |
| 117 | Forward Delete | Clears buffer | - |
| 123 | Left Arrow | Clears buffer | - |
| 124 | Right Arrow | Clears buffer | - |
| 125 | Down Arrow | Clears buffer | - |
| 126 | Up Arrow | Clears buffer | - |
| 115 | Home | Clears buffer | - |
| 119 | End | Clears buffer | - |
| 116 | Page Up | Clears buffer | - |
| 121 | Page Down | Clears buffer | - |

## 11. Double Conversion (Idempotence)

| Original | After 1st | After 2nd | Status |
|----------|-----------|-----------|--------|
| `hello` | `руддщ` | `hello` | - |
| `привет` | `ghbdtn` | `привет` | - |
| `HELLO` | `РУДДЩ` | `HELLO` | - |
| `ПРИВЕТ` | `GHBDTN` | `ПРИВЕТ` | - |
| `Hello World` | `Руддщ Цщкдв` | `Hello World` | - |
| `123abc` | `123фис` | `123abc` | - |
| `test!` | `еу|е!` | `test!` | - |

## 12. Unicode and Emoji

| Input | Description | Expected Behavior | Status |
|-------|-------------|-------------------|--------|
| `hello 👋` | Emoji at end | Convert text, preserve emoji | - |
| `👋 hello` | Emoji at start | Convert text, preserve emoji | - |
| `hel👋lo` | Emoji in middle | Convert text around emoji | - |
| `cafe` | No diacritics | `сфау` | - |

## 13. Punctuation (Word Boundaries)

**IMPORTANT**: Characters that map to Russian letters should NOT clear the buffer!

Characters that CLEAR WordTracker buffer:
```
Space: " "
Newlines: "\n", "\t", "\r"
Sentence terminators: "!"
Brackets: "(", ")"
Slashes on Windows-style Russian layout: "\\", "|"
Special: "@", "#", "$", "%", "^", "&", "*"
Math: "+", "=", "-", "_"
```

Characters that DO NOT clear buffer (map to Russian letters):
```
Semicolon: ";" -> ж
Apostrophe: "'" -> э
Colon: ":" -> Ж
Comma: "," -> б
Period: "." -> ю
Brackets: "[" -> х, "]" -> ъ, "{" -> Х, "}" -> Ъ
Comparison: "<" -> Б, ">" -> Ю
Backtick: "`" -> ё
Tilde: "~" -> Ё
Double quote: "\"" -> Э
Slash/question: "/" -> ., "?" -> ,
```

## 14. Stress Tests

| Test | Description | Expected | Status |
|------|-------------|----------|--------|
| 100 conversions | Rapid fire | No crashes | - |
| Fast typing simulation | ~200 WPM | Correct tracking | - |
| Round-trip 50 times | Idempotence | Return to original | - |
| Large text (10KB) | Memory test | No memory issues | - |

## 15. Layout Detection Thresholds

| EN/RU Ratio | Expected Result | Status |
|-------------|-----------------|--------|
| > 0.8 | `.english` | - |
| < 0.2 | `.russian` | - |
| 0.2 - 0.8 | `.mixed` | - |
| 0 letters | `.unknown` | - |

Test cases:
- `abcdefgh` (100% EN) -> `.english`
- `абвгдежз` (100% RU) -> `.russian`
- `abcd абвг` (50/50) -> `.mixed`
- `12345` (no letters) -> `.unknown`
- `abcdefghij абв` (77% EN) -> `.mixed` (below 0.8)
- `abcdefghijk абв` (79% EN) -> `.mixed` (below 0.8)
- `abcdefghijkl абв` (80% EN) -> `.mixed` (exact threshold is not enough)
- `abcdefghijklm абв` (>80% EN) -> `.english` (above threshold)

---

## Full Character Mapping Reference

### Lowercase EN to RU
```
q→й  w→ц  e→у  r→к  t→е  y→н  u→г  i→ш  o→щ  p→з
a→ф  s→ы  d→в  f→а  g→п  h→р  j→о  k→л  l→д
z→я  x→ч  c→с  v→м  b→и  n→т  m→ь
```

### Uppercase EN to RU
```
Q→Й  W→Ц  E→У  R→К  T→Е  Y→Н  U→Г  I→Ш  O→Щ  P→З
A→Ф  S→Ы  D→В  F→А  G→П  H→Р  J→О  K→Л  L→Д
Z→Я  X→Ч  C→С  V→М  B→И  N→Т  M→Ь
```

### Special Characters EN to RU
```
[→х  ]→ъ  {→Х  }→Ъ
;→ж  '→э  :→Ж  "→Э
,→б  .→ю  <→Б  >→Ю
/→.  ?→,
`→ё  ~→Ё
```

---

## Test Execution

### Running Tests
```bash
# Run production-code test harnesses
swift run PuntoCoreTest
swift run PuntoParityTest

# Run diagnostics
swift run PuntoDiag converter
swift run PuntoDiag tracker
swift run PuntoDiag all
```

### Test Results Summary

| Suite | Passed | Failed | Notes |
|-------|--------|--------|-------|
| Conversion | - | - | - |
| Word Tracking | - | - | - |
| Stress | - | - | - |
| Edge Cases | - | - | - |

---

## Test Results Summary

**Date:** 2026-01-18

| Suite | Passed | Failed | Notes |
|-------|--------|--------|-------|
| Conversion | 58 | 0 | All pass |
| Word Tracking | 23 | 0 | All pass |
| Double Conversion | 10 | 0 | All pass |
| Long Strings | 4 | 0 | All pass |
| Edge Cases | 10 | 0 | All pass |
| Mass Stress | 5 | 0 | All pass (100 round-trips each) |
| **Hotkey Tests** | ~30 | 0 | NEW: isModifierOnly, displayString, KeyCodeNames, Codable |
| **Shift+Number** | ~11 | 0 | NEW: @→", #→№, $→;, ^→:, &→? mappings |
| **Layout Detection** | ~13 | 0 | NEW: 80%/20% threshold boundaries |
| **Real WordTracker** | ~45 | 0 | NEW: keyCode handling, navigation keys, boundaries |
| **PuntoParityTest** | corpus | 0 | Executable documented parity corpus over production PuntoCore |
| **ConvertWithResult** | ~6 | 0 | NEW: direction metadata |
| **Unicode Boundary** | ~14 | 0 | NEW: isEnglishLetter/isRussianLetter boundaries |

**Total: ~200+ passed, 0 failed**

---

## Known Issues

None - all tests pass.

### Notes on `/`, `?`, and `.` Mapping

The mapping handles these correctly thanks to layout detection:
- EN `/` -> RU `.` (period)
- EN `?` -> RU `,` (comma)
- EN `.` -> RU `ю`

Round-trips work correctly because:
1. Text with EN letters is detected as English -> converts using `enToRu`
2. Text with RU letters is detected as Russian -> converts using `ruToEn`
3. The `.` character in `ruToEn` maps back to `/` (from reverse mapping)

Example: `path/to/file.txt` -> `зфер.ещ.ашдуюече` -> `path/to/file.txt`

---

## Changelog

- 2026-01-17: Initial version with comprehensive edge cases
- 2026-01-17: Fixed incorrect test expectations (pipe character in expected values)
- 2026-01-17: Fixed TestLayoutConverter to use layout detection (matching main app behavior)
- 2026-01-17: All 110 tests now pass
- 2026-05-24: Added executable PuntoParityTest corpus and aligned punctuation expectations with layout-aware tracking
