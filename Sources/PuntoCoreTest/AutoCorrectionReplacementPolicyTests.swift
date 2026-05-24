import Foundation
import PuntoCore

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

