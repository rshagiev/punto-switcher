import AppKit
import Foundation
import PuntoCore

/// App-side executor for non-replacement user commands.
///
/// These commands still use PuntoCore policies for decisions, while this
/// coordinator applies selected-text search, auto-correction toggling, current
/// app exception toggling, and global-enabled cleanup to live app services.
final class ApplicationCommandRuntimeCoordinator {
    private let settingsManager: SettingsManager
    private let textState: TextRuntimeStateCoordinator
    private let textAccessor: TextAccessor
    private let textActionRuntime: TextActionRuntimeCoordinator
    private let ownBundleID: String?
    private let currentApplicationBundleID: () -> String?
    private let currentApplicationName: () -> String?
    private let flashStatusIcon: () -> Void

    init(
        settingsManager: SettingsManager,
        textState: TextRuntimeStateCoordinator,
        textAccessor: TextAccessor,
        textActionRuntime: TextActionRuntimeCoordinator,
        ownBundleID: String?,
        currentApplicationBundleID: @escaping () -> String?,
        currentApplicationName: @escaping () -> String?,
        flashStatusIcon: @escaping () -> Void
    ) {
        self.settingsManager = settingsManager
        self.textState = textState
        self.textAccessor = textAccessor
        self.textActionRuntime = textActionRuntime
        self.ownBundleID = ownBundleID
        self.currentApplicationBundleID = currentApplicationBundleID
        self.currentApplicationName = currentApplicationName
        self.flashStatusIcon = flashStatusIcon
    }

    func handleSelectedTextSearch(destination: SearchShortcutDestination) {
        PuntoLog.info(">>> Selected text search triggered <<< destination=\(destination)")

        guard textActionRuntime.preflightTextAction(.selectedTextSearch) else {
            return
        }

        let capturedText = textAccessor.captureSelectedText(lastTrackedWord: nil, lastTrackedTail: nil)
        let runtimePlan = SelectedTextSearchPolicy.runtimePlan(
            from: SelectedTextSearchPolicy.plan(capturedText: capturedText, destination: destination)
        )

        switch runtimePlan {
        case .blockedCapture(let capturedText, let logMessage):
            PuntoLog.info(logMessage)
            textActionRuntime.clearStateAfterBlockedCapture(capturedText)

        case .open(let url, let logMessage, let shouldFlashIcon):
            PuntoLog.info(logMessage)
            NSWorkspace.shared.open(url)
            if shouldFlashIcon {
                flashStatusIcon()
            }

        case .skipped(let logMessage):
            PuntoLog.info(logMessage)

        case .noText(let logMessage):
            PuntoLog.info(logMessage)
        }
    }

    func toggleAutoCorrection() {
        let action = AutoCorrectionTogglePolicy.action(wasEnabled: settingsManager.autoCorrectionEnabled)
        settingsManager.autoCorrectionEnabled = action.newEnabledValue
        textState.clearTextAndConversionState(
            trackedTextReason: action.clearTrackedTextReason,
            conversionSessionReason: action.clearConversionSessionReason
        )
        PuntoLog.info(action.logMessage)
        if action.shouldFlashIcon {
            flashStatusIcon()
        }
    }

    func toggleCurrentApplicationDisabled() {
        let rawBundleID = currentApplicationBundleID()
        guard let action = ApplicationDisablePolicy.toggleAction(
            bundleID: rawBundleID,
            ownBundleID: ownBundleID,
            isCurrentlyDisabled: settingsManager.isApplicationDisabled(bundleID: rawBundleID)
        ) else {
            return
        }

        settingsManager.setApplicationDisabled(bundleID: action.bundleID, disabled: action.disabled)
        if action.shouldClearState,
           let clearTrackedTextReason = action.clearTrackedTextReason,
           let clearConversionSessionReason = action.clearConversionSessionReason {
            textState.clearTextAndConversionState(
                trackedTextReason: clearTrackedTextReason,
                conversionSessionReason: clearConversionSessionReason
            )
        }
        PuntoLog.info(ApplicationDisablePolicy.toggleLogMessage(
            action: action,
            applicationName: currentApplicationName()
        ))
    }

    func handleGlobalEnabledChanged(wasEnabled: Bool, isEnabled: Bool) {
        let action = HotkeyRoutingPolicy.stateClearActionAfterEnabledChange(
            wasEnabled: wasEnabled,
            isEnabled: isEnabled
        )

        textState.apply(action)
        if let logMessage = action.logMessage {
            PuntoLog.info(logMessage)
        }
    }

    func isCurrentApplicationDisabled() -> Bool {
        settingsManager.isApplicationDisabled(bundleID: currentApplicationBundleID())
    }

    func isCurrentApplicationCompletelyDisabled() -> Bool {
        settingsManager.isApplicationCompletelyDisabled(bundleID: currentApplicationBundleID())
    }

    func canDoSearchClick() -> Bool {
        textAccessor.canDoSearchClick(bundleID: currentApplicationBundleID())
    }
}
