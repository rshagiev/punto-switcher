import Foundation

public struct ReplacementWindowAction: Equatable {
    public let ignoreAccessibilityNotificationsUntil: Date
    public let releaseEventRecaptureAt: DispatchTime
    public let shouldIgnoreHotkeyEvents: Bool
    public let markConversionInProgress: Bool

    public init(
        ignoreAccessibilityNotificationsUntil: Date,
        releaseEventRecaptureAt: DispatchTime,
        shouldIgnoreHotkeyEvents: Bool,
        markConversionInProgress: Bool
    ) {
        self.ignoreAccessibilityNotificationsUntil = ignoreAccessibilityNotificationsUntil
        self.releaseEventRecaptureAt = releaseEventRecaptureAt
        self.shouldIgnoreHotkeyEvents = shouldIgnoreHotkeyEvents
        self.markConversionInProgress = markConversionInProgress
    }
}

public enum ConversionProtectionPolicy {
    public static let startupPermissionAlertDelay: TimeInterval = 0.5
    public static let inputSourceSwitchGraceInterval: TimeInterval = 0.75
    public static let eventRecaptureProtectionDelay: TimeInterval = 0.3

    public static func startupPermissionAlertDeadline(now: DispatchTime) -> DispatchTime {
        now + startupPermissionAlertDelay
    }

    public static func inputSourceIgnoreDeadline(now: Date) -> Date {
        now.addingTimeInterval(inputSourceSwitchGraceInterval)
    }

    public static func eventRecaptureReleaseDeadline(now: DispatchTime) -> DispatchTime {
        now + eventRecaptureProtectionDelay
    }

    public static func eventRecaptureIgnoreDeadline(now: Date) -> Date {
        now.addingTimeInterval(eventRecaptureProtectionDelay)
    }

    public static func replacementWindowAction(now: Date, dispatchNow: DispatchTime) -> ReplacementWindowAction {
        ReplacementWindowAction(
            ignoreAccessibilityNotificationsUntil: eventRecaptureIgnoreDeadline(now: now),
            releaseEventRecaptureAt: eventRecaptureReleaseDeadline(now: dispatchNow),
            shouldIgnoreHotkeyEvents: true,
            markConversionInProgress: true
        )
    }
}
