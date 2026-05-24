import Foundation
import PuntoCore

func runTextTailReplacementPolicyTests() throws {
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
}
