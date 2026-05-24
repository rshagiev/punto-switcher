import AppKit
import ApplicationServices
import Foundation
import PuntoCore
import PuntoSettings

/// App-side executor for startup presentation and Accessibility permission flow.
///
/// PuntoCore owns the observed installer/update/welcome and permission-copy
/// contracts. This coordinator applies them to UserDefaults, alerts, System
/// Settings opening, and permission polling.
final class StartupRuntimeCoordinator {
    private let settingsManager: SettingsManager
    private let startHotkeyManager: () -> Void
    private var permissionCheckTimer: Timer?

    init(
        settingsManager: SettingsManager,
        startHotkeyManager: @escaping () -> Void
    ) {
        self.settingsManager = settingsManager
        self.startHotkeyManager = startHotkeyManager
    }

    @discardableResult
    func runStartupPresentationAndPermissionFlow(arguments: [String] = CommandLine.arguments) -> Bool {
        var updateSettings = settingsManager.applicationUpdateSettings

        if StartupPresentationPolicy.shouldHandleInstallArgument(arguments) {
            PuntoLog.info(StartupPresentationPolicy.installArgumentHandlerLogName)
            updateSettings = StartupPresentationPolicy.updateSettingsAfterInstallArgument(updateSettings)
            settingsManager.applicationUpdateSettings = updateSettings
            PuntoLog.info(StartupPresentationPolicy.nativeInstalledTooltipMessage)
        }

        if StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: settingsManager.isFirstLaunch,
            updateSettings: updateSettings
        ) {
            PuntoLog.info(StartupPresentationPolicy.observedWelcomeLogMessage)
            showOnboardingAlert()
            settingsManager.consumeFirstLaunchPresentationFlags()
            updateSettings = StartupPresentationPolicy.updateSettingsAfterWelcome(updateSettings)
            settingsManager.applicationUpdateSettings = updateSettings
        }

        if StartupPresentationPolicy.shouldDisplayUpdateFinishedTooltip(updateSettings: updateSettings) {
            PuntoLog.info(StartupPresentationPolicy.updateFinishedTooltipLogName)
            PuntoLog.info(StartupPresentationPolicy.nativeUpdatedTooltipMessage)
            updateSettings = StartupPresentationPolicy.updateSettingsAfterUpdateFinishedTooltip(updateSettings)
            settingsManager.applicationUpdateSettings = updateSettings
            settingsManager.consumeUpdatePresentationImportFlags()
        }

        let trusted = requestAccessibilityTrustIfNeeded()
        PuntoLog.info("Accessibility trusted: \(trusted)")
        PuntoLog.info(trusted
            ? StartupPresentationPolicy.observedAccessibilityEnabledLogMessage
            : StartupPresentationPolicy.observedAccessibilityDisabledLogMessage
        )

        if !trusted {
            DispatchQueue.main.asyncAfter(deadline: ConversionProtectionPolicy.startupPermissionAlertDeadline(now: .now())) { [weak self] in
                self?.showPermissionAlert()
            }
            startPermissionCheckTimer()
        }

        return trusted
    }

    func invalidate() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }

    private func startPermissionCheckTimer() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkPermissionsAndStart()
        }
    }

    private func checkPermissionsAndStart() {
        if AXIsProcessTrusted() {
            PuntoLog.info("Accessibility permissions granted!")
            invalidate()
            startHotkeyManager()
        }
    }

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
}
