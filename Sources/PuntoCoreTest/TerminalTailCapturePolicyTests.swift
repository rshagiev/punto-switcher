import Foundation
import PuntoCore

func runTerminalTailCapturePolicyTests() throws {
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
}
