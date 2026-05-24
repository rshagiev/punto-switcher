import Foundation
import PuntoCore

func runConversionProtectionPolicyTests() throws {
    let now = Date(timeIntervalSince1970: 100)
    let dispatchNow = DispatchTime.now()

    try expect(
        ConversionProtectionPolicy.startupPermissionAlertDelay,
        0.5,
        "conversion protection policy keeps startup permission alert delay"
    )
    try expect(
        ConversionProtectionPolicy.inputSourceSwitchGraceInterval,
        0.75,
        "conversion protection policy keeps input source switch grace interval"
    )
    try expect(
        ConversionProtectionPolicy.eventRecaptureProtectionDelay,
        0.3,
        "conversion protection policy keeps event recapture protection delay"
    )
    try expect(
        ConversionProtectionPolicy.inputSourceIgnoreDeadline(now: now),
        now.addingTimeInterval(0.75),
        "conversion protection policy computes input source ignore deadline"
    )
    let replacementWindow = ConversionProtectionPolicy.replacementWindowAction(
        now: now,
        dispatchNow: dispatchNow
    )
    try expect(
        replacementWindow.ignoreAccessibilityNotificationsUntil,
        now.addingTimeInterval(ConversionProtectionPolicy.eventRecaptureProtectionDelay),
        "replacement window action uses recapture interval for accessibility notifications"
    )
    try expect(
        replacementWindow.releaseEventRecaptureAt,
        dispatchNow + ConversionProtectionPolicy.eventRecaptureProtectionDelay,
        "replacement window action uses recapture interval for hotkey release"
    )
    try expect(
        replacementWindow.shouldIgnoreHotkeyEvents,
        true,
        "replacement window action suppresses hotkey recapture while replacing text"
    )
    try expect(
        replacementWindow.markConversionInProgress,
        true,
        "replacement window action marks conversion in progress while replacing text"
    )
}
