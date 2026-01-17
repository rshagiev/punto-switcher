import AppKit
import ApplicationServices
import Carbon

/// Main application delegate handling lifecycle and permissions
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var hotkeyManager: HotkeyManager?
    private var textAccessor: TextAccessor?
    private var layoutConverter: LayoutConverter?
    private var wordTracker: WordTracker?
    private var settingsManager: SettingsManager?
    private var settingsWindowController: SettingsWindowController?
    private var permissionCheckTimer: Timer?
    private var inputSourceManager: InputSourceManager?

    /// Информация о последней конвертации для undo
    private struct LastConversion {
        let originalText: String
        let convertedText: String
        let timestamp: Date
        let wasSelection: Bool
    }

    private var lastConversion: LastConversion?
    private let undoTimeout: TimeInterval = 3.0
    private var isConversionInProgress = false  // Prevents race condition with key press clearing undo
    private var ignoreNextInputSourceChange = false  // Ignore notification when we switch layout programmatically

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        PuntoLog.clear()
        PuntoLog.info("=== Punto Starting ===")

        // Initialize settings manager first
        settingsManager = SettingsManager()
        PuntoLog.info("Settings manager initialized")

        // Initialize core components
        layoutConverter = LayoutConverter()
        wordTracker = WordTracker()
        textAccessor = TextAccessor()
        inputSourceManager = InputSourceManager()
        PuntoLog.info("Core components initialized")

        // Initialize status bar
        statusBarController = StatusBarController(
            settingsManager: settingsManager!,
            onSettingsClick: { [weak self] in
                self?.showSettings()
            },
            onQuitClick: {
                NSApplication.shared.terminate(nil)
            }
        )
        PuntoLog.info("Status bar initialized")

        // Check if this is the first launch
        if settingsManager!.isFirstLaunch {
            PuntoLog.info("First launch detected")
            showOnboardingAlert()
            settingsManager!.isFirstLaunch = false
        }

        // Check permissions
        let trusted = AXIsProcessTrusted()
        PuntoLog.info("Accessibility trusted: \(trusted)")

        // Always try to start hotkey manager
        startHotkeyManager()

        // Subscribe to input source changes to clear WordTracker
        // This prevents buffer corruption when user switches keyboard layout
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
        PuntoLog.info("Subscribed to input source changes")

        // Show alert if permissions not granted and start checking periodically
        if !trusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showPermissionAlert()
            }
            startPermissionCheckTimer()
        }

        PuntoLog.info("=== Punto Started ===")
    }

    func applicationWillTerminate(_ notification: Notification) {
        PuntoLog.info("Punto terminating")
        permissionCheckTimer?.invalidate()
        hotkeyManager?.stop()
        DistributedNotificationCenter.default().removeObserver(self)
    }

    // MARK: - Input Source Change

    @objc private func inputSourceChanged() {
        // Skip if we triggered the layout switch ourselves (after conversion)
        if ignoreNextInputSourceChange {
            ignoreNextInputSourceChange = false
            PuntoLog.info("Input source changed - ignored (programmatic switch)")
            return
        }

        // Clear WordTracker when keyboard layout changes
        // This prevents buffer corruption from mixed-layout input
        wordTracker?.clear()
        lastConversion = nil  // Also clear undo state
        PuntoLog.info("Input source changed - WordTracker cleared")
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

    private func showOnboardingAlert() {
        OnboardingAlert.show { [weak self] openSettings in
            if openSettings {
                self?.openAccessibilitySettings()
            }
        }
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "Punto needs Accessibility access to detect hotkeys and convert text. Please add Punto to System Settings → Privacy & Security → Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
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
                PuntoLog.info(">>> Convert layout triggered <<<")
                self?.handleConvertLayout()
            },
            onToggleCase: { [weak self] in
                PuntoLog.info(">>> Toggle case triggered <<<")
                self?.handleToggleCase()
            },
            onKeyPress: { [weak self, weak wordTracker] keyCode, characters in
                wordTracker?.trackKeyPress(keyCode: keyCode, characters: characters)
                // Clear undo on any key press, but only if we're not in the middle of a conversion
                // This prevents race condition where async key event clears undo right after hotkey
                if self?.isConversionInProgress == false {
                    self?.lastConversion = nil
                }
            }
        )

        hotkeyManager?.start()
    }

    // MARK: - Actions

    private func handleConvertLayout() {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard settingsManager?.isEnabled == true else {
            PuntoLog.info("Disabled, skipping conversion")
            return
        }

        // Check for Secure Input (e.g., Terminal password prompts)
        if textAccessor?.isSecureInputEnabled() == true {
            PuntoLog.info("Secure Input enabled - conversion blocked for security")
            return
        }

        // Prevent race condition: block key press from clearing undo during conversion
        isConversionInProgress = true
        defer {
            isConversionInProgress = false
            let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            PuntoLog.info("⏱️ TOTAL conversion time: \(String(format: "%.1f", totalTime))ms")
        }

        // Ignore events during replacement to prevent re-capture
        hotkeyManager?.ignoreEvents = true

        // Check for undo possibility
        if let last = lastConversion,
           Date().timeIntervalSince(last.timestamp) < undoTimeout {
            // Undo: revert to original text
            PuntoLog.info("Undo: reverting '\(last.convertedText)' back to '\(last.originalText)'")

            if last.wasSelection {
                // Keep selection so user can press hotkey again to re-convert
                textAccessor?.setSelectedText(last.originalText, keepSelection: true)
            } else {
                // Use grapheme cluster count for correct backspace count
                let charCount = last.convertedText.count
                textAccessor?.replaceLastWord(wordLength: charCount, with: last.originalText)
            }

            // Switch layout back
            let originalLayout = layoutConverter!.detectLayout(last.originalText)
            switchLayoutIfEnabled(originalLayout)

            statusBarController?.flashIcon()
            lastConversion = nil

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.hotkeyManager?.ignoreEvents = false
            }
            return
        }

        var t1 = CFAbsoluteTimeGetCurrent()

        // Normal conversion
        if let selectedText = textAccessor?.getSelectedText(), !selectedText.isEmpty {
            let getTextTime = (CFAbsoluteTimeGetCurrent() - t1) * 1000
            PuntoLog.info("⏱️ getSelectedText: \(String(format: "%.1f", getTextTime))ms")

            PuntoLog.info("Converting selected text: '\(selectedText)'")
            let result = layoutConverter!.convertWithResult(selectedText)
            PuntoLog.info("Converted to: '\(result.text)'")

            t1 = CFAbsoluteTimeGetCurrent()
            // Keep selection so user can undo by pressing hotkey again
            textAccessor?.setSelectedText(result.text, keepSelection: true)
            let setTextTime = (CFAbsoluteTimeGetCurrent() - t1) * 1000
            PuntoLog.info("⏱️ setSelectedText: \(String(format: "%.1f", setTextTime))ms")

            statusBarController?.flashIcon()
            switchLayoutIfEnabled(result.targetLayout)

            // Save for undo
            lastConversion = LastConversion(
                originalText: selectedText,
                convertedText: result.text,
                timestamp: Date(),
                wasSelection: true
            )
        } else {
            let getTextTime = (CFAbsoluteTimeGetCurrent() - t1) * 1000
            PuntoLog.info("⏱️ getSelectedText (empty): \(String(format: "%.1f", getTextTime))ms")

            // No selection - convert last word
            if let lastWord = wordTracker?.getLastWord(), !lastWord.isEmpty {
                PuntoLog.info("Converting last word: '\(lastWord)'")
                let result = layoutConverter!.convertWithResult(lastWord)
                PuntoLog.info("Converted to: '\(result.text)'")

                t1 = CFAbsoluteTimeGetCurrent()
                textAccessor?.replaceLastWord(wordLength: lastWord.count, with: result.text)
                let replaceTime = (CFAbsoluteTimeGetCurrent() - t1) * 1000
                PuntoLog.info("⏱️ replaceLastWord: \(String(format: "%.1f", replaceTime))ms")

                wordTracker?.clear()
                statusBarController?.flashIcon()
                switchLayoutIfEnabled(result.targetLayout)

                // Save for undo
                lastConversion = LastConversion(
                    originalText: lastWord,
                    convertedText: result.text,
                    timestamp: Date(),
                    wasSelection: false
                )
            } else {
                PuntoLog.info("No text to convert")
            }
        }

        // Re-enable events after a delay (to let typed characters settle)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.hotkeyManager?.ignoreEvents = false
        }
    }

    private func switchLayoutIfEnabled(_ targetLayout: LayoutConverter.DetectedLayout) {
        guard settingsManager?.switchLayoutAfterConversion == true else { return }

        // Set flag to ignore the input source change notification we're about to trigger
        // This prevents WordTracker from being cleared by our own programmatic switch
        ignoreNextInputSourceChange = true

        switch targetLayout {
        case .english:
            inputSourceManager?.switchTo(KeyboardLanguage.english)
        case .russian:
            inputSourceManager?.switchTo(KeyboardLanguage.russian)
        case .mixed, .unknown:
            ignoreNextInputSourceChange = false  // Reset if no switch happened
        }
    }

    private func handleToggleCase() {
        guard settingsManager?.isEnabled == true else { return }

        hotkeyManager?.ignoreEvents = true

        if let selectedText = textAccessor?.getSelectedText(), !selectedText.isEmpty {
            PuntoLog.info("Toggling case for: '\(selectedText)'")
            let toggled = toggleCase(selectedText)
            textAccessor?.setSelectedText(toggled)
            statusBarController?.flashIcon()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.hotkeyManager?.ignoreEvents = false
        }
    }

    private func toggleCase(_ text: String) -> String {
        let uppercaseCount = text.filter { $0.isUppercase }.count
        let lowercaseCount = text.filter { $0.isLowercase }.count

        if uppercaseCount >= lowercaseCount {
            return text.lowercased()
        } else {
            return text.uppercased()
        }
    }

    // MARK: - Settings

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(settingsManager: settingsManager!)
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
