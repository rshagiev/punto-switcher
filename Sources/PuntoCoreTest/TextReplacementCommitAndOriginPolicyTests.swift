import Foundation
import PuntoCore

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
