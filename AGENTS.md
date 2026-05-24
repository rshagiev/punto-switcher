# Punto — macOS Keyboard Layout Switcher

> **Domain:** macOS tool (Swift)
> **Location:** `~/Projects/Punto`
> **Tier:** 1 (Slim reference)
> **Maturity:** production

## Quick Context
- Menu bar app for keyboard layout conversion (EN ↔ RU)
- Modifier-only hotkey: Cmd+Opt+Shift (no extra key needed)
- Uses Accessibility API + clipboard fallback for text manipulation
- Supports terminals (Ghostty, iTerm2, Terminal.app, Alacritty, Kitty)
- Undo support: повторное нажатие hotkey в течение 3 сек отменяет конвертацию

## Quick Start
```bash
# Build, sign, deploy & restart
./Scripts/deploy.sh

# Run tests
swift run PuntoCoreTest
swift run PuntoSettingsTest
swift run PuntoParityTest

# View logs
tail -f /tmp/punto.log
```

---

## Documentation

| Документ | Описание |
|----------|----------|
| `docs/TECHNICAL_SPEC.md` | Полная техническая спецификация |
| `docs/FLOWS.md` | ASCII-диаграммы потоков данных |
| `docs/PROTECTION_MECHANISMS.md` | Защитные механизмы и edge cases |

---

## Hotkeys
- **Cmd+Opt+Shift** (modifier-only) → Конвертация раскладки
- **Cmd+Opt+Z** → Переключение регистра (UPPER ↔ lower)
- **Повторное Cmd+Opt+Shift** (< 3 сек) → Undo последней конвертации

## Key Files

| Task | File |
|------|------|
| App lifecycle, orchestration | `Sources/Punto/App/AppDelegate.swift` |
| Hotkey detection | `Sources/PuntoRuntime/HotkeyManager.swift` |
| Text get/set | `Sources/PuntoRuntime/TextAccessor.swift` |
| Character mapping | `Sources/PuntoCore/LayoutConverter.swift` |
| Word tracking | `Sources/PuntoCore/WordTracker.swift` |
| Layout switching | `Sources/PuntoRuntime/InputSourceManager.swift` |
| Settings storage | `Sources/PuntoSettings/SettingsManager.swift` |
| Menu bar UI | `Sources/Punto/App/StatusBarController.swift` |

## Build & Run

```bash
# Quick build (arm64 only), sign, deploy and restart
./Scripts/deploy.sh

# Full build (universal)
./Scripts/build.sh
open Release/Punto.app
```

**ВАЖНО:** После любых изменений кода — запускать `./Scripts/deploy.sh`. Простое копирование бинаря без переподписи ломает bundle signature и может сбросить/сломать Accessibility identity.

---

## Critical Implementation Details

### 1. Modifier-Only Hotkey Detection
Детектируется через `flagsChanged` events. Срабатывает когда:
- Все модификаторы (Cmd+Opt+Shift) были нажаты
- Все модификаторы отпущены
- Прошло > 0.5 сек с последнего срабатывания (debounce)

### 2. Re-Capture Prevention
При конвертации наши CGEvents могут перехватываться:
```swift
hotkeyManager.ignoreEvents = true
// ... конвертация ...
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    hotkeyManager.ignoreEvents = false
}
```

### 3. Input Source Change Protection
При программном переключении раскладки:
```swift
ignoreInputSourceChangesUntil = Date().addingTimeInterval(0.75)
inputSourceManager?.switchTo(.russian)
// В inputSourceChanged(): уведомления внутри grace window не очищают WordTracker
```

### 4. Text Access Strategy
1. AX API direct (kAXSelectedTextAttribute)
2. AX API via app focusedUIElement (Safari/Electron)
3. Recursive search in children (depth ≤ 5)
4. Clipboard fallback (Cmd+C)

### 5. Terminal-Like Surface Support
- Не определять терминалы по bundle ID как основной механизм
- `TextAccessor.captureSelectedText(lastTrackedWord:)` выбирает стратегию по runtime capability
- AX selection используется только если focused element поддерживает замену `AXSelectedText`
- Non-settable/terminal-like surfaces не заменяются через AX; если есть non-settable selection, Punto конвертирует только tracked typed tail текущей команды, а passive clipboard принимается только когда trimmed clipboard точно совпадает с tracked typed tail и заканчивается `lastTrackedWord`
- Замена для keyboard-tail strategy: backspaces + Cmd+V, не `setSelectedText`

### 6. Security
- `isSecureInputEnabled()` — блок при Terminal password prompts
- `isPasswordField()` — блок для AXSecureTextField (browser passwords)

---

## AppDelegate Flags

| Флаг | Назначение |
|------|------------|
| `isConversionInProgress` | Race condition protection |
| `ignoreInputSourceChangesUntil` | Grace window for programmatic layout switch notifications |
| `lastConversion` | Undo data (original, converted, timestamp) |

## Timings

| Параметр | Значение |
|----------|----------|
| Debounce modifier-only | 0.5 сек |
| ignoreEvents delay | 0.3 сек |
| Undo window | 3.0 сек |
| Backspace delay | 0.02 сек |
| Clipboard poll | 0.02 × 10 сек |

---

## Common Issues

| Problem | Solution |
|---------|----------|
| Permissions not working | Run binary directly, not via `open` |
| Hotkey triggers multiple times | Check debounce and modifiersWerePressed |
| Text converts back | Check ignoreEvents flag |
| Event tap disabled | Auto re-enabled on tapDisabledByTimeout |
| WordTracker empty | Check `ignoreInputSourceChangesUntil` grace window |
| Safari not working | Uses clipboard fallback automatically |

## Character Mapping (partial)
```
EN → RU: q→й w→ц e→у r→к t→е y→н u→г i→ш o→щ p→з
         a→ф s→ы d→в f→а g→п h→р j→о k→л l→д
         z→я x→ч c→с v→м b→и n→т m→ь
         [→х ]→ъ ;→ж '→э `→ё ,→б .→ю
```

---

## Terminal-Like Apps

Поддержка должна быть capability-based, а не через список bundle ID. Если приложение не даёт безопасно заменить AX selection, Punto использует tracked last word или passive clipboard tail selection и keyboard replacement.
