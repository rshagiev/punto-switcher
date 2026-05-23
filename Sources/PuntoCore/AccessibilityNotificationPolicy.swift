import Foundation

public enum AccessibilityNotificationAction: Equatable {
    case clearTrackedText(reason: String)
    case ignore(reason: String)
}

public enum AccessibilityNotificationPolicy {
    public static let focusedUIElementChanged = "AXFocusedUIElementChanged"
    public static let focusedWindowChanged = "AXFocusedWindowChanged"
    public static let mainWindowChanged = "AXMainWindowChanged"
    public static let windowCreated = "AXWindowCreated"
    public static let selectedTextChanged = "AXSelectedTextChanged"
    public static let valueChanged = "AXValueChanged"

    public static let observedNotifications = [
        focusedUIElementChanged,
        focusedWindowChanged,
        mainWindowChanged,
        windowCreated,
        selectedTextChanged,
        valueChanged
    ]

    public static func action(
        notificationName: String,
        observedBundleID: String?,
        ownBundleID: String?,
        now: Date,
        ignoreUntil: Date?,
        isConversionInProgress: Bool
    ) -> AccessibilityNotificationAction {
        let normalizedNotification = notificationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard observedNotifications.contains(normalizedNotification) else {
            return .ignore(reason: "unsupported accessibility notification")
        }

        if normalizedNotification == selectedTextChanged || normalizedNotification == valueChanged {
            return .ignore(reason: "text mutation notification is diagnostic")
        }

        if isConversionInProgress {
            return .ignore(reason: "conversion in progress")
        }

        if let ignoreUntil, now < ignoreUntil {
            return .ignore(reason: "replacement grace window")
        }

        let normalizedObservedBundleID = ApplicationBundleIDPolicy.normalized(observedBundleID)
        let normalizedOwnBundleID = ApplicationBundleIDPolicy.normalized(ownBundleID)
        if let normalizedObservedBundleID,
           let normalizedOwnBundleID,
           normalizedObservedBundleID == normalizedOwnBundleID {
            return .ignore(reason: "own application")
        }

        return .clearTrackedText(reason: "accessibility \(normalizedNotification)")
    }
}
