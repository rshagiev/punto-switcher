# Punto — Защитные механизмы

Детальное описание всех edge cases и их решений в приложении.

---

## Содержание

1. [Обзор](#1-обзор)
2. [Re-capture Prevention](#2-re-capture-prevention)
3. [Input Source Change Protection](#3-input-source-change-protection)
4. [Mixed Layout Detection](#4-mixed-layout-detection)
5. [Race Condition Prevention](#5-race-condition-prevention)
6. [Safari Text Verification](#6-safari-text-verification)
7. [Password/Secure Input](#7-passwordsecure-input)
8. [Event Tap Recovery](#8-event-tap-recovery)
9. [Cmd+V/Cmd+Z Detection](#9-cmdvcmdz-detection)
10. [Modifier-Only Hotkey Cancellation](#10-modifier-only-hotkey-cancellation)
11. [Сводная таблица](#11-сводная-таблица)

---

## 1. Обзор

Punto работает с глобальными keyboard events и Accessibility API, что создаёт множество edge cases. Каждый защитный механизм решает конкретную проблему:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    КАРТА ЗАЩИТНЫХ МЕХАНИЗМОВ                            │
│                                                                          │
│  ┌─────────────────┐                                                    │
│  │  HotkeyManager  │                                                    │
│  │  ├─ ignoreEvents     ←─── Re-capture Prevention (#2)                │
│  │  ├─ modifiersWerePressed ← Hotkey Cancellation (#10)                │
│  │  └─ Cmd+V/Z detection    ← WordTracker Clearing (#9)                │
│  └─────────────────┘                                                    │
│                                                                          │
│  ┌─────────────────┐                                                    │
│  │   AppDelegate   │                                                    │
│  │  ├─ isConversionInProgress ←── Race Condition (#5)                  │
│  │  ├─ ignoreInputSourceChangesUntil ← Input Source (#3)               │
│  │  └─ Security checks          ←── Password/Secure (#7)               │
│  └─────────────────┘                                                    │
│                                                                          │
│  ┌─────────────────┐                                                    │
│  │   WordTracker   │                                                    │
│  │  └─ isMixedLayout  ←── Mixed Layout Detection (#4)                  │
│  └─────────────────┘                                                    │
│                                                                          │
│  ┌─────────────────┐                                                    │
│  │   TextAccessor  │                                                    │
│  │  └─ Text verification ←── Safari Bug Fix (#6)                       │
│  └─────────────────┘                                                    │
│                                                                          │
│  ┌─────────────────┐                                                    │
│  │   Event Tap     │                                                    │
│  │  └─ tapDisabledBy... ←── Event Tap Recovery (#8)                    │
│  └─────────────────┘                                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Re-capture Prevention

### Проблема

При конвертации Punto отправляет CGEvents (backspaces, Cmd+V). Эти события проходят через собственный event tap и могут:

1. Триггерить WordTracker (добавлять/удалять символы)
2. Очищать undo state
3. В крайнем случае — вызывать повторную конвертацию

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            БЕЗ ЗАЩИТЫ                                    │
│                                                                          │
│  handleConvertLayout()                                                   │
│       │                                                                  │
│       ├── replaceLastWord("ghbdtn" → "привет")                          │
│       │       │                                                          │
│       │       ├── CGEvent: Backspace (keyCode=51)                       │
│       │       │       │                                                  │
│       │       │       └── HotkeyManager receives keyDown!               │
│       │       │           └── onKeyPress(51, ...) → WordTracker        │
│       │       │               удаляет символ из буфера                   │
│       │       │                                                          │
│       │       ├── CGEvent: Backspace × 5 ещё                            │
│       │       │       │                                                  │
│       │       │       └── WordTracker полностью очищается               │
│       │       │                                                          │
│       │       └── CGEvent: Cmd+V (paste)                                │
│       │               │                                                  │
│       │               └── HotkeyManager: Cmd+V detected!                │
│       │                   └── onKeyPress(9, nil) → "external command"  │
│       │                       WordTracker.clear()                        │
│       │                                                                  │
│       └── Undo сохраняется... но WordTracker уже пустой!                │
│                                                                          │
│  РЕЗУЛЬТАТ: При следующей конвертации WordTracker пуст → ничего         │
│             не конвертируется!                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

### Решение

**Файл:** `HotkeyManager.swift`, `AppDelegate.swift`

```swift
// AppDelegate: в начале handleConvertLayout()
hotkeyManager?.ignoreEvents = true

// ... конвертация ...

// AppDelegate: в конце handleConvertLayout()
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
    self?.hotkeyManager?.ignoreEvents = false
}

// HotkeyManager: в handleEvent()
if ignoreEvents {
    return Unmanaged.passUnretained(event)  // Пропустить, не обрабатывать
}
```

### Thread Safety

```swift
// HotkeyManager: ignoreEvents thread-safe
private let stateQueue = DispatchQueue(label: "com.punto.hotkeymanager.state")
private var _ignoreEvents = false

var ignoreEvents: Bool {
    get { stateQueue.sync { _ignoreEvents } }
    set { stateQueue.sync { _ignoreEvents = newValue } }
}
```

### Тайминг

| Параметр | Значение | Обоснование |
|----------|----------|-------------|
| ignoreEvents delay | 0.3 сек | Достаточно для завершения paste + буферизации |

### Визуализация

```
TIME ────────────────────────────────────────────────────────────────▶

         ignoreEvents = true                    ignoreEvents = false
                │                                       │
                ▼                                       ▼
     ┌──────────────────────────────────────────────────┐
     │        PROTECTED ZONE (0.3 sec)                  │
     │                                                  │
     │  Backspaces    Cmd+V    App processes paste     │
     │     ↓           ↓              ↓                │
     │  ignored     ignored      completed             │
     └──────────────────────────────────────────────────┘
```

---

## 3. Input Source Change Protection

### Проблема

Когда Punto программно переключает раскладку после конвертации:
1. Система отправляет `kTISNotifySelectedKeyboardInputSourceChanged`
2. `inputSourceChanged()` вызывается
3. Без защиты — WordTracker очищается
4. Undo ломается (lastConversion тоже очищается)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            БЕЗ ЗАЩИТЫ                                    │
│                                                                          │
│  handleConvertLayout()                                                   │
│       │                                                                  │
│       ├── convert("hello" → "руддщ")                                    │
│       ├── switchLayoutIfEnabled(.russian)                               │
│       │       │                                                          │
│       │       └── TISSelectInputSource(russianSource)                   │
│       │               │                                                  │
│       │               ▼                                                  │
│       │       ┌───────────────────────────────────────┐                 │
│       │       │  macOS sends notification:            │                 │
│       │       │  kTISNotifySelectedKeyboard...        │                 │
│       │       └───────────────────────────────────────┘                 │
│       │               │                                                  │
│       │               ▼                                                  │
│       │       inputSourceChanged()                                       │
│       │       wordTracker.clear()  ← НЕ НУЖНО!                          │
│       │       lastConversion = nil ← ЛОМАЕТ UNDO!                       │
│       │                                                                  │
│       └── ... дальнейшая обработка                                      │
│                                                                          │
│  РЕЗУЛЬТАТ: Undo не работает, WordTracker пуст                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Решение

**Файл:** `AppDelegate.swift`

```swift
private var ignoreInputSourceChangesUntil: Date?

// В switchLayoutIfEnabled():
ignoreInputSourceChangesUntil = Date().addingTimeInterval(0.75)
inputSourceManager?.switchTo(.russian)

// В inputSourceChanged():
@objc private func inputSourceChanged() {
    if let ignoreUntil = ignoreInputSourceChangesUntil {
        if Date() < ignoreUntil {
            PuntoLog.info("Input source changed - ignored (programmatic switch grace window)")
            return  // НЕ очищаем
        }
        ignoreInputSourceChangesUntil = nil
    }

    if isConversionInProgress {
        PuntoLog.info("Input source changed - ignored (conversion in progress)")
        return  // НЕ очищаем
    }

    wordTracker?.clear(reason: "input source changed")
    lastConversion = nil
}
```

### Визуализация

```
┌──────────────────────────────────────────────────────────────────┐
│  Punto programmatic switch                                        │
│                                                                   │
│  switchLayoutIfEnabled()                                          │
│       │                                                           │
│       ├── ignoreInputSourceChangesUntil = now + 0.75s            │
│       │                                                           │
│       └── TISSelectInputSource()                                  │
│               │                                                   │
│               ▼ (async notification)                              │
│       inputSourceChanged()                                        │
│               │                                                   │
│               ├── inside ignoreInputSourceChangesUntil? → YES    │
│               │       │                                           │
│               │       └── return ◀─── SKIP CLEAR                 │
│               │                                                   │
│               └── (NO path not taken)                            │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  User manual switch                                               │
│                                                                   │
│  User presses Cmd+Space (system hotkey)                          │
│       │                                                           │
│       ▼                                                           │
│  inputSourceChanged()                                             │
│       │                                                           │
│       ├── inside ignoreInputSourceChangesUntil? → NO             │
│       │                                                           │
│       └── wordTracker.clear() ◀─── CLEAR (correct behavior)      │
│           lastConversion = nil                                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 4. Mixed Layout Detection

### Проблема

Уведомление о смене раскладки может прийти с задержкой. Пользователь уже начал печатать на новой раскладке, но Punto думает что раскладка старая:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            TIMELINE                                      │
│                                                                          │
│  T0: Пользователь на EN раскладке, печатает "hel"                       │
│      WordTracker: ['h', 'e', 'l']                                        │
│                                                                          │
│  T1: Пользователь нажимает Cmd+Space (switch to RU)                     │
│      macOS начинает обработку...                                         │
│                                                                          │
│  T2: Пользователь печатает "л" (уже на RU!)                             │
│      WordTracker: ['h', 'e', 'l', 'л']  ← CORRUPTION!                   │
│                                                                          │
│  T3: Notification приходит (ПОСЛЕ T2!)                                  │
│      inputSourceChanged()                                                │
│      ... но уже поздно!                                                  │
│                                                                          │
│  РЕЗУЛЬТАТ: WordTracker содержит "helл" — мусор                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Решение

**Файл:** `WordTracker.swift`

```swift
func getLastWord() -> String? {
    // ... build word from buffer ...

    // Validate: reject mixed-layout words
    if isMixedLayout(word) {
        clear(reason: "mixed layout in '\(word)'")
        return nil
    }

    return word
}

private func isMixedLayout(_ text: String) -> Bool {
    var hasEnglish = false
    var hasRussian = false

    for char in text {
        if isEnglishLetter(char) { hasEnglish = true }
        else if isRussianLetter(char) { hasRussian = true }

        if hasEnglish && hasRussian { return true }  // Early exit
    }

    return false
}
```

### Детектирование букв

```swift
private func isEnglishLetter(_ char: Character) -> Bool {
    guard let scalar = char.unicodeScalars.first else { return false }
    return (scalar.value >= 0x41 && scalar.value <= 0x5A) ||  // A-Z
           (scalar.value >= 0x61 && scalar.value <= 0x7A)     // a-z
}

private func isRussianLetter(_ char: Character) -> Bool {
    guard let scalar = char.unicodeScalars.first else { return false }
    return (scalar.value >= 0x410 && scalar.value <= 0x44F) ||  // А-я
           scalar.value == 0x401 || scalar.value == 0x451       // Ё, ё
}
```

### Примеры

| Ввод | hasEnglish | hasRussian | Результат |
|------|------------|------------|-----------|
| "hello" | true | false | OK |
| "привет" | false | true | OK |
| "helло" | true | true | REJECTED |
| "123" | false | false | OK (no letters) |
| "hello123" | true | false | OK |

---

## 5. Race Condition Prevention

### Проблема

`lastConversion` используется для undo. Но асинхронный key press callback может очистить его во время конвертации:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    RACE CONDITION                                        │
│                                                                          │
│  Main Thread                      Event Tap Thread                       │
│       │                                │                                 │
│       ▼                                │                                 │
│  handleConvertLayout()                 │                                 │
│       │                                │                                 │
│       ├── convert text                 │                                 │
│       │       │                        │                                 │
│       │       │    ◀─────────────────────── keyDown event arrives       │
│       │       │                        │                                 │
│       │       │                        ▼                                 │
│       │       │              onKeyPress callback                         │
│       │       │              lastConversion = nil ← CLEARED!            │
│       │       │                        │                                 │
│       │       ▼                        │                                 │
│       ├── setSelectedText              │                                 │
│       │                                │                                 │
│       └── lastConversion = {...}       │                                 │
│                ▲                       │                                 │
│                │                       │                                 │
│           OVERWRITTEN! Но если event прошёл между                       │
│           convert и save, undo сломан                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Решение

**Файл:** `AppDelegate.swift`

```swift
private var isConversionInProgress = false

func handleConvertLayout() {
    isConversionInProgress = true
    defer { isConversionInProgress = false }

    // ... conversion logic ...
}

// В callback onKeyPress:
onKeyPress: { [weak self] keyCode, characters in
    // ...
    // Clear undo ONLY if not in conversion
    if self?.isConversionInProgress == false {
        self?.lastConversion = nil
    }
}
```

### Визуализация

```
┌────────────────────────────────────────────────────────────────────────┐
│  С ЗАЩИТОЙ                                                              │
│                                                                         │
│  handleConvertLayout():                                                 │
│       │                                                                 │
│       ├── isConversionInProgress = true ◀─── LOCK                      │
│       │                                                                 │
│       │         [key event arrives]                                     │
│       │               │                                                 │
│       │               ▼                                                 │
│       │         onKeyPress:                                             │
│       │         if isConversionInProgress == false:                    │
│       │             lastConversion = nil                                │
│       │         │                                                       │
│       │         └── isConversionInProgress == true!                    │
│       │             → SKIP clear                                        │
│       │                                                                 │
│       ├── ... conversion ...                                            │
│       │                                                                 │
│       ├── lastConversion = {...}                                        │
│       │                                                                 │
│       └── isConversionInProgress = false ◀─── UNLOCK                   │
│                                                                         │
│  Undo работает корректно!                                               │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Safari Text Verification

### Проблема

Safari возвращает success из AX API для setSelectedText, но текст не меняется:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            SAFARI BUG                                    │
│                                                                          │
│  setSelectedTextViaAccessibility("руддщ"):                              │
│       │                                                                  │
│       └── AXUIElementSetAttributeValue(                                 │
│               focusedElement,                                            │
│               kAXSelectedTextAttribute,                                  │
│               "руддщ"                                                    │
│           )                                                              │
│               │                                                          │
│               └── returns .success ← LIE!                               │
│                                                                          │
│  В Safari текст остался "hello" — AX API для web content                │
│  возвращает success но фактически ничего не делает                      │
└─────────────────────────────────────────────────────────────────────────┘
```

### Решение

**Файл:** `TextAccessor.swift`

```swift
private func setSelectedTextViaAccessibility(_ text: String, keepSelection: Bool) -> Bool {
    // ... set text ...

    let result = AXUIElementSetAttributeValue(...)
    if result != .success { return false }

    // VERIFY the change actually happened
    Thread.sleep(forTimeInterval: 0.05)

    var newSelectedText: AnyObject?
    AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute, &newSelectedText)
    let actualText = newSelectedText as? String

    // If text didn't change, AX lied to us
    if actualText == originalText && originalText != text {
        PuntoLog.info("AX returned success but text unchanged (Safari bug)")
        return false  // Trigger clipboard fallback
    }

    return true
}
```

### Flow с верификацией

```
┌─────────────────────────────────────────────────────────────────────────┐
│  setSelectedText("руддщ")                                               │
│       │                                                                  │
│       ▼                                                                  │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  TRY AX API                                                      │   │
│  │       │                                                          │   │
│  │       ├── originalText = read current text                      │   │
│  │       │                                                          │   │
│  │       ├── AXUIElementSetAttributeValue(text)                    │   │
│  │       │       │                                                  │   │
│  │       │       └── result == .success?                           │   │
│  │       │            │           │                                 │   │
│  │       │           Yes         No → return false                 │   │
│  │       │            │                                             │   │
│  │       │            ▼                                             │   │
│  │       ├── Thread.sleep(0.05)  ← wait for write                  │   │
│  │       │                                                          │   │
│  │       ├── actualText = read current text again                  │   │
│  │       │                                                          │   │
│  │       └── actualText == originalText                            │   │
│  │            && originalText != text?                              │   │
│  │                 │           │                                    │   │
│  │                Yes         No → return true (success!)          │   │
│  │                 │                                                │   │
│  │                 └── return false ← DETECTED SAFARI BUG          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│       │                                                                  │
│       │ (return false)                                                  │
│       ▼                                                                  │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  FALLBACK: Clipboard method (Cmd+V)                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Password/Secure Input

### Проблема

Конвертация не должна работать в полях ввода пароля — это угроза безопасности.

### Два уровня защиты

**1. Secure Input (Terminal)**

```swift
func isSecureInputEnabled() -> Bool {
    return IsSecureEventInputEnabled()  // macOS Carbon API
}
```

Когда включён:
- Terminal при `sudo`, `ssh`, password prompt
- Некоторые банковские приложения

**2. Password Field (GUI apps)**

```swift
func isPasswordField() -> Bool {
    guard let element = getFocusedElement() else { return false }

    var subrole: AnyObject?
    if AXUIElementCopyAttributeValue(element, kAXSubroleAttribute, &subrole) == .success,
       let sr = subrole as? String,
       sr == "AXSecureTextField" {
        return true
    }

    return false
}
```

Когда true:
- Поля пароля в браузерах
- Login dialogs в приложениях

### Использование

**Файл:** `AppDelegate.swift`

```swift
func handleConvertLayout() {
    // ...

    if textAccessor?.isSecureInputEnabled() == true {
        PuntoLog.info("Secure Input enabled - conversion blocked")
        return
    }

    if textAccessor?.isPasswordField() == true {
        PuntoLog.info("Password field detected - conversion blocked")
        return
    }

    // ... proceed with conversion ...
}
```

---

## 8. Event Tap Recovery

### Проблема

macOS может отключить CGEvent tap при высокой нагрузке или по security причинам:

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Event tap был создан и работал...                                      │
│       │                                                                  │
│       ▼                                                                  │
│  [Heavy system load или security event]                                 │
│       │                                                                  │
│       ▼                                                                  │
│  macOS отключает tap:                                                    │
│  CGEventType.tapDisabledByTimeout                                        │
│  или                                                                     │
│  CGEventType.tapDisabledByUserInput                                      │
│       │                                                                  │
│       ▼                                                                  │
│  Punto перестаёт получать события!                                      │
│  Hotkeys не работают!                                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Решение

**Файл:** `HotkeyManager.swift`

```swift
private func handleEvent(...) -> Unmanaged<CGEvent>? {
    // Handle tap disabled (system may disable it under heavy load)
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        PuntoLog.info("Event tap was disabled, re-enabling...")
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    // ... normal event handling ...
}
```

### Визуализация

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Normal operation                                                        │
│       │                                                                  │
│       │ [tap disabled by system]                                        │
│       ▼                                                                  │
│  handleEvent receives:                                                   │
│  type == .tapDisabledByTimeout                                           │
│       │                                                                  │
│       ▼                                                                  │
│  CGEvent.tapEnable(tap, true) ← RE-ENABLE                               │
│       │                                                                  │
│       ▼                                                                  │
│  Normal operation resumed                                                │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Cmd+V/Cmd+Z Detection

### Проблема

Когда пользователь:
- **Cmd+V** — вставляет текст из clipboard
- **Cmd+Z** — отменяет ввод

WordTracker должен очиститься, т.к. его содержимое больше не соответствует тексту на экране.

### Решение

**Файл:** `HotkeyManager.swift`

```swift
// В handleEvent(), после проверки hotkeys:

// Detect Cmd+V (paste)
if hasCmd && !hasOpt && !hasControl && keyCode == 9 {  // V key
    PuntoLog.info("Cmd+V detected - will clear WordTracker")
    DispatchQueue.main.async { [weak self] in
        self?.onKeyPress(keyCode, nil)  // nil = signal to clear
    }
    return Unmanaged.passUnretained(event)
}

// Detect Cmd+Z (undo)
if hasCmd && !hasOpt && !hasControl && keyCode == 6 {  // Z key
    PuntoLog.info("Cmd+Z detected - will clear WordTracker")
    DispatchQueue.main.async { [weak self] in
        self?.onKeyPress(keyCode, nil)  // nil = signal to clear
    }
    return Unmanaged.passUnretained(event)
}
```

**Файл:** `WordTracker.swift`

```swift
func trackKeyPress(keyCode: UInt16, characters: String?) {
    // nil characters is a signal to clear buffer
    if characters == nil && keyCode != deleteKeyCode {
        clear(reason: "external command (keyCode=\(keyCode))")
        return
    }
    // ...
}
```

### Почему используется nil

```
┌─────────────────────────────────────────────────────────────────────────┐
│  СИГНАЛ vs СИМВОЛ                                                        │
│                                                                          │
│  onKeyPress(keyCode, characters):                                        │
│       │                                                                  │
│       ├── characters == "a" → добавить 'a' в буфер                      │
│       ├── characters == nil && keyCode == 51 → backspace (удалить)      │
│       └── characters == nil && keyCode != 51 → СИГНАЛ ОЧИСТКИ           │
│                                                                          │
│  Cmd+V: keyCode=9, characters=nil → clear buffer                        │
│  Cmd+Z: keyCode=6, characters=nil → clear buffer                        │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 10. Modifier-Only Hotkey Cancellation

### Проблема

Modifier-only hotkey (Cmd+Opt+Shift) не должен срабатывать, если пользователь нажал дополнительную клавишу:

```
Cmd+Opt+Shift (держит) → V → отпускает модификаторы
                         │
                         └── Это Cmd+Opt+Shift+V, не Cmd+Opt+Shift!
```

### Решение

**Файл:** `HotkeyManager.swift`

```swift
// В handleEvent():

// Process keyDown events
guard type == .keyDown else { ... }

// Any key press cancels modifier-only hotkey detection
modifiersWerePressed = false  // ← CANCEL
```

### Визуализация

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Сценарий 1: Чистый modifier-only                                       │
│                                                                          │
│  flagsChanged: Cmd+Opt+Shift нажаты                                      │
│       │                                                                  │
│       └── modifiersWerePressed = true                                   │
│               │                                                          │
│               ▼                                                          │
│  flagsChanged: Все отпущены                                              │
│       │                                                                  │
│       └── modifiersWerePressed && noModifiers → TRIGGER!                │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  Сценарий 2: С дополнительной клавишей                                  │
│                                                                          │
│  flagsChanged: Cmd+Opt+Shift нажаты                                      │
│       │                                                                  │
│       └── modifiersWerePressed = true                                   │
│               │                                                          │
│               ▼                                                          │
│  keyDown: V (или любая клавиша)                                          │
│       │                                                                  │
│       └── modifiersWerePressed = false ← CANCEL                         │
│               │                                                          │
│               ▼                                                          │
│  flagsChanged: Все отпущены                                              │
│       │                                                                  │
│       └── modifiersWerePressed == false → NO TRIGGER                    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 11. Сводная таблица

| # | Механизм | Проблема | Решение | Файл |
|---|----------|----------|---------|------|
| 2 | Re-capture Prevention | Собственные CGEvents перехватываются | `ignoreEvents` флаг + 0.3s delay | HotkeyManager, AppDelegate |
| 3 | Input Source Change | Программный switch очищает WordTracker | `ignoreInputSourceChangesUntil` grace window | AppDelegate |
| 4 | Mixed Layout Detection | Delayed notification → corrupted buffer | `isMixedLayout()` проверка | WordTracker |
| 5 | Race Condition | Key event очищает undo во время конвертации | `isConversionInProgress` флаг | AppDelegate |
| 6 | Safari Verification | AX API возвращает success но не работает | Проверка после установки | TextAccessor |
| 7 | Password/Secure | Конвертация в password полях | `isSecureInputEnabled()` + `isPasswordField()` | TextAccessor, AppDelegate |
| 8 | Event Tap Recovery | System отключает tap | Re-enable при `tapDisabledBy...` | HotkeyManager |
| 9 | Cmd+V/Cmd+Z Detection | Paste/Undo ломают WordTracker | Detect и clear buffer | HotkeyManager, WordTracker |
| 10 | Hotkey Cancellation | Modifier-only + key = не modifier-only | Reset `modifiersWerePressed` при keyDown | HotkeyManager |

---

## Чеклист при добавлении нового функционала

При добавлении нового функционала проверьте:

- [ ] Не ломает ли новый код существующие защитные механизмы?
- [ ] Нужен ли `ignoreEvents` при отправке CGEvents?
- [ ] Нужен ли `ignoreInputSourceChangesUntil` при переключении раскладки?
- [ ] Как влияет на `lastConversion` и undo?
- [ ] Работает ли в терминалах?
- [ ] Работает ли в Safari/Chrome?
- [ ] Блокируется ли в password полях?
- [ ] Thread-safe ли доступ к shared state?
