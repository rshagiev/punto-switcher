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
}
