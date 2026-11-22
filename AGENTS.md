# Punto Native

Native macOS 14+ Swift app. Preserve the user's live settings and permission identity.

- Run `swift run -c release PuntoChecks` for core changes.
- Run `bash Scripts/check-self-learning.sh` for self-learning checks. The checks use temporary settings and call the cancellation handler directly. They require no physical keystrokes or Accessibility grant.
- For a live conversion chord in an isolated field, use `bash Scripts/press-conversion-chord.sh <bundle-id> '<exact fixture text>'`. The probe sends system modifier events only after checking the foreground app and field contents. Verify the resulting field contents after posting.
- Build the full signed bundle with `bash Scripts/build-app.sh`; do not replace an installed executable alone.
- `Scripts/deploy.sh` installs `/Applications/PuntoNative.app`. Use an explicitly selected stable signing identity when updating a permissioned local installation.
- Use Computer Use for UI checks. Never send test messages, execute commands in a user's terminal, or overwrite a nonempty user draft. Use isolated fixtures.
- Luna checks are opt-in network tests using synthetic text and the signed-in Codex account. Do not put live user text or account data in test artifacts.
- Keep bundled resources and their provenance intact. The build must work without an original Punto installation or resource downloads.
- Release assets belong in GitHub Releases, not git. Preserve historical tags and archive branches. Do not force-push or rename branches to an unverified model.
- Copy and Apply must use the exact reviewed text, including individually rejected edits. Never auto-apply after the target or source text changes.
- Quick Luna mode is conservative proofreading. Prompt mode is explicitly selected in review and must not invent requirements.

## Check the menu and Today

- In an isolated app, open the status menu, expand and collapse the current-app card, toggle automatic correction, then pause and resume Punto. Reopen the menu and confirm the previous mode is restored after resuming. Keep the app in the card as the target while the menu is open. Verify that opening and closing the card leaves the same menu window open and that an explicit app choice appears in Profiles. Verify Option-0 opens and closes the card and, while it is expanded, Option-1 switches automatic correction and Option-2 pauses or resumes Punto.
- Seed Today with different activity on two days in a temporary settings folder. Switch between Day and Week. Verify the two conversion totals, the stacked chart and the symbol total below it. Confirm that days before local recording are shown as missing history.

## Check the GitHub invitation

- Run `swift run -c release PuntoChecks` for the threshold, failed open, dismissal, restart and migration checks. Run `bash Scripts/build-app.sh` for an isolated app bundle.
- Use a fresh test profile and an isolated editable field, with analytics off. Mix manual and automatic conversions. Verify the text after each conversion. The GitHub link stays in the menu regardless of invitation history. The first five successful conversions leave the invitation hidden. The sixth makes it available in the popup and Today and highlights the existing menu link. Layout toggles and failed replacements do not count.
- On the native UI, check that the popup leaves focus in the editor. A click outside closes only the popup. Opening GitHub or choosing “Больше не предлагать” hides the shared invitation, including after restart. The plain GitHub link stays available.
- A fixture that calls the completion handler covers the shared UI state. Changes to event delivery, focus or popup buttons also need a separate live run through `CGEventTap`. For the default manual chord, use `bash Scripts/press-conversion-chord.sh <fixture-bundle-id> '<exact fixture text>'` from the integrated checkout. Check the automatic path in the same isolated editor.

## Packaging a release

- Use `bash Scripts/package-release.sh` for local packaging. For a stable OTA candidate, follow [docs/OTA.md](docs/OTA.md#сборка-и-публикация-stable) for the release version, increasing build number, notes, and GitHub feed URLs.
- Use the existing `Punto Local Code Signing` identity and the established stable Sparkle key for public candidates. Verify the app's designated requirement against the previous public DMG. Keep private keys in Keychain or a protected temporary file. Use a separate key and feed URL for tests.
- Verify the four artifacts before a handoff: DMG, its checksum, OTA ZIP, and `appcast.xml`. Confirm that the appcast points to the ZIP for the intended tag.
- Packaging is local. Create a GitHub draft and upload assets only when requested. Publish only with explicit authorization.
