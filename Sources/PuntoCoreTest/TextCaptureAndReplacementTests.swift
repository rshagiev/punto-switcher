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

func runLayoutConversionReplacementPolicyTests() throws {
    let converter = LayoutConverter()

    try expect(
        LayoutConversionReplacementPolicy.replacement(
            for: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            conversionResult: converter.convertWithResult("hello")
        ),
        LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            convertedText: "руддщ",
            targetLayout: .russian,
            keepSelection: true,
            undoMethod: .accessibilitySelection,
            trackedTailAfterReplacement: nil
        ),
        "layout conversion policy plans AX selected-text replacement"
    )

    try expect(
        LayoutConversionReplacementPolicy.replacement(
            for: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                source: "AX non-settable command-tail selection"
            ),
            conversionResult: converter.convertWithResult("ghbdtn")
        ),
        LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                source: "AX non-settable command-tail selection"
            ),
            convertedText: "привет",
            targetLayout: .russian,
            keepSelection: false,
            undoMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
            trackedTailAfterReplacement: "git commit привет"
        ),
        "layout conversion policy plans terminal-tail replacement"
    )

    try expect(
        LayoutConversionReplacementPolicy.lastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "git commit ghbdtn"
        ),
        LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardBackspacePaste,
                source: "last word"
            ),
            convertedText: "привет",
            targetLayout: .russian,
            keepSelection: false,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: "git commit привет"
        ),
        "layout conversion policy plans last-word replacement and tail update"
    )

    try expect(
        LayoutConversionReplacementPolicy.lastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: nil
        ),
        LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardBackspacePaste,
                source: "last word"
            ),
            convertedText: "привет",
            targetLayout: .russian,
            keepSelection: false,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: nil
        ),
        "layout conversion policy permits last-word replacement without tracked tail"
    )

    try expectNil(
        LayoutConversionReplacementPolicy.lastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "git commit stale"
        ),
        "layout conversion policy rejects stale last-word tracked tail"
    )
    try expectNil(
        LayoutConversionReplacementPolicy.lastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "otherghbdtn"
        ),
        "layout conversion policy rejects glued last-word tracked tail"
    )
    try expect(
        LayoutConversionReplacementPolicy.shouldClearTrackedTextAfterSkippedLastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "git commit stale"
        ),
        true,
        "layout conversion policy clears tracker after stale last-word tail skip"
    )
    try expect(
        LayoutConversionReplacementPolicy.shouldClearTrackedTextAfterSkippedLastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "otherghbdtn"
        ),
        true,
        "layout conversion policy clears tracker after glued last-word tail skip"
    )
    try expect(
        LayoutConversionReplacementPolicy.shouldClearTrackedTextAfterSkippedLastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "git commit ghbdtn"
        ),
        false,
        "layout conversion policy keeps tracker when last-word tail is current"
    )
    try expect(
        LayoutConversionReplacementPolicy.shouldClearTrackedTextAfterSkippedLastWordReplacement(
            lastWord: "teстing",
            conversionResult: converter.convertWithResult("teстing"),
            lastTrackedTail: "teстing"
        ),
        false,
        "layout conversion policy keeps tracker after non-applicable mixed last word"
    )

    try expectNil(
        LayoutConversionReplacementPolicy.replacement(
            for: CapturedText(
                text: "missing",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                source: "stale terminal tail"
            ),
            conversionResult: converter.convertWithResult("missing")
        ),
        "layout conversion policy rejects unrewritable terminal-tail replacement"
    )

    try expectNil(
        LayoutConversionReplacementPolicy.lastWordReplacement(
            lastWord: "teстing",
            conversionResult: converter.convertWithResult("teстing"),
            lastTrackedTail: "teстing"
        ),
        "layout conversion policy rejects mixed last-word no-op"
    )
}

func runManualLayoutConversionPolicyTests() throws {
    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            lastWord: "ghbdtn",
            lastTrackedTail: "git commit ghbdtn"
        ),
        .selectedText(LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            convertedText: "руддщ",
            targetLayout: .russian,
            keepSelection: true,
            undoMethod: .accessibilitySelection,
            trackedTailAfterReplacement: nil
        )),
        "manual layout conversion policy gives selected text priority over last word"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: CapturedText(
                text: "user@host % git commit\n",
                replacementMethod: .blocked,
                source: "unsafe non-settable selection"
            ),
            lastWord: "ghbdtn",
            lastTrackedTail: "git commit ghbdtn"
        ),
        .blockedCapture(CapturedText(
            text: "user@host % git commit\n",
            replacementMethod: .blocked,
            source: "unsafe non-settable selection"
        )),
        "manual layout conversion policy stops on blocked capture instead of falling back to last word"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                source: "AX non-settable command-tail selection"
            ),
            lastWord: "ignored",
            lastTrackedTail: "git commit ghbdtn"
        ),
        .selectedText(LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                source: "AX non-settable command-tail selection"
            ),
            convertedText: "привет",
            targetLayout: .russian,
            keepSelection: false,
            undoMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
            trackedTailAfterReplacement: "git commit привет"
        )),
        "manual layout conversion policy plans terminal-tail selected text conversion"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: nil,
            lastWord: "ghbdtn",
            lastTrackedTail: "git commit ghbdtn"
        ),
        .lastWord(LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardBackspacePaste,
                source: "last word"
            ),
            convertedText: "привет",
            targetLayout: .russian,
            keepSelection: false,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: "git commit привет"
        )),
        "manual layout conversion policy falls back to current last word"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: nil,
            lastWord: "ghbdtn",
            lastTrackedTail: "otherghbdtn"
        ),
        .clearTrackedTextAfterSkippedLastWord,
        "manual layout conversion policy reports stale glued last-word tail cleanup"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: nil,
            lastWord: "teстing",
            lastTrackedTail: "teстing"
        ),
        .skipped(reason: "last-word replacement unavailable"),
        "manual layout conversion policy skips mixed last-word no-op without cleanup"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: nil,
            lastWord: nil,
            lastTrackedTail: nil
        ),
        .noText,
        "manual layout conversion policy reports no text"
    )
}

func runManualLayoutConversionRuntimePolicyTests() throws {
    let selectedReplacement = LayoutConversionReplacement(
        capturedText: CapturedText(
            text: "commit",
            replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
            source: "passive clipboard tail"
        ),
        convertedText: "сщььше",
        targetLayout: .russian,
        keepSelection: false,
        undoMethod: .keyboardRewriteTail(originalTail: "git сщььше"),
        trackedTailAfterReplacement: "git сщььше"
    )
    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .selectedText(selectedReplacement),
            suppressAutoCorrectionAfterManualConversion: true
        ),
        .replace(ManualLayoutReplacementRuntimePlan(
            replacement: selectedReplacement,
            captureTimingLabel: "getSelectedText",
            originalTextLogMessage: "Converting captured text (passive clipboard tail): 'commit'",
            convertedTextLogMessage: "Converted to: 'сщььше'",
            replacementTimingLabel: "setSelectedText",
            failedReplacementLogMessage: "Captured text replacement aborted",
            failedReplacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
            commitPlan: TextReplacementCommitPolicy.manualSelectedText(
                selectedReplacement,
                suppressAutoCorrectionAfterManualConversion: true
            )
        )),
        "manual conversion runtime plans selected-text replacement side effects"
    )

    let lastWordReplacement = LayoutConversionReplacement(
        capturedText: CapturedText(text: "ghbdtn", replacementMethod: .keyboardBackspacePaste, source: "last word"),
        convertedText: "привет",
        targetLayout: .russian,
        keepSelection: false,
        undoMethod: .keyboardBackspacePaste,
        trackedTailAfterReplacement: "git commit привет"
    )
    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .lastWord(lastWordReplacement),
            suppressAutoCorrectionAfterManualConversion: false
        ),
        .replace(ManualLayoutReplacementRuntimePlan(
            replacement: lastWordReplacement,
            captureTimingLabel: "getSelectedText (empty)",
            originalTextLogMessage: "Converting last word: 'ghbdtn'",
            convertedTextLogMessage: "Converted to: 'привет'",
            replacementTimingLabel: "replaceLastWord",
            failedReplacementLogMessage: "Last-word replacement aborted",
            failedReplacementMethod: .keyboardBackspacePaste,
            commitPlan: TextReplacementCommitPolicy.manualLastWord(
                lastWordReplacement,
                suppressAutoCorrectionAfterManualConversion: false
            )
        )),
        "manual conversion runtime plans last-word replacement side effects"
    )

    let blockedCapture = CapturedText(
        text: "user@host % git commit\n",
        replacementMethod: .blocked,
        source: "unsafe non-settable selection"
    )
    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .blockedCapture(blockedCapture),
            suppressAutoCorrectionAfterManualConversion: true
        ),
        .blockedCapture(
            capturedText: blockedCapture,
            logMessage: "Blocked unsafe selection fallback: unsafe non-settable selection"
        ),
        "manual conversion runtime preserves blocked capture for stale-state cleanup"
    )

    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .clearTrackedTextAfterSkippedLastWord,
            suppressAutoCorrectionAfterManualConversion: true
        ),
        .clearTrackedText(
            reason: "stale last-word tracked tail",
            logMessage: "Last-word conversion skipped: replacement plan could not be derived"
        ),
        "manual conversion runtime clears stale tracked tail after unsafe last-word plan"
    )

    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .skipped(reason: "captured text replacement unavailable"),
            suppressAutoCorrectionAfterManualConversion: true
        ),
        .skip(logMessage: "Layout conversion skipped: captured text replacement unavailable"),
        "manual conversion runtime reports skipped conversion reason"
    )

    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .noText,
            suppressAutoCorrectionAfterManualConversion: true
        ),
        .noText(logMessage: "No text to convert"),
        "manual conversion runtime reports no-text branch"
    )
}

func runConversionSessionTests() throws {
    let session = ConversionSession(undoTimeout: 3)
    let now = Date(timeIntervalSince1970: 100)

    try expectNil(session.undoCandidate(now: now), "empty session has no undo")

    session.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor",
        origin: .autoCorrection(rule: AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"))
    )

    try expect(session.undoCandidate(now: now.addingTimeInterval(2), contextID: "com.example.editor")?.originalText, "ghbdtn", "undo available inside timeout")
    try expect(
        session.undoCandidate(now: now.addingTimeInterval(2), contextID: " COM.EXAMPLE.Editor ")?.originalText,
        "ghbdtn",
        "undo matches normalized app context id"
    )
    try expect(
        session.lastConversion?.contextID,
        "com.example.editor",
        "undo session stores normalized context id"
    )
    try expect(
        session.undoCandidate(now: now.addingTimeInterval(2), contextID: "com.example.editor")?.origin,
        .autoCorrection(rule: AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")),
        "undo preserves conversion origin"
    )
    try expectNil(session.undoCandidate(now: now.addingTimeInterval(2), contextID: "com.example.chat"), "undo rejected in different app context")
    try expect(session.lastConversion?.originalText, "ghbdtn", "context mismatch keeps undo session for original app")

    let futureSession = ConversionSession(undoTimeout: 3)
    futureSession.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(futureSession.undoCandidate(now: now.addingTimeInterval(-0.1), contextID: "com.example.editor"), "undo rejects future-dated conversion record")
    try expectNil(futureSession.lastConversion, "undo clears future-dated conversion record")

    let timeoutBoundarySession = ConversionSession(undoTimeout: 3)
    timeoutBoundarySession.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(timeoutBoundarySession.undoCandidate(now: now.addingTimeInterval(3), contextID: "com.example.editor"), "undo expires at exact timeout boundary")
    try expectNil(timeoutBoundarySession.lastConversion, "undo clears record at exact timeout boundary")

    let expiredSession = ConversionSession(undoTimeout: 3)
    expiredSession.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(expiredSession.undoCandidate(now: now.addingTimeInterval(3.1), contextID: "com.example.editor"), "undo expires after timeout")
    try expectNil(expiredSession.lastConversion, "undo clears expired conversion record")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: " "
    )
    try expectNil(session.lastConversion?.contextID, "undo session normalizes blank context id to nil")
    try expect(
        session.undoCandidate(now: now.addingTimeInterval(1), contextID: nil)?.originalText,
        "hello",
        "undo matches nil context after blank normalization"
    )

    session.clear(reason: "test")
    try expectNil(session.undoCandidate(now: now), "clear removes undo")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "same",
        convertedText: "same",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects no-op conversion records")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects empty original records")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "hello",
        convertedText: "",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects empty converted records")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "unsafe",
        convertedText: "blocked",
        replacementMethod: .blocked,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects blocked replacement records")

    let commitSession = ConversionSession(undoTimeout: 3)
    commitSession.record(
        ConversionRecordCommit(
            originalText: "hello",
            convertedText: "руддщ",
            replacementMethod: .keyboardBackspacePaste,
            origin: .layoutConversion
        ),
        now: now,
        contextID: "com.example.editor"
    )
    try expect(
        commitSession.undoCandidate(now: now.addingTimeInterval(1), contextID: "com.example.editor")?.convertedText,
        "руддщ",
        "undo session records conversion commit payloads"
    )
    try expect(
        commitSession.undoCandidate(now: now.addingTimeInterval(1), contextID: "com.example.editor")?.origin,
        .layoutConversion,
        "undo session preserves commit payload origin"
    )
}

func runUndoReplacementPolicyTests() throws {
    let now = Date(timeIntervalSince1970: 100)

    try expect(
        UndoReplacementPolicy.replacement(
            for: ConversionRecord(
                originalText: "hello",
                convertedText: "руддщ",
                timestamp: now,
                replacementMethod: .accessibilitySelection,
                contextID: "com.example.editor"
            )
        ),
        UndoReplacement(
            capturedText: CapturedText(text: "руддщ", replacementMethod: .accessibilitySelection, source: "undo"),
            replacementText: "hello",
            keepSelection: true,
            nextReplacementMethod: .accessibilitySelection,
            trackedTailAfterUndo: nil
        ),
        "undo policy plans AX selected-text undo with selection retained"
    )

    try expect(
        UndoReplacementPolicy.replacement(
            for: ConversionRecord(
                originalText: "ghbdtn",
                convertedText: "привет",
                timestamp: now,
                replacementMethod: .keyboardBackspacePaste,
                contextID: "com.example.editor"
            )
        ),
        UndoReplacement(
            capturedText: CapturedText(text: "привет", replacementMethod: .keyboardBackspacePaste, source: "undo"),
            replacementText: "ghbdtn",
            keepSelection: false,
            nextReplacementMethod: .keyboardBackspacePaste,
            trackedTailAfterUndo: nil
        ),
        "undo policy plans keyboard replacement undo"
    )

    try expect(
        UndoReplacementPolicy.replacement(
            for: ConversionRecord(
                originalText: "ghbdtn",
                convertedText: "привет",
                timestamp: now,
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
                contextID: "com.example.terminal"
            )
        ),
        UndoReplacement(
            capturedText: CapturedText(text: "привет", replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"), source: "undo"),
            replacementText: "ghbdtn",
            keepSelection: false,
            nextReplacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
            trackedTailAfterUndo: "git commit ghbdtn"
        ),
        "undo policy plans terminal-tail undo and next redo method"
    )

    try expectNil(
        UndoReplacementPolicy.replacement(
            for: ConversionRecord(
                originalText: "ghbdtn",
                convertedText: "missing",
                timestamp: now,
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
                contextID: "com.example.terminal"
            )
        ),
        "undo policy rejects unrewritable terminal-tail undo"
    )
    try expect(
        UndoReplacementPolicy.shouldClearSessionAfterFailedReplacement(),
        true,
        "undo policy clears stale undo session after failed replacement"
    )
    try expect(
        UndoReplacementPolicy.actionAfterFailedReplacement(method: .keyboardBackspacePaste),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "undo replacement failed",
            clearConversionSessionReason: "undo replacement failed"
        ),
        "undo policy clears tracked text and session after failed keyboard undo"
    )
    try expect(
        UndoReplacementPolicy.actionAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit привет")),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "undo replacement failed",
            clearConversionSessionReason: "undo replacement failed"
        ),
        "undo policy clears tracked text and session after failed terminal-tail undo"
    )
    try expect(
        UndoReplacementPolicy.actionAfterFailedReplacement(method: .accessibilitySelection),
        ReplacementFailureAction(clearTrackedText: false, clearConversionSession: false),
        "undo policy keeps tracked text and session after failed AX undo"
    )
    try expect(
        UndoReplacementPolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardBackspacePaste),
        true,
        "undo policy clears tracked text after failed keyboard undo"
    )
    try expect(
        UndoReplacementPolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit привет")),
        true,
        "undo policy clears tracked text after failed terminal-tail undo"
    )
    try expect(
        UndoReplacementPolicy.shouldClearTrackedTextAfterFailedReplacement(method: .accessibilitySelection),
        false,
        "undo policy keeps tracked text after failed AX undo"
    )

    try expect(
        UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(origin: .layoutConversion),
        true,
        "undo layout policy switches after layout conversion undo"
    )
    try expect(
        UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(origin: .manualRedo),
        true,
        "undo layout policy switches after manual redo"
    )
    try expect(
        UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(origin: .toggleCase),
        false,
        "undo layout policy skips toggle-case undo"
    )
    try expect(
        UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(
            origin: .autoCorrection(rule: AutoCorrectionRule(trigger: "teh", replacement: "the"))
        ),
        false,
        "undo layout policy skips auto-correction undo"
    )
    try expect(
        UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(
            origin: .autoCorrectionRedo(rule: AutoCorrectionRule(trigger: "teh", replacement: "the"))
        ),
        false,
        "undo layout policy skips auto-correction redo"
    )
}

func runUndoRuntimePolicyTests() throws {
    let now = Date(timeIntervalSince1970: 100)
    let layoutRecord = ConversionRecord(
        originalText: "ghbdtn",
        convertedText: "привет",
        timestamp: now,
        replacementMethod: .keyboardBackspacePaste,
        contextID: "com.example.editor",
        origin: .layoutConversion
    )

    try expect(
        UndoRuntimePolicy.plan(
            record: nil,
            autoCorrectionRules: [],
            isUndoLearningEnabled: true
        ),
        .noCandidate,
        "undo runtime reports missing candidate"
    )

    try expect(
        UndoRuntimePolicy.plan(
            record: layoutRecord,
            autoCorrectionRules: [],
            isUndoLearningEnabled: true
        ),
        .replacement(UndoRuntimeReplacement(
            record: layoutRecord,
            undoReplacement: UndoReplacement(
                capturedText: CapturedText(text: "привет", replacementMethod: .keyboardBackspacePaste, source: "undo"),
                replacementText: "ghbdtn",
                keepSelection: false,
                nextReplacementMethod: .keyboardBackspacePaste,
                trackedTailAfterUndo: nil
            ),
            shouldSwitchLayoutAfterUndo: true,
            redoOrigin: .manualRedo,
            learnedAutoCorrectionRules: nil
        )),
        "undo runtime plans layout undo with layout switch and manual redo origin"
    )
    try expect(
        UndoRuntimePolicy.planFailureAction(record: layoutRecord),
        UndoPlanFailureAction(
            clearConversionSession: true,
            clearConversionSessionReason: "undo plan derivation failed",
            logMessage: "Undo aborted: replacement plan could not be derived"
        ),
        "undo runtime owns plan-failure cleanup and log action"
    )
    if case .replacement(let layoutUndoPlan) = UndoRuntimePolicy.plan(
        record: layoutRecord,
        autoCorrectionRules: [],
        isUndoLearningEnabled: true
    ) {
        let commitPlan = UndoRuntimePolicy.appliedCommitPlan(for: layoutUndoPlan)
        try expect(commitPlan.layoutSwitchTarget, .english, "undo commit plan switches back to original text layout")
        try expectNil(commitPlan.skippedLayoutSwitchLogMessage, "undo commit plan has no skip log when layout switch is planned")
        try expect(commitPlan.soundFeedbackEvent, .undo, "undo commit plan plays undo sound")
        try expect(commitPlan.productStatisticsEvent, .revert, "undo commit plan records revert statistics")
        try expectNil(commitPlan.trackedTailCommit, "undo commit plan has no tail replay for ordinary keyboard replacement")
        try expectNil(commitPlan.learnedAutoCorrectionRules, "undo commit plan has no learned rules for manual layout undo")
        try expect(
            commitPlan.conversionRecordCommit,
            ConversionRecordCommit(
                originalText: "привет",
                convertedText: "ghbdtn",
                replacementMethod: .keyboardBackspacePaste,
                origin: .manualRedo
            ),
            "undo commit plan records manual redo candidate after layout undo"
        )
    } else {
        throw TestFailure(description: "undo runtime commit plan for layout undo: expected replacement plan")
    }

    let terminalRecord = ConversionRecord(
        originalText: "ghbdtn",
        convertedText: "привет",
        timestamp: now,
        replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
        contextID: "com.example.terminal",
        origin: .manualRedo
    )
    try expect(
        UndoRuntimePolicy.plan(
            record: terminalRecord,
            autoCorrectionRules: [],
            isUndoLearningEnabled: true
        ),
        .replacement(UndoRuntimeReplacement(
            record: terminalRecord,
            undoReplacement: UndoReplacement(
                capturedText: CapturedText(
                    text: "привет",
                    replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
                    source: "undo"
                ),
                replacementText: "ghbdtn",
                keepSelection: false,
                nextReplacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                trackedTailAfterUndo: "git commit ghbdtn"
            ),
            shouldSwitchLayoutAfterUndo: true,
            redoOrigin: .layoutConversion,
            learnedAutoCorrectionRules: nil
        )),
        "undo runtime plans terminal-tail undo with rewritten redo tail"
    )
    if case .replacement(let terminalUndoPlan) = UndoRuntimePolicy.plan(
        record: terminalRecord,
        autoCorrectionRules: [],
        isUndoLearningEnabled: true
    ) {
        let commitPlan = UndoRuntimePolicy.appliedCommitPlan(for: terminalUndoPlan)
        try expect(commitPlan.layoutSwitchTarget, .english, "terminal undo commit plan switches back to original text layout")
        try expect(
            commitPlan.trackedTailCommit,
            TrackedTailCommit(text: "git commit ghbdtn", reason: "undo completed"),
            "terminal undo commit plan replays rewritten command tail"
        )
        try expect(
            commitPlan.conversionRecordCommit,
            ConversionRecordCommit(
                originalText: "привет",
                convertedText: "ghbdtn",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                origin: .layoutConversion
            ),
            "terminal undo commit plan records tail-aware redo candidate"
        )
    } else {
        throw TestFailure(description: "undo runtime commit plan for terminal undo: expected replacement plan")
    }

    let badTailRecord = ConversionRecord(
        originalText: "ghbdtn",
        convertedText: "missing",
        timestamp: now,
        replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
        contextID: "com.example.terminal",
        origin: .layoutConversion
    )
    try expect(
        UndoRuntimePolicy.plan(
            record: badTailRecord,
            autoCorrectionRules: [],
            isUndoLearningEnabled: true
        ),
        .planFailure(record: badTailRecord),
        "undo runtime reports replacement plan failure"
    )

    let undoneRule = AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive)
    let otherRule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let autoCorrectionRecord = ConversionRecord(
        originalText: "teh ",
        convertedText: "the ",
        timestamp: now,
        replacementMethod: .keyboardBackspacePaste,
        contextID: "com.example.editor",
        origin: .autoCorrection(rule: undoneRule)
    )
    try expect(
        UndoRuntimePolicy.plan(
            record: autoCorrectionRecord,
            autoCorrectionRules: [undoneRule, otherRule],
            isUndoLearningEnabled: true
        ),
        .replacement(UndoRuntimeReplacement(
            record: autoCorrectionRecord,
            undoReplacement: UndoReplacement(
                capturedText: CapturedText(text: "the ", replacementMethod: .keyboardBackspacePaste, source: "undo"),
                replacementText: "teh ",
                keepSelection: false,
                nextReplacementMethod: .keyboardBackspacePaste,
                trackedTailAfterUndo: nil
            ),
            shouldSwitchLayoutAfterUndo: false,
            redoOrigin: .autoCorrectionRedo(rule: undoneRule),
            learnedAutoCorrectionRules: [otherRule]
        )),
        "undo runtime plans auto-correction undo learning and redo origin"
    )
    if case .replacement(let autoCorrectionUndoPlan) = UndoRuntimePolicy.plan(
        record: autoCorrectionRecord,
        autoCorrectionRules: [undoneRule, otherRule],
        isUndoLearningEnabled: true
    ) {
        let commitPlan = UndoRuntimePolicy.appliedCommitPlan(for: autoCorrectionUndoPlan)
        try expectNil(commitPlan.layoutSwitchTarget, "auto-correction undo commit plan skips layout switching")
        try expect(
            commitPlan.skippedLayoutSwitchLogMessage?.hasPrefix("Undo: skipped layout switch for origin autoCorrection"),
            true,
            "auto-correction undo commit plan preserves skipped layout-switch log"
        )
        try expect(commitPlan.learnedAutoCorrectionRules, [otherRule], "auto-correction undo commit plan learns by removing undone rule")
        try expect(
            commitPlan.learnedRuleLogMessage,
            "Auto-correction undo learned exception for 'teh'",
            "auto-correction undo commit plan trims learned-rule log text"
        )
        try expect(
            commitPlan.conversionRecordCommit,
            ConversionRecordCommit(
                originalText: "the ",
                convertedText: "teh ",
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrectionRedo(rule: undoneRule)
            ),
            "auto-correction undo commit plan records auto-correction redo origin"
        )
    } else {
        throw TestFailure(description: "undo runtime commit plan for auto-correction undo: expected replacement plan")
    }

    if case .replacement(let disabledLearningPlan) = UndoRuntimePolicy.plan(
        record: autoCorrectionRecord,
        autoCorrectionRules: [undoneRule, otherRule],
        isUndoLearningEnabled: false
    ) {
        try expectNil(
            disabledLearningPlan.learnedAutoCorrectionRules,
            "undo runtime keeps rules when undo learning is disabled"
        )
    } else {
        throw TestFailure(description: "undo runtime keeps rules when undo learning is disabled: expected replacement plan")
    }

    let repeatSession = ConversionSession(undoTimeout: 3)
    let repeatContextID = "com.example.editor"
    var currentText = "руддщ"
    var currentTime = now
    repeatSession.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: currentTime,
        contextID: repeatContextID,
        origin: .layoutConversion
    )

    for index in 0..<10 {
        currentTime = currentTime.addingTimeInterval(0.2)
        guard let record = repeatSession.undoCandidate(now: currentTime, contextID: repeatContextID) else {
            throw TestFailure(description: "repeat undo/redo scenario step \(index): expected undo candidate")
        }
        try expect(
            record.convertedText,
            currentText,
            "repeat undo/redo scenario step \(index) targets current text"
        )

        guard case .replacement(let repeatPlan) = UndoRuntimePolicy.plan(
            record: record,
            autoCorrectionRules: [],
            isUndoLearningEnabled: false
        ) else {
            throw TestFailure(description: "repeat undo/redo scenario step \(index): expected replacement plan")
        }

        let commitPlan = UndoRuntimePolicy.appliedCommitPlan(for: repeatPlan)
        currentText = commitPlan.conversionRecordCommit.convertedText
        repeatSession.record(commitPlan.conversionRecordCommit, now: currentTime, contextID: repeatContextID)
    }

    try expect(currentText, "руддщ", "repeat undo/redo scenario returns to original visible text after even presses")
    try expect(
        repeatSession.undoCandidate(now: currentTime.addingTimeInterval(0.1), contextID: repeatContextID)?.originalText,
        "hello",
        "repeat undo/redo scenario leaves next undo original ready"
    )
    try expect(
        repeatSession.undoCandidate(now: currentTime.addingTimeInterval(0.1), contextID: repeatContextID)?.convertedText,
        "руддщ",
        "repeat undo/redo scenario leaves next undo converted ready"
    )
    try expect(
        repeatSession.undoCandidate(now: currentTime.addingTimeInterval(0.1), contextID: repeatContextID)?.origin,
        .layoutConversion,
        "repeat undo/redo scenario restores layout-conversion origin after even presses"
    )
}

func runTextReplacementCommitPolicyTests() throws {
    let selectedReplacement = LayoutConversionReplacement(
        capturedText: CapturedText(
            text: "commit",
            replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
            source: "passive clipboard tail"
        ),
        convertedText: "сщььше",
        targetLayout: .russian,
        keepSelection: false,
        undoMethod: .keyboardRewriteTail(originalTail: "git сщььше"),
        trackedTailAfterReplacement: "git сщььше"
    )
    try expect(
        TextReplacementCommitPolicy.manualSelectedText(
            selectedReplacement,
            suppressAutoCorrectionAfterManualConversion: true
        ),
        TextReplacementCommitPlan(
            trackedTailCommit: TrackedTailCommit(
                text: "git сщььше",
                reason: "terminal selection conversion completed",
                suppressAutoCorrectionForCurrentToken: true
            ),
            layoutSwitchCommit: LayoutSwitchCommit(targetLayout: .russian, surface: .selectedText),
            soundFeedbackEvent: .layoutConversion,
            productStatisticsEvent: .manualSwitch,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: "commit",
                convertedText: "сщььше",
                replacementMethod: .keyboardRewriteTail(originalTail: "git сщььше"),
                origin: .layoutConversion
            )
        ),
        "commit policy describes manual selected terminal conversion side effects"
    )

    let lastWordReplacement = LayoutConversionReplacement(
        capturedText: CapturedText(text: "ghbdtn", replacementMethod: .keyboardBackspacePaste, source: "last word"),
        convertedText: "привет",
        targetLayout: .russian,
        keepSelection: false,
        undoMethod: .keyboardBackspacePaste,
        trackedTailAfterReplacement: "привет"
    )
    try expect(
        TextReplacementCommitPolicy.manualLastWord(
            lastWordReplacement,
            suppressAutoCorrectionAfterManualConversion: false
        ),
        TextReplacementCommitPlan(
            clearTrackedTextBeforeTailCommit: true,
            trackedTailCommit: TrackedTailCommit(text: "привет", reason: "last-word conversion completed"),
            layoutSwitchCommit: LayoutSwitchCommit(targetLayout: .russian, surface: .lastWord),
            soundFeedbackEvent: .layoutConversion,
            productStatisticsEvent: .manualSwitch,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: "ghbdtn",
                convertedText: "привет",
                replacementMethod: .keyboardBackspacePaste,
                origin: .layoutConversion
            )
        ),
        "commit policy describes manual last-word conversion side effects"
    )

    let toggleReplacement = ToggleCaseReplacement(
        originalText: "Hello",
        toggledText: "hELLO",
        undoMethod: .accessibilitySelection,
        trackedTailAfterReplacement: nil
    )
    try expect(
        TextReplacementCommitPolicy.toggleCase(toggleReplacement),
        TextReplacementCommitPlan(
            trackedTailCommit: nil,
            layoutSwitchCommit: nil,
            soundFeedbackEvent: .toggleCase,
            productStatisticsEvent: nil,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: "Hello",
                convertedText: "hELLO",
                replacementMethod: .accessibilitySelection,
                origin: .toggleCase
            )
        ),
        "commit policy describes toggle-case side effects without layout/stat switch"
    )

    let rule = AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive)
    let decision = AutoCorrectionDecision(original: "Teh", replacement: "The", rule: rule)
    let autoReplacement = AutoCorrectionReplacement(
        originalText: "Teh ",
        replacementText: "The ",
        replacementLength: 4,
        undoMethod: .keyboardBackspacePaste,
        trackedTailAfterReplacement: "The "
    )
    try expect(
        TextReplacementCommitPolicy.autoCorrection(decision: decision, replacement: autoReplacement),
        TextReplacementCommitPlan(
            trackedTailCommit: TrackedTailCommit(text: "The ", reason: "auto-correction completed"),
            layoutSwitchCommit: nil,
            soundFeedbackEvent: .autoCorrection,
            productStatisticsEvent: .automaticSwitch,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: "Teh ",
                convertedText: "The ",
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: rule)
            )
        ),
        "commit policy describes auto-correction side effects"
    )
}

func runConversionOriginPolicyTests() throws {
    let rule = AutoCorrectionRule(trigger: "teh", replacement: "the")

    try expect(
        ConversionOriginPolicy.originAfterUndo(.layoutConversion),
        .manualRedo,
        "conversion origin policy records manual redo after layout conversion undo"
    )
    try expect(
        ConversionOriginPolicy.originAfterUndo(.manualRedo),
        .layoutConversion,
        "conversion origin policy alternates manual redo back to layout conversion"
    )
    try expect(
        ConversionOriginPolicy.originAfterUndo(.toggleCase),
        .toggleCase,
        "conversion origin policy preserves toggle-case undo chain"
    )
    try expect(
        ConversionOriginPolicy.originAfterUndo(.autoCorrection(rule: rule)),
        .autoCorrectionRedo(rule: rule),
        "conversion origin policy records auto-correction redo after undo"
    )
    try expect(
        ConversionOriginPolicy.originAfterUndo(.autoCorrectionRedo(rule: rule)),
        .autoCorrectionRedo(rule: rule),
        "conversion origin policy keeps auto-correction redo non-learning"
    )
    try expect(
        ConversionOriginPolicy.originAfterUndo(record: ConversionRecord(
            originalText: "hello",
            convertedText: "руддщ",
            timestamp: Date(timeIntervalSince1970: 100),
            replacementMethod: .keyboardBackspacePaste,
            origin: .layoutConversion
        )),
        .manualRedo,
        "conversion origin policy reads origin from conversion record"
    )
}

