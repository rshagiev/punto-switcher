import AppKit
import ApplicationServices
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
    private var permissionCheckTimer: Timer?
    private var inputSourceManager: InputSourceManager?
    private var textState: TextRuntimeStateCoordinator?
    private var appRuntime: ApplicationRuntimeCoordinator?
    private var keyPressRuntime: KeyPressRuntimeCoordinator?
    private var textActionRuntime: TextActionRuntimeCoordinator?
    private var autoCorrectionRuntime: AutoCorrectionRuntimeCoordinator?
    private var undoRuntime: UndoRuntimeCoordinator?

    private var isConversionInProgress: Bool {
        textState?.isConversionInProgress == true
    }

    private var ignoreInputSourceChangesUntil: Date? {
        get { textState?.ignoreInputSourceChangesUntil }
        set { textState?.ignoreInputSourceChangesUntil = newValue }
    }

    private var ignoreAccessibilityNotificationsUntil: Date? {
        textState?.ignoreAccessibilityNotificationsUntil
    }

    private var lastKeyPressTime: Date? {
        textState?.lastKeyPressTime
    }

    private var activeApplicationBundleID: String? {
        appRuntime?.activeApplicationBundleID
    }

    private var activeApplicationName: String? {
        appRuntime?.activeApplicationName
    }

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        PuntoLog.clear()
        PuntoLog.info("=== Punto Starting ===")

        // Initialize settings manager first
        settingsManager = SettingsManager()
        PuntoLog.info("Settings manager initialized")

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
        accessibilityStateObserver = AccessibilityStateObserver { [weak self] notificationName, observedBundleID in
            self?.accessibilityStateChanged(notificationName: notificationName, observedBundleID: observedBundleID)
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
                self?.handleGlobalEnabledChanged(wasEnabled: wasEnabled, isEnabled: isEnabled)
            },
            onToggleCurrentAppDisabled: { [weak self] in
                self?.toggleCurrentApplicationDisabled()
            },
            isCurrentAppDisabled: { [weak self] in
                self?.isCurrentApplicationDisabled() ?? false
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

        var updateSettings: ApplicationUpdateSettingsSnapshot
        if StartupPresentationPolicy.shouldHandleInstallArgument(CommandLine.arguments) {
            PuntoLog.info(PuntoSwitcherObservedSurface.StartupPresentation.handleInstallArgumentSelector)
            updateSettings = StartupPresentationPolicy.updateSettingsAfterInstallArgument(settingsManager!.applicationUpdateSettings)
            settingsManager!.applicationUpdateSettings = updateSettings
            PuntoLog.info(StartupPresentationPolicy.nativeInstalledTooltipMessage)
        } else {
            updateSettings = settingsManager!.applicationUpdateSettings
        }

        if StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: settingsManager!.isFirstLaunch,
            updateSettings: updateSettings
        ) {
            PuntoLog.info(StartupPresentationPolicy.observedWelcomeLogMessage)
            showOnboardingAlert()
            settingsManager!.consumeFirstLaunchPresentationFlags()
            updateSettings = StartupPresentationPolicy.updateSettingsAfterWelcome(updateSettings)
            settingsManager!.applicationUpdateSettings = updateSettings
        }

        if StartupPresentationPolicy.shouldDisplayUpdateFinishedTooltip(updateSettings: updateSettings) {
            PuntoLog.info(PuntoSwitcherObservedSurface.StartupPresentation.showUpdateFinishedTooltipSelector)
            PuntoLog.info(StartupPresentationPolicy.nativeUpdatedTooltipMessage)
            updateSettings = StartupPresentationPolicy.updateSettingsAfterUpdateFinishedTooltip(updateSettings)
            settingsManager!.applicationUpdateSettings = updateSettings
        }

        // Check permissions
        let trusted = requestAccessibilityTrustIfNeeded()
        PuntoLog.info("Accessibility trusted: \(trusted)")
        PuntoLog.info(trusted
            ? StartupPresentationPolicy.observedAccessibilityEnabledLogMessage
            : StartupPresentationPolicy.observedAccessibilityDisabledLogMessage
        )

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

        // Show alert if permissions not granted and start checking periodically
        if !trusted {
            DispatchQueue.main.asyncAfter(deadline: ConversionProtectionPolicy.startupPermissionAlertDeadline(now: .now())) { [weak self] in
                self?.showPermissionAlert()
            }
            startPermissionCheckTimer()
        }

        PuntoLog.info("=== Punto Started ===")
    }

    func applicationWillTerminate(_ notification: Notification) {
        PuntoLog.info("Punto terminating")
        permissionCheckTimer?.invalidate()
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

    private func accessibilityStateChanged(notificationName: String, observedBundleID: String?) {
        let action = AccessibilityNotificationPolicy.action(
            notificationName: notificationName,
            observedBundleID: observedBundleID,
            ownBundleID: Bundle.main.bundleIdentifier,
            now: Date(),
            ignoreUntil: ignoreAccessibilityNotificationsUntil,
            isConversionInProgress: isConversionInProgress
        )

        switch action {
        case .clearTrackedText(let reason):
            textState?.clearTextAndConversionState(
                trackedTextReason: reason,
                conversionSessionReason: reason
            )
            PuntoLog.info("Accessibility notification '\(notificationName)' cleared text state")
        case .ignore(let reason):
            PuntoLog.debug("Accessibility notification '\(notificationName)' ignored (\(reason))")
        }
    }

    @objc private func inputSourcePreferencesChanged() {
        let action = InputSourceChangePolicy.preferencesChangeAction()
        if action.shouldRefreshInputSources {
            inputSourceManager?.refreshInputSources()
        }
        textState?.clearTextAndConversionState(
            trackedTextReason: action.clearTrackedTextReason,
            conversionSessionReason: action.clearConversionSessionReason
        )
        PuntoLog.info(action.logMessage)
    }

    // MARK: - Permission Monitoring

    private func startPermissionCheckTimer() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkPermissionsAndStart()
        }
    }

    private func checkPermissionsAndStart() {
        if AXIsProcessTrusted() {
            PuntoLog.info("Accessibility permissions granted!")
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = nil
            startHotkeyManager()
        }
    }

    // MARK: - Permissions

    private func requestAccessibilityTrustIfNeeded() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func showOnboardingAlert() {
        OnboardingAlert.show { [weak self] openSettings in
            if openSettings {
                self?.openAccessibilitySettings()
            }
        }
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = AccessibilityPreferencesPolicy.permissionRequiredTitle
        alert.informativeText = AccessibilityPreferencesPolicy.permissionRequiredMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: AccessibilityPreferencesPolicy.openSettingsButtonTitle)
        alert.addButton(withTitle: AccessibilityPreferencesPolicy.laterButtonTitle)

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    private func openAccessibilitySettings() {
        let opened = NSWorkspace.shared.open(AccessibilityPreferencesPolicy.preferencesURL)
        guard AccessibilityPreferencesPolicy.shouldRunLegacyFallback(openedURL: opened) else {
            return
        }

        var error: NSDictionary?
        if let script = NSAppleScript(source: AccessibilityPreferencesPolicy.legacyAppleScriptSource) {
            script.executeAndReturnError(&error)
        }

        if let error {
            PuntoLog.error("Failed to open Accessibility preferences fallback: \(error)")
        }
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
                self?.handleConvertLayout()
            },
            onToggleCase: { [weak self] in
                PuntoLog.info(">>> Toggle case triggered <<<")
                self?.handleToggleCase()
            },
            onToggleAutoCorrection: { [weak self] in
                self?.handleToggleAutoCorrection()
            },
            onCancelLayoutChange: { [weak self] in
                let contextID = self?.activeApplicationBundleID
                    ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
                self?.undoRuntime?.handleCancelLayoutChange(contextID: contextID)
            },
            onFindInYandex: { [weak self] in
                self?.handleSelectedTextSearch(destination: .yandexSearch)
            },
            onFindInSlovari: { [weak self] in
                self?.handleSelectedTextSearch(destination: .yandexTranslate)
            },
            onSearchClick: { [weak self] in
                self?.handleSelectedTextSearch(destination: .yandexSearch)
            },
            canDoSearchClick: { [weak self] in
                self?.textAccessor?.canDoSearchClick(
                    bundleID: self?.activeApplicationBundleID
                        ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
                ) ?? false
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

    private func handleSelectedTextSearch(destination: SearchShortcutDestination) {
        PuntoLog.info(">>> Selected text search triggered <<< destination=\(destination)")

        guard textActionRuntime?.preflightTextAction(.selectedTextSearch) == true else {
            return
        }

        let capturedText = textAccessor?.captureSelectedText(lastTrackedWord: nil, lastTrackedTail: nil)
        let runtimePlan = SelectedTextSearchPolicy.runtimePlan(
            from: SelectedTextSearchPolicy.plan(capturedText: capturedText, destination: destination)
        )

        switch runtimePlan {
        case .blockedCapture(let capturedText, let logMessage):
            PuntoLog.info(logMessage)
            textActionRuntime?.clearStateAfterBlockedCapture(capturedText)

        case .open(let url, let logMessage, let shouldFlashIcon):
            PuntoLog.info(logMessage)
            NSWorkspace.shared.open(url)
            if shouldFlashIcon {
                statusBarController?.flashIcon()
            }

        case .skipped(let logMessage):
            PuntoLog.info(logMessage)

        case .noText(let logMessage):
            PuntoLog.info(logMessage)
        }
    }

    // MARK: - Actions

    private func handleConvertLayout() {
        let startTime = CFAbsoluteTimeGetCurrent()
        let conversionContextID = activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        // Log which app is frontmost and time since last keypress
        let timeSinceLastKey: String
        if let lastKey = lastKeyPressTime {
            let elapsed = Date().timeIntervalSince(lastKey) * 1000
            timeSinceLastKey = String(format: "%.0fms", elapsed)
        } else {
            timeSinceLastKey = "n/a"
        }

        if let frontApp = NSWorkspace.shared.frontmostApplication {
            PuntoLog.info(">>> Convert triggered <<< app='\(frontApp.localizedName ?? "?")' sinceLastKey=\(timeSinceLastKey)")
        } else {
            PuntoLog.info(">>> Convert triggered <<< (no frontmost app) sinceLastKey=\(timeSinceLastKey)")
        }

        guard textActionRuntime?.preflightTextAction(.layoutConversion) == true else {
            return
        }

        _ = textActionRuntime?.beginReplacementWindow()
        defer {
            let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            PuntoLog.info("⏱️ TOTAL conversion time: \(String(format: "%.1f", totalTime))ms")
        }

        defer {
            textActionRuntime?.finishReplacementWindow()
        }

        // Check for undo possibility
        if undoRuntime?.performUndoIfAvailable(contextID: conversionContextID) == true {
            return
        }

        var t1 = CFAbsoluteTimeGetCurrent()

        let lastTrackedWord = wordTracker?.getLastWord()
        let lastTrackedTail = wordTracker?.getTypedTail()
        let capturedText = textAccessor?.captureSelectedText(lastTrackedWord: lastTrackedWord, lastTrackedTail: lastTrackedTail)
        let getTextTime = (CFAbsoluteTimeGetCurrent() - t1) * 1000

        let plan = ManualLayoutConversionPolicy.plan(
            capturedText: capturedText,
            lastWord: lastTrackedWord,
            lastTrackedTail: lastTrackedTail,
            russianLayoutType: settingsManager?.russianKeyboardLayoutType
                ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType,
            converter: layoutConverter!
        )

        let runtimePlan = ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: plan,
            suppressAutoCorrectionAfterManualConversion: settingsManager?.suppressAutoCorrectionAfterManualConversion
                ?? SettingsPersistencePolicy.defaultSuppressAutoCorrectionAfterManualConversion
        )

        switch runtimePlan {
        case .blockedCapture(let capturedText, let logMessage):
            PuntoLog.info(logMessage)
            textActionRuntime?.clearStateAfterBlockedCapture(capturedText)
            return

        case .replace(let replacementPlan):
            PuntoLog.info("⏱️ \(replacementPlan.captureTimingLabel): \(String(format: "%.1f", getTextTime))ms")
            PuntoLog.info(replacementPlan.originalTextLogMessage)
            PuntoLog.info(replacementPlan.convertedTextLogMessage)

            t1 = CFAbsoluteTimeGetCurrent()
            let replacementApplied = textAccessor?.replaceCapturedText(
                replacementPlan.replacement.capturedText,
                with: replacementPlan.replacement.convertedText,
                keepSelection: replacementPlan.replacement.keepSelection
            ) ?? false
            let replaceTime = (CFAbsoluteTimeGetCurrent() - t1) * 1000
            PuntoLog.info("⏱️ \(replacementPlan.replacementTimingLabel): \(String(format: "%.1f", replaceTime))ms")
            guard replacementApplied else {
                PuntoLog.info(replacementPlan.failedReplacementLogMessage)
                textActionRuntime?.clearTrackedTextAfterFailedReplacement(method: replacementPlan.failedReplacementMethod)
                return
            }

            textActionRuntime?.commitSuccessfulTextReplacement(
                replacementPlan.commitPlan,
                contextID: conversionContextID
            )

        case .clearTrackedText(let reason, let logMessage):
            PuntoLog.info(logMessage)
            textState?.clearTrackedText(reason: reason)
            return

        case .skip(let logMessage):
            PuntoLog.info(logMessage)
            return

        case .noText(let logMessage):
            PuntoLog.info(logMessage)
            return
        }
    }

    private func handleToggleCase() {
        let conversionContextID = activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        guard textActionRuntime?.preflightTextAction(.toggleCase) == true else {
            return
        }

        _ = textActionRuntime?.beginReplacementWindow()
        defer {
            textActionRuntime?.finishReplacementWindow()
        }

        let lastTrackedWord = wordTracker?.getLastWord()
        let lastTrackedTail = wordTracker?.getTypedTail()
        let capturedText = textAccessor?.captureSelectedText(lastTrackedWord: lastTrackedWord, lastTrackedTail: lastTrackedTail)
        let runtimePlan = ToggleCaseConversionPolicy.runtimePlan(
            from: ToggleCaseConversionPolicy.plan(capturedText: capturedText)
        )

        switch runtimePlan {
        case .blockedCapture(let capturedText, let logMessage):
            PuntoLog.info(logMessage)
            textActionRuntime?.clearStateAfterBlockedCapture(capturedText)

        case .replace(let replacementPlan):
            PuntoLog.info(replacementPlan.logMessage)
            if textAccessor?.replaceCapturedText(
                replacementPlan.capturedText,
                with: replacementPlan.replacement.toggledText,
                keepSelection: replacementPlan.keepSelection
            ) == true {
                textActionRuntime?.commitSuccessfulTextReplacement(
                    replacementPlan.commitPlan,
                    contextID: conversionContextID
                )
            } else {
                PuntoLog.info(replacementPlan.failedReplacementLogMessage)
                textActionRuntime?.clearTrackedTextAfterFailedReplacement(method: replacementPlan.failedReplacementMethod)
            }

        case .skipped(let logMessage):
            PuntoLog.info(logMessage)

        case .noText(let logMessage):
            PuntoLog.info(logMessage)
        }
    }

    private func handleToggleAutoCorrection() {
        let action = AutoCorrectionTogglePolicy.action(
            wasEnabled: settingsManager?.autoCorrectionEnabled == true
        )
        settingsManager?.autoCorrectionEnabled = action.newEnabledValue
        textState?.clearTextAndConversionState(
            trackedTextReason: action.clearTrackedTextReason,
            conversionSessionReason: action.clearConversionSessionReason
        )
        PuntoLog.info(action.logMessage)
        if action.shouldFlashIcon {
            statusBarController?.flashIcon()
        }
    }

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

    private func toggleCurrentApplicationDisabled() {
        let rawBundleID = activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard let action = ApplicationDisablePolicy.toggleAction(
            bundleID: rawBundleID,
            ownBundleID: Bundle.main.bundleIdentifier,
            isCurrentlyDisabled: settingsManager?.isApplicationDisabled(bundleID: rawBundleID) ?? false
        ) else {
            return
        }

        settingsManager?.setApplicationDisabled(bundleID: action.bundleID, disabled: action.disabled)
        if action.shouldClearState,
           let clearTrackedTextReason = action.clearTrackedTextReason,
           let clearConversionSessionReason = action.clearConversionSessionReason {
            textState?.clearTextAndConversionState(
                trackedTextReason: clearTrackedTextReason,
                conversionSessionReason: clearConversionSessionReason
            )
        }
        PuntoLog.info(ApplicationDisablePolicy.toggleLogMessage(
            action: action,
            applicationName: activeApplicationName
        ))
    }

    private func handleGlobalEnabledChanged(wasEnabled: Bool, isEnabled: Bool) {
        let action = HotkeyRoutingPolicy.stateClearActionAfterEnabledChange(
            wasEnabled: wasEnabled,
            isEnabled: isEnabled
        )

        textState?.apply(action)
        if let logMessage = action.logMessage {
            PuntoLog.info(logMessage)
        }
    }

}
