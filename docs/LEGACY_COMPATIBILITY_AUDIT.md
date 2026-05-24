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

Application update/install state is also native-write only. Imported Punto
Switcher updater keys (`configVersion`, install/update booleans, request-rate
and date markers) seed `applicationUpdateSettings` when no native snapshot
exists, but startup presentation writes back only the normalized native Codable
payload. There is no helper that emits the old updater plist dictionary from
native state.
The only legacy updater writes left are one-shot consumption of imported
`isFirstInstallation`, `isJustInstalled`, `isJustUpdated`, and `isUpdating` so
old presentation flags cannot reopen welcome/update UI.

## Settings Mirror Cut

Most legacy settings keys are now read-only import fallbacks at runtime. Native
settings changes write native keys for hotkeys, selected-text layout switching,
manual conversion, layout preferences, app exceptions, return-reset apps,
auto-correction gates, sound resources, pasteboard restore, and user rules. The
old Punto Switcher key names remain pinned in policies, tests, and reverse audit
so imported preferences still work, but normal use no longer rewrites the old
plist shape on every settings change.

The intentional exception is first-run/update consumption. Routine first-launch
and update-state writes are native-only, but when onboarding or an update
presentation consumes old state, Punto still clears the observed legacy booleans
as well as the native state so imported `isFirstInstallation`,
`isJustInstalled`, `isJustUpdated`, or `isUpdating` values cannot reopen
one-shot UI.

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
the behavior policies that parse settings or execute native logic. AppDelegate
is also guarded from reopening app/input-source, AX-notification, text-action,
command, startup, and undo runtime policy execution after those decisions have
been moved into coordinators.

Runtime-compatible aliases, log prefixes, and metric names are now owned by the
native policy that consumes them, not by `PuntoSwitcherObservedSurface`.
`PuntoCoreTest` aligns those native constants back to the reverse-audit anchors,
while `Scripts/test-legacy-boundary.sh` rejects direct
`PuntoSwitcherObservedSurface` references from the app shell and selected
behavior-policy files. This keeps the observed binary surface useful as evidence
without turning it into a second runtime dependency graph. Startup presentation
logs and auto-correction old-rule import keys follow the same split: the runtime
and import policy own the native-compatible strings they use, while tests align
those strings back to the reverse-audit anchors.

The boundary also protects diagnostic code from becoming another legacy fork.
`Scripts/debug.sh components` now runs `PuntoCoreTest` and `PuntoDiag` against
the production module instead of carrying inline copies of `LayoutConverter` and
`WordTracker`; the boundary script fails if those duplicate classes or their old
mapping/boundary tables reappear.

The boundary also keeps live macOS transport out of `PuntoCore`: AppKit
pasteboard snapshots, AX elements, CGEvent synthesis, and TIS switching belong
to runtime adapters and diagnostics, while core modules stay as policy and
domain code.

Runtime-owned settings, sound, and clipboard key constants now use
`native*Key` for active native write keys and `legacy*Key` for import-only
aliases. `observed*Key` is reserved for reverse-audit anchors, so a
Punto-compatible string value no longer makes a runtime setting look like it is
owned by the binary audit layer.

The same split applies to auto-correction cancelling-key aliases: behavior code
uses `legacy*Name` / `legacy*SelectorAlias`, while
`PuntoSwitcherObservedSurface` owns the observed per-key names and selectors.
Tests align the two surfaces without making behavior policies depend on the
reverse-audit namespace.

Hotkey import aliases follow the same rule. `LegacyHotkeyPolicy` exposes
`legacy*Key` constants for Punto Switcher shortcut dictionaries and shortcut
field keys, while `PuntoSwitcherObservedSurface.Hotkeys` owns the observed keys
and selector/class boundary. The boundary audit rejects `observed*Key` inside
selected behavior-policy files.

The repository also no longer carries a placeholder SwiftPM `Tests/` file that
claims tests live elsewhere. This toolchain cannot import XCTest, so placeholder
test targets create a false green surface; the boundary script now fails if that
placeholder comes back.

`SettingsManager` now keeps native primary keys and Punto Switcher import aliases
in separate namespaces inside the importable `PuntoSettings` target.
`SettingsStorageKeys` is the native write surface; `SettingsImportKeys` is
read-only import evidence, with the only writer exceptions being one-shot
consumption of imported first-run/update presentation flags. Boolean and hotkey
slot metadata lives in `SettingsBoolSlotRegistry` and `SettingsHotkeySlotRegistry`,
so the manager does not rebuild defaults, native keys, or import alias precedence
inline. Low-level `UserDefaults` access sits behind `SettingsDefaultsStore`, so
typed persistence, Codable payloads, injected test domains, and persistent-domain
checks do not spread through the settings composition layer. Native-vs-import
resolution sits behind `SettingsValueResolver`, so the manager does not rebuild
alias precedence, inverted legacy booleans, hotkey fallbacks, input-source
fallbacks, searchbar snapshots, sound/import toggle scans, legacy statistics
snapshots, updater snapshots, or imported user-rule merges inline.
`PuntoSettingsTest` now exercises the real manager against isolated `UserDefaults`
suites, while the boundary script fails if imported aliases leak back into the
routine key namespace, if routine code starts writing import-only keys again, or if
the manager reopens direct native/import resolution helpers.

Launch-at-login now follows the same storage/runtime split. `SettingsManager`
imports Punto Switcher's `launchesOnStartup` key only as a read fallback and
writes the native `launchAtLogin` key; the live `ServiceManagement` registration
side effect is handled by the app shell through `LoginItemController`, not by the
importable settings module.

Legacy scalar parsing is centralized in `LegacyValuePolicy` instead of being
reimplemented per feature. Searchbar settings, update/install settings, product
statistics, hotkeys, undo-learning, user-rule imports, and alias-sensitive
settings now share the same Bool/Int/date/bundle-id normalization surface while
keeping their native write targets separate.

## Next Candidates

- Continue splitting only the remaining constants where the policy currently
  uses reverse-audit naming for a real import key, runtime alias, URL fragment,
  default, or sentinel value.
- Add an explicit export path if we ever need to generate Punto Switcher-shaped
  settings intentionally; keep routine runtime writes native-only.
- Keep searchbar/click-search split this way: selected-text Yandex shortcuts and
  double-click search are real native behavior; proprietary `PSSearchbarSettings`
  remains an import fallback and audit shell.
