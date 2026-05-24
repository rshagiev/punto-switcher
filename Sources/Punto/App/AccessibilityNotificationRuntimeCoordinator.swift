import Foundation
import PuntoCore

/// App-side executor for Accessibility notification state invalidation.
final class AccessibilityNotificationRuntimeCoordinator {
    private let textState: TextRuntimeStateCoordinator
    private let ownBundleID: String?

    init(
        textState: TextRuntimeStateCoordinator,
        ownBundleID: String?
    ) {
        self.textState = textState
        self.ownBundleID = ownBundleID
    }

    func handle(notificationName: String, sourceBundleID: String?, now: Date = Date()) {
        let action = AccessibilityNotificationPolicy.action(
            notificationName: notificationName,
            sourceBundleID: sourceBundleID,
            ownBundleID: ownBundleID,
            now: now,
            ignoreUntil: textState.ignoreAccessibilityNotificationsUntil,
            isConversionInProgress: textState.isConversionInProgress
        )

        switch action {
        case .clearTrackedText(let reason):
            textState.clearTextAndConversionState(
                trackedTextReason: reason,
                conversionSessionReason: reason
            )
            PuntoLog.info("Accessibility notification '\(notificationName)' cleared text state")

        case .ignore(let reason):
            PuntoLog.debug("Accessibility notification '\(notificationName)' ignored (\(reason))")
        }
    }
}
