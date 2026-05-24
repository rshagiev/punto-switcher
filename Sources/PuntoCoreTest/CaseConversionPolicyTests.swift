import Foundation
import PuntoCore

func runCaseConverterTests() throws {
    try expect(CaseConverter.toggleCase("hello"), "HELLO", "case converter lower to upper")
    try expect(CaseConverter.toggleCase("HELLO"), "hello", "case converter upper to lower")
    try expect(CaseConverter.toggleCase("Hello"), "hELLO", "case converter inverts title case")
    try expect(CaseConverter.toggleCase("hELLO"), "Hello", "case converter restores inverted title case")
    try expect(CaseConverter.toggleCase("HeLLo WoRLd"), "hEllO wOrlD", "case converter inverts mixed latin text")

    try expect(CaseConverter.toggleCase("привет"), "ПРИВЕТ", "case converter russian lower to upper")
    try expect(CaseConverter.toggleCase("ПРИВЕТ"), "привет", "case converter russian upper to lower")
    try expect(CaseConverter.toggleCase("ПрИвЕт"), "пРиВеТ", "case converter inverts mixed russian text")
    try expect(CaseConverter.toggleCase("Ё"), "ё", "case converter toggles russian yo")

    try expect(CaseConverter.toggleCase("hello123"), "HELLO123", "case converter preserves numbers")
    try expect(CaseConverter.toggleCase(";'[].,"), ";'[].,", "case converter preserves punctuation")
    try expect(CaseConverter.toggleCase(""), "", "case converter empty string")
    try expect(CaseConverter.toggleCase(" "), " ", "case converter whitespace")

    for sample in ["Hello", "WORLD", "привет", "ПРИВЕТ", "MiXeD CaSe", "ПрИвЕт МиР"] {
        try expect(CaseConverter.toggleCase(CaseConverter.toggleCase(sample)), sample, "case converter round-trip \(sample)")
    }
}

func runToggleCasePolicyTests() throws {
    try expect(
        ToggleCasePolicy.replacement(
            for: CapturedText(
                text: "Hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            )
        ),
        ToggleCaseReplacement(
            originalText: "Hello",
            toggledText: "hELLO",
            undoMethod: .accessibilitySelection,
            trackedTailAfterReplacement: nil
        ),
        "toggle-case policy records AX replacement for undo"
    )

    try expect(
        ToggleCasePolicy.replacement(
            for: CapturedText(
                text: "commit",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "AX non-settable command-tail selection"
            )
        ),
        ToggleCaseReplacement(
            originalText: "commit",
            toggledText: "COMMIT",
            undoMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
            trackedTailAfterReplacement: "git COMMIT"
        ),
        "toggle-case policy records terminal tail replacement for undo"
    )

    try expectNil(
        ToggleCasePolicy.replacement(
            for: CapturedText(text: "", replacementMethod: .accessibilitySelection, source: "empty")
        ),
        "toggle-case policy rejects empty capture"
    )

    try expectNil(
        ToggleCasePolicy.replacement(
            for: CapturedText(text: "Hello", replacementMethod: .blocked, source: "blocked")
        ),
        "toggle-case policy rejects blocked capture"
    )
}

func runToggleCaseConversionPolicyTests() throws {
    let axCapture = CapturedText(
        text: "Hello",
        replacementMethod: .accessibilitySelection,
        source: "AX editable selection"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: axCapture),
        .capturedText(
            capture: axCapture,
            replacement: ToggleCaseReplacement(
                originalText: "Hello",
                toggledText: "hELLO",
                undoMethod: .accessibilitySelection,
                trackedTailAfterReplacement: nil
            )
        ),
        "toggle-case conversion policy plans editable selected text"
    )

    let tailCapture = CapturedText(
        text: "commit",
        replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
        source: "AX non-settable command-tail selection"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: tailCapture),
        .capturedText(
            capture: tailCapture,
            replacement: ToggleCaseReplacement(
                originalText: "commit",
                toggledText: "COMMIT",
                undoMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
                trackedTailAfterReplacement: "git COMMIT"
            )
        ),
        "toggle-case conversion policy plans terminal-tail selected text"
    )

    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: CapturedText(
            text: "Hello",
            replacementMethod: .blocked,
            source: "unsafe stale clipboard fallback"
        )),
        .blockedCapture(CapturedText(
            text: "Hello",
            replacementMethod: .blocked,
            source: "unsafe stale clipboard fallback"
        )),
        "toggle-case conversion policy blocks unsafe capture"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: CapturedText(
            text: "",
            replacementMethod: .accessibilitySelection,
            source: "empty selection"
        )),
        .noText,
        "toggle-case conversion policy reports empty capture as no text"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: nil),
        .noText,
        "toggle-case conversion policy reports nil capture as no text"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(
            from: ToggleCaseConversionPolicy.plan(capturedText: axCapture)
        ),
        .replace(ToggleCaseReplacementRuntimePlan(
            capturedText: axCapture,
            replacement: ToggleCaseReplacement(
                originalText: "Hello",
                toggledText: "hELLO",
                undoMethod: .accessibilitySelection,
                trackedTailAfterReplacement: nil
            ),
            logMessage: "Toggling case for captured text: 'Hello'",
            keepSelection: true,
            failedReplacementLogMessage: "Toggle case replacement aborted",
            failedReplacementMethod: .accessibilitySelection,
            commitPlan: TextReplacementCommitPlan(
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
            )
        )),
        "toggle-case runtime policy plans editable replacement execution and commit"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(
            from: ToggleCaseConversionPolicy.plan(capturedText: tailCapture)
        ),
        .replace(ToggleCaseReplacementRuntimePlan(
            capturedText: tailCapture,
            replacement: ToggleCaseReplacement(
                originalText: "commit",
                toggledText: "COMMIT",
                undoMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
                trackedTailAfterReplacement: "git COMMIT"
            ),
            logMessage: "Toggling case for captured text: 'commit'",
            keepSelection: false,
            failedReplacementLogMessage: "Toggle case replacement aborted",
            failedReplacementMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
            commitPlan: TextReplacementCommitPlan(
                trackedTailCommit: TrackedTailCommit(text: "git COMMIT", reason: "toggle-case completed"),
                layoutSwitchCommit: nil,
                soundFeedbackEvent: .toggleCase,
                productStatisticsEvent: nil,
                conversionRecordCommit: ConversionRecordCommit(
                    originalText: "commit",
                    convertedText: "COMMIT",
                    replacementMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
                    origin: .toggleCase
                )
            )
        )),
        "toggle-case runtime policy plans terminal-tail replay and undo record"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(from: .blockedCapture(CapturedText(
            text: "Hello",
            replacementMethod: .blocked,
            source: "unsafe stale clipboard fallback"
        ))),
        .blockedCapture(
            capturedText: CapturedText(
                text: "Hello",
                replacementMethod: .blocked,
                source: "unsafe stale clipboard fallback"
            ),
            logMessage: "Toggle case blocked unsafe selection fallback: unsafe stale clipboard fallback"
        ),
        "toggle-case runtime policy preserves blocked-capture cleanup log"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(from: .skipped(reason: "replacement unavailable")),
        .skipped(logMessage: "Toggle case aborted: replacement plan could not be derived"),
        "toggle-case runtime policy owns skipped log"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(from: .noText),
        .noText(logMessage: "Toggle case: no selected text"),
        "toggle-case runtime policy owns no-text log"
    )
}
