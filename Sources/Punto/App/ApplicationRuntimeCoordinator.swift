import AppKit
import Foundation
import PuntoCore

/// App-side owner for active-application context and per-application layout memory.
///
/// Pure policy modules still decide when context changes clear text state and
/// when layouts may be remembered/restored. This coordinator applies those
/// decisions to the live settings/input-source adapters.
final class ApplicationRuntimeCoordinator {
    private let settingsManager: SettingsManager
    private let inputSourceManager: InputSourceManager
    private let textState: TextRuntimeStateCoordinator
    private let ownBundleID: String?

    private let applicationLayoutMemory = ApplicationLayoutMemory()

    private(set) var activeApplicationBundleID: String?
    private(set) var activeApplicationName: String?

    init(
        settingsManager: SettingsManager,
        inputSourceManager: InputSourceManager,
        textState: TextRuntimeStateCoordinator,
        ownBundleID: String? = Bundle.main.bundleIdentifier
    ) {
        self.settingsManager = settingsManager
        self.inputSourceManager = inputSourceManager
        self.textState = textState
        self.ownBundleID = ownBundleID
    }

    func loadRememberedLayouts() {
        applicationLayoutMemory.replaceAll(with: settingsManager.rememberedApplicationLayouts)
    }

    func setInitialActiveApplication(_ runningApplication: NSRunningApplication?) {
        activeApplicationBundleID = runningApplication?.bundleIdentifier
        activeApplicationName = runningApplication?.localizedName
    }

    func effectiveCurrentApplicationBundleID(frontmostApplication: NSRunningApplication?) -> String? {
        activeApplicationBundleID ?? frontmostApplication?.bundleIdentifier
    }

    func effectiveCurrentApplicationName(frontmostApplication: NSRunningApplication?) -> String? {
        activeApplicationName ?? frontmostApplication?.localizedName
    }

    func handleInputSourceChanged(now: Date = Date(), frontmostApplication: NSRunningApplication?) {
        let action = InputSourceChangePolicy.action(
            now: now,
            ignoreChangesUntil: textState.ignoreInputSourceChangesUntil,
            isConversionInProgress: textState.isConversionInProgress
        )
        textState.ignoreInputSourceChangesUntil = InputSourceChangePolicy.nextIgnoreChangesUntil(
            now: now,
            currentIgnoreChangesUntil: textState.ignoreInputSourceChangesUntil
        )

        switch action {
        case .ignoreProgrammaticSwitch(let logMessage):
            PuntoLog.info(logMessage)

        case .ignoreConversionInProgress(let logMessage):
            PuntoLog.info(logMessage)

        case .rememberLayoutAndClearTextState(let plan):
            rememberCurrentLayout(
                reason: plan.layoutMemoryReason,
                frontmostApplication: frontmostApplication
            )
            textState.clearTextAndConversionState(
                trackedTextReason: plan.clearTrackedTextReason,
                conversionSessionReason: plan.clearConversionSessionReason
            )
            PuntoLog.info(plan.logMessage)
        }
    }

    @discardableResult
    func handleActiveApplicationChanged(runningApplication: NSRunningApplication?) -> Bool {
        let newBundleID = runningApplication?.bundleIdentifier
        let newName = runningApplication?.localizedName

        if ApplicationLayoutPolicy.shouldRecordCurrentLayoutOnApplicationActivation(
            rememberInputSourceForEachApp: settingsManager.rememberInputSourceForEachApp
        ) {
            rememberCurrentLayout(reason: "active application changed", frontmostApplication: runningApplication)
        }

        let action = ApplicationContextPolicy.activationAction(
            previousBundleID: activeApplicationBundleID,
            newBundleID: newBundleID,
            ownBundleID: ownBundleID
        )

        switch action {
        case .preserveCurrentExternalContext(let logMessage):
            PuntoLog.info(logMessage)
            return false

        case .activateExternal(let plan):
            if plan.shouldResetTextState {
                textState.clearTextAndConversionState(
                    trackedTextReason: plan.clearTrackedTextReason,
                    conversionSessionReason: plan.clearConversionSessionReason
                )
            }
        }

        activeApplicationBundleID = newBundleID
        activeApplicationName = newName
        return true
    }

    func rememberCurrentLayout(reason: String, frontmostApplication: NSRunningApplication?) {
        guard settingsManager.rememberInputSourceForEachApp else { return }
        guard let layoutID = inputSourceManager.currentLayoutID() else { return }

        guard let update = ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: settingsManager.rememberInputSourceForEachApp,
            activeBundleID: activeApplicationBundleID ?? frontmostApplication?.bundleIdentifier,
            frontmostBundleID: frontmostApplication?.bundleIdentifier,
            ownBundleID: ownBundleID,
            currentLayoutID: layoutID
        ) else {
            PuntoLog.info("Skipped layout memory update (reason: \(reason))")
            return
        }

        applicationLayoutMemory.remember(bundleID: update.bundleID, layoutID: update.layoutID)
        settingsManager.rememberedApplicationLayouts = applicationLayoutMemory.snapshot()
        PuntoLog.info("Remembered layout '\(update.layoutID)' for app '\(update.bundleID)' (reason: \(reason))")
    }

    func rememberProgrammaticLayoutSwitch(targetLayoutID: String?, didSwitch: Bool) {
        guard let update = ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: settingsManager.rememberInputSourceForEachApp,
            activeBundleID: activeApplicationBundleID,
            ownBundleID: ownBundleID,
            targetLayoutID: targetLayoutID,
            didSwitch: didSwitch
        ) else {
            if !didSwitch {
                textState.ignoreInputSourceChangesUntil = nil
            }
            return
        }

        applicationLayoutMemory.remember(bundleID: update.bundleID, layoutID: update.layoutID)
        settingsManager.rememberedApplicationLayouts = applicationLayoutMemory.snapshot()
        PuntoLog.info("Remembered programmatic layout '\(update.layoutID)' for app '\(update.bundleID)'")
    }

    func restoreRememberedLayoutForActiveApplication(isApplicationDisabled: Bool) {
        let newBundleID = activeApplicationBundleID
        guard settingsManager.rememberInputSourceForEachApp else {
            return
        }

        let restoreBundleID = ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: newBundleID,
            ownBundleID: ownBundleID,
            isApplicationDisabled: isApplicationDisabled
        )

        guard let rememberedLayoutID = applicationLayoutMemory.layoutID(for: restoreBundleID) else {
            PuntoLog.info("No remembered layout for app '\(newBundleID ?? "?")'")
            return
        }

        switch ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: newBundleID,
            ownBundleID: ownBundleID,
            isApplicationDisabled: isApplicationDisabled,
            rememberedLayoutID: rememberedLayoutID,
            currentLayoutID: inputSourceManager.currentLayoutID()
        ) {
        case .skip:
            PuntoLog.info("Skipped remembered layout restore for app '\(newBundleID ?? "?")'")

        case .alreadyActive(let layoutID):
            PuntoLog.info("Remembered layout '\(layoutID)' already active for app '\(newBundleID ?? "?")'")

        case .switchTo(let layoutID):
            textState.ignoreInputSourceChangesUntil = ConversionProtectionPolicy.inputSourceIgnoreDeadline(now: Date())
            let switched = inputSourceManager.switchToLayoutID(layoutID)
            if switched {
                PuntoLog.info("Restored remembered layout '\(layoutID)' for app '\(newBundleID ?? "?")'")
            } else {
                textState.ignoreInputSourceChangesUntil = nil
            }
        }
    }
}
