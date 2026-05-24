import Foundation

public enum AccessibilityReplacementPolicy {
    public struct SelectionRange: Equatable {
        public let location: Int
        public let length: Int

        public init(location: Int, length: Int) {
            self.location = location
            self.length = length
        }
    }

    public static let selectedTextVerificationDelay: TimeInterval = 0.05
    public static let focusedApplicationRetryAttempts = 3
    public static let focusedApplicationRetryDelay: TimeInterval = 0.05

    public static var focusedApplicationLookupAttempts: [Int] {
        Array(1...focusedApplicationRetryAttempts)
    }

    public static func shouldAcceptSelectedTextSet(
        setSucceeded: Bool,
        originalSelectedText: String?,
        observedSelectedText: String?,
        replacement: String
    ) -> Bool {
        guard setSucceeded else {
            return false
        }

        guard originalSelectedText != nil || observedSelectedText != nil else {
            return false
        }

        if observedSelectedText == originalSelectedText,
           originalSelectedText != replacement {
            return false
        }

        return true
    }

    public static func shouldRetryFocusedApplicationLookup(attempt: Int) -> Bool {
        attempt < focusedApplicationRetryAttempts
    }

    public static func shouldReadOriginalSelectionRange(keepSelection: Bool) -> Bool {
        keepSelection
    }

    public static func originalSelectionLocation(location: Int, length: Int) -> Int? {
        guard location >= 0, length >= 0 else {
            return nil
        }

        return location
    }

    public static func replacementSelectionRange(
        originalSelectionLocation: Int?,
        replacement: String,
        keepSelection: Bool
    ) -> SelectionRange? {
        guard keepSelection,
              let originalSelectionLocation,
              originalSelectionLocation >= 0 else {
            return nil
        }

        return SelectionRange(
            location: originalSelectionLocation,
            length: replacement.utf16.count
        )
    }
}
