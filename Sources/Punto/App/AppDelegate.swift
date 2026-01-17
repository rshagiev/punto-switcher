import AppKit
import ApplicationServices

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
            onKeyPress: { [weak wordTracker] keyCode, characters in
                wordTracker?.trackKeyPress(keyCode: keyCode, characters: characters)
            }
        )

        hotkeyManager?.start()
    }

    // MARK: - Actions

    private func handleConvertLayout() {
        guard settingsManager?.isEnabled == true else {
            PuntoLog.info("Disabled, skipping conversion")
            return
        }

        // Ignore events during replacement to prevent re-capture
        hotkeyManager?.ignoreEvents = true

        // Try to get selected text first
        if let selectedText = textAccessor?.getSelectedText(), !selectedText.isEmpty {
            PuntoLog.info("Converting selected text: '\(selectedText)'")
            let result = layoutConverter!.convertWithResult(selectedText)
            PuntoLog.info("Converted to: '\(result.text)'")
            textAccessor?.setSelectedText(result.text)
            statusBarController?.flashIcon()
            switchLayoutIfEnabled(result.targetLayout)
        } else {
            // No selection - convert last word
            if let lastWord = wordTracker?.getLastWord(), !lastWord.isEmpty {
                PuntoLog.info("Converting last word: '\(lastWord)'")
                let result = layoutConverter!.convertWithResult(lastWord)
                PuntoLog.info("Converted to: '\(result.text)'")
                textAccessor?.replaceLastWord(wordLength: lastWord.count, with: result.text)
                wordTracker?.clear()
                statusBarController?.flashIcon()
                switchLayoutIfEnabled(result.targetLayout)
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

        switch targetLayout {
        case .english:
            inputSourceManager?.switchTo(.english)
        case .russian:
            inputSourceManager?.switchTo(.russian)
        case .mixed, .unknown:
            break
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
