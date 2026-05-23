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
        case .ignoreProgrammaticSwitch:
            PuntoLog.info("Input source changed - ignored (programmatic switch grace window)")
            return
        case .ignoreConversionInProgress:
            PuntoLog.info("Input source changed - ignored (conversion in progress)")
            return
        case .rememberLayoutAndClearTextState:
            break
        }

        rememberCurrentLayoutForActiveApplication(reason: "input source changed")

        // Clear WordTracker when keyboard layout changes
        // This prevents buffer corruption from mixed-layout input
        wordTracker?.clear(reason: "input source changed")
        conversionSession.clear(reason: "input source changed")
        PuntoLog.info("Input source changed - WordTracker cleared")
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

        guard newBundleID != Bundle.main.bundleIdentifier else {
            PuntoLog.info("Punto window activated - preserving last external app '\(activeApplicationBundleID ?? "?")'")
            return
        }

        if ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: activeApplicationBundleID,
            newBundleID: newBundleID,
            ownBundleID: Bundle.main.bundleIdentifier
        ) {
            wordTracker?.clear(reason: "active application changed")
            conversionSession.clear(reason: "active application changed")
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
        inputSourceManager?.refreshInputSources()
        wordTracker?.clear(reason: "Input source preferences changed")
        conversionSession.clear(reason: "Input source preferences changed")
        PuntoLog.info("Input source preferences changed - input sources refreshed")
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
                guard HotkeyRoutingPolicy.shouldTrackKeyState(
                    isEnabled: self?.settingsManager?.isEnabled == true,
                    isCurrentApplicationDisabled: self?.isCurrentApplicationDisabled() == true
                ) else {
                    PuntoLog.info("Key tracking skipped by routing policy")
                    return
                }

                let isSecureInputEnabled = self?.textAccessor?.isSecureInputEnabled() == true
                let isPasswordField = self?.textAccessor?.isPasswordField() == true
                guard TextTrackingSecurityPolicy.shouldTrackTextInput(
                    isSecureInputEnabled: isSecureInputEnabled,
                    isPasswordField: isPasswordField
                ) else {
                    if TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(
                        isSecureInputEnabled: isSecureInputEnabled,
                        isPasswordField: isPasswordField
                    ) {
                        self?.clearTextStateForSecureInput(
                            context: TextTrackingSecurityPolicy.diagnosticContext(
                                isSecureInputEnabled: isSecureInputEnabled,
                                isPasswordField: isPasswordField
                            ) ?? "secure input"
                        )
                    }
                    PuntoLog.info("Key tracking skipped for secure/password input")
                    return
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
                if ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
                    bundleID: self?.activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
                    keyCode: keyCode,
                    resetBundleComponents: self?.settingsManager?.resetOnReturnBundleComponents
                        ?? ApplicationReturnKeyPolicy.defaultResetBundleComponents
                ) {
                    let consumedCompletedToken = wordTracker?.consumeCompletedToken() != nil
                    if let statisticsEvent = ProductStatisticsPolicy.eventAfterCompletedTokenConsumption(consumedCompletedToken) {
                        self?.settingsManager?.recordProductStatisticsEvent(statisticsEvent)
                    }
                    self?.conversionSession.clear(reason: "return in reset-on-return app")
                    PuntoLog.info("Auto-correction skipped and text state reset on Return for app '\(self?.activeApplicationBundleID ?? "?")'")
                    return
                }
                self?.handleAutoCorrectionIfNeeded()
                // Clear undo on any key press, but only if we're not in the middle of a conversion
                // This prevents race condition where async key event clears undo right after hotkey
                if self?.isConversionInProgress == false {
                    self?.conversionSession.clear(reason: "key press")
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
        guard let capturedText, !capturedText.text.isEmpty else {
            PuntoLog.info("Selected text search skipped: no selected text")
            return
        }

        if TextCapturePolicy.shouldStopAfterBlockedCapture(capturedText) {
            PuntoLog.info("Selected text search blocked unsafe selection fallback: \(capturedText.source)")
            clearStateAfterBlockedCapture(capturedText)
            return
        }

        guard let url = SearchShortcutPolicy.url(for: capturedText.text, destination: destination) else {
            PuntoLog.info("Selected text search skipped: empty normalized query")
            return
        }

        PuntoLog.info("Opening selected text search URL: \(url.absoluteString)")
        NSWorkspace.shared.open(url)
        statusBarController?.flashIcon()
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

        // Process selected text if any
        if let capturedText = capturedText, TextCapturePolicy.shouldStopAfterBlockedCapture(capturedText) {
            PuntoLog.info("Blocked unsafe selection fallback: \(capturedText.source)")
            clearStateAfterBlockedCapture(capturedText)
            return
        } else if let capturedText = capturedText, !capturedText.text.isEmpty {
            PuntoLog.info("⏱️ getSelectedText: \(String(format: "%.1f", getTextTime))ms")

            PuntoLog.info("Converting captured text (\(capturedText.source)): '\(capturedText.text)'")
            let result = layoutConverter!.convertWithResult(
                capturedText.text,
                russianLayoutType: settingsManager?.russianKeyboardLayoutType
                    ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType
            )
            PuntoLog.info("Converted to: '\(result.text)'")
            guard let replacement = LayoutConversionReplacementPolicy.replacement(
                for: capturedText,
                conversionResult: result
            ) else {
                PuntoLog.info("Captured text conversion skipped: replacement plan could not be derived")
                return
            }

            t1 = CFAbsoluteTimeGetCurrent()
            let replacementApplied = textAccessor?.replaceCapturedText(
                replacement.capturedText,
                with: replacement.convertedText,
                keepSelection: replacement.keepSelection
            ) ?? false
            let setTextTime = (CFAbsoluteTimeGetCurrent() - t1) * 1000
            PuntoLog.info("⏱️ setSelectedText: \(String(format: "%.1f", setTextTime))ms")
            guard replacementApplied else {
                PuntoLog.info("Captured text replacement aborted")
                clearTrackedTextAfterFailedReplacement(method: replacement.capturedText.replacementMethod)
                return
            }

            statusBarController?.flashIcon()
            soundFeedbackController?.play(.layoutConversion)
            settingsManager?.recordProductStatisticsEvent(.manualSwitch)
            switchLayoutIfEnabled(replacement.targetLayout, surface: .selectedText)

            if let rewrittenTail = replacement.trackedTailAfterReplacement {
                wordTracker?.replaceTrackedTail(
                    with: rewrittenTail,
                    reason: "terminal selection conversion completed",
                    suppressAutoCorrectionForCurrentToken: settingsManager?.suppressAutoCorrectionAfterManualConversion
                        ?? SettingsPersistencePolicy.defaultSuppressAutoCorrectionAfterManualConversion,
                    russianLayoutType: settingsManager?.russianKeyboardLayoutType
                        ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType
                )
            }

            // Save for undo
            conversionSession.record(
                originalText: replacement.capturedText.text,
                convertedText: replacement.convertedText,
                replacementMethod: replacement.undoMethod,
                contextID: conversionContextID
            )
        } else {
            PuntoLog.info("⏱️ getSelectedText (empty): \(String(format: "%.1f", getTextTime))ms")

            // No selection - convert last word
            if let lastWord = wordTracker?.getLastWord(), !lastWord.isEmpty {
                PuntoLog.info("Converting last word: '\(lastWord)'")
                let result = layoutConverter!.convertWithResult(
                    lastWord,
                    russianLayoutType: settingsManager?.russianKeyboardLayoutType
                        ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType
                )
                PuntoLog.info("Converted to: '\(result.text)'")
                guard let replacement = LayoutConversionReplacementPolicy.lastWordReplacement(
                    lastWord: lastWord,
                    conversionResult: result,
                    lastTrackedTail: lastTrackedTail
                ) else {
                    PuntoLog.info("Last-word conversion skipped: replacement plan could not be derived")
                    if LayoutConversionReplacementPolicy.shouldClearTrackedTextAfterSkippedLastWordReplacement(
                        lastWord: lastWord,
                        conversionResult: result,
                        lastTrackedTail: lastTrackedTail
                    ) {
                        wordTracker?.clear(reason: "stale last-word tracked tail")
                    }
                    return
                }

                t1 = CFAbsoluteTimeGetCurrent()
                let replacementApplied = textAccessor?.replaceCapturedText(
                    replacement.capturedText,
                    with: replacement.convertedText,
                    keepSelection: replacement.keepSelection
                ) ?? false
                let replaceTime = (CFAbsoluteTimeGetCurrent() - t1) * 1000
                PuntoLog.info("⏱️ replaceLastWord: \(String(format: "%.1f", replaceTime))ms")
                guard replacementApplied else {
                    PuntoLog.info("Last-word replacement aborted")
                    clearTrackedTextAfterFailedReplacement(method: replacement.capturedText.replacementMethod)
                    return
                }

                wordTracker?.clear(reason: "conversion completed")
                if let updatedTail = replacement.trackedTailAfterReplacement {
                    wordTracker?.replaceTrackedTail(
                        with: updatedTail,
                        reason: "last-word conversion completed",
                        suppressAutoCorrectionForCurrentToken: settingsManager?.suppressAutoCorrectionAfterManualConversion
                            ?? SettingsPersistencePolicy.defaultSuppressAutoCorrectionAfterManualConversion,
                        russianLayoutType: settingsManager?.russianKeyboardLayoutType
                            ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType
                    )
                }
                statusBarController?.flashIcon()
                soundFeedbackController?.play(.layoutConversion)
                settingsManager?.recordProductStatisticsEvent(.manualSwitch)
                switchLayoutIfEnabled(replacement.targetLayout, surface: .lastWord)

                // Save for undo
                conversionSession.record(
                    originalText: replacement.capturedText.text,
                    convertedText: replacement.convertedText,
                    replacementMethod: replacement.undoMethod,
                    contextID: conversionContextID
                )
            } else {
                PuntoLog.info("No text to convert")
            }
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
        guard let last = conversionSession.undoCandidate(contextID: contextID) else {
            return false
        }

        PuntoLog.info("Undo: reverting '\(last.convertedText)' back to '\(last.originalText)'")

        guard let undoReplacement = UndoReplacementPolicy.replacement(for: last) else {
            PuntoLog.info("Undo aborted: replacement plan could not be derived")
            conversionSession.clear(reason: "undo plan derivation failed")
            return true
        }

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

        if UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(origin: last.origin) {
            let originalLayout = layoutConverter!.detectLayout(last.originalText)
            switchLayoutIfEnabled(originalLayout, surface: .undo)
        } else {
            PuntoLog.info("Undo: skipped layout switch for origin \(last.origin)")
        }

        statusBarController?.flashIcon()
        soundFeedbackController?.play(.undo)
        settingsManager?.recordProductStatisticsEvent(.revert)
        if let undoneTail = undoReplacement.trackedTailAfterUndo {
            wordTracker?.replaceTrackedTail(
                with: undoneTail,
                reason: "undo completed",
                russianLayoutType: settingsManager?.russianKeyboardLayoutType
                    ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType
            )
        }

        if let learnedRules = AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: settingsManager?.autoCorrectionRules ?? [],
            record: last,
            isUndoLearningEnabled: settingsManager?.autoCorrectionUndoLearningEnabled
                ?? SettingsPersistencePolicy.defaultAutoCorrectionUndoLearningEnabled
        ) {
            settingsManager?.autoCorrectionRules = learnedRules
            reloadAutoCorrectionRules()
            PuntoLog.info("Auto-correction undo learned exception for '\(last.originalText.trimmingCharacters(in: .whitespacesAndNewlines))'")
        }

        conversionSession.record(
            originalText: last.convertedText,
            convertedText: last.originalText,
            replacementMethod: undoReplacement.nextReplacementMethod,
            contextID: contextID,
            origin: ConversionOriginPolicy.originAfterUndo(record: last)
        )

        return true
    }

    private func switchLayoutIfEnabled(
        _ targetLayout: LayoutConverter.DetectedLayout,
        surface: LayoutConversionSurface
    ) {
        guard LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: surface,
            switchLayoutAfterConversion: settingsManager?.switchLayoutAfterConversion == true,
            switchLayoutAfterSelectedTextConversion: settingsManager?.switchLayoutAfterSelectedTextConversion
                ?? SettingsPersistencePolicy.defaultSwitchLayoutAfterSelectedTextConversion
        ) else {
            return
        }

        // Ignore the burst of notifications caused by our own programmatic switch.
        ignoreInputSourceChangesUntil = ConversionProtectionPolicy.inputSourceIgnoreDeadline(now: Date())
        PuntoLog.debug("ignoreInputSourceChangesUntil set (switching to \(targetLayout))")

        switch targetLayout {
        case .english:
            let targetLayoutID = inputSourceManager?.languageLayoutID(.english)
            let didSwitch = inputSourceManager?.switchTo(KeyboardLanguage.english) ?? false
            playInputSourceSwitchSound(targetLayout: targetLayout, didSwitch: didSwitch, context: .textReplacement)
            rememberProgrammaticLayoutSwitch(targetLayoutID: targetLayoutID, didSwitch: didSwitch)
        case .russian:
            let targetLayoutID = inputSourceManager?.languageLayoutID(.russian)
            let didSwitch = inputSourceManager?.switchTo(KeyboardLanguage.russian) ?? false
            playInputSourceSwitchSound(targetLayout: targetLayout, didSwitch: didSwitch, context: .textReplacement)
            rememberProgrammaticLayoutSwitch(targetLayoutID: targetLayoutID, didSwitch: didSwitch)
        case .mixed, .unknown:
            ignoreInputSourceChangesUntil = nil  // Reset if no switch happened
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
        if let statisticsEvent = ProductStatisticsPolicy.eventAfterCompletedTokenConsumption(token != nil) {
            settingsManager?.recordProductStatisticsEvent(statisticsEvent)
        }
        let routePreflight = AutoCorrectionPreflightPolicy.action(
            isEnabled: settingsManager?.isEnabled == true,
            autoCorrectionEnabled: settingsManager?.autoCorrectionEnabled == true,
            autoCorrectOnEnterAndTab: settingsManager?.autoCorrectOnEnterAndTab
                ?? SettingsPersistencePolicy.defaultAutoCorrectOnEnterAndTab,
            isConversionInProgress: isConversionInProgress,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled(),
            hasCompletedToken: token != nil,
            completedTokenSeparator: token?.separator,
            isCompletedTokenAutoCorrectionSuppressed: token?.isAutoCorrectionSuppressed == true,
            isSecureInputEnabled: false,
            isPasswordField: false
        )

        switch routePreflight {
        case .proceed:
            break
        case .consumeTokenAndSkip, .skip:
            if let message = AutoCorrectionPreflightPolicy.logMessage(for: routePreflight) {
                PuntoLog.info(message)
            }
            return
        case .blockAndClear:
            break
        }

        guard let token else { return }

        let securityPreflight = AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: settingsManager?.autoCorrectOnEnterAndTab
                ?? SettingsPersistencePolicy.defaultAutoCorrectOnEnterAndTab,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: token.separator,
            isCompletedTokenAutoCorrectionSuppressed: token.isAutoCorrectionSuppressed,
            isSecureInputEnabled: textAccessor?.isSecureInputEnabled() == true,
            isPasswordField: textAccessor?.isPasswordField() == true
        )

        if case .blockAndClear(let reason) = securityPreflight {
            clearTextStateForSecureInput(context: reason)
            if let message = AutoCorrectionPreflightPolicy.logMessage(for: securityPreflight) {
                PuntoLog.info(message)
            }
            return
        }

        reloadAutoCorrectionRules()
        let trackedTailBeforeCorrection = wordTracker?.getTypedTailPreservingBoundaryWhitespace()

        guard let decision = autoCorrectionEngine.correction(for: token.word) else {
            return
        }

        _ = beginReplacementWindow()
        defer {
            finishReplacementWindow()
        }

        guard let replacement = AutoCorrectionReplacementPolicy.replacement(
            for: decision,
            completedToken: token,
            trackedTailBeforeCorrection: trackedTailBeforeCorrection
        ) else {
            PuntoLog.info("Auto-correction aborted: replacement plan could not be derived")
            if AutoCorrectionReplacementPolicy.shouldClearConversionSessionAfterPlanFailure() {
                conversionSession.clear(reason: "auto-correction plan derivation failed")
            }
            return
        }
        PuntoLog.info("Auto-correcting completed word '\(decision.original)' -> '\(decision.replacement)'")

        let applied = textAccessor?.replaceRecentText(
            length: replacement.replacementLength,
            with: replacement.replacementText
        ) ?? false
        if applied {
            wordTracker?.replaceTrackedTail(
                with: replacement.trackedTailAfterReplacement,
                reason: "auto-correction completed",
                russianLayoutType: settingsManager?.russianKeyboardLayoutType
                    ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType
            )
            conversionSession.record(
                originalText: replacement.originalText,
                convertedText: replacement.replacementText,
                replacementMethod: replacement.undoMethod,
                contextID: activeApplicationBundleID ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
                origin: .autoCorrection(rule: decision.rule)
            )
            statusBarController?.flashIcon()
            soundFeedbackController?.play(.autoCorrection)
            settingsManager?.recordProductStatisticsEvent(.automaticSwitch)
        } else {
            PuntoLog.info("Auto-correction replacement aborted")
            clearTrackedTextAfterFailedReplacement(method: replacement.undoMethod)
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

        if let capturedText = capturedText, TextCapturePolicy.shouldStopAfterBlockedCapture(capturedText) {
            PuntoLog.info("Toggle case blocked unsafe selection fallback: \(capturedText.source)")
            clearStateAfterBlockedCapture(capturedText)
            return
        } else if let capturedText = capturedText, !capturedText.text.isEmpty {
            PuntoLog.info("Toggling case for captured text (\(capturedText.source)): '\(capturedText.text)'")
            guard let replacement = ToggleCasePolicy.replacement(for: capturedText) else {
                PuntoLog.info("Toggle case aborted: replacement plan could not be derived")
                return
            }
            let keepSelection = TextReplacementPolicy.shouldKeepSelectionAfterReplacement(method: capturedText.replacementMethod)
            if textAccessor?.replaceCapturedText(capturedText, with: replacement.toggledText, keepSelection: keepSelection) == true {
                if let rewrittenTail = replacement.trackedTailAfterReplacement {
                    wordTracker?.replaceTrackedTail(
                        with: rewrittenTail,
                        reason: "toggle-case completed",
                        russianLayoutType: settingsManager?.russianKeyboardLayoutType
                            ?? KeyboardLayoutTypePolicy.defaultRussianLayoutType
                    )
                }
                conversionSession.record(
                    originalText: replacement.originalText,
                    convertedText: replacement.toggledText,
                    replacementMethod: replacement.undoMethod,
                    contextID: conversionContextID,
                    origin: .toggleCase
                )
                statusBarController?.flashIcon()
                soundFeedbackController?.play(.toggleCase)
            } else {
                PuntoLog.info("Toggle case replacement aborted")
                clearTrackedTextAfterFailedReplacement(method: capturedText.replacementMethod)
            }
        } else {
            PuntoLog.info("Toggle case: no selected text")
        }
    }

    private func handleToggleAutoCorrection() {
        let wasEnabled = settingsManager?.autoCorrectionEnabled == true
        settingsManager?.autoCorrectionEnabled = !wasEnabled
        wordTracker?.clear(reason: "auto-correction toggled")
        conversionSession.clear(reason: "auto-correction toggled")
        PuntoLog.info("Auto-correction \(wasEnabled ? "disabled" : "enabled") by hotkey")
        statusBarController?.flashIcon()
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

        let routeAction = TextActionPreflightPolicy.action(
            kind: kind,
            isEnabled: settingsManager?.isEnabled == true,
            isManualConversionDisabled: settingsManager?.manualConversionDisabled == true,
            isConversionInProgress: isConversionInProgress,
            isCurrentApplicationDisabled: isCurrentApplicationCompletelyDisabled(),
            isSecureInputEnabled: false,
            isPasswordField: false
        )
        guard handle(routeAction) else {
            return false
        }

        if textAccessor?.isSecureInputEnabled() == true {
            return handle(TextActionPreflightPolicy.action(
                kind: kind,
                isEnabled: true,
                isManualConversionDisabled: false,
                isConversionInProgress: false,
                isCurrentApplicationDisabled: false,
                isSecureInputEnabled: true,
                isPasswordField: false
            ))
        }

        if textAccessor?.isPasswordField() == true {
            return handle(TextActionPreflightPolicy.action(
                kind: kind,
                isEnabled: true,
                isManualConversionDisabled: false,
                isConversionInProgress: false,
                isCurrentApplicationDisabled: false,
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
        if action.shouldClearState {
            wordTracker?.clear(reason: "disabled current app")
            conversionSession.clear(reason: "disabled current app")
        }
        PuntoLog.info("\(action.disabled ? "Disabled" : "Enabled") Punto in app '\(activeApplicationName ?? action.bundleID)' (\(action.bundleID))")
    }

    private func handleGlobalEnabledChanged(wasEnabled: Bool, isEnabled: Bool) {
        guard HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(
            wasEnabled: wasEnabled,
            isEnabled: isEnabled
        ) else {
            return
        }

        wordTracker?.clear(reason: "Punto disabled")
        conversionSession.clear(reason: "Punto disabled")
        PuntoLog.info("Punto disabled - cleared text state")
    }

    private func clearTextStateForSecureInput(context: String = "secure input") {
        guard TextTrackingSecurityPolicy.shouldClearTrackedState(
            isSecureInputEnabled: true,
            isPasswordField: true
        ) else {
            return
        }

        wordTracker?.clear(reason: "secure text input")
        conversionSession.clear(reason: "secure text input")
        writeSecureInputDiagnostics(context: context)
        PuntoLog.info("Secure/password input - cleared text state")
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

        if action.clearTrackedText {
            wordTracker?.clear(reason: "failed keyboard replacement")
        }

        if action.clearConversionSession {
            conversionSession.clear(reason: "failed keyboard replacement")
        }
    }

    private func clearStateAfterFailedUndoReplacement(method: TextReplacementMethod) {
        let action = UndoReplacementPolicy.actionAfterFailedReplacement(method: method)

        if action.clearTrackedText {
            wordTracker?.clear(reason: "undo replacement failed")
        }

        if action.clearConversionSession {
            conversionSession.clear(reason: "undo replacement failed")
        }
    }

    private func clearStateAfterBlockedCapture(_ capturedText: CapturedText?) {
        let action = TextCapturePolicy.actionAfterBlockedCapture(capturedText)

        if action.clearTrackedText {
            wordTracker?.clear(reason: "blocked unsafe text capture")
        }

        if action.clearConversionSession {
            conversionSession.clear(reason: "blocked unsafe text capture")
        }
    }
}
