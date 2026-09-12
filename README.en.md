# Punto Native - keyboard layout switcher for macOS

[Русский](README.md) · English

Punto Native is a Punto Switcher alternative for Apple Silicon Macs. It fixes English or Russian text typed with the wrong keyboard layout, either automatically or with a custom keyboard shortcut.

Type `ghbdtn`, press **Command + Option + Shift**, and get `привет`. Select a phrase to convert it all at once. `руддщ` becomes `hello`.

**[Download for Mac](https://github.com/rshagiev/punto-switcher/releases/latest)** · macOS 14+ · Apple Silicon (M1 or newer) · No Intel build

## Features

- Convert the last typed word or selected text between English QWERTY and Russian layouts.
- Enable automatic layout correction or keep manual shortcuts only.
- Choose a mode for each app: global settings, automatic, manual only, or disabled. Drag apps from Finder into Profiles.
- Add word, prefix, substring or regular-expression rules; learn from cancelled corrections.
- Remember the layout per app, show brief conversion feedback, and configure sounds and login launch.
- Runs in the menu bar. The Dock icon appears while a settings or review window is open.

Built with Swift, AppKit and SwiftUI. Development checks included Safari text fields and web editors, Codex, Terminal and Ghostty. Password fields are excluded; behavior in other editors may vary.

## Install

1. Download the DMG from Releases and drag **PuntoNative.app** into Applications.
2. Open the app and grant Accessibility and Input Monitoring permissions in System Settings.
3. Quit other keyboard layout switchers before using Punto Native.

Language tables and sounds are bundled. The original Punto Switcher is not required. The build is not Apple-notarized; macOS may require allowing it to open in Privacy & Security.

## Optional text editing with Luna

Luna uses your installed [Codex CLI](https://developers.openai.com/codex/cli/) and signed-in account. It runs only when requested. Keyboard layout conversion works without Codex or a network connection.

Select text or place the cursor in a paragraph, then use one of two configurable commands:

- **Fix immediately** applies conservative typo and grammar correction.
- **Review before replacing** opens a before/after comparison with three modes:

| Mode in the app | Purpose |
| --- | --- |
| **Ошибки** | Correct typos and grammar while keeping the author's voice. |
| **Собрать мысль** | Organize rough dictation, repetitions and explicit self-corrections into readable text. |
| **Промпт** | Turn a rough task description into a structured LLM prompt. |

Click a highlighted edit to reject it; click again to accept it. Completed variants are cached for the current text. Switching modes during generation cancels the old request. If you edit the source or switch fields while a quick request is running, automatic replacement is cancelled.

Luna can miss details, so review important names, numbers and requirements. Requests use the limits of your Codex account; no separate API key is configured in Punto. The app's interface is currently in Russian.

## Privacy

Layout conversion stays on your Mac. Luna sends only the selected text or current paragraph to Codex when invoked. There is no continuous LLM processing or typing-history log. Settings, daily counters and learning words are stored locally. Codex account settings and data policies also apply to Luna requests.

## Build

Requires Swift 6 and Xcode Command Line Tools on macOS 14+.

```sh
swift run -c release PuntoChecks
bash Scripts/build-app.sh
open 'Build/Punto Native.app'
```

The default build uses ad-hoc signing. Set `CODE_SIGN_IDENTITY` to use your own certificate. Build a DMG with `bash Scripts/package-release.sh`.

[Release notes](CHANGELOG.md) · [Architecture](docs/ARCHITECTURE.md) · [Verification](docs/VERIFICATION.md) · [Report an issue](https://github.com/rshagiev/punto-switcher/issues)
