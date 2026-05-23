import Foundation

public struct UndoRuntimeReplacement: Equatable {
    public let record: ConversionRecord
    public let undoReplacement: UndoReplacement
    public let shouldSwitchLayoutAfterUndo: Bool
    public let redoOrigin: ConversionOrigin
    public let learnedAutoCorrectionRules: [AutoCorrectionRule]?

    public init(
        record: ConversionRecord,
        undoReplacement: UndoReplacement,
        shouldSwitchLayoutAfterUndo: Bool,
        redoOrigin: ConversionOrigin,
        learnedAutoCorrectionRules: [AutoCorrectionRule]?
    ) {
        self.record = record
        self.undoReplacement = undoReplacement
        self.shouldSwitchLayoutAfterUndo = shouldSwitchLayoutAfterUndo
        self.redoOrigin = redoOrigin
        self.learnedAutoCorrectionRules = learnedAutoCorrectionRules
    }
}

public struct UndoAppliedCommitPlan: Equatable {
    public let layoutSwitchTarget: LayoutConverter.DetectedLayout?
    public let skippedLayoutSwitchLogMessage: String?
    public let soundFeedbackEvent: SoundFeedbackEvent
    public let productStatisticsEvent: ProductStatisticsEvent
    public let trackedTailCommit: TrackedTailCommit?
    public let learnedAutoCorrectionRules: [AutoCorrectionRule]?
    public let learnedRuleLogMessage: String?
    public let conversionRecordCommit: ConversionRecordCommit

    public init(
        layoutSwitchTarget: LayoutConverter.DetectedLayout?,
        skippedLayoutSwitchLogMessage: String?,
        soundFeedbackEvent: SoundFeedbackEvent,
        productStatisticsEvent: ProductStatisticsEvent,
        trackedTailCommit: TrackedTailCommit?,
        learnedAutoCorrectionRules: [AutoCorrectionRule]?,
        learnedRuleLogMessage: String?,
        conversionRecordCommit: ConversionRecordCommit
    ) {
        self.layoutSwitchTarget = layoutSwitchTarget
        self.skippedLayoutSwitchLogMessage = skippedLayoutSwitchLogMessage
        self.soundFeedbackEvent = soundFeedbackEvent
        self.productStatisticsEvent = productStatisticsEvent
        self.trackedTailCommit = trackedTailCommit
        self.learnedAutoCorrectionRules = learnedAutoCorrectionRules
        self.learnedRuleLogMessage = learnedRuleLogMessage
        self.conversionRecordCommit = conversionRecordCommit
    }
}

public enum UndoRuntimePlan: Equatable {
    case noCandidate
    case planFailure(record: ConversionRecord)
    case replacement(UndoRuntimeReplacement)
}

public enum UndoRuntimePolicy {
    public static func plan(
        record: ConversionRecord?,
        autoCorrectionRules: [AutoCorrectionRule],
        isUndoLearningEnabled: Bool
    ) -> UndoRuntimePlan {
        guard let record else {
            return .noCandidate
        }

        guard let undoReplacement = UndoReplacementPolicy.replacement(for: record) else {
            return .planFailure(record: record)
        }

        return .replacement(UndoRuntimeReplacement(
            record: record,
            undoReplacement: undoReplacement,
            shouldSwitchLayoutAfterUndo: UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(origin: record.origin),
            redoOrigin: ConversionOriginPolicy.originAfterUndo(record: record),
            learnedAutoCorrectionRules: AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
                rules: autoCorrectionRules,
                record: record,
                isUndoLearningEnabled: isUndoLearningEnabled
            )
        ))
    }

    public static func appliedCommitPlan(
        for plan: UndoRuntimeReplacement,
        converter: LayoutConverter = LayoutConverter()
    ) -> UndoAppliedCommitPlan {
        let record = plan.record
        let undoReplacement = plan.undoReplacement
        let layoutSwitchTarget = plan.shouldSwitchLayoutAfterUndo
            ? converter.detectLayout(record.originalText)
            : nil

        return UndoAppliedCommitPlan(
            layoutSwitchTarget: layoutSwitchTarget,
            skippedLayoutSwitchLogMessage: plan.shouldSwitchLayoutAfterUndo
                ? nil
                : "Undo: skipped layout switch for origin \(record.origin)",
            soundFeedbackEvent: .undo,
            productStatisticsEvent: .revert,
            trackedTailCommit: undoReplacement.trackedTailAfterUndo.map {
                TrackedTailCommit(text: $0, reason: "undo completed")
            },
            learnedAutoCorrectionRules: plan.learnedAutoCorrectionRules,
            learnedRuleLogMessage: plan.learnedAutoCorrectionRules == nil
                ? nil
                : "Auto-correction undo learned exception for '\(record.originalText.trimmingCharacters(in: .whitespacesAndNewlines))'",
            conversionRecordCommit: ConversionRecordCommit(
                originalText: record.convertedText,
                convertedText: record.originalText,
                replacementMethod: undoReplacement.nextReplacementMethod,
                origin: plan.redoOrigin
            )
        )
    }
}
