import Foundation
import PuntoCore

func runAccessibilityNotificationPolicyTests() throws {
    let now = Date(timeIntervalSince1970: 1_000)

    try expect(
        AccessibilityNotificationPolicy.supportedNotifications,
        [
            AccessibilityNotificationPolicy.focusedUIElementChanged,
            AccessibilityNotificationPolicy.focusedWindowChanged,
            AccessibilityNotificationPolicy.mainWindowChanged,
            AccessibilityNotificationPolicy.windowCreated,
            AccessibilityNotificationPolicy.selectedTextChanged,
            AccessibilityNotificationPolicy.valueChanged
        ],
        "accessibility notification policy observes focus, main-window, window creation, selection, and value changes"
    )
    try expect(
        AccessibilityNotificationPolicy.supportedNotifications,
        [
            PuntoSwitcherObservedSurface.AccessibilityNotifications.focusedUIElementChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.focusedWindowChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.mainWindowChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.windowCreated,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.selectedTextChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.valueChanged
        ],
        "accessibility notification policy aligns native notification names to reverse-audit anchors"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedUIElementChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXFocusedUIElementChanged"),
        "accessibility notification policy clears state on focused element changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXSelectedTextChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "text mutation notification is diagnostic"),
        "accessibility notification policy keeps typed tracking on noisy selection changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXMainWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXMainWindowChanged"),
        "accessibility notification policy clears state when the main window changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXWindowCreated",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXWindowCreated"),
        "accessibility notification policy clears state when a new window is created"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXValueChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "text mutation notification is diagnostic"),
        "accessibility notification policy observes but does not clear on ordinary value changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: now.addingTimeInterval(0.1),
            isConversionInProgress: false
        ),
        .ignore(reason: "replacement grace window"),
        "accessibility notification policy suppresses replacement-window notifications"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: now,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXFocusedWindowChanged"),
        "accessibility notification policy clears after replacement grace window expires"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: true
        ),
        .ignore(reason: "conversion in progress"),
        "accessibility notification policy suppresses in-flight conversions"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: " COM.Example.Punto ",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "own application"),
        "accessibility notification policy ignores Punto's own windows"
    )
    try expect(
        ConversionProtectionPolicy.eventRecaptureIgnoreDeadline(now: now),
        now.addingTimeInterval(ConversionProtectionPolicy.eventRecaptureProtectionDelay),
        "conversion protection policy shares replacement grace interval with accessibility notifications"
    )
}
