import AppKit

/// Shows the onboarding alert for first-time users
enum OnboardingAlert {

    /// Shows the permission request alert
    /// - Parameter completion: Called with `true` if user clicked "Open System Settings"
    static func show(completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Punto needs permissions"
        alert.informativeText = """
        To convert text in other apps, Punto needs Accessibility access.

        Click "Open System Settings" and add Punto to the list.
        """

        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

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
        alert.messageText = "Accessibility Access Denied"
        alert.informativeText = """
        Punto cannot function without Accessibility access.

        Please go to System Settings > Privacy & Security > Accessibility and enable Punto.
        """

        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Quit")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        } else {
            NSApplication.shared.terminate(nil)
        }
    }
}
