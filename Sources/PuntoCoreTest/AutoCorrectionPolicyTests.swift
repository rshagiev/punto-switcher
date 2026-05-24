import Foundation
import PuntoCore

func runAutoCorrectionEngineTests() throws {
    let engine = AutoCorrectionEngine(rules: [
        AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"),
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive)
    ])

    try expect(engine.correction(for: "ghbdtn")?.replacement, "привет", "auto-correction exact rule")
    try expect(engine.correction(for: "Teh")?.replacement, "The", "auto-correction preserves title case")
    try expect(engine.correction(for: "TEH")?.replacement, "THE", "auto-correction preserves uppercase")
    try expect(engine.correction(for: "tEh")?.replacement, "tHe", "auto-correction preserves mixed case by position")
    try expectNil(engine.correction(for: "unknown"), "auto-correction ignores unknown word")

    let symbolRuleEngine = AutoCorrectionEngine(rules: [
        AutoCorrectionRule(trigger: "404", replacement: "not found", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "++", replacement: "increment", matchMode: .caseInsensitive)
    ])
    try expect(
        symbolRuleEngine.correction(for: "404")?.replacement,
        "not found",
        "auto-correction does not uppercase replacement for numeric trigger"
    )
    try expect(
        symbolRuleEngine.correction(for: "++")?.replacement,
        "increment",
        "auto-correction does not uppercase replacement for symbol trigger"
    )

    let normalizedRuleEngine = AutoCorrectionEngine(rules: [
        AutoCorrectionRule(trigger: " ghbdtn ", replacement: " привет\n"),
        AutoCorrectionRule(trigger: " Teh ", replacement: " the ", matchMode: .caseInsensitive)
    ])
    try expect(
        normalizedRuleEngine.correction(for: "ghbdtn")?.replacement,
        "привет",
        "auto-correction trims exact user rule fields"
    )
    try expect(
        normalizedRuleEngine.correction(for: "TEH")?.replacement,
        "THE",
        "auto-correction trims case-insensitive user rule fields"
    )

    let tracker = WordTracker()
    type("ghbdtn ", into: tracker)
    try expect(tracker.consumeCompletedToken(), WordTracker.CompletedToken(word: "ghbdtn", separator: " "), "word tracker exposes completed space token")
    try expectNil(tracker.consumeCompletedToken(), "word tracker consumes completed token once")

    type("teh", into: tracker)
    tracker.trackKeyPress(keyCode: 36, characters: "\r")
    try expect(tracker.consumeCompletedToken(), WordTracker.CompletedToken(word: "teh", separator: "\n"), "word tracker exposes completed return token")
}

func runAutoCorrectionPreflightPolicyTests() throws {
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "auto-correction preflight allows eligible completed token"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: "\n",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction on Enter/Tab disabled"),
        "auto-correction preflight consumes Return token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: "\t",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction on Enter/Tab disabled"),
        "auto-correction preflight consumes Tab token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: " ",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "auto-correction preflight still allows Space token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: " ",
            isCompletedTokenAutoCorrectionSuppressed: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "completed token auto-correction cancelled"),
        "auto-correction preflight consumes edited-token cancellation"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "Punto disabled"),
        "auto-correction preflight consumes token when Punto is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction disabled"),
        "auto-correction preflight consumes token when auto-correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "conversion in progress"),
        "auto-correction preflight consumes token during conversion window"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: true,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "current app disabled"),
        "auto-correction preflight consumes token for disabled app"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "no completed token"),
        "auto-correction preflight skips without token"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: true,
            isPasswordField: false
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction preflight clears state for secure input"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "auto-correction preflight clears state for password field"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction preflight prioritizes secure input"
    )
    try expect(
        AutoCorrectionPreflightPolicy.logMessage(for: .blockAndClear(reason: "password field")),
        "Auto-correction blocked for secure input",
        "auto-correction preflight preserves secure block log"
    )
}

func runAutoCorrectionReplacementPolicyTests() throws {
    let rule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let replacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "ghbdtn", separator: " "),
        trackedTailBeforeCorrection: "say ghbdtn "
    )

    try expect(
        replacement,
        AutoCorrectionReplacement(
            originalText: "ghbdtn ",
            replacementText: "привет ",
            replacementLength: 7,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: "say привет "
        ),
        "auto-correction replacement preserves separator and tracked tail"
    )

    let newlineReplacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "teh", replacement: "the", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "teh", separator: "\n"),
        trackedTailBeforeCorrection: "teh\n"
    )

    try expect(
        newlineReplacement?.trackedTailAfterReplacement,
        "the\n",
        "auto-correction replacement preserves newline boundary"
    )

    let dashReplacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "ghbdtn", separator: "-"),
        trackedTailBeforeCorrection: "echo ghbdtn-"
    )

    try expect(
        dashReplacement,
        AutoCorrectionReplacement(
            originalText: "ghbdtn-",
            replacementText: "привет-",
            replacementLength: 7,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: "echo привет-"
        ),
        "auto-correction replacement preserves dash suffix boundary"
    )

    let staleTailReplacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "teh", replacement: "the", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "teh", separator: " "),
        trackedTailBeforeCorrection: "other text "
    )

    try expect(
        staleTailReplacement?.trackedTailAfterReplacement,
        "the ",
        "auto-correction replacement falls back to replacement text for stale tail"
    )

    try expectNil(
        AutoCorrectionReplacementPolicy.replacement(
            for: AutoCorrectionDecision(original: "other", replacement: "the", rule: rule),
            completedToken: WordTracker.CompletedToken(word: "teh", separator: " "),
            trackedTailBeforeCorrection: "teh "
        ),
        "auto-correction replacement rejects mismatched token and decision"
    )

    try expectNil(
        AutoCorrectionReplacementPolicy.replacement(
            for: AutoCorrectionDecision(original: "teh", replacement: "the", rule: rule),
            completedToken: WordTracker.CompletedToken(word: "teh", separator: ""),
            trackedTailBeforeCorrection: "teh"
        ),
        "auto-correction replacement rejects missing boundary separator"
    )

    try expect(
        AutoCorrectionReplacementPolicy.shouldClearConversionSessionAfterPlanFailure(),
        true,
        "auto-correction clears stale undo session after replacement plan failure"
    )
}

func runAutoCorrectionRuntimePolicyTests() throws {
    let token = WordTracker.CompletedToken(word: "ghbdtn", separator: " ")
    let suppressedToken = WordTracker.CompletedToken(
        word: "ghbdtn",
        separator: " ",
        isAutoCorrectionSuppressed: true
    )

    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: token
        ),
        .proceed,
        "auto-correction runtime route proceeds for enabled completed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: token
        ),
        .consumeTokenAndSkip(reason: "Punto disabled"),
        "auto-correction runtime route consumes token when Punto is disabled"
    )
    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: suppressedToken
        ),
        .consumeTokenAndSkip(reason: "completed token auto-correction cancelled"),
        "auto-correction runtime route consumes suppressed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.securityPreflightAction(
            token: token,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "auto-correction runtime security blocks password fields"
    )
    try expect(
        AutoCorrectionRuntimePolicy.securityPreflightAction(
            token: token,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction runtime security prioritizes secure input"
    )

    let rule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let engine = AutoCorrectionEngine(rules: [rule])
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: token,
            trackedTailBeforeCorrection: "say ghbdtn ",
            engine: engine
        ),
        .replacement(
            decision: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule),
            replacement: AutoCorrectionReplacement(
                originalText: "ghbdtn ",
                replacementText: "привет ",
                replacementLength: 7,
                undoMethod: .keyboardBackspacePaste,
                trackedTailAfterReplacement: "say привет "
            )
        ),
        "auto-correction runtime derives executable replacement plan"
    )
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: WordTracker.CompletedToken(word: "unknown", separator: " "),
            trackedTailBeforeCorrection: "unknown ",
            engine: engine
        ),
        .noCorrection,
        "auto-correction runtime reports no correction without a matching rule"
    )
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: WordTracker.CompletedToken(word: "ghbdtn", separator: ""),
            trackedTailBeforeCorrection: "ghbdtn",
            engine: engine
        ),
        .planFailure(decision: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule)),
        "auto-correction runtime reports plan failure for invalid completed token boundary"
    )

    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed(completedTokenStatisticsEvent: .completedWord, token: token),
        "auto-correction runtime gate proceeds after route and security checks"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: token,
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "say ghbdtn ",
            engine: engine
        ),
        .replacement(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correcting completed word 'ghbdtn' -> 'привет'",
            replacement: AutoCorrectionReplacement(
                originalText: "ghbdtn ",
                replacementText: "привет ",
                replacementLength: 7,
                undoMethod: .keyboardBackspacePaste,
                trackedTailAfterReplacement: "say привет "
            ),
            commitPlan: TextReplacementCommitPlan(
                trackedTailCommit: TrackedTailCommit(text: "say привет ", reason: "auto-correction completed"),
                layoutSwitchCommit: nil,
                soundFeedbackEvent: .autoCorrection,
                productStatisticsEvent: .automaticSwitch,
                conversionRecordCommit: ConversionRecordCommit(
                    originalText: "ghbdtn ",
                    convertedText: "привет ",
                    replacementMethod: .keyboardBackspacePaste,
                    origin: .autoCorrection(rule: rule)
                )
            )
        ),
        "auto-correction runtime attempt includes statistics, log, replacement, and commit plan"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: nil,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipped(completedTokenStatisticsEvent: nil, logMessage: nil),
        "auto-correction runtime gate skips cleanly without completed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipped(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correction skipped: Punto disabled"
        ),
        "auto-correction runtime gate consumes completed-token stats when route skips"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(
            completedTokenStatisticsEvent: .completedWord,
            reason: "password field",
            logMessage: "Auto-correction blocked for secure input"
        ),
        "auto-correction runtime gate blocks and clears secure/password input before tail lookup"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: WordTracker.CompletedToken(word: "unknown", separator: " "),
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "unknown ",
            engine: engine
        ),
        .noCorrection(completedTokenStatisticsEvent: .completedWord),
        "auto-correction runtime attempt preserves completed-token stats for no-op rule lookup"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: WordTracker.CompletedToken(word: "ghbdtn", separator: ""),
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "ghbdtn",
            engine: engine
        ),
        .planFailure(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correction aborted: replacement plan could not be derived",
            conversionSessionClearReason: "auto-correction plan derivation failed"
        ),
        "auto-correction runtime attempt owns plan-failure cleanup reason"
    )
}

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

func runAutoCorrectionRuleStoreTests() throws {
    let tsv = """
    # trigger replacement
    ghbdtn\tпривет
    teh\tthe\tcaseInsensitive\ttrue
    invalid-only
    ghbdtn\tздравствуйте
    typo\tfixed\tcaseinsensitive\ttrue
    maybe\tperhaps\tcaseInsensitive\tmaybe
    """

    let importResult = try AutoCorrectionRuleStore.decodeRules(from: Data(tsv.utf8))
    try expect(importResult.rules.count, 2, "rule store parses and deduplicates tsv rules")
    try expect(importResult.rules[0].replacement, "здравствуйте", "rule store last duplicate wins")
    try expect(importResult.rules[1].matchMode, .caseInsensitive, "rule store parses match mode")
    try expect(importResult.skippedLines[4], "invalid-only", "rule store reports malformed line")
    try expect(importResult.skippedLines[6], "typo\tfixed\tcaseinsensitive\ttrue", "rule store reports invalid match mode")
    try expect(importResult.skippedLines[7], "maybe\tperhaps\tcaseInsensitive\tmaybe", "rule store reports invalid preserveCase flag")

    let sparseImport = try AutoCorrectionRuleStore.decodeRules(from: Data("good\tok\n\nbroken-only\nnext\tfine\n".utf8))
    try expect(sparseImport.skippedLines[3], "broken-only", "rule store preserves physical line numbers across blank lines")

    let quotedCommaImport = try AutoCorrectionRuleStore.decodeRules(from: Data("\"cgfcb,j\",спасибо,exact,true\n".utf8))
    try expect(
        quotedCommaImport.rules.first,
        AutoCorrectionRule(trigger: "cgfcb,j", replacement: "спасибо"),
        "rule store parses quoted comma trigger"
    )

    let escapedQuoteImport = try AutoCorrectionRuleStore.decodeRules(from: Data("\"say \"\"hi\"\"\",hello\n".utf8))
    try expect(
        escapedQuoteImport.rules.first,
        AutoCorrectionRule(trigger: "say \"hi\"", replacement: "hello"),
        "rule store parses escaped quotes in quoted csv trigger"
    )

    let malformedCSVImport = try AutoCorrectionRuleStore.decodeRules(from: Data("good,ok\nbad,\"unterminated\nnext,fine\n".utf8))
    try expect(
        malformedCSVImport.skippedLines[2],
        "bad,\"unterminated",
        "rule store reports unterminated quoted csv line"
    )
    try expect(
        malformedCSVImport.rules,
        [
            AutoCorrectionRule(trigger: "good", replacement: "ok"),
            AutoCorrectionRule(trigger: "next", replacement: "fine")
        ],
        "rule store keeps valid csv lines around malformed quoted line"
    )

    let misplacedQuoteImport = try AutoCorrectionRuleStore.decodeRules(from: Data("good,ok\nbad\"quote,value\nnext,fine\n".utf8))
    try expect(
        misplacedQuoteImport.skippedLines[2],
        "bad\"quote,value",
        "rule store reports misplaced csv quote"
    )
    try expect(
        misplacedQuoteImport.rules,
        [
            AutoCorrectionRule(trigger: "good", replacement: "ok"),
            AutoCorrectionRule(trigger: "next", replacement: "fine")
        ],
        "rule store keeps valid csv lines around misplaced quote"
    )

    let jsonData = try AutoCorrectionRuleStore.encodeRules(importResult.rules)
    let jsonResult = try AutoCorrectionRuleStore.decodeRules(from: jsonData)
    try expect(jsonResult.rules, importResult.rules, "rule store json round-trip")
    try expect(
        AutoCorrectionRuleStore.normalizedRules([
            AutoCorrectionRule(trigger: " ", replacement: "ignored"),
            AutoCorrectionRule(trigger: " teh ", replacement: " the ", matchMode: .caseInsensitive),
            AutoCorrectionRule(trigger: "TEH", replacement: "THE", matchMode: .caseInsensitive),
            AutoCorrectionRule(trigger: "empty", replacement: " ")
        ]),
        [AutoCorrectionRule(trigger: "TEH", replacement: "THE", matchMode: .caseInsensitive)],
        "rule store normalizes decoded persisted rules"
    )

    let merged = AutoCorrectionRuleStore.mergedRules(
        existing: [AutoCorrectionRule(trigger: "teh", replacement: "old", matchMode: .caseInsensitive)],
        imported: [AutoCorrectionRule(trigger: "TEH", replacement: "the", matchMode: .caseInsensitive)]
    )
    try expect(merged.count, 1, "rule store merges case-insensitive duplicates")
    try expect(merged[0].replacement, "the", "rule store imported duplicate overrides")

    let legacyRules = LegacyUserRulePolicy.rules(from: [
        [
            "rule_string": " ghbdtn ",
            "rule": " привет ",
            "is_active": NSNumber(value: true),
            "is_regexp": NSNumber(value: false),
            "do_replace": NSNumber(value: true)
        ],
        [
            "string": "teh",
            "rule": "the",
            "isRuleActive": "yes",
            "isRegExp": "no",
            "shouldSwitchLayout": "true"
        ],
        [
            "rule_string": "inactive",
            "rule": "ignored",
            "is_active": NSNumber(value: false)
        ],
        [
            "rule_string": "regexp",
            "rule": "ignored",
            "is_regexp": NSNumber(value: true)
        ],
        [
            "rule_string": "switchOnly",
            "rule": "ignored",
            "do_replace": NSNumber(value: false)
        ]
    ])
    try expect(
        legacyRules,
        [
            AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"),
            AutoCorrectionRule(trigger: "teh", replacement: "the")
        ],
        "legacy user rule policy imports active non-regexp Punto Switcher replacement rules"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.createUserRuleSelector,
        "createUserRule",
        "observed surface preserves user-rule create selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.modifyUserRuleSelector,
        "modifyUserRule",
        "observed surface preserves user-rule modify selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.removeUserRuleWithIndexSelector,
        "removeUserRuleWithIndex:",
        "observed surface preserves user-rule remove selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.addUserRuleSelector,
        "addUserRuleWithString:rule:shouldSwitchLayout:isRuleActive:isRegExp:",
        "observed surface preserves user-rule add selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.modifyUserRuleWithIndexSelector,
        "modifyUserRuleWithIndex:string:rule:shouldSwitchLayout:isRuleActive:isRegExp:",
        "observed surface preserves user-rule indexed modify selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.showWordAddedTooltipSelector,
        "showWordAddedTooltip:",
        "observed surface preserves user-rule word-added tooltip selector"
    )
    try expect(
        LegacyUserRulePolicy.rules(from: []),
        [],
        "legacy user rule policy preserves observed empty userRulesDictionary as empty"
    )
    try expectNil(
        LegacyUserRulePolicy.rules(from: ["not": "array"]),
        "legacy user rule policy ignores unexpected userRulesDictionary shape"
    )

    let catalogRules = [
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "", replacement: "missing"),
        AutoCorrectionRule(trigger: "same", replacement: "same"),
        AutoCorrectionRule(trigger: "TEH", replacement: "THE", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "  ghbdtn  ", replacement: "  привет  ")
    ]
    try expect(
        AutoCorrectionRuleCatalog.filteredRuleIndexes(in: catalogRules, query: "the"),
        [0, 3],
        "rule catalog filters by replacement"
    )
    try expect(
        AutoCorrectionRuleCatalog.filteredRuleIndexes(in: catalogRules, query: "привет"),
        [4],
        "rule catalog filters by normalized replacement"
    )
    try expect(
        AutoCorrectionRuleCatalog.filteredRuleIndexes(in: catalogRules, query: "ghbdtn"),
        [4],
        "rule catalog filters by normalized trigger"
    )
    let issues = AutoCorrectionRuleCatalog.validationIssues(for: catalogRules)
    try expect(issues.contains { $0.severity == .error && $0.ruleIndex == 1 }, true, "rule catalog flags empty trigger")
    try expect(issues.contains { $0.severity == .warning && $0.ruleIndex == 2 }, true, "rule catalog warns identical replacement")
    try expect(issues.contains { $0.severity == .warning && $0.ruleIndex == 3 }, true, "rule catalog warns duplicate trigger")
    try expect(AutoCorrectionRuleCatalog.hasBlockingIssues(catalogRules), true, "rule catalog reports blocking issues")
}

func runAutoCorrectionRuleSourcePolicyTests() throws {
    let starterRules = [
        AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    ]
    let persistedRules = [
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive)
    ]

    try expect(
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesDefaultConfPath,
        "switcher.use_old_rules",
        "observed surface pins Punto Switcher default-conf old-rules path"
    )
    try expect(
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesAccessor,
        "switcherUseOldRules",
        "observed surface pins Punto Switcher old-rules accessor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.useOldRulesDefaultConfPath,
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesDefaultConfPath,
        "rule source policy keeps default-conf old-rules path aligned with reverse-audit anchor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.useOldRulesAccessor,
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesAccessor,
        "rule source policy keeps old-rules accessor aligned with reverse-audit anchor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules
        ),
        [
            AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"),
            AutoCorrectionRule(trigger: "custom", replacement: "замена")
        ],
        "rule source policy adds Punto Switcher userRulesDictionary rules to starter catalog"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [],
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy keeps starter catalog when Punto Switcher userRulesDictionary is empty"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [],
            starterRules: starterRules,
            useStarterRules: false
        ),
        [],
        "rule source policy disables starter catalog when switcher.use_old_rules is false"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules,
            useStarterRules: false
        ),
        [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
        "rule source policy keeps user rules when old starter rules are disabled"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: persistedRules,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules
        ),
        persistedRules,
        "rule source policy prefers native saved rules over Punto Switcher userRulesDictionary"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy uses starter catalog before rules are saved"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: persistedRules,
            starterRules: starterRules
        ),
        persistedRules,
        "rule source policy uses persisted user rules"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: [],
            starterRules: starterRules
        ),
        [],
        "rule source policy preserves intentionally empty persisted rules"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: nil,
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy falls back to starter catalog for unreadable persisted rules"
    )
}

func runAutoCorrectionStarterCatalogTests() throws {
    let rules = AutoCorrectionStarterCatalog.rules
    try expect(rules.isEmpty, false, "starter catalog is not empty")
    try expect(AutoCorrectionRuleCatalog.hasBlockingIssues(rules), false, "starter catalog has no blocking issues")

    let converter = LayoutConverter()
    for rule in rules.prefix(36) {
        try expect(converter.convert(rule.trigger), rule.replacement, "starter wrong-layout rule \(rule.trigger)")
    }

    let engine = AutoCorrectionEngine(rules: rules)
    try expect(engine.correction(for: "ghbdtn")?.replacement, "привет", "starter catalog fixes wrong-layout привет")
    try expect(engine.correction(for: "cgfcb,j")?.replacement, "спасибо", "starter catalog fixes wrong-layout спасибо")
    try expect(engine.correction(for: "Teh")?.replacement, "The", "starter catalog fixes english typo with title case")
    try expect(engine.correction(for: "ADN")?.replacement, "AND", "starter catalog fixes english typo with uppercase")
}
