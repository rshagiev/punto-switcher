# Legacy Compatibility Audit

## Principle

Punto should preserve Punto Switcher behavior where it affects text safety, hotkeys,
layout choice, undo, app exceptions, secure input, and import of existing user
preferences. It should not continuously rewrite native runtime state into old
Punto Switcher storage shapes unless the native app actively needs that shape.

## Keep

- Text capture/replacement safety: AX capability checks, clipboard fallback,
  terminal-like typed-tail replacement, secure/password blocking.
- User-facing behavior: modifier-only conversion, toggle case, undo, auto-correct
  gates, cancelling keys, disabled apps, per-app layout memory, selected-text
  layout switching, pasteboard restore.
- Native import compatibility: old hotkey dictionaries, old rule dictionaries,
  old layout IDs, old sound settings, old statistics snapshots, and old update
  flags can still seed native state when native keys are missing.
- Reverse-audit probes that guard a real behavior boundary.

## Quarantine

- Observed selectors, class names, and plist keys that only document Punto
  Switcher internals should stay in small policy types and tests, not leak into
  orchestration code unless the app uses them.
- Import/export bridges should be treated as compatibility adapters. Runtime
  managers should read through them only at the boundary and then operate on
  native data structures.

## Cut

- Continuous legacy mirroring for data that Punto itself owns natively.
- Network/update/statistics compatibility with Yandex services.
- Proprietary UI surfaces such as searchbar suggestion UI, undo-learning popup
  UI, update/install tooltip copy, and copied visual/audio assets.
- Newly discovered reverse strings when they do not constrain native behavior.

## First Applied Cut

Product statistics are now native-write only. `SettingsManager.productStatistics`
still imports old `typedWords` / `typedSymbols` / `PSDayuseSettings` values when
no native snapshot exists, including the observed day-use date markers, but
runtime events only update the Codable `productStatistics` payload. The old
`PSDayuseSettings` keys remain pinned for audit/import coverage, but no core
writer generates that legacy shape.

## Settings Mirror Cut

Most legacy settings keys are now read-only import fallbacks at runtime. Native
settings changes write native keys for hotkeys, selected-text layout switching,
manual conversion, layout preferences, app exceptions, return-reset apps,
auto-correction gates, sound resources, pasteboard restore, and user rules. The
old Punto Switcher key names remain pinned in policies, tests, and reverse audit
so imported preferences still work, but normal use no longer rewrites the old
plist shape on every settings change.

The intentional exception is first-run/update consumption. Routine first-launch
writes are native-only, but when onboarding or an installer/update presentation
consumes old state, Punto still clears the observed legacy booleans as well as
the native state so imported `isFirstInstallation`, `isJustInstalled`, or
`isJustUpdated` values cannot reopen one-shot UI.

## Enforced Boundary

`Scripts/test-legacy-boundary.sh` keeps the cut from regressing. It fails if
removed legacy export helpers return, and it scans `SettingsManager` writes so
native-owned settings cannot start writing Punto Switcher plist keys again by
accident. The script is part of `Scripts/test-cycle.sh`, alongside the reverse
audit that still pins observed Punto Switcher evidence. Reverse-audit-only
selectors, class names, resources, metric strings, and tooltip/window
identifiers for accessibility preferences, Mail helpers, cancelling keys,
clipboard replacement, hotkey editing, input-source install prompts,
keyboard-layout private selectors, product statistics, search-click UI gates,
settings setters, sound state, startup presentation, status icons, undo
learning, and user-rule UI now live in `PuntoSwitcherObservedSurface` instead of
the behavior policies that parse settings or execute native logic.

The boundary also protects diagnostic code from becoming another legacy fork.
`Scripts/debug.sh components` now runs `PuntoCoreTest` and `PuntoDiag` against
the production module instead of carrying inline copies of `LayoutConverter` and
`WordTracker`; the boundary script fails if those duplicate classes or their old
mapping/boundary tables reappear.

The repository also no longer carries a placeholder SwiftPM `Tests/` file that
claims tests live elsewhere. This toolchain cannot import XCTest, so placeholder
test targets create a false green surface; the boundary script now fails if that
placeholder comes back.

`SettingsManager` now keeps native primary keys and Punto Switcher import aliases
in separate namespaces. `Keys` is the native write surface; `ImportKeys` is
read-only import evidence, with the only writer exception still being
first-run consumption of the imported `isFirstInstallation` flag. The boundary
script fails if imported aliases leak back into the routine key namespace or if
routine code starts writing import-only keys again.

## Next Candidates

- Continue splitting only the remaining constants where the policy currently
  uses the observed value as a real import key or runtime alias.
- Add an explicit export path if we ever need to generate Punto Switcher-shaped
  settings intentionally; keep routine runtime writes native-only.
- Keep searchbar/click-search split this way: selected-text Yandex shortcuts and
  double-click search are real native behavior; proprietary `PSSearchbarSettings`
  remains an import fallback and audit shell.
