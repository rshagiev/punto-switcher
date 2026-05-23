import Foundation

public enum AccessibilitySelectionProbeOutcome: Equatable {
    case text
    case empty
    case noFocus
    case failed
}

public enum AccessibilitySelectionSearchFinalOutcome: Equatable {
    case empty
    case failed
}

public enum AccessibilitySelectionSearchPolicy {
    public static func shouldTryAlternativeSelectionSource(after outcome: AccessibilitySelectionProbeOutcome) -> Bool {
        switch outcome {
        case .empty, .failed:
            return true
        case .text, .noFocus:
            return false
        }
    }

    public static func sawEmptySelection(_ current: Bool, after outcome: AccessibilitySelectionProbeOutcome) -> Bool {
        current || outcome == .empty
    }

    public static func finalOutcomeAfterSearch(sawEmptySelection: Bool) -> AccessibilitySelectionSearchFinalOutcome {
        sawEmptySelection ? .empty : .failed
    }
}
