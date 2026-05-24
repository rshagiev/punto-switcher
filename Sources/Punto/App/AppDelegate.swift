import AppKit
import Carbon
import PuntoCore

/// Main application delegate handling lifecycle and permissions
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var hotkeyManager: HotkeyManager?
    private var textAccessor: TextAccessor?
    private var layoutConverter: LayoutConverter?
    private var wordTracker: WordTracker?
    private var settingsManager: SettingsManager?
    private var settingsWindowController: SettingsWindowController?
    private var soundFeedbackController: SoundFeedbackController?
    private var accessibilityStateObserver: AccessibilityStateObserver?
    private var accessibilityNotificationRuntime: AccessibilityNotificationRuntimeCoordinator?
    private var inputSourceManager: InputSourceManager?
    private var textState: TextRuntimeStateCoordinator?
    private var appRuntime: ApplicationRuntimeCoordinator?
    private var keyPressRuntime: KeyPressRuntimeCoordinator?
    private var textActionRuntime: TextActionRuntimeCoordinator?
    private var autoCorrectionRuntime: AutoCorrectionRuntimeCoordinator?
    private var undoRuntime: UndoRuntimeCoordinator?
    private var manualTextActionRuntime: ManualTextActionRuntimeCoordinator?
    private var commandRuntime: ApplicationCommandRuntimeCoordinator?
    private var startupRuntime: StartupRuntimeCoordinator?

    private var activeApplicationBundleID: String? {
        appRuntime?.activeApplicationBundleID
    }

    private var activeApplicationName: String? {
        appRuntime?.activeApplicationName
    }

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        PuntoLog.prepareForNewSession()
        PuntoLog.info("=== Punto Starting ===")

        // Initialize settings manager first
        settingsManager = SettingsManager()
        PuntoLog.info("Settings manager initialized")
        startupRuntime = StartupRuntimeCoordinator(settingsManager: settingsManager!) { [weak self] in
            self?.startHotkeyManager()
        }

        // Initialize core components
        layoutConverter = LayoutConverter()
        wordTracker = WordTracker(maxTailSize: 512)
        textState = TextRuntimeStateCoordinator(wordTracker: wordTracker!) { [weak self] ignoreEvents in
            self?.hotkeyManager?.ignoreEvents = ignoreEvents
        }
        textAccessor = TextAccessor(
            shouldRestorePasteboard: { [weak settingsManager] in
                settingsManager?.restorePasteboardAfterConversion
                    ?? SettingsPersistencePolicy.defaultRestorePasteboardAfterConversion
            }
        )
        inputSourceManager = InputSourceManager(
            preferredRussianLayoutType: { [weak settingsManager] in
                settingsManager?.russianKeyboardLayoutType ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType
            },
            preferredEnglishSourceID: { [weak settingsManager] in
                settingsManager?.preferredEnglishInputSourceID
            },
            preferredRussianSourceID: { [weak settingsManager] in
                settingsManager?.preferredRussianInputSourceID
            }
        )
        appRuntime = ApplicationRuntimeCoordinator(
            settingsManager: settingsManager!,
            inputSourceManager: inputSourceManager!,
            textState: textState!
        )
        soundFeedbackController = SoundFeedbackController(settingsManager: settingsManager!)
        textActionRuntime = TextActionRuntimeCoordinator(
            settingsManager: settingsManager!,
            textState: textState!,
            textAccessor: textAccessor!,
            inputSourceManager: inputSourceManager!,
            wordTracker: wordTracker!,
            soundFeedbackController: soundFeedbackController!,
            appRuntime: appRuntime!,
            currentApplicationBundleID: { [weak self] in
                self?.activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            },
            runningApplicationBundleIDs: {
                NSWorkspace.shared.runningApplications.map(\.bundleIdentifier)
            },
            isCurrentApplicationCompletelyDisabled: { [weak self] in
                self?.isCurrentApplicationCompletelyDisabled() ?? false
            },
            flashStatusIcon: { [weak self] in
                self?.statusBarController?.flashIcon()
            }
        )
        autoCorrectionRuntime = AutoCorrectionRuntimeCoordinator(
            settingsManager: settingsManager!,
            wordTracker: wordTracker!,
            textState: textState!,
            textAccessor: textAccessor!,
            textActionRuntime: textActionRuntime!,
            currentApplicationBundleID: { [weak self] in
                self?.activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            },
            isCurrentApplicationDisabled: { [weak self] in
                self?.isCurrentApplicationDisabled() ?? false
            }
        )
        undoRuntime = UndoRuntimeCoordinator(
            settingsManager: settingsManager!,
            textState: textState!,
            textAccessor: textAccessor!,
            textActionRuntime: textActionRuntime!,
            layoutConverter: layoutConverter!,
            reloadAutoCorrectionRules: { [weak self] in
                self?.autoCorrectionRuntime?.reloadRules()
            }
        )
        manualTextActionRuntime = ManualTextActionRuntimeCoordinator(
            settingsManager: settingsManager!,
            wordTracker: wordTracker!,
            textState: textState!,
            textAccessor: textAccessor!,
            textActionRuntime: textActionRuntime!,
            undoRuntime: undoRuntime!,
            layoutConverter: layoutConverter!,
            currentApplicationBundleID: { [weak self] in
                self?.activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            }
        )
        commandRuntime = ApplicationCommandRuntimeCoordinator(
            settingsManager: settingsManager!,
            textState: textState!,
            textAccessor: textAccessor!,
            textActionRuntime: textActionRuntime!,
            ownBundleID: Bundle.main.bundleIdentifier,
            currentApplicationBundleID: { [weak self] in
                self?.activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            },
            currentApplicationName: { [weak self] in
                self?.activeApplicationName ?? NSWorkspace.shared.frontmostApplication?.localizedName
            },
            flashStatusIcon: { [weak self] in
                self?.statusBarController?.flashIcon()
            }
        )
        keyPressRuntime = KeyPressRuntimeCoordinator(
            settingsManager: settingsManager!,
            wordTracker: wordTracker!,
            textState: textState!,
            textAccessor: textAccessor!,
            layoutConverter: layoutConverter!,
            soundFeedbackController: soundFeedbackController!,
            currentApplicationBundleID: { [weak self] in
                self?.activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            },
            isCurrentApplicationDisabled: { [weak self] in
                self?.isCurrentApplicationDisabled() ?? false
            },
            clearTextStateForSecureInput: { [weak self] context in
                self?.textActionRuntime?.clearTextStateForSecureInput(context: context)
            },
            runAutoCorrectionIfNeeded: { [weak self] in
                self?.autoCorrectionRuntime?.handleAutoCorrectionIfNeeded()
            }
        )
        accessibilityNotificationRuntime = AccessibilityNotificationRuntimeCoordinator(
            textState: textState!,
            ownBundleID: Bundle.main.bundleIdentifier
        )
        accessibilityStateObserver = AccessibilityStateObserver { [weak self] notificationName, observedBundleID in
            self?.accessibilityNotificationRuntime?.handle(
                notificationName: notificationName,
                observedBundleID: observedBundleID
            )
        }
        PuntoLog.info("Core components initialized")

        // Initialize status bar
        statusBarController = StatusBarController(
            settingsManager: settingsManager!,
            onSettingsClick: { [weak self] in
                self?.showSettings()
            },
            onQuitClick: {
                NSApplication.shared.terminate(nil)
            },
            onEnabledChanged: { [weak self] wasEnabled, isEnabled in
                self?.commandRuntime?.handleGlobalEnabledChanged(wasEnabled: wasEnabled, isEnabled: isEnabled)
            },
            onToggleCurrentAppDisabled: { [weak self] in
                self?.commandRuntime?.toggleCurrentApplicationDisabled()
            },
            isCurrentAppDisabled: { [weak self] in
                self?.commandRuntime?.isCurrentApplicationDisabled() ?? false
            },
            currentAppBundleID: { [weak self] in
                self?.appRuntime?.effectiveCurrentApplicationBundleID(
                    frontmostApplication: NSWorkspace.shared.frontmostApplication
                )
            },
            currentAppName: { [weak self] in
                self?.appRuntime?.effectiveCurrentApplicationName(
                    frontmostApplication: NSWorkspace.shared.frontmostApplication
                )
            }
        )
        PuntoLog.info("Status bar initialized")

        _ = startupRuntime?.runStartupPresentationAndPermissionFlow()

        // Always try to start hotkey manager
        startHotkeyManager()
        appRuntime?.setInitialActiveApplication(NSWorkspace.shared.frontmostApplication)
        accessibilityStateObserver?.observe(runningApplication: NSWorkspace.shared.frontmostApplication)
        appRuntime?.loadRememberedLayouts()
        autoCorrectionRuntime?.reloadRules()

        // Subscribe to input source changes to clear WordTracker
        // This prevents buffer corruption when user switches keyboard layout
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
        PuntoLog.info("Subscribed to input source changes")

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeApplicationChanged(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        PuntoLog.info("Subscribed to active application changes")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(inputSourcePreferencesChanged),
            name: .puntoInputSourcePreferencesChanged,
            object: settingsManager
        )
        PuntoLog.info("Subscribed to input source preference changes")

        PuntoLog.info("=== Punto Started ===")
    }

    func applicationWillTerminate(_ notification: Notification) {
        PuntoLog.info("Punto terminating")
        startupRuntime?.invalidate()
        accessibilityStateObserver?.stop()
        hotkeyManager?.stop()
        DistributedNotificationCenter.default().removeObserver(self)
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Input Source Change

    @objc private func inputSourceChanged() {
        appRuntime?.handleInputSourceChanged(frontmostApplication: NSWorkspace.shared.frontmostApplication)
    }

    @objc private func activeApplicationChanged(_ notification: Notification) {
        let runningApp = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)
            ?? NSWorkspace.shared.frontmostApplication

        guard appRuntime?.handleActiveApplicationChanged(runningApplication: runningApp) == true else {
            return
        }

        accessibilityStateObserver?.observe(runningApplication: runningApp)
        statusBarController?.refreshCurrentApplicationState()
        appRuntime?.restoreRememberedLayoutForActiveApplication(
            isApplicationDisabled: settingsManager?.isApplicationDisabled(bundleID: activeApplicationBundleID) == true
        )
    }

    @objc private func inputSourcePreferencesChanged() {
        appRuntime?.handleInputSourcePreferencesChanged()
    }

    // MARK: - Hotkey Manager

    private func startHotkeyManager() {
        guard let settingsManager = settingsManager,
              textAccessor != nil,
              layoutConverter != nil,
              wordTracker != nil,
              let keyPressRuntime = keyPressRuntime else {
            PuntoLog.error("Failed to initialize - missing components")
            return
        }

        hotkeyManager = HotkeyManager(
            settingsManager: settingsManager,
            onConvertLayout: { [weak self] in
                self?.manualTextActionRuntime?.handleConvertLayout()
            },
            onToggleCase: { [weak self] in
                self?.manualTextActionRuntime?.handleToggleCase()
            },
            onToggleAutoCorrection: { [weak self] in
                self?.commandRuntime?.toggleAutoCorrection()
            },
            onCancelLayoutChange: { [weak self] in
                let contextID = self?.activeApplicationBundleID
                    ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
                self?.undoRuntime?.handleCancelLayoutChange(contextID: contextID)
            },
            onFindInYandex: { [weak self] in
                self?.commandRuntime?.handleSelectedTextSearch(destination: .yandexSearch)
            },
            onFindInSlovari: { [weak self] in
                self?.commandRuntime?.handleSelectedTextSearch(destination: .yandexTranslate)
            },
            onSearchClick: { [weak self] in
                self?.commandRuntime?.handleSelectedTextSearch(destination: .yandexSearch)
            },
            canDoSearchClick: { [weak self] in
                self?.commandRuntime?.canDoSearchClick() ?? false
            },
            onClearTrackedText: { [weak self] reason in
                self?.textState?.clearTextAndConversionState(
                    trackedTextReason: reason,
                    conversionSessionReason: reason
                )
            },
            onKeyPress: { keyCode, characters in
                keyPressRuntime.handleKeyPress(keyCode: keyCode, characters: characters)
            },
            isCurrentApplicationDisabled: { [weak self] in
                self?.isCurrentApplicationCompletelyDisabled() ?? false
            }
        )

        hotkeyManager?.start()
    }

    // MARK: - Actions

    // MARK: - Settings

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                settingsManager: settingsManager!,
                currentApplication: { [weak self] in
                    let app = NSWorkspace.shared.frontmostApplication
                    let bundleID = self?.activeApplicationBundleID ?? app?.bundleIdentifier
                    guard let bundleID, bundleID != Bundle.main.bundleIdentifier else {
                        return nil
                    }
                    return (bundleID: bundleID, name: self?.activeApplicationName ?? app?.localizedName)
                }
            )
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func isCurrentApplicationDisabled() -> Bool {
        let bundleID = activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return settingsManager?.isApplicationDisabled(bundleID: bundleID) ?? false
    }

    private func isCurrentApplicationCompletelyDisabled() -> Bool {
        let bundleID = activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return settingsManager?.isApplicationCompletelyDisabled(bundleID: bundleID) ?? false
    }

}
