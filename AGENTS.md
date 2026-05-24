# Punto — macOS Keyboard Layout Switcher

> **Domain:** macOS tool (Swift)
> **Location:** `~/Projects/Punto`
> **Tier:** 1 (Slim reference)
> **Maturity:** production

## Quick Context

- Menu bar app for keyboard layout conversion (EN <-> RU).
- Modifier-only hotkey: Cmd+Opt+Shift, no extra key needed.
- Uses Accessibility API plus clipboard fallback for text manipulation.
- Supports terminals and terminal-like surfaces by runtime capability, not primarily by bundle ID.
- Undo support: pressing Cmd+Opt+Shift again within 3 seconds restores the last conversion.

## Quick Start

```bash
# Build, sign, deploy, and restart
./Scripts/deploy.sh

# Run tests
swift run PuntoTest all

# View logs
tail -f /tmp/punto.log
```

After code changes, run `./Scripts/deploy.sh`. Copying only the binary can break the bundle signature and may reset or break the Accessibility identity.

## Documentation

| Document | Description |
| --- | --- |
| `docs/TECHNICAL_SPEC.md` | Full technical specification |
| `docs/FLOWS.md` | ASCII data-flow diagrams |
| `docs/PROTECTION_MECHANISMS.md` | Protection mechanisms and edge cases |

## Hotkeys

- Cmd+Opt+Shift: convert layout.
- Cmd+Opt+Z: toggle case, upper <-> lower.
- Repeated Cmd+Opt+Shift within 3 seconds: undo the last conversion.

## Key Files

| Task | File |
| --- | --- |
| App lifecycle and orchestration | `Sources/Punto/App/AppDelegate.swift` |
| Hotkey detection | `Sources/Punto/Core/HotkeyManager.swift` |
| Text get/set | `Sources/Punto/Core/TextAccessor.swift` |
| Character mapping | `Sources/Punto/Core/LayoutConverter.swift` |
| Word tracking | `Sources/Punto/Core/WordTracker.swift` |
| Layout switching | `Sources/Punto/Core/InputSourceManager.swift` |
| Settings storage | `Sources/Punto/Settings/SettingsManager.swift` |
| Menu bar UI | `Sources/Punto/App/StatusBarController.swift` |

## Build And Run

```bash
# Quick build, sign, deploy, and restart
./Scripts/deploy.sh

# Full universal build
./Scripts/build.sh
open Release/Punto.app
```

## Critical Implementation Details

### Modifier-Only Hotkey Detection

The hotkey is detected through `flagsChanged` events. It fires when:

- All required modifiers, Cmd+Opt+Shift, were pressed.
- All required modifiers were released.
- More than 0.5 seconds passed since the last trigger.

### Re-Capture Prevention

Events generated during conversion can be captured by the app again. Conversion code must set:

```swift
hotkeyManager.ignoreEvents = true
// ... conversion ...
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    hotkeyManager.ignoreEvents = false
}
```

### Input Source Change Protection

Programmatic layout switching must not clear `WordTracker` through self-generated input source notifications:

```swift
ignoreInputSourceChangesUntil = Date().addingTimeInterval(0.75)
inputSourceManager?.switchTo(.russian)
// inputSourceChanged() ignores notifications inside this grace window.
```

### Text Access Strategy

Use this order:

1. AX direct access through `kAXSelectedTextAttribute`.
2. AX access through the app focused UI element, for example Safari or Electron.
3. Recursive child search, depth <= 5.
4. Clipboard fallback through Cmd+C.

### Terminal-Like Surface Support

- Do not use terminal bundle IDs as the main detection mechanism.
- `TextAccessor.captureSelectedText(lastTrackedWord:)` chooses the strategy by runtime capability.
- AX selection is used only if the focused element safely supports `AXSelectedText` replacement.
- Non-settable or terminal-like surfaces must not be replaced through AX.
- If there is non-settable selection, Punto converts only the tracked typed tail of the current command.
- Passive clipboard is accepted only when the trimmed clipboard exactly matches the tracked typed tail and ends with `lastTrackedWord`.
- Keyboard-tail replacement uses backspaces plus Cmd+V, not `setSelectedText`.

### Security

- `isSecureInputEnabled()` blocks conversion in secure input contexts such as terminal password prompts.
- `isPasswordField()` blocks conversion in `AXSecureTextField`, including browser password fields.

## AppDelegate Flags

| Flag | Purpose |
| --- | --- |
| `isConversionInProgress` | Race condition protection |
| `ignoreInputSourceChangesUntil` | Grace window for programmatic layout-switch notifications |
| `lastConversion` | Undo data: original, converted, timestamp |

## Timings

| Parameter | Value |
| --- | --- |
| Modifier-only debounce | 0.5 seconds |
| Ignore generated events delay | 0.3 seconds |
| Undo window | 3.0 seconds |
| Clipboard poll | 0.02 x 10 seconds |

Keep terminal keyboard replacement timings in sync with `KeyboardReplacementPolicy` and its tests.

## Common Issues

| Problem | Check |
| --- | --- |
| Permissions not working | Run the signed app bundle from `/Applications`; verify Accessibility permission identity |
| Hotkey triggers multiple times | Check debounce and `modifiersWerePressed` |
| Text converts back | Check `ignoreEvents` |
| Event tap disabled | Verify auto re-enable on `tapDisabledByTimeout` |
| WordTracker empty | Check `ignoreInputSourceChangesUntil` grace window |
| Safari not working | Confirm clipboard fallback path |
| Terminal corruption or duplicated tail | Check keyboard-tail timing and whether active Cmd+C fallback ran before replacement |

## Character Mapping

Partial EN -> RU mapping:

```text
q->й w->ц e->у r->к t->е y->н u->г i->ш o->щ p->з
a->ф s->ы d->в f->а g->п h->р j->о k->л l->д
z->я x->ч c->с v->м b->и n->т m->ь
[->х ]->ъ ;->ж '->э `->ё ,->б .->ю
```

## Release Checklist

1. Run the focused Swift test suite for touched code.
2. Run terminal harness when terminal behavior changes: `./Scripts/test-terminal.sh`.
3. Run native bundle audit before release: `PUNTO_AUDIT_INSTALLED_BUNDLE=1 ./Scripts/test-native-bundle-audit.sh`.
4. Build and deploy with `./Scripts/deploy.sh` after code changes.
5. For public release, build universal app with `./Scripts/build.sh`, create and verify DMG, then attach the DMG to GitHub Releases instead of committing it to git.
6. Verify signing with `codesign --verify --deep --strict --verbose=2 /Applications/Punto.app`.

## Git Hygiene

- Do not commit build artifacts from `.build/` or `Release/`.
- Release DMGs belong in GitHub Releases, not in git history.
- Keep changes scoped and preserve user changes in a dirty worktree.
