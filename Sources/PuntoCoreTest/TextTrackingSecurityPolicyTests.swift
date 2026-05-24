import Foundation
import PuntoCore

func runTextTrackingSecurityPolicyTests() throws {
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: false, isPasswordField: false),
        true,
        "text tracking security allows normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: true, isPasswordField: false),
        false,
        "text tracking security blocks secure input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: false, isPasswordField: true),
        false,
        "text tracking security blocks password fields"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: true, isPasswordField: true),
        false,
        "text tracking security blocks combined secure password context"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: false, isPasswordField: false),
        false,
        "text tracking security keeps state for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: true, isPasswordField: false),
        true,
        "text tracking security clears state for secure input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: false, isPasswordField: true),
        true,
        "text tracking security clears state for password fields"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: true, isPasswordField: true),
        true,
        "text tracking security clears state for combined secure password context"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: false, isPasswordField: false),
        false,
        "text tracking security skips secure diagnostics for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: true, isPasswordField: false),
        true,
        "text tracking security writes secure diagnostics when secure input blocks tracking"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: false, isPasswordField: true),
        true,
        "text tracking security writes secure diagnostics when password fields block tracking"
    )
    try expectNil(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: false, isPasswordField: false),
        "text tracking security omits secure diagnostics context for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: true, isPasswordField: false),
        "secure input",
        "text tracking security reports secure-input diagnostics context"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: false, isPasswordField: true),
        "password field",
        "text tracking security reports password-field diagnostics context"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: true, isPasswordField: true),
        "secure input",
        "text tracking security gives secure input diagnostics priority over password field"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: false, isPasswordField: false),
        TextTrackingSecurityClearAction(clearTrackedText: false, clearConversionSession: false),
        "text tracking security keeps state for normal clear action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: true, isPasswordField: false),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "secure input",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security owns secure-input state cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: false, isPasswordField: true),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "password field",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security owns password-field state cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: true, isPasswordField: true),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "secure input",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security gives secure input priority in combined cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: "AXSecureTextField"),
        true,
        "text tracking security detects secure text subrole"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXSecureTextField", subrole: nil),
        true,
        "text tracking security detects secure text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: " axsecuretextfield ", subrole: nil),
        true,
        "text tracking security normalizes secure text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: " AX Secure Text Field ", subrole: nil),
        true,
        "text tracking security shares AX role normalization with accessibility role policy"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: "AXPasswordTextField"),
        true,
        "text tracking security detects password-like subrole"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: nil),
        false,
        "text tracking security allows ordinary text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXWebArea", subrole: "AXSearchField"),
        false,
        "text tracking security allows ordinary web/search text roles"
    )

    let diagnosticsSnapshot = SecureInputDiagnosticsPolicy.snapshot(
        secureInputState: true,
        context: " secure text input ",
        currentApp: " COM.Apple.Terminal ",
        runningApps: ["com.apple.Terminal", "COM.APPLE.TERMINAL", nil, " "],
        enabledLayouts: ["com.apple.keylayout.ABC", "UNDEFINED", " com.apple.keylayout.Russian "]
    )
    try expect(
        diagnosticsSnapshot,
        SecureInputDiagnosticsSnapshot(
            secureInputState: true,
            context: "secure text input",
            currentApp: "com.apple.terminal",
            runningApps: ["com.apple.terminal"],
            enabledLayouts: ["com.apple.keylayout.ABC", "com.apple.keylayout.Russian"]
        ),
        "secure input diagnostics policy normalizes Punto Switcher-style plist fields"
    )
    let diagnosticsDictionary = SecureInputDiagnosticsPolicy.plistDictionary(from: diagnosticsSnapshot)
    try expect(
        SecureInputDiagnosticsPolicy.secureInputDiagnosticsPlistFilename,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.plistFilename,
        "secure input diagnostics policy aligns plist filename to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.secureInputStateKey] as? Bool,
        true,
        "secure input diagnostics writes SecureInputState key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.secureInputStateKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.secureInputStateKey,
        "secure input diagnostics policy aligns secure input key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.contextKey] as? String,
        "secure text input",
        "secure input diagnostics writes Context key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.contextKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.contextKey,
        "secure input diagnostics policy aligns context key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.currentAppKey] as? String,
        "com.apple.terminal",
        "secure input diagnostics writes currentApp key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.currentAppKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.currentAppKey,
        "secure input diagnostics policy aligns current-app key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.runningAppsKey] as? [String],
        ["com.apple.terminal"],
        "secure input diagnostics writes runningApps key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.runningAppsKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.runningAppsKey,
        "secure input diagnostics policy aligns running-apps key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.enabledLayoutsKey] as? [String],
        ["com.apple.keylayout.ABC", "com.apple.keylayout.Russian"],
        "secure input diagnostics writes enabledLayouts key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.enabledLayoutsKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.enabledLayoutsKey,
        "secure input diagnostics policy aligns enabled-layouts key to reverse-audit anchor"
    )
}
