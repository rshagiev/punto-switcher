import AppKit
import Carbon
import PuntoCore

/// Main application delegate handling Cocoa lifecycle and UI wiring.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var runtime: ApplicationRuntimeContainer?

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        PuntoLog.prepareForNewSession()
        PuntoLog.info("=== Punto Starting ===")

        runtime = ApplicationRuntimeContainer { [weak self] in
            self?.statusBarController?.flashIcon()
        }
        PuntoLog.info("Settings manager initialized")
        PuntoLog.info("Core components initialized")

        guard let runtime else {
            PuntoLog.error("Failed to initialize runtime container")
            return
        }

        statusBarController = StatusBarController(
            settingsManager: runtime.settingsManager,
            onSettingsClick: { [weak self] in
                self?.showSettings()
            },
            onQuitClick: {
                NSApplication.shared.terminate(nil)
            },
            onEnabledChanged: { [weak self] wasEnabled, isEnabled in
                self?.runtime?.commandRuntime.handleGlobalEnabledChanged(
                    wasEnabled: wasEnabled,
                    isEnabled: isEnabled
                )
            },
            onToggleCurrentAppDisabled: { [weak self] in
                self?.runtime?.commandRuntime.toggleCurrentApplicationDisabled()
            },
            isCurrentAppDisabled: { [weak self] in
                self?.runtime?.commandRuntime.isCurrentApplicationDisabled() ?? false
            },
            currentAppBundleID: { [weak self] in
                self?.runtime?.appRuntime.effectiveCurrentApplicationBundleID(
                    frontmostApplication: NSWorkspace.shared.frontmostApplication
                )
            },
            currentAppName: { [weak self] in
                self?.runtime?.appRuntime.effectiveCurrentApplicationName(
                    frontmostApplication: NSWorkspace.shared.frontmostApplication
                )
            }
        )
        PuntoLog.info("Status bar initialized")

        _ = runtime.runStartupPresentationAndPermissionFlow()
        runtime.startInitialRuntimeState(frontmostApplication: NSWorkspace.shared.frontmostApplication)

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
            object: runtime.settingsManager
        )
        PuntoLog.info("Subscribed to input source preference changes")

        PuntoLog.info("=== Punto Started ===")
    }

    func applicationWillTerminate(_ notification: Notification) {
        PuntoLog.info("Punto terminating")
        runtime?.invalidate()
        DistributedNotificationCenter.default().removeObserver(self)
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Runtime Notifications

    @objc private func inputSourceChanged() {
        runtime?.handleInputSourceChanged(frontmostApplication: NSWorkspace.shared.frontmostApplication)
    }

    @objc private func activeApplicationChanged(_ notification: Notification) {
        let runningApp = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)
            ?? NSWorkspace.shared.frontmostApplication

        guard runtime?.handleActiveApplicationChanged(runningApplication: runningApp) == true else {
            return
        }

        statusBarController?.refreshCurrentApplicationState()
    }

    @objc private func inputSourcePreferencesChanged() {
        runtime?.handleInputSourcePreferencesChanged()
    }

    // MARK: - Settings

    private func showSettings() {
        guard let runtime else { return }

        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                settingsManager: runtime.settingsManager,
                currentApplication: { [weak self] in
                    self?.runtime?.currentSettingsApplication()
                },
                setLoginItemEnabled: { isEnabled in
                    LoginItemController.setEnabled(isEnabled, bundleIdentifier: Bundle.main.bundleIdentifier)
                },
                onToggleChanged: { [weak self] action in
                    self?.handleSettingsToggleChanged(action)
                }
            )
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func handleSettingsToggleChanged(_ action: SettingsToggleChangeAction) {
        for effect in action.effects {
            switch effect {
            case .updateStatusBarVisibility:
                statusBarController?.updateVisibility()
            case .applyAutoCorrectionRuntimeChange:
                runtime?.commandRuntime.handleAutoCorrectionSettingChanged(
                    wasEnabled: action.wasEnabled,
                    isEnabled: action.isEnabled
                )
            case .refreshCurrentApplicationState:
                statusBarController?.refreshCurrentApplicationState()
            case .setLoginItemEnabled,
                 .updateAdvancedSettingsVisibility:
                break
            }
        }
    }
}
