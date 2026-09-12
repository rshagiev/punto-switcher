# Punto Native

Native macOS 14+ Swift app. Preserve the user's live settings and permission identity.

- Run `swift run -c release PuntoChecks` for core changes.
- Build the full signed bundle with `bash Scripts/build-app.sh`; do not replace an installed executable alone.
- `Scripts/deploy.sh` installs `/Applications/PuntoNative.app`. Use an explicitly selected stable signing identity when updating a permissioned local installation.
- Use Computer Use for UI checks. Never send test messages, execute commands in a user's terminal, or overwrite a nonempty user draft. Use isolated fixtures.
- Luna checks are opt-in network tests using synthetic text and the signed-in Codex account. Do not put live user text or account data in test artifacts.
- Keep bundled resources and their provenance intact. The build must work without an original Punto installation or resource downloads.
- Release assets belong in GitHub Releases, not git. Preserve historical tags and archive branches. Do not force-push or rename branches to an unverified model.
- Copy and Apply must use the exact reviewed text, including individually rejected edits. Never auto-apply after the target or source text changes.
- Quick Luna mode is conservative proofreading. Prompt mode is explicitly selected in review and must not invent requirements.
