# Punto — Техническая Спецификация

Полная техническая документация macOS-приложения для конвертации раскладки клавиатуры.

**Версия:** 1.0
**Дата:** Январь 2026
**Bundle ID:** `com.rshagiev.Punto`
**Минимальная macOS:** 12.0 (Monterey)
**Архитектура:** Universal Binary (arm64 + x86_64)

---

## Содержание

1. [Обзор](#1-обзор)
2. [Архитектура](#2-архитектура)
3. [Компоненты](#3-компоненты)
4. [Потоки данных](#4-потоки-данных)
5. [Защитные механизмы](#5-защитные-механизмы)
6. [Тайминги и константы](#6-тайминги-и-константы)
7. [API Reference](#7-api-reference)
8. [Отладка](#8-отладка)
9. [Структура проекта](#9-структура-проекта)

---

## 1. Обзор

### Что делает Punto

Punto — это menu bar приложение для macOS, которое конвертирует текст между русской (ЙЦУКЕН) и английской (QWERTY) раскладками клавиатуры.

### Основные функции

| Функция | Горячая клавиша | Описание |
|---------|-----------------|----------|
| Конвертация раскладки | `Cmd+Opt+Shift` | Конвертирует выделенный текст или последнее слово |
| Переключение регистра | `Cmd+Opt+Z` | Посимвольная инверсия регистра: `Hello` ↔ `hELLO`, `UPPER` ↔ `upper` |
| Undo | Повторное `Cmd+Opt+Shift` | Отмена последней конвертации (в течение 3 сек) |

### Режимы работы

```
┌─────────────────────────────────────────────────────────────┐
│                   РЕЖИМЫ КОНВЕРТАЦИИ                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. ВЫДЕЛЕННЫЙ ТЕКСТ                                        │
│     ┌─────────┐    Cmd+Opt+Shift    ┌─────────┐            │
│     │ "ghbdtn"│ ─────────────────── │"привет" │            │
│     └─────────┘                     └─────────┘            │
│                                                             │
│  2. ПОСЛЕДНЕЕ СЛОВО (WordTracker)                           │
│     Пользователь печатает → буфер накапливает               │
│     ┌───────────────────┐                                   │
│     │ g│h│b│d│t│n│      │ ← Ring buffer (50 chars)         │
│     └───────────────────┘                                   │
│     Cmd+Opt+Shift → backspaces + вставка "привет"           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Архитектура

### Диаграмма компонентов

```
┌─────────────────────────────────────────────────────────────────────┐
│                           AppDelegate                                │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ Lifecycle │ Флаги состояния │ Оркестрация │ Undo State        │  │
│  │                                                               │  │
│  │ • isConversionInProgress     - блокирует race condition      │  │
│  │ • ignoreInputSourceChangesUntil - окно для своих переключений│  │
│  │ • lastConversion             - данные для undo               │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
         │              │               │               │
         │              │               │               │
    ┌────▼────┐    ┌───▼─────┐    ┌───▼─────┐    ┌───▼─────┐
    │ Hotkey  │    │  Text   │    │ Layout  │    │  Word   │
    │ Manager │    │ Accessor│    │Converter│    │ Tracker │
    ├─────────┤    ├─────────┤    ├─────────┤    ├─────────┤
    │CGEvent  │    │AX API   │    │EN↔RU    │    │Ring     │
    │Tap      │    │Clipboard│    │mappings │    │buffer   │
    │         │    │fallback │    │         │    │50 chars │
    └─────────┘    └─────────┘    └─────────┘    └─────────┘
         │
         │
    ┌────▼────────────────────────────────────────────────────────────┐
    │                     StatusBarController                          │
    │  ┌────────────────────────────────────────────────────────────┐ │
    │  │ Menu bar icon │ Dropdown menu │ Flash feedback (0.15s)     │ │
    │  └────────────────────────────────────────────────────────────┘ │
    └─────────────────────────────────────────────────────────────────┘
```

### Вспомогательные компоненты

```
┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐
│  InputSource       │  │  Settings          │  │  Logger            │
│  Manager           │  │  Manager           │  │                    │
├────────────────────┤  ├────────────────────┤  ├────────────────────┤
│ TIS API            │  │ UserDefaults       │  │ /tmp/punto.log     │
│ EN/RU источники    │  │ Hotkeys (Codable)  │  │ INFO/DEBUG/ERROR   │
│ switchTo(language) │  │ Launch at login    │  │                    │
└────────────────────┘  └────────────────────┘  └────────────────────┘
```

---

## 3. Компоненты

### 3.1 AppDelegate

**Файл:** `Sources/Punto/App/AppDelegate.swift`

Главный оркестратор приложения. Управляет жизненным циклом, правами доступа и координирует все компоненты.

#### Флаги состояния

| Флаг | Тип | Назначение |
|------|-----|------------|
| `isConversionInProgress` | Bool | Блокирует очистку undo во время конвертации |
| `ignoreInputSourceChangesUntil` | Date? | Игнорирует пачку уведомлений о смене раскладки в коротком окне после программного переключения |
| `lastConversion` | LastConversion? | Данные для undo (оригинал, результат, timestamp, replacementMethod) |
| `lastKeyPressTime` | Date? | Время последнего нажатия (для диагностики) |

#### Структура LastConversion

```swift
private struct LastConversion {
    let originalText: String      // Исходный текст
    let convertedText: String     // Результат конвертации
    let timestamp: Date           // Время конвертации
    let wasSelection: Bool        // true = выделение, false = последнее слово
}
```

#### Жизненный цикл

```
applicationDidFinishLaunching()
├── PuntoLog.prepareForNewSession() — архивирование прошлого /tmp/punto.log и чистый активный лог
├── SettingsManager() — инициализация настроек
├── Core компоненты:
│   ├── LayoutConverter
│   ├── WordTracker
│   ├── TextAccessor
│   └── InputSourceManager
├── StatusBarController — menu bar UI
├── Проверка первого запуска → OnboardingAlert
├── AXIsProcessTrusted() — проверка прав
├── startHotkeyManager() — запуск перехвата
├── Подписка на kTISNotifySelectedKeyboardInputSourceChanged
└── Если нет прав → showPermissionAlert() + timer каждые 2 сек
```

---

### 3.2 HotkeyManager

**Файл:** `Sources/PuntoRuntime/HotkeyManager.swift`

Перехватывает глобальные клавиатурные события через CGEvent Tap.

#### Modifier-Only Hotkey Detection

Ключевая особенность — детектирование горячей клавиши без дополнительной буквы (только модификаторы Cmd+Opt+Shift):

```
                    flagsChanged events
                           │
                           ▼
                ┌─────────────────────┐
                │ Все Cmd+Opt+Shift   │──Yes──▶ modifiersWerePressed = true
                │    нажаты?          │
                └─────────────────────┘
                           │ No
                           ▼
                ┌─────────────────────┐
                │ modifiersWerePressed│──No──▶ (игнорировать)
                │    == true?         │
                └─────────────────────┘
                           │ Yes
                           ▼
                ┌─────────────────────┐
                │ ВСЕ модификаторы    │──No──▶ (ждать отпускания)
                │   отпущены?         │
                └─────────────────────┘
                           │ Yes
                           ▼
                ┌─────────────────────┐
                │ Debounce check      │──<0.5s──▶ (игнорировать)
                │   (0.5 сек)         │
                └─────────────────────┘
                           │ ≥0.5s
                           ▼
                   onConvertLayout()
```

#### Состояния

| Переменная | Тип | Назначение |
|------------|-----|------------|
| `modifiersWerePressed` | Bool | Были ли нажаты все модификаторы |
| `lastTriggerTime` | Date | Время последнего срабатывания (debounce) |
| `_ignoreEvents` | Bool | Игнорировать события (thread-safe через stateQueue) |
| `isRunning` | Bool | Запущен ли event tap |

#### Thread Safety

```swift
private let stateQueue = DispatchQueue(label: "com.punto.hotkeymanager.state")
private var _ignoreEvents = false

var ignoreEvents: Bool {
    get { stateQueue.sync { _ignoreEvents } }
    set { stateQueue.sync { _ignoreEvents = newValue } }
}
```

#### Event Tap Recovery

Система может отключить event tap при высокой нагрузке:

```swift
if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
    CGEvent.tapEnable(tap: tap, enable: true)
}
```

---

### 3.3 TextAccessor

**Файл:** `Sources/PuntoRuntime/TextAccessor.swift`

Получает и устанавливает текст в активном приложении через Accessibility API с fallback на clipboard.

#### Стратегия получения текста

```
getSelectedText()
       │
       ▼
┌─────────────────────┐
│ 1. AX API direct    │───Success───▶ return text
│    (focused elem)   │              lastGetUsedClipboard = false
└─────────────────────┘
       │ Fail/Empty
       ▼
┌─────────────────────┐
│ 2. AX API via app   │───Success───▶ return text
│    (focusedUIElem)  │              (для Safari/Electron)
└─────────────────────┘
       │ Fail
       ▼
┌─────────────────────┐
│ 3. Recursive search │───Success───▶ return text
│    (children, d≤5)  │
└─────────────────────┘
       │ Fail
       ▼
┌─────────────────────┐
│ 4. Clipboard        │───Success───▶ return text
│    (Cmd+C)          │              lastGetUsedClipboard = true
└─────────────────────┘
       │ Fail
       ▼
   return nil
```

#### Clipboard Fallback (Cmd+C)

1. Сохранить полный snapshot текущего clipboard (`pasteboardItems` + все types/data), не только plain string
2. Очистить clipboard
3. Зафиксировать baseline `changeCount` после очистки
4. Отправить Cmd+C через CGEvent (cgAnnotatedSessionEventTap)
5. Polling: проверять clipboard каждые 20ms, до 10 раз (200ms max), ожидая change после baseline
6. После 60ms попробовать HID fallback (cghidEventTap)
7. Проверить, что clipboard изменился после baseline; совпадение текста с прежним clipboard не считается ошибкой
8. Trim whitespace
9. Восстановить исходный clipboard snapshot, включая пустой clipboard и rich/file contents

#### Стратегия установки текста

```
setSelectedText(text, keepSelection)
       │
       ▼
┌─────────────────────────────┐
│ lastGetUsedClipboard=true?  │──Yes──▶ Clipboard method (Cmd+V)
└─────────────────────────────┘
       │ No
       ▼
┌─────────────────────────────┐
│ Try AX API set              │───Success───▶ Done
│ + верификация изменения     │    (проверяем, что текст
└─────────────────────────────┘     действительно изменился)
       │ Fail/Safari bug
       ▼
   Clipboard method (Cmd+V)
```

#### Terminal-Like Surface Support

Punto больше не выбирает терминальный путь по списку bundle ID. `TextAccessor` выбирает стратегию по runtime capability:

- если AX selection существует и focused element позволяет settable `AXSelectedText`, используется обычная replacement strategy с сохранением выделения;
- если AX selection выглядит как non-settable text surface, она не считается безопасной;
- для terminal-like/non-settable surfaces AX selection не заменяется напрямую; если non-settable selection есть, конвертируется только tracked typed tail текущей команды или его суффикс, а prefix/middle selection блокируется как небезопасный; passive clipboard допускается только когда trimmed clipboard точно совпадает с tracked typed tail из `WordTracker` и заканчивается последним словом;
- replacement для keyboard-tail strategy выполняется через `replaceLastWord()` (backspaces + Cmd+V).

#### Security Protection

```swift
func isSecureInputEnabled() -> Bool {
    return IsSecureEventInputEnabled()  // Terminal password prompts
}

func isPasswordField() -> Bool {
    // Проверяет AXSecureTextField subrole
}
```

---

### 3.4 WordTracker

**Файл:** `Sources/PuntoCore/WordTracker.swift`

Отслеживает последнее напечатанное слово в кольцевом буфере. Отдельный typed-tail буфер хранит контекст текущей terminal-like команды для безопасной проверки selection/clipboard fallback.

#### Ring Buffer

```
maxSize = 50 символов для last word
maxTailSize = 512 символов в production для terminal command tail

Пример добавления "hello":
  head=0: [_____]  → h → [h____] head=1, count=1
                   → e → [he___] head=2, count=2
                   → l → [hel__] head=3, count=3
                   → l → [hell_] head=4, count=4
                   → o → [hello] head=0, count=5 (циклический)

getLastWord() читает от (head - count) до head по модулю maxSize
getTypedTail() читает отдельный tail buffer; в тестах без явного maxTailSize он совпадает с maxSize
```

#### Word Boundaries

Очищают буфер (новое слово):

| Символы | Описание |
|---------|----------|
| Space, Tab, Newline | Пробельные |
| `! ? ( ) / \ \| @ # $ % ^ & * + = - _` | Разделители |
| Arrow keys, Home, End, Page Up/Down | Навигация |
| Return, Enter, Tab, Escape | Управляющие |

**НЕ очищают** (маппятся на русские буквы):
`;` `'` `[` `]` `` ` `` `,` `.`

#### Mixed Layout Detection

Защита от corrupted данных при задержке уведомления о смене раскладки:

```swift
func getLastWord() -> String? {
    // ...
    if isMixedLayout(word) {  // e.g., "heпо" = EN + RU
        clear(reason: "mixed layout")
        return nil
    }
    return word
}
```

`WordTracker` не имеет terminal-specific режимов. Пробел всегда считается границей слова; terminal-like поведение выбирается позже в `TextAccessor`.

---

### 3.5 LayoutConverter

**Файл:** `Sources/PuntoCore/LayoutConverter.swift`

Конвертирует текст между EN и RU раскладками.

#### Таблица маппинга (QWERTY → ЙЦУКЕН)

```
Lowercase:
q→й  w→ц  e→у  r→к  t→е  y→н  u→г  i→ш  o→щ  p→з
a→ф  s→ы  d→в  f→а  g→п  h→р  j→о  k→л  l→д
z→я  x→ч  c→с  v→м  b→и  n→т  m→ь

Punctuation:
[→х  ]→ъ  ;→ж  '→э  `→ё  ,→б  .→ю  /→.

Shift+Numbers (EN→RU):
@ → "   # → №   $ → ;   ^ → :   & → ?
```

#### Layout Detection

```swift
func detectLayout(_ text: String) -> DetectedLayout {
    // Считаем EN и RU буквы
    let englishRatio = englishCount / total

    if englishRatio > 0.8 { return .english }
    if englishRatio < 0.2 { return .russian }
    return .mixed
}
```

#### ConversionResult

```swift
struct ConversionResult {
    let text: String            // Конвертированный текст
    let targetLayout: DetectedLayout  // Целевая раскладка
}
```

---

### 3.6 InputSourceManager

**Файл:** `Sources/PuntoRuntime/InputSourceManager.swift`

Управляет системными раскладками клавиатуры через TIS API.

#### Поиск раскладок

```swift
// English: primary language "en" (including en-US/en_US) or known source id tokens: ABC, US, USInternational
// Russian: primary language "ru" (including ru-RU/ru_RU) or known source id token: Russian
```

Selectable but disabled explicit/required EN/RU sources are not treated as
missing immediately. `InputSourceSelectionPolicy` returns them with
`sourceIDsToEnable`, and `InputSourceManager` attempts `TISEnableInputSource`
before falling back to the `promptUserToInstallLayouts` diagnostic.

#### Переключение

```swift
@discardableResult
func switchTo(_ language: KeyboardLanguage) -> Bool {
    let status = TISSelectInputSource(source)
    return status == noErr
}
```

---

### 3.7 SettingsManager

**Файл:** `Sources/PuntoSettings/SettingsManager.swift`

Хранение настроек в UserDefaults.

#### Настройки

| Ключ | Тип | Default | Описание |
|------|-----|---------|----------|
| `isEnabled` | Bool | true | Функция включена |
| `isFirstLaunch` | Bool | true | Показать onboarding |
| `showInMenuBar` | Bool | true | Показывать иконку |
| `launchAtLogin` | Bool | false | Запуск при входе |
| `switchLayoutAfterConversion` | Bool | false | Переключать раскладку |
| `convertLayoutHotkey` | Hotkey | Cmd+Opt+Shift | Горячая клавиша конвертации |
| `toggleCaseHotkey` | Hotkey | Cmd+Opt+Z | Горячая клавиша регистра |

#### Hotkey Structure

```swift
struct Hotkey: Codable, Equatable {
    var keyCode: UInt16       // UInt16.max = modifier-only
    var command: Bool
    var option: Bool
    var shift: Bool
    var control: Bool

    var isModifierOnly: Bool  // keyCode == UInt16.max
    var displayString: String // "⌘⌥⇧" или "⌘⌥Z"
}
```

---

### 3.8 StatusBarController

**Файл:** `Sources/Punto/App/StatusBarController.swift`

UI в строке меню.

#### Структура меню

```
┌─────────────────────────────┐
│  Punto                      │  (disabled title)
├─────────────────────────────┤
│  ✓ Enabled                  │  Toggle on/off
├─────────────────────────────┤
│  Convert Layout    ⌘⌥⇧      │  (info)
│  Toggle Case       ⌘⌥Z      │  (info)
├─────────────────────────────┤
│  Settings...       ⌘,       │
├─────────────────────────────┤
│  Quit Punto        ⌘Q       │
└─────────────────────────────┘
```

#### Flash Feedback

```swift
func flashIcon() {
    // Тинирует иконку controlAccentColor на 0.15 сек
}
```

---

## 4. Потоки данных

### 4.1 Основной flow конвертации

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. Пользователь нажимает Cmd+Opt+Shift (держит и отпускает)        │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  2. HotkeyManager.handleEvent() — flagsChanged                      │
│     • modifiersWerePressed = true (все модификаторы нажаты)         │
│     • Ждём отпускания всех модификаторов                            │
│     • Debounce check (0.5s)                                         │
│     • DispatchQueue.main.async { onConvertLayout() }                │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  3. AppDelegate.handleConvertLayout()                               │
│     ┌──────────────────────────────────────────────────────────┐   │
│     │ isConversionInProgress = true                             │   │
│     │ hotkeyManager.ignoreEvents = true                         │   │
│     └──────────────────────────────────────────────────────────┘   │
│                                                                     │
│     ┌──────────────────────────────────────────────────────────┐   │
│     │ Проверки безопасности:                                    │   │
│     │ • isSecureInputEnabled() → блок                           │   │
│     │ • isPasswordField() → блок                                │   │
│     └──────────────────────────────────────────────────────────┘   │
│                                                                     │
│     ┌──────────────────────────────────────────────────────────┐   │
│     │ Проверка UNDO (последние 3 сек):                          │   │
│     │ • Если есть lastConversion → восстановить оригинал        │   │
│     │ • Переключить раскладку обратно                           │   │
│     │ • return                                                  │   │
│     └──────────────────────────────────────────────────────────┘   │
│                                                                     │
│     ┌──────────────────────────────────────────────────────────┐   │
│     │ Нормальная конвертация:                                   │   │
│     │ • WordTracker.getLastWord()                               │   │
│     │ • captureSelectedText(lastTrackedWord:)                   │   │
│     │ • Если есть CapturedText → replaceCapturedText()          │   │
│     │ • Иначе → lastTrackedWord → replaceLastWord()             │   │
│     └──────────────────────────────────────────────────────────┘   │
│                                                                     │
│     ┌──────────────────────────────────────────────────────────┐   │
│     │ Финализация:                                              │   │
│     │ • flashIcon()                                             │   │
│     │ • switchLayoutIfEnabled(targetLayout)                     │   │
│     │ • Сохранить lastConversion для undo                       │   │
│     │ • После 0.3s: ignoreEvents = false                        │   │
│     └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 Flow для terminal-like surfaces

```
┌────────────────────────────────────────────────────────────┐
│  captureSelectedText(lastTrackedWord:)                     │
└────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│  AX selectedText найден?                                   │
│  focused element supports settable AXSelectedText?         │
└────────────────────────────────────────────────────────────┘
                         │
            ┌────────────┴────────────┐
            ▼                         ▼
┌─────────────────────┐    ┌─────────────────────┐
│ Да: CapturedText    │    │ Нет: проверить      │
│ accessibility       │    │ passive clipboard   │
│ selection           │    │ tail selection      │
└─────────────────────┘    └─────────────────────┘
            │                         │
            ▼                         ▼
┌─────────────────────┐    ┌─────────────────────┐
│ replaceCapturedText │    │ accepted tail?      │
│ via AX/clipboard    │    │ → backspace+paste   │
│ paste fallback      │    │ else use lastWord   │
└─────────────────────┘    └─────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│  replaceLastWord(wordLength, replacement)                  │
│  • backspaces × wordLength                                 │
│  • Cmd+V (paste)                                           │
└────────────────────────────────────────────────────────────┘
```

### 4.3 Undo Flow

```
┌──────────────────────────────────────┐
│ 1-я конвертация: "hello" → "руддщ"   │
│ lastConversion = {                   │
│   originalText: "hello"              │
│   convertedText: "руддщ"             │
│   timestamp: now                     │
│   wasSelection: true                 │
│ }                                    │
└──────────────────────────────────────┘
                    │
                    ▼ (повторное Cmd+Opt+Shift < 3 сек)
┌──────────────────────────────────────┐
│ handleConvertLayout()                │
│ • lastConversion существует          │
│ • time < 3 сек                       │
│ ↓                                    │
│ UNDO MODE:                           │
│ • setSelectedText("hello")           │
│ • switchTo(english)                  │
│ • lastConversion = nil               │
└──────────────────────────────────────┘
```

---

## 5. Защитные механизмы

### 5.1 Re-capture Prevention

**Проблема:** При вставке текста через Cmd+V генерируются CGEvents, которые могут быть перехвачены HotkeyManager и снова вызвать конвертацию.

**Решение:**
```swift
hotkeyManager.ignoreEvents = true
// ... конвертация ...
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    hotkeyManager.ignoreEvents = false
}
```

### 5.2 Input Source Change Protection

**Проблема:** Когда Punto программно переключает раскладку, система отправляет `kTISNotifySelectedKeyboardInputSourceChanged`, что очищает WordTracker.

**Решение:**
```swift
// В switchLayoutIfEnabled():
ignoreInputSourceChangesUntil = Date().addingTimeInterval(0.75)
inputSourceManager?.switchTo(.russian)

// В inputSourceChanged():
if let ignoreUntil = ignoreInputSourceChangesUntil, Date() < ignoreUntil {
    return  // Не очищать WordTracker
}
ignoreInputSourceChangesUntil = nil
wordTracker?.clear()
```

### 5.3 Mixed Layout Detection

**Проблема:** Уведомление о смене раскладки может прийти с задержкой, и WordTracker накопит символы из обеих раскладок.

**Решение:**
```swift
func getLastWord() -> String? {
    if isMixedLayout(word) {  // e.g., "heпо"
        clear(reason: "mixed layout")
        return nil
    }
    return word
}
```

### 5.4 Race Condition Prevention

**Проблема:** Асинхронное нажатие клавиши может очистить lastConversion во время конвертации.

**Решение:**
```swift
isConversionInProgress = true
defer { isConversionInProgress = false }

// В onKeyPress callback:
if self?.isConversionInProgress == false {
    self?.lastConversion = nil
}
```

### 5.5 Safari Text Verification

**Проблема:** Safari возвращает success из AX API, но текст не меняется.

**Решение:**
```swift
// После установки текста — проверяем, что он изменился
Thread.sleep(forTimeInterval: 0.05)
let actualText = // read again
if actualText == originalText && originalText != text {
    return false  // Fallback на clipboard
}
```

### 5.6 Cmd+V/Cmd+Z Detection

**Проблема:** Вставленный или отменённый текст не должен попадать в WordTracker.

**Решение:**
```swift
// В HotkeyManager:
if hasCmd && keyCode == 9 {  // V
    onKeyPress(keyCode, nil)  // nil = сигнал очистить
}
if hasCmd && keyCode == 6 {  // Z
    onKeyPress(keyCode, nil)
}
```

---

## 6. Тайминги и константы

### Тайминги

| Константа | Значение | Назначение |
|-----------|----------|------------|
| Debounce modifier-only | 0.5 сек | Минимум между срабатываниями |
| ignoreEvents delay | 0.3 сек | После конвертации |
| Undo window | 3.0 сек | Время для повторного нажатия |
| Backspace delay | 0.02 сек | Между backspaces |
| Post-paste delay | 0.03 сек | После Cmd+V |
| Clipboard restore | 0.3 сек | Перед восстановлением |
| Flash icon duration | 0.15 сек | Визуальный feedback |
| Clipboard poll | 0.02 сек × 10 | Ожидание Cmd+C |
| AX retry delay | 0.05 сек | Между попытками AX API |

### Key Codes

| Код | Клавиша |
|-----|---------|
| 6 | Z |
| 8 | C |
| 9 | V |
| 36 | Return |
| 48 | Tab |
| 49 | Space |
| 51 | Delete (Backspace) |
| 53 | Escape |
| 76 | Enter (numpad) |
| 117 | Forward Delete |
| 123-126 | Arrow keys |

### Buffer Sizes

| Константа | Значение |
|-----------|----------|
| WordTracker maxSize | 50 символов |
| WordTracker production maxTailSize | 512 символов |
| Recursive search depth | 5 уровней |

---

## 7. API Reference

### HotkeyManager

```swift
class HotkeyManager {
    var ignoreEvents: Bool      // Thread-safe
    func start()                // Запустить event tap
    func stop()                 // Остановить event tap
}
```

### TextAccessor

```swift
class TextAccessor {
    func captureSelectedText(lastTrackedWord: String?) -> CapturedText?
    func replaceCapturedText(_ capturedText: CapturedText, with replacement: String, keepSelection: Bool = false) -> Bool
    func getSelectedText() -> String?
    func setSelectedText(_ text: String, keepSelection: Bool = false) -> Bool
    func replaceLastWord(wordLength: Int, with replacement: String) -> Bool
    func isSecureInputEnabled() -> Bool
    func isPasswordField() -> Bool
}
```

### LayoutConverter

```swift
class LayoutConverter {
    func convert(_ text: String) -> String
    func convertWithResult(_ text: String) -> ConversionResult
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
    func clear(reason: String = "unknown")
}
```

### InputSourceManager

```swift
class InputSourceManager {
    func refreshInputSources()
    func switchTo(_ language: KeyboardLanguage) -> Bool
}
```

### SettingsManager

```swift
class SettingsManager {
    var isEnabled: Bool
    var isFirstLaunch: Bool
    var showInMenuBar: Bool
    var launchAtLogin: Bool
    var switchLayoutAfterConversion: Bool
    var convertLayoutHotkey: Hotkey
    var toggleCaseHotkey: Hotkey

    func resetConvertLayoutHotkey()
    func resetToggleCaseHotkey()
}
```

---

## 8. Отладка

### Логи

```bash
# Просмотр логов в реальном времени
tail -f /tmp/punto.log

# Формат логов
[HH:mm:ss.SSS] [FileName:Line] LEVEL: Message
```

### Тестирование

```bash
# Запуск тестов
swift run PuntoCoreTest
swift run PuntoSettingsTest
swift run PuntoParityTest

# Отдельные тесты
swift run PuntoDiag converter # Диагностика конвертации
swift run PuntoDiag tracker   # Диагностика WordTracker
```

### Диагностика

```bash
# Проверка прав и состояния
swift run PuntoDiag all
swift run PuntoDiag permissions
./Scripts/debug.sh components  # Production core harnesses, без inline-копий core
```

### Частые проблемы

| Проблема | Решение |
|----------|---------|
| Права не работают | Запустить бинарник напрямую, не через `open` |
| Hotkey срабатывает многократно | Проверить debounce и флаги |
| Текст конвертируется обратно | Проверить ignoreEvents |
| Event tap отключён | Автоматически переактивируется |
| WordTracker пустой после конвертации | Проверить `ignoreInputSourceChangesUntil` grace window |

---

## 9. Структура проекта

```
Punto/
├── Package.swift
├── CLAUDE.md                    # Инструкции для AI
├── Sources/
│   ├── Punto/
│   │   ├── main.swift           # Точка входа
│   │   ├── App/
│   │   │   ├── AppDelegate.swift
│   │   │   └── StatusBarController.swift
│   │   └── UI/
│   │       ├── SettingsWindowController.swift
│   │       ├── HotkeyRecorderView.swift
│   │       ├── OnboardingAlert.swift
│   │       └── Styles.swift
│   ├── PuntoCore/
│   │   ├── LayoutConverter.swift
│   │   ├── WordTracker.swift
│   │   └── ...
│   ├── PuntoRuntime/
│   │   ├── HotkeyManager.swift
│   │   ├── TextAccessor.swift
│   │   ├── InputSourceManager.swift
│   │   └── ...
│   ├── PuntoSettings/
│   │   ├── SettingsDefaultsStore.swift
│   │   ├── SettingsManager.swift
│   │   └── SettingsValueResolver.swift
│   ├── PuntoSettingsTest/
│   │   └── main.swift
│   ├── PuntoDiag/
│   │   └── main.swift
│   └── PuntoParityTest/
│       └── main.swift
├── Resources/
│   ├── Info.plist
│   ├── Punto.entitlements
│   └── Assets.xcassets/
├── Scripts/
│   ├── build.sh
│   └── debug.sh
├── docs/
│   ├── TECHNICAL_SPEC.md        # Этот документ
│   ├── FLOWS.md                 # Диаграммы потоков
│   └── PROTECTION_MECHANISMS.md # Защитные механизмы
└── Release/
    └── Punto.app/
```

---

## Сборка и запуск

```bash
# Quick build (arm64 only), sign, deploy и restart
./Scripts/deploy.sh

# Full build (universal)
./Scripts/build.sh
open Release/Punto.app
```

---

## Требуемые права

| Право | Где настраивается | API проверки |
|-------|-------------------|--------------|
| Accessibility | System Settings → Privacy → Accessibility | `AXIsProcessTrusted()` |
| Input Monitoring | System Settings → Privacy → Input Monitoring | (может требоваться для некоторых приложений) |
