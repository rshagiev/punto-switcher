import Foundation
import PuntoCore

import Foundation
import PuntoCore

func runTextCapturePolicyTests() throws {
    try expect(
        KeyboardEventKeyCodePolicy.copyKeyCode,
        8,
        "keyboard event key code policy uses C key for copy"
    )
    try expect(
        ClipboardCapturePolicy.copyKeyCode,
        KeyboardEventKeyCodePolicy.copyKeyCode,
        "clipboard capture shares copy key code policy"
    )
    try expect(
        ClipboardCapturePolicy.keyUpDelay,
        0.01,
        "clipboard capture preserves copy key-up delay"
    )
    try expect(
        ClipboardCapturePolicy.pollInterval,
        0.02,
        "clipboard capture preserves polling interval"
    )
    try expect(
        ClipboardCapturePolicy.maxPollAttempts,
        10,
        "clipboard capture preserves max poll attempts"
    )
    try expect(
        ClipboardCapturePolicy.shouldAttemptHIDFallback(pollAttempt: 3, pasteboardChanged: false),
        true,
        "clipboard capture tries HID fallback on third unchanged poll"
    )
    try expect(
        ClipboardCapturePolicy.shouldAttemptHIDFallback(pollAttempt: 3, pasteboardChanged: true),
        false,
        "clipboard capture skips HID fallback after pasteboard change"
    )
    try expect(
        ClipboardCapturePolicy.shouldAttemptHIDFallback(pollAttempt: 2, pasteboardChanged: false),
        false,
        "clipboard capture waits before HID fallback"
    )
    try expect(
        ClipboardCapturePolicy.shouldStopPolling(pasteboardChanged: true),
        true,
        "clipboard capture stops polling after pasteboard change"
    )
    try expect(
        ClipboardCapturePolicy.shouldStopPolling(pasteboardChanged: false),
        false,
        "clipboard capture continues polling while pasteboard is unchanged"
    )
    try expect(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: "browser selection",
            pasteboardChanged: true,
            previousClipboardText: nil
        ),
        "browser selection",
        "clipboard capture accepts changed non-empty copied text"
    )
    try expect(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: "browser selection",
            pasteboardChanged: false,
            previousClipboardText: "browser selection"
        ),
        "browser selection",
        "clipboard capture accepts unchanged text when it matches previous clipboard"
    )
    try expectNil(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: "stale clipboard",
            pasteboardChanged: false,
            previousClipboardText: "different previous"
        ),
        "clipboard capture rejects unchanged stale clipboard mismatch"
    )
    try expectNil(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: " \n\t ",
            pasteboardChanged: true,
            previousClipboardText: nil
        ),
        "clipboard capture rejects whitespace-only copied text"
    )

    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "commit", lastTrackedTail: "git commit")?.originalTail,
        "git commit",
        "terminal rewrite accepts selected suffix inside tracked tail"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: " commit\n", lastTrackedTail: "git commit")?.selectedText,
        "commit",
        "terminal rewrite trims copied selection"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "user@host % git commit\n", lastTrackedTail: "git commit"),
        TextCapturePolicy.TailRewrite(selectedText: "git commit", originalTail: "git commit"),
        "terminal rewrite extracts typed tail from prompt-prefixed selection"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "Last login\nuser@host % git commit\n", lastTrackedTail: "git commit"),
        TextCapturePolicy.TailRewrite(selectedText: "git commit", originalTail: "git commit"),
        "terminal rewrite extracts typed tail from multiline prompt selection"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "Punto ➜ git commit\n", lastTrackedTail: "git commit"),
        TextCapturePolicy.TailRewrite(selectedText: "git commit", originalTail: "git commit"),
        "terminal rewrite extracts typed tail from zsh arrow prompt"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "➜  Punto git:(main) ✗ git commit\n", lastTrackedTail: "git commit"),
        TextCapturePolicy.TailRewrite(selectedText: "git commit", originalTail: "git commit"),
        "terminal rewrite extracts typed tail from dirty git zsh prompt"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "λ git commit\n", lastTrackedTail: "git commit"),
        TextCapturePolicy.TailRewrite(selectedText: "git commit", originalTail: "git commit"),
        "terminal rewrite extracts typed tail from lambda prompt"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "old > scrollback git commit", lastTrackedTail: "git commit"),
        "terminal rewrite rejects prompt marker that is not at prompt boundary"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "oldgit commit", lastTrackedTail: "git commit"),
        "terminal rewrite rejects glued prefix before tracked tail"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "old scrollback git commit", lastTrackedTail: "git commit"),
        "terminal rewrite rejects promptless scrollback before tracked tail"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "old scrollback\ngit commit", lastTrackedTail: "git commit"),
        "terminal rewrite rejects promptless multiline scrollback before tracked tail"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "old clipboard", lastTrackedTail: "git commit"),
        "terminal rewrite rejects unrelated selection"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "git", lastTrackedTail: "git commit"),
        "terminal rewrite rejects prefix-only selection"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "it com", lastTrackedTail: "git commit"),
        "terminal rewrite rejects middle selection"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "mit", lastTrackedTail: "git commit"),
        "terminal rewrite rejects partial-word suffix selection"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "make test&&ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "make test&&ghbdtn"),
        "terminal rewrite accepts suffix after shell and boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "make test||ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "make test||ghbdtn"),
        "terminal rewrite accepts suffix after shell or boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "make test;ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "make test;ghbdtn"),
        "terminal rewrite accepts suffix after shell semicolon boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "echo $(ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "echo $(ghbdtn"),
        "terminal rewrite accepts suffix after shell grouping boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "cat<ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "cat<ghbdtn"),
        "terminal rewrite accepts suffix after shell redirection boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "FOO=ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "FOO=ghbdtn"),
        "terminal rewrite accepts suffix after shell assignment boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "--ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "--ghbdtn"),
        "terminal rewrite accepts suffix after shell option boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "user@host % commit", lastTrackedTail: "commit"),
        TextCapturePolicy.TailRewrite(selectedText: "commit", originalTail: "commit"),
        "terminal rewrite accepts single-word AX command tail"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "git commit old prompt", lastTrackedTail: "git commit"),
        "terminal rewrite rejects non-current command tail selection"
    )

    try expect(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "git commit",
        "passive clipboard accepts exact typed tail"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects missing clipboard text"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "git commit",
            lastTrackedWord: nil,
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects missing tracked word"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: nil
        ),
        "passive clipboard rejects missing tracked tail"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "old clipboard",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects unrelated clipboard text"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "prompt % git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects prompt-prefixed garbage"
    )
    try expect(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "commit"
        ),
        "commit",
        "passive clipboard accepts exact single-word typed tail"
    )
    try expect(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "git commit\n",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "git commit",
        "passive clipboard trims trailing newline from exact typed tail"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "commit",
            lastTrackedWord: "push",
            lastTrackedTail: "commit"
        ),
        "passive clipboard rejects tail that does not end with tracked last word"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "old clipboard commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects stale clipboard ending with last word"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "last command\ngit commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects multiline terminal garbage"
    )
    try expect(
        TextCapturePolicy.shouldAttemptActiveClipboardFallbackForNonSettableSelection(
            selectedText: "commit",
            lastTrackedTail: "git commit"
        ),
        false,
        "capture policy skips active clipboard copy when AX non-settable selection is already a safe tail"
    )
    try expect(
        TextCapturePolicy.shouldAttemptActiveClipboardFallbackForNonSettableSelection(
            selectedText: "user@host % git commit\n",
            lastTrackedTail: "git commit"
        ),
        false,
        "capture policy skips active clipboard copy for prompt-prefixed safe AX tail"
    )
    try expect(
        TextCapturePolicy.shouldPreferActiveClipboardFallbackForNonSettableContentSelection(
            accessibilityRoles: ["AXStaticText", "AXWebArea"]
        ),
        true,
        "capture policy prefers active clipboard confirmation for non-settable AXWebArea content"
    )
    try expect(
        TextCapturePolicy.shouldPreferActiveClipboardFallbackForNonSettableContentSelection(
            accessibilityRoles: ["AXStaticText", "AXScrollArea"]
        ),
        false,
        "capture policy keeps AXScrollArea eligible for terminal-tail routing unless AX selection is unsafe"
    )
    try expect(
        TextCapturePolicy.shouldAttemptActiveClipboardFallbackForNonSettableSelection(
            selectedText: "old scrollback",
            lastTrackedTail: "git commit"
        ),
        true,
        "capture policy attempts active clipboard copy after unsafe non-settable AX mismatch"
    )
    try expect(
        TextCapturePolicy.shouldAttemptActiveClipboardFallbackForNonSettableSelection(
            selectedText: "browser selection",
            lastTrackedTail: nil
        ),
        true,
        "capture policy attempts active clipboard copy when non-settable AX text has no tracked tail"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "mail selection",
            activeClipboardText: "mail selection",
            accessibilityRoles: ["AXStaticText", "AXWebArea"]
        ),
        CapturedText(
            text: "mail selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy accepts matched non-settable AXWebArea content through active clipboard replacement"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "commit",
            activeClipboardText: "commit",
            accessibilityRoles: ["AXStaticText", "AXWebArea"]
        ),
        CapturedText(
            text: "commit",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy avoids misclassifying AXWebArea selected suffix as terminal-tail rewrite when clipboard confirms content selection"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "parallels selection",
            activeClipboardText: "parallels selection",
            accessibilityRoles: ["AXStaticText", "AXScrollArea"]
        ),
        CapturedText(
            text: "parallels selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy accepts matched AXScrollArea content observed in Punto Switcher Mail/Parallels path"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "static selection",
            activeClipboardText: "static selection",
            accessibilityRoles: ["AXStaticText", "AXGroup"]
        ),
        "capture policy rejects generic non-settable content without observed content roles"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "mail selection",
            activeClipboardText: "different clipboard",
            accessibilityRoles: ["AXWebArea"]
        ),
        "capture policy rejects mismatched active clipboard content selection"
    )

    try expect(
        TextReplacementPolicy.rewriteTail("git commit ghbdtn", replacing: "ghbdtn", with: "привет"),
        "git commit привет",
        "rewrite tail replaces selected suffix"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("лол лол", replacing: "лол лол", with: "kjk kjk"),
        "kjk kjk",
        "rewrite tail replaces whole terminal tail"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("лол лол", replacing: "лол", with: "kjk"),
        "лол kjk",
        "rewrite tail replaces repeated selected suffix only"
    )
    try expectNil(
        TextReplacementPolicy.rewriteTail("abc def", replacing: "abc", with: "фис"),
        "rewrite tail rejects selected first word in tail"
    )
    try expectNil(
        TextReplacementPolicy.rewriteTail("abc def", replacing: "xyz", with: "чнп"),
        "rewrite tail rejects selection outside tail"
    )
    try expectNil(
        TextReplacementPolicy.rewriteTail("ghbdtn && echo done", replacing: "ghbdtn", with: "привет"),
        "rewrite tail rejects stale middle match"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterReplacement(
            capturedText: "ghbdtn",
            replacement: "привет",
            method: .keyboardRewriteTail(originalTail: "git commit ghbdtn")
        ),
        "git commit привет",
        "replacement policy computes rewritten tracked tail"
    )
    try expect(
        TextReplacementPolicy.recordedMethodAfterReplacement(
            capturedText: "ghbdtn",
            replacement: "привет",
            method: .keyboardRewriteTail(originalTail: "git commit ghbdtn")
        ),
        .keyboardRewriteTail(originalTail: "git commit привет"),
        "replacement policy records rewritten tail for undo"
    )
    try expect(
        TextReplacementPolicy.recordedMethodAfterReplacement(
            capturedText: "hello",
            replacement: "руддщ",
            method: .accessibilitySelection
        ),
        .accessibilitySelection,
        "replacement policy preserves accessibility method"
    )
    try expectNil(
        TextReplacementPolicy.recordedMethodAfterReplacement(
            capturedText: "missing",
            replacement: "привет",
            method: .keyboardRewriteTail(originalTail: "git commit ghbdtn")
        ),
        "replacement policy rejects unrewritable tail"
    )
    try expectNil(
        TextReplacementPolicy.recordedMethodAfterReplacement(
            capturedText: "ghbdtn",
            replacement: "привет",
            method: .keyboardRewriteTail(originalTail: "ghbdtn && echo done")
        ),
        "replacement policy rejects stale non-suffix tail"
    )
    try expect(
        TextReplacementPolicy.recordedMethodAfterUndo(
            convertedText: "привет",
            originalText: "ghbdtn",
            method: .keyboardRewriteTail(originalTail: "git commit привет")
        ),
        .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
        "replacement policy records full original tail after undo"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterUndo(
            convertedText: "привет",
            originalText: "ghbdtn",
            method: .keyboardRewriteTail(originalTail: "git commit привет")
        ),
        "git commit ghbdtn",
        "replacement policy computes full tracked tail after undo"
    )
    try expectNil(
        TextReplacementPolicy.recordedMethodAfterUndo(
            convertedText: "missing",
            originalText: "ghbdtn",
            method: .keyboardRewriteTail(originalTail: "git commit привет")
        ),
        "replacement policy rejects unrewritable undo tail"
    )
    try expectNil(
        TextReplacementPolicy.recordedMethodAfterUndo(
            convertedText: "привет",
            originalText: "ghbdtn",
            method: .keyboardRewriteTail(originalTail: "привет && echo done")
        ),
        "replacement policy rejects stale non-suffix undo tail"
    )
    try expect(
        TextReplacementPolicy.recordedMethodAfterUndo(
            convertedText: "руддщ",
            originalText: "hello",
            method: .keyboardBackspacePaste
        ),
        .keyboardBackspacePaste,
        "replacement policy preserves non-tail method after undo"
    )
    try expect(
        TextReplacementPolicy.shouldKeepSelectionAfterReplacement(method: .accessibilitySelection),
        true,
        "replacement policy keeps editable AX selection selected"
    )
    try expect(
        TextReplacementPolicy.shouldKeepSelectionAfterReplacement(method: .keyboardBackspacePaste),
        false,
        "replacement policy does not keep keyboard replacement selected"
    )
    try expect(
        TextReplacementPolicy.shouldKeepSelectionAfterReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        false,
        "replacement policy does not keep terminal tail replacement selected"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterLastWordReplacement(
            lastTrackedTail: "git commit ghbdtn",
            lastWord: "ghbdtn",
            replacement: "привет"
        ),
        "git commit привет",
        "last-word policy rewrites suffix in tracked tail"
    )
    try expectNil(
        TextReplacementPolicy.trackedTailAfterLastWordReplacement(
            lastTrackedTail: "otherghbdtn",
            lastWord: "ghbdtn",
            replacement: "привет"
        ),
        "last-word policy rejects glued suffix in tracked tail"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterLastWordReplacement(
            lastTrackedTail: "ghbdtn",
            lastWord: "ghbdtn",
            replacement: "привет"
        ),
        "привет",
        "last-word policy rewrites single-word tail"
    )
    try expectNil(
        TextReplacementPolicy.trackedTailAfterLastWordReplacement(
            lastTrackedTail: "git commit stale",
            lastWord: "ghbdtn",
            replacement: "привет"
        ),
        "last-word policy rejects stale tracked tail"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterRecentTextReplacement(
            lastTrackedTail: "git commit teh ",
            original: "teh ",
            replacement: "the "
        ),
        "git commit the ",
        "recent-text policy rewrites completed token suffix"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterRecentTextReplacement(
            lastTrackedTail: "otherteh ",
            original: "teh ",
            replacement: "the "
        ),
        "the ",
        "recent-text policy rejects glued completed token suffix"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterRecentTextReplacement(
            lastTrackedTail: nil,
            original: "ghbdtn ",
            replacement: "привет "
        ),
        "привет ",
        "recent-text policy falls back to replacement without tracked tail"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterRecentTextReplacement(
            lastTrackedTail: "git commit stale ",
            original: "ghbdtn ",
            replacement: "привет "
        ),
        "привет ",
        "recent-text policy discards stale tracked tail"
    )
    try expectNil(
        TextReplacementPolicy.rewriteTail("git commit", replacing: "mit", with: "ьше"),
        "rewrite tail rejects partial-word suffix replacement"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("make test&&ghbdtn", replacing: "ghbdtn", with: "привет"),
        "make test&&привет",
        "rewrite tail accepts suffix after shell and boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("make test||ghbdtn", replacing: "ghbdtn", with: "привет"),
        "make test||привет",
        "rewrite tail accepts suffix after shell or boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("make test;ghbdtn", replacing: "ghbdtn", with: "привет"),
        "make test;привет",
        "rewrite tail accepts suffix after shell semicolon boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("echo $(ghbdtn", replacing: "ghbdtn", with: "привет"),
        "echo $(привет",
        "rewrite tail accepts suffix after shell grouping boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("cat<ghbdtn", replacing: "ghbdtn", with: "привет"),
        "cat<привет",
        "rewrite tail accepts suffix after shell redirection boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("FOO=ghbdtn", replacing: "ghbdtn", with: "привет"),
        "FOO=привет",
        "rewrite tail accepts suffix after shell assignment boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("--ghbdtn", replacing: "ghbdtn", with: "привет"),
        "--привет",
        "rewrite tail accepts suffix after shell option boundary"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("hello", replacementSupported: true),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: nil,
            lastTrackedTail: nil
        ),
        CapturedText(text: "hello", replacementMethod: .accessibilitySelection, source: "AX editable selection"),
        "capture policy accepts editable AX selection"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("commit", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "AX non-settable command-tail selection"),
        "capture policy rewrites non-settable AX command tail"
    )
    let terminalToggleCapture = try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("hello", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: "hello",
            lastTrackedTail: "git hello"
        ),
        CapturedText(text: "hello", replacementMethod: .keyboardRewriteTail(originalTail: "git hello"), source: "AX non-settable command-tail selection"),
        "capture policy supports terminal tail capture for toggle-case"
    )
    guard let terminalToggleCapture else {
        throw TestFailure(description: "capture policy supports terminal tail capture for toggle-case: expected non-nil capture")
    }
    try expect(
        TextReplacementPolicy.trackedTailAfterReplacement(
            capturedText: terminalToggleCapture.text,
            replacement: CaseConverter.toggleCase(terminalToggleCapture.text),
            method: terminalToggleCapture.replacementMethod
        ),
        "git HELLO",
        "capture policy updates terminal tail after toggle-case replacement"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("user@host % git commit\n", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "AX non-settable command-tail selection"),
        "capture policy extracts prompt-prefixed AX command tail"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("old scrollback", replacementSupported: false),
            activeClipboardText: "git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "clipboard command-tail selection"),
        "capture policy uses active clipboard command tail after non-settable AX mismatch"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("old scrollback", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardBackspacePaste, source: "passive clipboard tail selection"),
        "capture policy accepts passive clipboard command tail"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("old scrollback", replacementSupported: false),
            activeClipboardText: "prompt % old",
            passiveClipboardText: "prompt % old",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "", replacementMethod: .blocked, source: "unsafe non-settable selection"),
        "capture policy blocks unsafe non-settable fallback"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(
            CapturedText(text: "", replacementMethod: .blocked, source: "unsafe non-settable selection")
        ),
        true,
        "capture policy stops conversion after blocked capture"
    )
    try expect(
        TextCapturePolicy.actionAfterBlockedCapture(
            CapturedText(text: "", replacementMethod: .blocked, source: "unsafe non-settable selection")
        ),
        BlockedCaptureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "blocked unsafe text capture",
            clearConversionSessionReason: "blocked unsafe text capture"
        ),
        "capture policy clears stale state after blocked capture"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(
            CapturedText(text: "hello", replacementMethod: .accessibilitySelection, source: "AX editable selection")
        ),
        false,
        "capture policy continues after safe capture"
    )
    try expect(
        TextCapturePolicy.actionAfterBlockedCapture(
            CapturedText(text: "hello", replacementMethod: .accessibilitySelection, source: "AX editable selection")
        ),
        BlockedCaptureAction(clearTrackedText: false, clearConversionSession: false),
        "capture policy preserves state after safe capture"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(nil),
        false,
        "capture policy continues when nothing was captured"
    )
    try expect(
        TextCapturePolicy.actionAfterBlockedCapture(nil),
        BlockedCaptureAction(clearTrackedText: false, clearConversionSession: false),
        "capture policy preserves state when nothing was captured"
    )

    let webContentCapture = try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "browser selection",
            activeClipboardText: "browser selection\n",
            accessibilityRole: "AXWebArea"
        ),
        CapturedText(
            text: "browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy accepts fresh AXWebArea clipboard selection"
    )
    guard let webContentCapture else {
        throw TestFailure(description: "capture policy accepts fresh AXWebArea clipboard selection: expected non-nil capture")
    }
    try expect(
        webContentCapture.selectedTextReplacementTransport,
        .clipboard,
        "capture policy routes web content selection replacement through clipboard"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "nested browser selection",
            activeClipboardText: "nested browser selection",
            accessibilityRoles: ["AXStaticText", "AXGroup", "AXWebArea"]
        ),
        CapturedText(
            text: "nested browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy accepts selected text from descendants inside AXWebArea"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "normalized browser selection",
            activeClipboardText: "normalized browser selection",
            accessibilityRoles: ["AXStaticText", " ax web area "]
        ),
        CapturedText(
            text: "normalized browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy accepts normalized AXWebArea ancestry"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "  browser selection  ",
            activeClipboardText: "  browser selection  ",
            accessibilityRole: "AXWebArea"
        ),
        CapturedText(
            text: "  browser selection  ",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy preserves exact AXWebArea selection whitespace"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "   ",
            activeClipboardText: "   ",
            accessibilityRole: "AXWebArea"
        ),
        "capture policy rejects whitespace-only AXWebArea clipboard selection"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "browser selection",
            activeClipboardText: "browser selection\n",
            accessibilityRole: "AXWebArea"
        ),
        CapturedText(
            text: "browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy trims copied AXWebArea wrapper newline only when raw values differ"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "static selection",
            activeClipboardText: "static selection",
            accessibilityRoles: ["AXStaticText", "AXGroup", "AXWindow"]
        ),
        "capture policy rejects static text without AXWebArea ancestry"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "old scrollback",
            activeClipboardText: "old scrollback",
            accessibilityRole: "AXTextArea"
        ),
        "capture policy does not treat terminal-like text areas as web content"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "browser selection",
            activeClipboardText: "different clipboard",
            accessibilityRole: "AXWebArea"
        ),
        "capture policy rejects stale web content clipboard"
    )

    try expectNil(
        TextCapturePolicy.captureDecision(
            observation: .emptySelection,
            activeClipboardText: "ignored",
            passiveClipboardText: "ignored",
            lastTrackedWord: "ignored",
            lastTrackedTail: "ignored"
        ),
        "capture policy returns nil for empty AX selection"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "browser selection",
            passiveClipboardText: nil,
            lastTrackedWord: nil,
            lastTrackedTail: nil
        ),
        CapturedText(
            text: "browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy uses active clipboard for no-focus fallback"
    )
    try expectNil(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: " \n\t ",
            passiveClipboardText: nil,
            lastTrackedWord: nil,
            lastTrackedTail: nil
        ),
        "capture policy rejects whitespace-only no-focus active clipboard fallback"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "user@host % git commit\n",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "active clipboard command-tail selection"),
        "capture policy extracts prompt-prefixed command tail after no-focus active clipboard"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "old > scrollback git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "", replacementMethod: .blocked, source: "unsafe active clipboard terminal tail"),
        "capture policy blocks prompt-like scrollback before no-focus active clipboard fallback"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(
            TextCapturePolicy.captureDecision(
                observation: .noFocusedElement,
                activeClipboardText: "old > scrollback git commit",
                passiveClipboardText: nil,
                lastTrackedWord: "commit",
                lastTrackedTail: "git commit"
            )
        ),
        true,
        "capture policy stops after unsafe no-focus terminal clipboard"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(
            text: "git commit",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy keeps exact no-focus active clipboard as selected-text fallback"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "browser selection",
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(
            text: "browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy prefers fresh active clipboard selection over stale passive tail after AX failure"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: " \n\t ",
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardBackspacePaste, source: "passive clipboard tail selection"),
        "capture policy ignores whitespace-only active clipboard and uses valid passive tail after AX failure"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "user@host % git commit\n",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "active clipboard command-tail selection"),
        "capture policy extracts terminal command tail from active clipboard after AX failure"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(
            text: "git commit",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy keeps exact AX-failed active clipboard as selected-text fallback"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "old > scrollback git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "", replacementMethod: .blocked, source: "unsafe active clipboard terminal tail"),
        "capture policy blocks prompt-like scrollback after AX failure"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: nil,
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardBackspacePaste, source: "passive clipboard tail selection"),
        "capture policy uses passive command tail only when active clipboard is unavailable"
    )
}
