import Foundation
import PuntoCore

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
