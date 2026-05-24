import Foundation
import PuntoCore

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
