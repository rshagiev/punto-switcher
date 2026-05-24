import Foundation
import PuntoCore

func runTextReplacementPolicyTests() throws {
    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            replacement: "привет",
            keepSelection: true
        ),
        .accessibilitySelection(text: "привет", keepSelection: true),
        "replacement policy keeps AX selection replacement as AX plan"
    )
    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "browser selection",
                replacementMethod: .accessibilitySelection,
                source: "active clipboard fallback",
                selectedTextReplacementTransport: .clipboard
            ),
            replacement: "браузер",
            keepSelection: true
        ),
        .clipboardSelection(text: "браузер", selectAfterPaste: true),
        "replacement policy routes clipboard selected-text capture directly to clipboard plan"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "hello",
                replacementMethod: .keyboardBackspacePaste,
                source: "passive clipboard tail selection"
            ),
            replacement: "привет",
            keepSelection: true
        ),
        .keyboardBackspacePaste(deleteLength: 5, text: "привет"),
        "replacement policy uses captured length for keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "",
                replacementMethod: .keyboardBackspacePaste,
                source: "empty keyboard capture"
            ),
            replacement: "привет",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks empty keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "commit",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "AX non-settable command-tail selection"
            ),
            replacement: "COMMIT",
            keepSelection: false
        ),
        .keyboardBackspacePaste(deleteLength: 10, text: "git COMMIT"),
        "replacement policy rewrites full terminal tail before keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "commit",
                replacementMethod: .keyboardRewriteTail(originalTail: "commit && git commit"),
                source: "AX non-settable command-tail selection"
            ),
            replacement: "COMMIT",
            keepSelection: false
        ),
        .keyboardBackspacePaste(deleteLength: 20, text: "commit && git COMMIT"),
        "replacement policy rewrites the terminal tail suffix, not the first matching word"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "missing",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "stale tail"
            ),
            replacement: "MISSING",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks unrewritable terminal tail"
    )
    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "mit",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "stale tail"
            ),
            replacement: "ьше",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks partial-word terminal tail replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(text: "", replacementMethod: .blocked, source: "blocked"),
            replacement: "ignored",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks unsafe capture"
    )
}
