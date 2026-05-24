import Foundation
import PuntoCore

func runAutoCorrectionPreflightPolicyTests() throws {
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "auto-correction preflight allows eligible completed token"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: "\n",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction on Enter/Tab disabled"),
        "auto-correction preflight consumes Return token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: "\t",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction on Enter/Tab disabled"),
        "auto-correction preflight consumes Tab token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: " ",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "auto-correction preflight still allows Space token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: " ",
            isCompletedTokenAutoCorrectionSuppressed: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "completed token auto-correction cancelled"),
        "auto-correction preflight consumes edited-token cancellation"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "Punto disabled"),
        "auto-correction preflight consumes token when Punto is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction disabled"),
        "auto-correction preflight consumes token when auto-correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "conversion in progress"),
        "auto-correction preflight consumes token during conversion window"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: true,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "current app disabled"),
        "auto-correction preflight consumes token for disabled app"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "no completed token"),
        "auto-correction preflight skips without token"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: true,
            isPasswordField: false
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction preflight clears state for secure input"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "auto-correction preflight clears state for password field"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction preflight prioritizes secure input"
    )
    try expect(
        AutoCorrectionPreflightPolicy.logMessage(for: .blockAndClear(reason: "password field")),
        "Auto-correction blocked for secure input",
        "auto-correction preflight preserves secure block log"
    )
}

