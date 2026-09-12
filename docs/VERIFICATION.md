# Release verification

## 2.0.0-rc.1, 2026-09-13

- `swift run -c release PuntoChecks`: passed. Includes 1,023 comparisons of indexed language-rule decisions against sequential evaluation; 1,084 assertions through that stage, then profiles, text-diff choice/round-trip and processing-depth checks. These are regression assertions, not a measured natural-language accuracy percentage.
- Archived main `9aeb92c`: `swift run -c release PuntoCoreTest` passed on the current Mac before replacing the checkout. Historical GUI behavior was not re-tested for this comparison.
- New Prompt mode: two opt-in live requests through `gpt-5.6-luna` returned structured prompts. One resolved CSV -> JSON and preserved 42, no deletion, deferred UI work and plan-before-code. The other preserved the URL and path and kept the table/list choice unresolved. This is sample evidence; it does not establish perfect completeness of every rewrite.
- Previous development checks exercised Safari input/textarea/contenteditable, Codex, Terminal and Ghostty; repeat conversion, clipboard restoration, secure-field exclusion, profile behavior and selective Luna application were investigated. Private raw logs and user settings are not published.

## Boundaries

No universal app-compatibility claim. Native input paths differ across applications, secure input cannot be overridden, and model output can omit nuance. The release targets Apple Silicon only. This release is not Apple-notarized. Public updates are manual.

## Repeat locally

Run core checks and the bundle audit. For live UI tests, use a disposable text fixture, never a user's unsent message or active command. Confirm initial and final text, focus, input source and clipboard, then repeat the action. For a Luna request, also test editing the source while the request runs; automatic replacement must be cancelled.

## Final installed candidate

The arm64-only bundle was installed with the existing local signing identity; the settings file checksum stayed unchanged. Code-signature and resource audits passed. The DMG checksum was verified by hdiutil. Computer Use showed the connected Codex state, all three mode controls, and switching from a loading Structure request back to a cached Prompt result without waiting; loading cleared immediately.

One additional UI Prompt sample omitted the number 42 even though the two scripted examples preserved their numbers. Prompt output remains review-only and is not a lossless transformation guarantee. The diff makes this omission visible; no automatic acceptance of Prompt output is implemented.

## 2.0.0 publication

The release candidate was promoted to 2.0.0 without changes to Swift code or language rules. The bundle version, documentation, signature and disk image were refreshed for the stable release. The same Apple Silicon and notarization boundaries apply.
