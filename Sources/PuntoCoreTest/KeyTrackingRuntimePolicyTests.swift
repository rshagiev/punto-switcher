import Foundation
import PuntoCore

func runKeyTrackingRuntimePolicyTests() throws {
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .track,
        "key tracking runtime tracks normal enabled input"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipRouting(logMessage: "Key tracking skipped by routing policy"),
        "key tracking runtime skips when Punto is disabled"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipRouting(logMessage: "Key tracking skipped by routing policy"),
        "key tracking runtime skips disabled applications"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockSecureInput(context: "secure input", logMessage: "Key tracking skipped for secure/password input"),
        "key tracking runtime blocks secure input before tracking text"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockSecureInput(context: "password field", logMessage: "Key tracking skipped for secure/password input"),
        "key tracking runtime blocks password fields before tracking text"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "org.telegram.desktop",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .resetOnReturn,
        "key tracking runtime routes reset-on-return apps away from auto-correction"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "com.apple.TextEdit",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .runAutoCorrection,
        "key tracking runtime keeps ordinary editors eligible for return auto-correction"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "org.telegram.desktop",
            keyCode: 49,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .runAutoCorrection,
        "key tracking runtime ignores non-return keys for reset-on-return apps"
    )
    try expect(
        KeyTrackingRuntimePolicy.resetOnReturnPlan(
            consumedCompletedToken: true,
            bundleID: "org.telegram.desktop"
        ),
        KeyTrackingResetPlan(
            completedTokenStatisticsEvent: .completedWord,
            conversionSessionClearReason: "return in reset-on-return app",
            logMessage: "Auto-correction skipped and text state reset on Return for app 'org.telegram.desktop'"
        ),
        "key tracking runtime records completed word and clears undo for reset-on-return"
    )
    try expect(
        KeyTrackingRuntimePolicy.resetOnReturnPlan(
            consumedCompletedToken: false,
            bundleID: nil
        ),
        KeyTrackingResetPlan(
            completedTokenStatisticsEvent: nil,
            conversionSessionClearReason: "return in reset-on-return app",
            logMessage: "Auto-correction skipped and text state reset on Return for app '?'"
        ),
        "key tracking runtime handles reset-on-return without completed token"
    )
    try expect(
        KeyTrackingRuntimePolicy.conversionSessionClearReasonAfterAutoCorrection(isConversionInProgress: false),
        "key press",
        "key tracking runtime clears stale undo after ordinary non-converting key press"
    )
    try expectNil(
        KeyTrackingRuntimePolicy.conversionSessionClearReasonAfterAutoCorrection(isConversionInProgress: true),
        "key tracking runtime preserves undo while auto-correction conversion window is active"
    )
}
