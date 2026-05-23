import AppKit
import PuntoCore

/// Shows the onboarding alert for first-time users
enum OnboardingAlert {

    /// Shows the permission request alert
    /// - Parameter completion: Called with `true` if user clicked "Open System Settings"
    static func show(completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = AccessibilityPreferencesPolicy.permissionRequestTitle
        alert.informativeText = AccessibilityPreferencesPolicy.permissionRequestMessage

        alert.addButton(withTitle: AccessibilityPreferencesPolicy.openSettingsButtonTitle)
        alert.addButton(withTitle: AccessibilityPreferencesPolicy.cancelButtonTitle)

        // Set the icon
        if let appIcon = NSImage(named: NSImage.applicationIconName) {
            alert.icon = appIcon
        }

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            completion(true)
        default:
            completion(false)
        }
    }

    /// Shows an alert when accessibility is denied
    static func showAccessibilityDenied() {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = AccessibilityPreferencesPolicy.permissionDeniedTitle
        alert.informativeText = AccessibilityPreferencesPolicy.permissionDeniedMessage

        alert.addButton(withTitle: AccessibilityPreferencesPolicy.openSettingsButtonTitle)
        alert.addButton(withTitle: AccessibilityPreferencesPolicy.quitButtonTitle)

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(AccessibilityPreferencesPolicy.preferencesURL)
        } else {
            NSApplication.shared.terminate(nil)
        }
    }
}
