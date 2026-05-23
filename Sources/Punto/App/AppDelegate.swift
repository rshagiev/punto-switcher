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
    private let applicationLayoutMemory = ApplicationLayoutMemory()
    private var autoCorrectionEngine = AutoCorrectionEngine(rules: [])
    private var activeApplicationBundleID: String?
    private var activeApplicationName: String?

    private let conversionSession = ConversionSession()
    private var isConversionInProgress = false  // Prevents race condition with key press clearing undo
    private var ignoreInputSourceChangesUntil: Date?  // Ignore notifications when we switch layout programmatically
    private var ignoreAccessibilityNotificationsUntil: Date?
    private var lastKeyPressTime: Date?  // Track when last key was pressed for debugging timing issues

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
        soundFeedbackController = SoundFeedbackController(settingsManager: settingsManager!)
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
                self?.activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            },
            currentAppName: { [weak self] in
                self?.activeApplicationName ?? NSWorkspace.shared.frontmostApplication?.localizedName
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
            settingsManager!.isFirstLaunch = false
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
        activeApplicationBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        activeApplicationName = NSWorkspace.shared.frontmostApplication?.localizedName
        accessibilityStateObserver?.observe(runningApplication: NSWorkspace.shared.frontmostApplication)
        applicationLayoutMemory.replaceAll(with: settingsManager?.rememberedApplicationLayouts ?? [:])
        reloadAutoCorrectionRules()

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
        let now = Date()
        let action = InputSourceChangePolicy.action(
            now: now,
            ignoreChangesUntil: ignoreInputSourceChangesUntil,
            isConversionInProgress: isConversionInProgress
        )
        ignoreInputSourceChangesUntil = InputSourceChangePolicy.nextIgnoreChangesUntil(
            now: now,
            currentIgnoreChangesUntil: ignoreInputSourceChangesUntil
        )

        switch action {
        case .ignoreProgrammaticSwitch(let logMessage):
            PuntoLog.info(logMessage)
            return
        case .ignoreConversionInProgress(let logMessage):
            PuntoLog.info(logMessage)
            return
        case .rememberLayoutAndClearTextState(let plan):
            rememberCurrentLayoutForActiveApplication(reason: plan.layoutMemoryReason)
            wordTracker?.clear(reason: plan.clearTrackedTextReason)
            conversionSession.clear(reason: plan.clearConversionSessionReason)
            PuntoLog.info(plan.logMessage)
        }
    }

    @objc private func activeApplicationChanged(_ notification: Notification) {
        let runningApp = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)
            ?? NSWorkspace.shared.frontmostApplication
        let newBundleID = runningApp?.bundleIdentifier
        let newName = runningApp?.localizedName

        if ApplicationLayoutPolicy.shouldRecordCurrentLayoutOnApplicationActivation(
            rememberInputSourceForEachApp: settingsManager?.rememberInputSourceForEachApp == true
        ) {
            rememberCurrentLayoutForActiveApplication(reason: "active application changed")
        }

        let action = ApplicationContextPolicy.activationAction(
            previousBundleID: activeApplicationBundleID,
            newBundleID: newBundleID,
            ownBundleID: Bundle.main.bundleIdentifier
        )

        switch action {
        case .preserveCurrentExternalContext(let logMessage):
            PuntoLog.info(logMessage)
            return
        case .activateExternal(let plan):
            if plan.shouldResetTextState,
               let clearTrackedTextReason = plan.clearTrackedTextReason,
               let clearConversionSessionReason = plan.clearConversionSessionReason {
                wordTracker?.clear(reason: clearTrackedTextReason)
                conversionSession.clear(reason: clearConversionSessionReason)
            }
        }

        activeApplicationBundleID = newBundleID
        activeApplicationName = newName
        accessibilityStateObserver?.observe(runningApplication: runningApp)
        statusBarController?.refreshCurrentApplicationState()

        guard settingsManager?.rememberInputSourceForEachApp == true else {
            return
        }

        let restoreBundleID = ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: newBundleID,
            ownBundleID: Bundle.main.bundleIdentifier,
            isApplicationDisabled: settingsManager?.isApplicationDisabled(bundleID: newBundleID) == true
        )

        guard let rememberedLayoutID = applicationLayoutMemory.layoutID(for: restoreBundleID) else {
            PuntoLog.info("No remembered layout for app '\(newBundleID ?? "?")'")
            return
        }

        switch ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: newBundleID,
            ownBundleID: Bundle.main.bundleIdentifier,
            isApplicationDisabled: settingsManager?.isApplicationDisabled(bundleID: newBundleID) == true,
            rememberedLayoutID: rememberedLayoutID,
            currentLayoutID: inputSourceManager?.currentLayoutID()
        ) {
        case .skip:
            PuntoLog.info("Skipped remembered layout restore for app '\(newBundleID ?? "?")'")
        case .alreadyActive(let layoutID):
            PuntoLog.info("Remembered layout '\(layoutID)' already active for app '\(newBundleID ?? "?")'")
        case .switchTo(let layoutID):
            ignoreInputSourceChangesUntil = ConversionProtectionPolicy.inputSourceIgnoreDeadline(now: Date())
            let switched = inputSourceManager?.switchToLayoutID(layoutID) ?? false
            if switched {
                PuntoLog.info("Restored remembered layout '\(layoutID)' for app '\(newBundleID ?? "?")'")
            } else {
                ignoreInputSourceChangesUntil = nil
            }
        }
    }

    private func rememberCurrentLayoutForActiveApplication(reason: String) {
        guard settingsManager?.rememberInputSourceForEachApp == true else { return }
        guard let layoutID = inputSourceManager?.currentLayoutID() else { return }

        guard let update = ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: settingsManager?.rememberInputSourceForEachApp == true,
            activeBundleID: activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            frontmostBundleID: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            ownBundleID: Bundle.main.bundleIdentifier,
            currentLayoutID: layoutID
        ) else {
            PuntoLog.info("Skipped layout memory update (reason: \(reason))")
            return
        }

        applicationLayoutMemory.remember(bundleID: update.bundleID, layoutID: update.layoutID)
        settingsManager?.rememberedApplicationLayouts = applicationLayoutMemory.snapshot()
        PuntoLog.info("Remembered layout '\(update.layoutID)' for app '\(update.bundleID)' (reason: \(reason))")
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
            wordTracker?.clear(reason: reason)
            conversionSession.clear(reason: reason)
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
        wordTracker?.clear(reason: action.clearTrackedTextReason)
        conversionSession.clear(reason: action.clearConversionSessionReason)
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
              let wordTracker = wordTracker else {
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
                self?.handleCancelLayoutChange()
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
            onClearTrackedText: { [weak self, weak wordTracker] reason in
                wordTracker?.clear(reason: reason)
                self?.conversionSession.clear(reason: reason)
            },
            onKeyPress: { [weak self, weak wordTracker] keyCode, characters in
                self?.lastKeyPressTime = Date()
                let keyTrackingPreflight = KeyTrackingRuntimePolicy.preflightPlan(
                    isEnabled: self?.settingsManager?.isEnabled == true,
                    isCurrentApplicationDisabled: self?.isCurrentApplicationDisabled() == true,
                    isSecureInputEnabled: self?.textAccessor?.isSecureInputEnabled() == true,
                    isPasswordField: self?.textAccessor?.isPasswordField() == true
                )

                switch keyTrackingPreflight {
                case .skipRouting(let logMessage):
                    PuntoLog.info(logMessage)
                    return

                case .blockSecureInput(let context, let logMessage):
                    self?.clearTextStateForSecureInput(context: context)
                    PuntoLog.info(logMessage)
                    return

                case .track:
                    break
                }

                wordTracker?.trackKeyPress(
                    keyCode: keyCode,
                    characters: characters,
                    autoCorrectionCancellingKeyNames: self?.settingsManager?.autoCorrectionCancellingKeyNames
                        ?? AutoCorrectionCancellingKeyPolicy.defaultEnabledKeyNames,
                    russianLayoutType: self?.settingsManager?.russianKeyboardLayoutType
                        ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType
                )
                self?.settingsManager?.recordProductStatisticsEvent(.typedText(characters))
                self?.playTextInputSound(characters: characters)

                switch KeyTrackingRuntimePolicy.postTrackRoute(
                    bundleID: self?.activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
                    keyCode: keyCode,
                    resetBundleComponents: self?.settingsManager?.resetOnReturnBundleComponents
                        ?? ApplicationReturnKeyPolicy.defaultResetBundleComponents
                ) {
                case .resetOnReturn:
                    let consumedCompletedToken = wordTracker?.consumeCompletedToken() != nil
                    let resetPlan = KeyTrackingRuntimePolicy.resetOnReturnPlan(
                        consumedCompletedToken: consumedCompletedToken,
                        bundleID: self?.activeApplicationBundleID
                    )
                    if let statisticsEvent = resetPlan.completedTokenStatisticsEvent {
                        self?.settingsManager?.recordProductStatisticsEvent(statisticsEvent)
                    }
                    self?.conversionSession.clear(reason: resetPlan.conversionSessionClearReason)
                    PuntoLog.info(resetPlan.logMessage)
                    return

                case .runAutoCorrection:
                    self?.handleAutoCorrectionIfNeeded()
                }

                if let clearReason = KeyTrackingRuntimePolicy.conversionSessionClearReasonAfterAutoCorrection(
                    isConversionInProgress: self?.isConversionInProgress == true
                ) {
                    self?.conversionSession.clear(reason: clearReason)
                }
            },
            isCurrentApplicationDisabled: { [weak self] in
                self?.isCurrentApplicationCompletelyDisabled() ?? false
            }
        )

        hotkeyManager?.start()
    }

    private func handleSelectedTextSearch(destination: SearchShortcutDestination) {
        PuntoLog.info(">>> Selected text search triggered <<< destination=\(destination)")

        guard preflightTextAction(.selectedTextSearch) else {
            return
        }

        let capturedText = textAccessor?.captureSelectedText(lastTrackedWord: nil, lastTrackedTail: nil)
        let runtimePlan = SelectedTextSearchPolicy.runtimePlan(
            from: SelectedTextSearchPolicy.plan(capturedText: capturedText, destination: destination)
        )

        switch runtimePlan {
        case .blockedCapture(let capturedText, let logMessage):
            PuntoLog.info(logMessage)
            clearStateAfterBlockedCapture(capturedText)

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

    private func playTextInputSound(characters: String?) {
        let detectedLayout = layoutConverter?.detectLayout(characters ?? "") ?? .unknown
        guard let event = SoundFeedbackPolicy.eventAfterTextInput(
            characters: characters,
            detectedLayout: detectedLayout
        ) else {
            return
        }
        soundFeedbackController?.play(event)
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

        guard preflightTextAction(.layoutConversion) else {
            return
        }

        _ = beginReplacementWindow()
        defer {
            let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            PuntoLog.info("⏱️ TOTAL conversion time: \(String(format: "%.1f", totalTime))ms")
        }

        defer {
            finishReplacementWindow()
        }

        // Check for undo possibility
        if performUndoIfAvailable(contextID: conversionContextID) {
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
            clearStateAfterBlockedCapture(capturedText)
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
                clearTrackedTextAfterFailedReplacement(method: replacementPlan.failedReplacementMethod)
                return
            }

            commitSuccessfulTextReplacement(
                replacementPlan.commitPlan,
                contextID: conversionContextID
            )

        case .clearTrackedText(let reason, let logMessage):
            PuntoLog.info(logMessage)
            wordTracker?.clear(reason: reason)
            return

        case .skip(let logMessage):
            PuntoLog.info(logMessage)
            return

        case .noText(let logMessage):
            PuntoLog.info(logMessage)
            return
        }
    }

    private func handleCancelLayoutChange() {
        let conversionContextID = activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        PuntoLog.info(">>> Cancel layout change triggered <<<")

        guard preflightTextAction(.layoutConversion) else {
            return
        }

        _ = beginReplacementWindow()
        defer {
            finishReplacementWindow()
        }

        guard performUndoIfAvailable(contextID: conversionContextID) else {
            PuntoLog.info("Cancel layout change: no recent conversion to undo")
            return
        }
    }

    @discardableResult
    private func performUndoIfAvailable(contextID: String?) -> Bool {
        let plan = UndoRuntimePolicy.plan(
            record: conversionSession.undoCandidate(contextID: contextID),
            autoCorrectionRules: settingsManager?.autoCorrectionRules ?? [],
            isUndoLearningEnabled: settingsManager?.autoCorrectionUndoLearningEnabled
                ?? SettingsPersistencePolicy.defaultAutoCorrectionUndoLearningEnabled
        )

        switch plan {
        case .noCandidate:
            return false

        case .planFailure(let record):
            let action = UndoRuntimePolicy.planFailureAction(record: record)
            if let logMessage = action.logMessage {
                PuntoLog.info(logMessage)
            }
            if action.clearConversionSession,
               let reason = action.clearConversionSessionReason {
                conversionSession.clear(reason: reason)
            }
            return true

        case .replacement(let plan):
            let last = plan.record
            let undoReplacement = plan.undoReplacement
            PuntoLog.info("Undo: reverting '\(last.convertedText)' back to '\(last.originalText)'")

            let undoApplied = textAccessor?.replaceCapturedText(
                undoReplacement.capturedText,
                with: undoReplacement.replacementText,
                keepSelection: undoReplacement.keepSelection
            ) ?? false
            guard undoApplied else {
                PuntoLog.info("Undo aborted: replacement was not applied")
                clearStateAfterFailedUndoReplacement(method: undoReplacement.capturedText.replacementMethod)
                return true
            }

            let commitPlan = UndoRuntimePolicy.appliedCommitPlan(for: plan, converter: layoutConverter!)
            if let layoutSwitchTarget = commitPlan.layoutSwitchTarget {
                switchLayoutIfEnabled(layoutSwitchTarget, surface: .undo)
            } else if let skippedLayoutSwitchLogMessage = commitPlan.skippedLayoutSwitchLogMessage {
                PuntoLog.info(skippedLayoutSwitchLogMessage)
            }

            statusBarController?.flashIcon()
            soundFeedbackController?.play(commitPlan.soundFeedbackEvent)
            settingsManager?.recordProductStatisticsEvent(commitPlan.productStatisticsEvent)
            if let trackedTailCommit = commitPlan.trackedTailCommit {
                wordTracker?.replaceTrackedTail(
                    with: trackedTailCommit.text,
                    reason: trackedTailCommit.reason,
                    suppressAutoCorrectionForCurrentToken: trackedTailCommit.suppressAutoCorrectionForCurrentToken,
                    russianLayoutType: settingsManager?.russianKeyboardLayoutType
                        ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType
                )
            }

            if let learnedRules = commitPlan.learnedAutoCorrectionRules {
                settingsManager?.autoCorrectionRules = learnedRules
                reloadAutoCorrectionRules()
                if let learnedRuleLogMessage = commitPlan.learnedRuleLogMessage {
                    PuntoLog.info(learnedRuleLogMessage)
                }
            }

            conversionSession.record(commitPlan.conversionRecordCommit, contextID: contextID)

            return true
        }
    }

    private func switchLayoutIfEnabled(
        _ targetLayout: LayoutConverter.DetectedLayout,
        surface: LayoutConversionSurface
    ) {
        let plan = LayoutSwitchRuntimePolicy.plan(
            targetLayout: targetLayout,
            surface: surface,
            switchLayoutAfterConversion: settingsManager?.switchLayoutAfterConversion == true,
            switchLayoutAfterSelectedTextConversion: settingsManager?.switchLayoutAfterSelectedTextConversion
                ?? SettingsPersistencePolicy.defaultSwitchLayoutAfterSelectedTextConversion
        )

        switch plan {
        case .skip:
            return

        case .unsupportedTarget(let clearInputSourceIgnoreDeadline):
            if clearInputSourceIgnoreDeadline {
                ignoreInputSourceChangesUntil = nil
            }

        case .switchTo(let request):
            ignoreInputSourceChangesUntil = request.ignoreInputSourceChangesUntil
            PuntoLog.debug("ignoreInputSourceChangesUntil set (switching to \(request.targetLayout))")
            let language = keyboardLanguage(for: request.language)
            let targetLayoutID = inputSourceManager?.languageLayoutID(language)
            let didSwitch = inputSourceManager?.switchTo(language) ?? false
            playInputSourceSwitchSound(targetLayout: request.targetLayout, didSwitch: didSwitch, context: .textReplacement)
            rememberProgrammaticLayoutSwitch(targetLayoutID: targetLayoutID, didSwitch: didSwitch)
        }
    }

    private func keyboardLanguage(for language: LayoutSwitchTargetLanguage) -> KeyboardLanguage {
        switch language {
        case .english:
            return .english
        case .russian:
            return .russian
        }
    }

    private func playInputSourceSwitchSound(
        targetLayout: LayoutConverter.DetectedLayout,
        didSwitch: Bool,
        context: InputSourceSwitchSoundContext
    ) {
        guard let event = SoundFeedbackPolicy.eventAfterInputSourceSwitch(
            targetLayout: targetLayout,
            didSwitch: didSwitch,
            context: context
        ) else {
            return
        }
        soundFeedbackController?.play(event)
    }

    private func rememberProgrammaticLayoutSwitch(targetLayoutID: String?, didSwitch: Bool) {
        guard let update = ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: settingsManager?.rememberInputSourceForEachApp == true,
            activeBundleID: activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            ownBundleID: Bundle.main.bundleIdentifier,
            targetLayoutID: targetLayoutID,
            didSwitch: didSwitch
        ) else {
            if !didSwitch {
                ignoreInputSourceChangesUntil = nil
            }
            return
        }

        applicationLayoutMemory.remember(bundleID: update.bundleID, layoutID: update.layoutID)
        settingsManager?.rememberedApplicationLayouts = applicationLayoutMemory.snapshot()
        PuntoLog.info("Remembered programmatic layout '\(update.layoutID)' for app '\(update.bundleID)'")
    }

    private func reloadAutoCorrectionRules() {
        autoCorrectionEngine = AutoCorrectionEngine(rules: settingsManager?.autoCorrectionRules ?? [])
    }

    private func handleAutoCorrectionIfNeeded() {
        let token = wordTracker?.consumeCompletedToken()
        let gatePlan = AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: settingsManager?.isEnabled == true,
            autoCorrectionEnabled: settingsManager?.autoCorrectionEnabled == true,
            autoCorrectOnEnterAndTab: settingsManager?.autoCorrectOnEnterAndTab
                ?? SettingsPersistencePolicy.defaultAutoCorrectOnEnterAndTab,
            isConversionInProgress: isConversionInProgress,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled(),
            isSecureInputEnabled: textAccessor?.isSecureInputEnabled() == true,
            isPasswordField: textAccessor?.isPasswordField() == true
        )

        func recordCompletedTokenStatistics(_ event: ProductStatisticsEvent?) {
            if let event {
                settingsManager?.recordProductStatisticsEvent(event)
            }
        }

        let plan: AutoCorrectionRuntimeAttemptPlan
        switch gatePlan {
        case .skipped(let completedTokenStatisticsEvent, let logMessage):
            recordCompletedTokenStatistics(completedTokenStatisticsEvent)
            if let logMessage {
                PuntoLog.info(logMessage)
            }
            return

        case .blockAndClear(let completedTokenStatisticsEvent, let reason, let logMessage):
            recordCompletedTokenStatistics(completedTokenStatisticsEvent)
            clearTextStateForSecureInput(context: reason)
            if let logMessage {
                PuntoLog.info(logMessage)
            }
            return

        case .proceed(let completedTokenStatisticsEvent, let token):
            reloadAutoCorrectionRules()
            plan = AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
                token: token,
                completedTokenStatisticsEvent: completedTokenStatisticsEvent,
                trackedTailBeforeCorrection: wordTracker?.getTypedTailPreservingBoundaryWhitespace(),
                engine: autoCorrectionEngine
            )
        }

        switch plan {
        case .noCorrection(let completedTokenStatisticsEvent):
            recordCompletedTokenStatistics(completedTokenStatisticsEvent)
            return
        case .planFailure(let completedTokenStatisticsEvent, let logMessage, let conversionSessionClearReason):
            recordCompletedTokenStatistics(completedTokenStatisticsEvent)
            PuntoLog.info(logMessage)
            if let conversionSessionClearReason {
                conversionSession.clear(reason: conversionSessionClearReason)
            }
            return

        case .replacement(let completedTokenStatisticsEvent, let logMessage, let replacement, let commitPlan):
            recordCompletedTokenStatistics(completedTokenStatisticsEvent)
            PuntoLog.info(logMessage)

            _ = beginReplacementWindow()
            defer {
                finishReplacementWindow()
            }

            let applied = textAccessor?.replaceRecentText(
                length: replacement.replacementLength,
                with: replacement.replacementText
            ) ?? false
            if applied {
                commitSuccessfulTextReplacement(
                    commitPlan,
                    contextID: activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
                )
            } else {
                PuntoLog.info("Auto-correction replacement aborted")
                clearTrackedTextAfterFailedReplacement(method: replacement.undoMethod)
            }
        }
    }

    private func handleToggleCase() {
        let conversionContextID = activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        guard preflightTextAction(.toggleCase) else {
            return
        }

        _ = beginReplacementWindow()
        defer {
            finishReplacementWindow()
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
            clearStateAfterBlockedCapture(capturedText)

        case .replace(let replacementPlan):
            PuntoLog.info(replacementPlan.logMessage)
            if textAccessor?.replaceCapturedText(
                replacementPlan.capturedText,
                with: replacementPlan.replacement.toggledText,
                keepSelection: replacementPlan.keepSelection
            ) == true {
                commitSuccessfulTextReplacement(
                    replacementPlan.commitPlan,
                    contextID: conversionContextID
                )
            } else {
                PuntoLog.info(replacementPlan.failedReplacementLogMessage)
                clearTrackedTextAfterFailedReplacement(method: replacementPlan.failedReplacementMethod)
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
        wordTracker?.clear(reason: action.clearTrackedTextReason)
        conversionSession.clear(reason: action.clearConversionSessionReason)
        PuntoLog.info(action.logMessage)
        if action.shouldFlashIcon {
            statusBarController?.flashIcon()
        }
    }

    private func commitSuccessfulTextReplacement(_ plan: TextReplacementCommitPlan, contextID: String?) {
        if plan.clearTrackedTextBeforeTailCommit {
            wordTracker?.clear(reason: "conversion completed")
        }

        if let trackedTailCommit = plan.trackedTailCommit {
            wordTracker?.replaceTrackedTail(
                with: trackedTailCommit.text,
                reason: trackedTailCommit.reason,
                suppressAutoCorrectionForCurrentToken: trackedTailCommit.suppressAutoCorrectionForCurrentToken,
                russianLayoutType: settingsManager?.russianKeyboardLayoutType
                    ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType
            )
        }

        if let layoutSwitchCommit = plan.layoutSwitchCommit {
            switchLayoutIfEnabled(layoutSwitchCommit.targetLayout, surface: layoutSwitchCommit.surface)
        }

        statusBarController?.flashIcon()
        soundFeedbackController?.play(plan.soundFeedbackEvent)
        if let productStatisticsEvent = plan.productStatisticsEvent {
            settingsManager?.recordProductStatisticsEvent(productStatisticsEvent)
        }

        conversionSession.record(plan.conversionRecordCommit, contextID: contextID)
    }

    private func beginReplacementWindow() -> ReplacementWindowAction {
        let action = ConversionProtectionPolicy.replacementWindowAction(now: Date(), dispatchNow: .now())
        isConversionInProgress = action.markConversionInProgress
        ignoreAccessibilityNotificationsUntil = action.ignoreAccessibilityNotificationsUntil
        hotkeyManager?.ignoreEvents = action.shouldIgnoreHotkeyEvents
        return action
    }

    private func finishReplacementWindow() {
        let releaseAt = ConversionProtectionPolicy.eventRecaptureReleaseDeadline(now: .now())
        DispatchQueue.main.asyncAfter(deadline: releaseAt) { [weak self] in
            self?.hotkeyManager?.ignoreEvents = false
            self?.isConversionInProgress = false
        }
    }

    private func preflightTextAction(_ kind: TextActionKind) -> Bool {
        func handle(_ action: TextActionPreflightAction) -> Bool {
            switch action {
            case .proceed:
                return true
            case .skip:
                if let message = TextActionPreflightPolicy.logMessage(action: action, kind: kind) {
                    PuntoLog.info(message)
                }
                return false
            case .blockAndClear(let reason):
                clearTextStateForSecureInput(context: reason)
                if let message = TextActionPreflightPolicy.logMessage(action: action, kind: kind) {
                    PuntoLog.info(message)
                }
                return false
            }
        }

        let routeAction = TextActionRuntimePreflightPolicy.routeAction(
            kind: kind,
            isEnabled: settingsManager?.isEnabled == true,
            isManualConversionDisabled: settingsManager?.manualConversionDisabled == true,
            isConversionInProgress: isConversionInProgress,
            isCurrentApplicationDisabled: isCurrentApplicationCompletelyDisabled()
        )
        guard handle(routeAction) else {
            return false
        }

        if textAccessor?.isSecureInputEnabled() == true {
            return handle(TextActionRuntimePreflightPolicy.securityAction(
                kind: kind,
                isSecureInputEnabled: true,
                isPasswordField: false
            ))
        }

        if textAccessor?.isPasswordField() == true {
            return handle(TextActionRuntimePreflightPolicy.securityAction(
                kind: kind,
                isSecureInputEnabled: false,
                isPasswordField: true
            ))
        }

        return true
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
            wordTracker?.clear(reason: clearTrackedTextReason)
            conversionSession.clear(reason: clearConversionSessionReason)
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

        if action.clearTrackedText, let reason = action.clearTrackedTextReason {
            wordTracker?.clear(reason: reason)
        }
        if action.clearConversionSession, let reason = action.clearConversionSessionReason {
            conversionSession.clear(reason: reason)
        }
        if let logMessage = action.logMessage {
            PuntoLog.info(logMessage)
        }
    }

    private func clearTextStateForSecureInput(context: String = "secure input") {
        let action = TextTrackingSecurityPolicy.clearAction(
            isSecureInputEnabled: context == "secure input",
            isPasswordField: context == "password field"
        )

        if action.clearTrackedText, let reason = action.clearTrackedTextReason {
            wordTracker?.clear(reason: reason)
        }
        if action.clearConversionSession, let reason = action.clearConversionSessionReason {
            conversionSession.clear(reason: reason)
        }
        if action.shouldWriteDiagnostics, let diagnosticContext = action.diagnosticContext {
            writeSecureInputDiagnostics(context: diagnosticContext)
        }
        if let logMessage = action.logMessage {
            PuntoLog.info(logMessage)
        }
    }

    private func writeSecureInputDiagnostics(context: String) {
        let snapshot = SecureInputDiagnosticsPolicy.snapshot(
            secureInputState: textAccessor?.isSecureInputEnabled() == true,
            context: context,
            currentApp: activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            runningApps: NSWorkspace.shared.runningApplications.map(\.bundleIdentifier),
            enabledLayouts: [
                inputSourceManager?.languageLayoutID(.english),
                inputSourceManager?.languageLayoutID(.russian),
                inputSourceManager?.currentLayoutID()
            ]
        )
        let dictionary = SecureInputDiagnosticsPolicy.plistDictionary(from: snapshot)
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(SecureInputDiagnosticsPolicy.observedPlistFilename)

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
            PuntoLog.info("Wrote secure input diagnostics to \(url.path)")
        } catch {
            PuntoLog.error("Failed to write secure input diagnostics: \(error)")
        }
    }

    private func clearTrackedTextAfterFailedReplacement(method: TextReplacementMethod) {
        let action = ReplacementFailurePolicy.actionAfterFailedReplacement(method: method)

        if action.clearTrackedText, let reason = action.clearTrackedTextReason {
            wordTracker?.clear(reason: reason)
        }

        if action.clearConversionSession, let reason = action.clearConversionSessionReason {
            conversionSession.clear(reason: reason)
        }
    }

    private func clearStateAfterFailedUndoReplacement(method: TextReplacementMethod) {
        let action = UndoReplacementPolicy.actionAfterFailedReplacement(method: method)

        if action.clearTrackedText, let reason = action.clearTrackedTextReason {
            wordTracker?.clear(reason: reason)
        }

        if action.clearConversionSession, let reason = action.clearConversionSessionReason {
            conversionSession.clear(reason: reason)
        }
    }

    private func clearStateAfterBlockedCapture(_ capturedText: CapturedText?) {
        let action = TextCapturePolicy.actionAfterBlockedCapture(capturedText)

        if action.clearTrackedText, let reason = action.clearTrackedTextReason {
            wordTracker?.clear(reason: reason)
        }

        if action.clearConversionSession, let reason = action.clearConversionSessionReason {
            conversionSession.clear(reason: reason)
        }
    }
}
