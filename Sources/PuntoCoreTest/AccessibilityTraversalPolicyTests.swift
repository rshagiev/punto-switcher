import Foundation
import PuntoCore

func runAccessibilityTraversalPolicyTests() throws {
    try expect(
        AccessibilityTraversalPolicy.maxDescendantSearchDepth,
        5,
        "accessibility traversal policy keeps recursive descendant search bounded"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 0),
        true,
        "accessibility traversal policy inspects root depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 4),
        true,
        "accessibility traversal policy inspects final descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 5),
        false,
        "accessibility traversal policy stops after max descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: -1),
        false,
        "accessibility traversal policy rejects negative descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.maxAncestorRoleDepth,
        5,
        "accessibility traversal policy keeps ancestor role collection bounded"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldCollectAncestorRole(atDepth: 5),
        true,
        "accessibility traversal policy includes final ancestor role depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldCollectAncestorRole(atDepth: 6),
        false,
        "accessibility traversal policy stops ancestor role collection after max depth"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .empty),
        true,
        "accessibility selection search continues after empty wrapper selection"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .failed),
        true,
        "accessibility selection search continues after failed wrapper selection"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .text),
        false,
        "accessibility selection search stops after text is found"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .noFocus),
        false,
        "accessibility selection search stops when no focused element exists"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(false, after: .empty),
        true,
        "accessibility selection search records empty selection probes"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(true, after: .failed),
        true,
        "accessibility selection search preserves previous empty probes through failures"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(false, after: .failed),
        false,
        "accessibility selection search does not invent empty state from unsupported AX probes"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.finalOutcomeAfterSearch(sawEmptySelection: true),
        .empty,
        "accessibility selection search preserves empty selection after alternatives are exhausted"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.finalOutcomeAfterSearch(sawEmptySelection: false),
        .failed,
        "accessibility selection search falls back to failed when no AX source answered"
    )
}
