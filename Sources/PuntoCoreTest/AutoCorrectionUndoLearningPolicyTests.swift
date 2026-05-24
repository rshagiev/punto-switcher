import Foundation
import PuntoCore

func runAutoCorrectionUndoLearningPolicyTests() throws {
    let undoneRule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let rules = [
        undoneRule,
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "gjrf", replacement: "пока")
    ]
    let record = ConversionRecord(
        originalText: "ghbdtn ",
        convertedText: "привет ",
        timestamp: Date(timeIntervalSince1970: 100),
        replacementMethod: .keyboardBackspacePaste,
        origin: .autoCorrection(rule: undoneRule)
    )

    let learnedRules = try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: record,
            isUndoLearningEnabled: true
        ),
        [
            AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
            AutoCorrectionRule(trigger: "gjrf", replacement: "пока")
        ],
        "auto-correction undo learning removes undone rule"
    )
    guard let learnedRules else {
        throw TestFailure(description: "auto-correction undo learning removes undone rule: expected updated rules")
    }
    let engine = AutoCorrectionEngine(rules: learnedRules)
    try expectNil(engine.correction(for: "ghbdtn"), "auto-correction undo learning suppresses repeated correction")
    try expect(engine.correction(for: "Teh")?.replacement, "The", "auto-correction undo learning keeps unrelated rules")
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: record,
            isUndoLearningEnabled: false
        ),
        "auto-correction undo learning setting can disable learned rule removal"
    )

    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: ConversionRecord(
                originalText: "hello",
                convertedText: "руддщ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .layoutConversion
            )
        ),
        "auto-correction undo learning ignores manual layout conversion undo"
    )
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [AutoCorrectionRule(trigger: "other", replacement: "другое")],
            record: record
        ),
        "auto-correction undo learning ignores already removed rule"
    )

    let preserveCaseVariant = AutoCorrectionRule(
        trigger: "teh",
        replacement: "the",
        matchMode: .caseInsensitive,
        preserveCase: false
    )
    let caseSensitiveRules = [
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive, preserveCase: true),
        preserveCaseVariant
    ]
    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: caseSensitiveRules,
            record: ConversionRecord(
                originalText: "teh ",
                convertedText: "the ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(
                    trigger: "teh",
                    replacement: "the",
                    matchMode: .caseInsensitive,
                    preserveCase: true
                ))
            )
        ),
        [preserveCaseVariant],
        "auto-correction undo learning preserves same trigger rule with different case behavior"
    )
    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [
                AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
                AutoCorrectionRule(trigger: "other", replacement: "другое")
            ],
            record: ConversionRecord(
                originalText: "TEH ",
                convertedText: "THE ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(
                    trigger: "TEH",
                    replacement: "the",
                    matchMode: .caseInsensitive
                ))
            )
        ),
        [AutoCorrectionRule(trigger: "other", replacement: "другое")],
        "auto-correction undo learning matches case-insensitive trigger case-insensitively"
    )
    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [
                AutoCorrectionRule(trigger: "Teh", replacement: "The"),
                AutoCorrectionRule(trigger: "teh", replacement: "the")
            ],
            record: ConversionRecord(
                originalText: "Teh ",
                convertedText: "The ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(trigger: "Teh", replacement: "The"))
            )
        ),
        [AutoCorrectionRule(trigger: "teh", replacement: "the")],
        "auto-correction undo learning keeps exact trigger case-sensitive"
    )

    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [
                AutoCorrectionRule(trigger: " ghbdtn ", replacement: " привет\n"),
                AutoCorrectionRule(trigger: "gjrf", replacement: "пока")
            ],
            record: ConversionRecord(
                originalText: "ghbdtn ",
                convertedText: "привет ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"))
            )
        ),
        [AutoCorrectionRule(trigger: "gjrf", replacement: "пока")],
        "auto-correction undo learning matches normalized rule fields"
    )

    try expect(
        AutoCorrectionUndoLearningPolicy.originAfterUndo(record: record),
        .autoCorrectionRedo(rule: undoneRule),
        "auto-correction undo learning preserves auto-correction redo origin"
    )
    try expect(
        AutoCorrectionUndoLearningPolicy.originAfterUndo(record: ConversionRecord(
            originalText: "hello",
            convertedText: "руддщ",
            timestamp: Date(timeIntervalSince1970: 100),
            replacementMethod: .keyboardBackspacePaste,
            origin: .layoutConversion
        )),
        .manualRedo,
        "auto-correction undo learning delegates manual redo origin"
    )
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: ConversionRecord(
                originalText: "привет ",
                convertedText: "ghbdtn ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .manualRedo
            )
        ),
        "auto-correction undo learning ignores manual redo record"
    )
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: ConversionRecord(
                originalText: "привет ",
                convertedText: "ghbdtn ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrectionRedo(rule: undoneRule)
            )
        ),
        "auto-correction undo learning ignores auto-correction redo record"
    )
}

