import Foundation
import PuntoCore

func runAccessibilityReplacementPolicyTests() throws {
    try expect(
        AccessibilityReplacementPolicy.selectedTextVerificationDelay,
        0.05,
        "AX replacement policy keeps selected text verification delay"
    )
    try expect(
        AccessibilityReplacementPolicy.focusedApplicationRetryAttempts,
        3,
        "AX replacement policy keeps focused application retry attempts"
    )
    try expect(
        AccessibilityReplacementPolicy.focusedApplicationRetryDelay,
        0.05,
        "AX replacement policy keeps focused application retry delay"
    )
    try expect(
        AccessibilityReplacementPolicy.focusedApplicationLookupAttempts,
        [1, 2, 3],
        "AX replacement policy owns focused application lookup attempt sequence"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: false,
            originalSelectedText: "hello",
            observedSelectedText: "руддщ",
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects failed set call"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "hello",
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects silent no-op"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "руддщ",
            replacement: "руддщ"
        ),
        true,
        "AX replacement policy accepts observed replacement"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: nil,
            replacement: "руддщ"
        ),
        true,
        "AX replacement policy accepts deselected changed state"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: nil,
            observedSelectedText: nil,
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects success without before or after text evidence"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "hello",
            replacement: "hello"
        ),
        true,
        "AX replacement policy accepts idempotent replacement"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 1),
        true,
        "AX replacement policy retries before final focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 2),
        true,
        "AX replacement policy retries on penultimate focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 3),
        false,
        "AX replacement policy does not sleep after final focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldReadOriginalSelectionRange(keepSelection: true),
        true,
        "AX replacement policy reads original selection range only when selection should be retained"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldReadOriginalSelectionRange(keepSelection: false),
        false,
        "AX replacement policy skips original selection range when selection retention is not needed"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: 5),
        4,
        "AX replacement policy accepts valid original selection range location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: 0),
        4,
        "AX replacement policy accepts collapsed valid selection range location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: -1, length: 5),
        nil,
        "AX replacement policy rejects negative original selection location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: -1),
        nil,
        "AX replacement policy rejects negative original selection length"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "руддщ",
            keepSelection: true
        ),
        AccessibilityReplacementPolicy.SelectionRange(location: 4, length: 5),
        "AX replacement policy reselects replacement at original selection location"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "a😀",
            keepSelection: true
        ),
        AccessibilityReplacementPolicy.SelectionRange(location: 4, length: 3),
        "AX replacement policy uses UTF-16 length for AX selection range"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: nil,
            replacement: "руддщ",
            keepSelection: true
        ),
        nil,
        "AX replacement policy does not guess a selection location when AX range is unavailable"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "руддщ",
            keepSelection: false
        ),
        nil,
        "AX replacement policy skips reselection when selection retention is disabled"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: -1,
            replacement: "руддщ",
            keepSelection: true
        ),
        nil,
        "AX replacement policy rejects invalid negative selection locations"
    )
}
