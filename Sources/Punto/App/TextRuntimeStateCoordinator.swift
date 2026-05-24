import Dispatch
import Foundation
import PuntoCore

/// App-side owner for mutable text runtime state.
///
/// Policy modules decide when state should be cleared or protected; this
/// coordinator applies those decisions to the live `WordTracker`,
/// `ConversionSession`, and replacement-window flags.
final class TextRuntimeStateCoordinator {
    let conversionSession: ConversionSession

    private let wordTracker: WordTracker
    private let setHotkeyIgnoreEvents: (Bool) -> Void

    private(set) var isConversionInProgress = false
    var ignoreInputSourceChangesUntil: Date?
    private(set) var ignoreAccessibilityNotificationsUntil: Date?
    var lastKeyPressTime: Date?

    init(
        wordTracker: WordTracker,
        conversionSession: ConversionSession = ConversionSession(),
        setHotkeyIgnoreEvents: @escaping (Bool) -> Void
    ) {
        self.wordTracker = wordTracker
        self.conversionSession = conversionSession
        self.setHotkeyIgnoreEvents = setHotkeyIgnoreEvents
    }

    func beginReplacementWindow(now: Date = Date(), dispatchNow: DispatchTime = .now()) -> ReplacementWindowAction {
        let action = ConversionProtectionPolicy.replacementWindowAction(now: now, dispatchNow: dispatchNow)
        isConversionInProgress = action.markConversionInProgress
        ignoreAccessibilityNotificationsUntil = action.ignoreAccessibilityNotificationsUntil
        setHotkeyIgnoreEvents(action.shouldIgnoreHotkeyEvents)
        return action
    }

    func finishReplacementWindow(dispatchNow: DispatchTime = .now()) {
        let releaseAt = ConversionProtectionPolicy.eventRecaptureReleaseDeadline(now: dispatchNow)
        DispatchQueue.main.asyncAfter(deadline: releaseAt) { [weak self] in
            self?.setHotkeyIgnoreEvents(false)
            self?.isConversionInProgress = false
        }
    }

    func clearTrackedText(reason: String) {
        wordTracker.clear(reason: reason)
    }

    func clearConversionSession(reason: String) {
        conversionSession.clear(reason: reason)
    }

    func clearTextAndConversionState(
        trackedTextReason: String?,
        conversionSessionReason: String?
    ) {
        if let trackedTextReason {
            clearTrackedText(reason: trackedTextReason)
        }
        if let conversionSessionReason {
            clearConversionSession(reason: conversionSessionReason)
        }
    }

    func apply(_ action: HotkeyRoutingStateClearAction) {
        if action.clearTrackedText {
            clearTrackedText(reason: action.clearTrackedTextReason ?? "unknown")
        }
        if action.clearConversionSession {
            clearConversionSession(reason: action.clearConversionSessionReason ?? "unknown")
        }
    }

    func apply(_ action: TextTrackingSecurityClearAction) {
        if action.clearTrackedText {
            clearTrackedText(reason: action.clearTrackedTextReason ?? "secure text input")
        }
        if action.clearConversionSession {
            clearConversionSession(reason: action.clearConversionSessionReason ?? "secure text input")
        }
    }

    func apply(_ action: ReplacementFailureAction) {
        if action.clearTrackedText {
            clearTrackedText(reason: action.clearTrackedTextReason ?? "failed replacement")
        }
        if action.clearConversionSession {
            clearConversionSession(reason: action.clearConversionSessionReason ?? "failed replacement")
        }
    }

    func apply(_ action: BlockedCaptureAction) {
        if action.clearTrackedText {
            clearTrackedText(reason: action.clearTrackedTextReason ?? "blocked unsafe text capture")
        }
        if action.clearConversionSession {
            clearConversionSession(reason: action.clearConversionSessionReason ?? "blocked unsafe text capture")
        }
    }
}
