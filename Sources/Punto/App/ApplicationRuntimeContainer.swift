import AppKit
import PuntoCore
import PuntoSettings
import PuntoRuntime

/// Owns the live runtime dependency graph for the menu-bar application.
///
/// `AppDelegate` stays responsible for Cocoa lifecycle and UI wiring; this
/// container owns the native Punto services that implement text capture,
/// replacement, application context, hotkeys, undo, and auto-correction.
final class ApplicationRuntimeContainer {
    let settingsManager: SettingsManager
    let layoutConverter: LayoutConverter
    let wordTracker: WordTracker
    let textState: TextRuntimeStateCoordinator
    let textAccessor: TextAccessor
    let inputSourceManager: InputSourceManager
    let appRuntime: ApplicationRuntimeCoordinator
    let soundFeedbackController: SoundFeedbackController
    let layoutSwitchRuntime: LayoutSwitchRuntimeCoordinator
    let textReplacementCommitRuntime: TextReplacementCommitRuntimeCoordinator
    let textActionRuntime: TextActionRuntimeCoordinator
    let autoCorrectionRuntime: AutoCorrectionRuntimeCoordinator
    let undoRuntime: UndoRuntimeCoordinator
    let manualTextActionRuntime: ManualTextActionRuntimeCoordinator
    let commandRuntime: ApplicationCommandRuntimeCoordinator
    let keyPressRuntime: KeyPressRuntimeCoordinator
    let accessibilityNotificationRuntime: AccessibilityNotificationRuntimeCoordinator
    let accessibilityStateObserver: AccessibilityStateObserver

    private let hotkeyIgnoreSink = HotkeyIgnoreEventSink()
    private var hotkeyManager: HotkeyManager?
    private var startupRuntime: StartupRuntimeCoordinator?

    var activeApplicationBundleID: String? {
        appRuntime.activeApplicationBundleID
    }

    var activeApplicationName: String? {
        appRuntime.activeApplicationName
    }

    init(flashStatusIcon: @escaping () -> Void) {
        settingsManager = SettingsManager()
        layoutConverter = LayoutConverter()
        wordTracker = WordTracker(maxTailSize: 512)
        textState = TextRuntimeStateCoordinator(wordTracker: wordTracker) { [hotkeyIgnoreSink] ignoreEvents in
            hotkeyIgnoreSink.hotkeyManager?.ignoreEvents = ignoreEvents
        }
        textAccessor = TextAccessor(
            shouldRestorePasteboard: { [settingsManager] in
                settingsManager.restorePasteboardAfterConversion
            }
        )
        inputSourceManager = InputSourceManager(
            preferredRussianLayoutType: { [settingsManager] in
                settingsManager.russianKeyboardLayoutType
            },
            preferredEnglishSourceID: { [settingsManager] in
                settingsManager.preferredEnglishInputSourceID
            },
            preferredRussianSourceID: { [settingsManager] in
                settingsManager.preferredRussianInputSourceID
            }
        )
        appRuntime = ApplicationRuntimeCoordinator(
            settingsManager: settingsManager,
            inputSourceManager: inputSourceManager,
            textState: textState
        )
        soundFeedbackController = SoundFeedbackController(settingsManager: settingsManager)
        layoutSwitchRuntime = LayoutSwitchRuntimeCoordinator(
            settingsManager: settingsManager,
            textState: textState,
            inputSourceManager: inputSourceManager,
            soundFeedbackController: soundFeedbackController,
            appRuntime: appRuntime
        )
        textReplacementCommitRuntime = TextReplacementCommitRuntimeCoordinator(
            settingsManager: settingsManager,
            textState: textState,
            wordTracker: wordTracker,
            soundFeedbackController: soundFeedbackController,
            layoutSwitchRuntime: layoutSwitchRuntime,
            flashStatusIcon: flashStatusIcon
        )
        textActionRuntime = TextActionRuntimeCoordinator(
            settingsManager: settingsManager,
            textState: textState,
            textAccessor: textAccessor,
            inputSourceManager: inputSourceManager,
            commitRuntime: textReplacementCommitRuntime,
            currentApplicationBundleID: { [appRuntime] in
                appRuntime.effectiveCurrentApplicationBundleID(
                    frontmostApplication: NSWorkspace.shared.frontmostApplication
                )
            },
            runningApplicationBundleIDs: {
                NSWorkspace.shared.runningApplications.map(\.bundleIdentifier)
            },
            isCurrentApplicationCompletelyDisabled: { [settingsManager, appRuntime] in
                settingsManager.isApplicationCompletelyDisabled(
                    bundleID: appRuntime.effectiveCurrentApplicationBundleID(
                        frontmostApplication: NSWorkspace.shared.frontmostApplication
                    )
                )
            }
        )

        var autoCorrectionRuntimeRef: AutoCorrectionRuntimeCoordinator?
        autoCorrectionRuntime = AutoCorrectionRuntimeCoordinator(
            settingsManager: settingsManager,
            wordTracker: wordTracker,
            textState: textState,
            textAccessor: textAccessor,
            textActionRuntime: textActionRuntime,
            currentApplicationBundleID: { [appRuntime] in
                appRuntime.effectiveCurrentApplicationBundleID(
                    frontmostApplication: NSWorkspace.shared.frontmostApplication
                )
            },
            isCurrentApplicationDisabled: { [settingsManager, appRuntime] in
                settingsManager.isApplicationDisabled(
                    bundleID: appRuntime.effectiveCurrentApplicationBundleID(
                        frontmostApplication: NSWorkspace.shared.frontmostApplication
                    )
                )
            }
        )
        autoCorrectionRuntimeRef = autoCorrectionRuntime
        undoRuntime = UndoRuntimeCoordinator(
            settingsManager: settingsManager,
            textState: textState,
            textAccessor: textAccessor,
            textActionRuntime: textActionRuntime,
            layoutConverter: layoutConverter,
            reloadAutoCorrectionRules: {
                autoCorrectionRuntimeRef?.reloadRules()
            }
        )
        manualTextActionRuntime = ManualTextActionRuntimeCoordinator(
            settingsManager: settingsManager,
            wordTracker: wordTracker,
            textState: textState,
            textAccessor: textAccessor,
            textActionRuntime: textActionRuntime,
            undoRuntime: undoRuntime,
            layoutConverter: layoutConverter,
            currentApplicationBundleID: { [appRuntime] in
                appRuntime.effectiveCurrentApplicationBundleID(
                    frontmostApplication: NSWorkspace.shared.frontmostApplication
                )
            }
        )
        commandRuntime = ApplicationCommandRuntimeCoordinator(
            settingsManager: settingsManager,
            textState: textState,
            textAccessor: textAccessor,
            textActionRuntime: textActionRuntime,
            ownBundleID: Bundle.main.bundleIdentifier,
            currentApplicationBundleID: { [appRuntime] in
                appRuntime.effectiveCurrentApplicationBundleID(
                    frontmostApplication: NSWorkspace.shared.frontmostApplication
                )
            },
            currentApplicationName: { [appRuntime] in
                appRuntime.effectiveCurrentApplicationName(
                    frontmostApplication: NSWorkspace.shared.frontmostApplication
                )
            },
            flashStatusIcon: flashStatusIcon
        )
        keyPressRuntime = KeyPressRuntimeCoordinator(
            settingsManager: settingsManager,
            wordTracker: wordTracker,
            textState: textState,
            textAccessor: textAccessor,
            layoutConverter: layoutConverter,
            soundFeedbackController: soundFeedbackController,
            currentEnglishLayoutVariant: { [layoutSwitchRuntime] in
                layoutSwitchRuntime.currentEnglishLayoutVariant()
            },
            currentApplicationBundleID: { [appRuntime] in
                appRuntime.effectiveCurrentApplicationBundleID(
                    frontmostApplication: NSWorkspace.shared.frontmostApplication
                )
            },
            isCurrentApplicationDisabled: { [settingsManager, appRuntime] in
                settingsManager.isApplicationDisabled(
                    bundleID: appRuntime.effectiveCurrentApplicationBundleID(
                        frontmostApplication: NSWorkspace.shared.frontmostApplication
                    )
                )
            },
            clearTextStateForSecureInput: { [textActionRuntime] context in
                textActionRuntime.clearTextStateForSecureInput(context: context)
            },
            runAutoCorrectionIfNeeded: {
                autoCorrectionRuntimeRef?.handleAutoCorrectionIfNeeded()
            }
        )
        accessibilityNotificationRuntime = AccessibilityNotificationRuntimeCoordinator(
            textState: textState,
            ownBundleID: Bundle.main.bundleIdentifier
        )
        accessibilityStateObserver = AccessibilityStateObserver { [accessibilityNotificationRuntime] notificationName, sourceBundleID in
            accessibilityNotificationRuntime.handle(
                notificationName: notificationName,
                sourceBundleID: sourceBundleID
            )
        }
        startupRuntime = StartupRuntimeCoordinator(settingsManager: settingsManager) { [weak self] in
            self?.startHotkeyManager()
        }
    }

    func runStartupPresentationAndPermissionFlow() -> Bool {
        startupRuntime?.runStartupPresentationAndPermissionFlow() ?? false
    }

    func startInitialRuntimeState(frontmostApplication: NSRunningApplication?) {
        startHotkeyManager()
        appRuntime.setInitialActiveApplication(frontmostApplication)
        accessibilityStateObserver.observe(runningApplication: frontmostApplication)
        appRuntime.loadRememberedLayouts()
        autoCorrectionRuntime.reloadRules()
    }

    func invalidate() {
        startupRuntime?.invalidate()
        accessibilityStateObserver.stop()
        hotkeyManager?.stop()
    }

    func handleInputSourceChanged(frontmostApplication: NSRunningApplication?) {
        appRuntime.handleInputSourceChanged(frontmostApplication: frontmostApplication)
    }

    @discardableResult
    func handleActiveApplicationChanged(runningApplication: NSRunningApplication?) -> Bool {
        guard appRuntime.handleActiveApplicationChanged(runningApplication: runningApplication) else {
            return false
        }

        accessibilityStateObserver.observe(runningApplication: runningApplication)
        appRuntime.restoreRememberedLayoutForActiveApplication(
            isApplicationDisabled: commandRuntime.isCurrentApplicationDisabled()
        )
        return true
    }

    func handleInputSourcePreferencesChanged() {
        appRuntime.handleInputSourcePreferencesChanged()
    }

    func currentSettingsApplication() -> (bundleID: String, name: String?)? {
        let app = NSWorkspace.shared.frontmostApplication
        let bundleID = appRuntime.effectiveCurrentApplicationBundleID(frontmostApplication: app)
        guard let bundleID, bundleID != Bundle.main.bundleIdentifier else {
            return nil
        }
        return (
            bundleID: bundleID,
            name: appRuntime.effectiveCurrentApplicationName(frontmostApplication: app)
        )
    }

    func startHotkeyManager() {
        guard hotkeyManager == nil else {
            hotkeyManager?.start()
            return
        }

        let manager = HotkeyManager(
            settingsManager: settingsManager,
            onConvertLayout: { [manualTextActionRuntime] in
                manualTextActionRuntime.handleConvertLayout()
            },
            onToggleCase: { [manualTextActionRuntime] in
                manualTextActionRuntime.handleToggleCase()
            },
            onToggleAutoCorrection: { [commandRuntime] in
                commandRuntime.toggleAutoCorrection()
            },
            onCancelLayoutChange: { [undoRuntime, appRuntime] in
                let contextID = appRuntime.effectiveCurrentApplicationBundleID(
                    frontmostApplication: NSWorkspace.shared.frontmostApplication
                )
                undoRuntime.handleCancelLayoutChange(contextID: contextID)
            },
            onFindInYandex: { [commandRuntime] in
                commandRuntime.handleSelectedTextSearch(destination: .yandexSearch)
            },
            onFindInSlovari: { [commandRuntime] in
                commandRuntime.handleSelectedTextSearch(destination: .yandexTranslate)
            },
            onSearchClick: { [commandRuntime] in
                commandRuntime.handleSearchClickSelectedTextSearch()
            },
            onClearTrackedText: { [textState] reason in
                textState.clearTextAndConversionState(
                    trackedTextReason: reason,
                    conversionSessionReason: reason
                )
            },
            onKeyPress: { [keyPressRuntime] keyCode, characters in
                keyPressRuntime.handleKeyPress(keyCode: keyCode, characters: characters)
            },
            isCurrentApplicationDisabled: { [commandRuntime] in
                commandRuntime.isCurrentApplicationCompletelyDisabled()
            }
        )

        hotkeyManager = manager
        hotkeyIgnoreSink.hotkeyManager = manager
        manager.start()
    }
}

private final class HotkeyIgnoreEventSink {
    weak var hotkeyManager: HotkeyManager?
}
