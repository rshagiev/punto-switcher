# Architecture

`PuntoCore` contains physical layout maps, indexed compatibility rules, user rules, modifier chord state, application modes, text diff choices and local processing-depth heuristics. It does not control the desktop or call a model.

`KeyboardEngine` owns the event tap, tracked word, app/input-source context and conversion lifecycle. Generated events are tagged and replayed through a fence; focus changes invalidate tracked state. Secure input and password fields are excluded. `TextAccess` selects the usable Accessibility, clipboard or tracked-tail path and checks its target before replacing text. Clipboard fallback preserves the previous pasteboard contents when it still owns the transaction.

`Settings` persists preferences independently of the original app. `AppProfilesView` and `SettingsView` expose native controls. Optional import reads original settings on first use; it is not a runtime dependency. `ConversionFeedback` and `LunaHUD` are nonactivating feedback surfaces.

`LunaClient` runs a bounded, ephemeral Codex CLI process with tools disabled and a strict JSON output schema. The source text is an untrusted JSON value, separate from the editor instructions. `LunaCorrection` owns cancellation, focus/source snapshots, cached mode variants, independent rejected edits, Apply and Undo. `LunaInteractiveText` renders clickable diff spans; display-only markers never enter copied or applied text.

Public builds omit the local update-candidate path. The optional local updater accepts a candidate only after checking its signing requirement against the running app. Public releases currently use manual installation from GitHub.
