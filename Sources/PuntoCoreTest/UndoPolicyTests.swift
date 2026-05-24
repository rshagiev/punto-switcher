import Foundation
import PuntoCore

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
