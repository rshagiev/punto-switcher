import Foundation
import PuntoCore

func runReplacementFailurePolicyTests() throws {
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .keyboardBackspacePaste),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "failed keyboard replacement",
            clearConversionSessionReason: "failed keyboard replacement"
        ),
        "replacement failure action clears tracked text and undo after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "failed keyboard replacement",
            clearConversionSessionReason: "failed keyboard replacement"
        ),
        "replacement failure action clears tracked text and undo after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .accessibilitySelection),
        ReplacementFailureAction(clearTrackedText: false, clearConversionSession: false),
        "replacement failure action preserves state after failed AX replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .blocked),
        ReplacementFailureAction(clearTrackedText: false, clearConversionSession: false),
        "replacement failure action ignores blocked plans"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardBackspacePaste),
        true,
        "replacement failure policy clears tracked text after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        true,
        "replacement failure policy clears tracked text after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .accessibilitySelection),
        false,
        "replacement failure policy keeps tracked text after failed AX selection replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .blocked),
        false,
        "replacement failure policy ignores blocked replacement plans"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .keyboardBackspacePaste),
        true,
        "replacement failure policy clears undo session after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        true,
        "replacement failure policy clears undo session after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .accessibilitySelection),
        false,
        "replacement failure policy keeps undo session after failed AX selection replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .blocked),
        false,
        "replacement failure policy keeps undo session for blocked plans"
    )
}
