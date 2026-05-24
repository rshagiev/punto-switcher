import Foundation
import PuntoCore

func runTextActionPreflightPolicyTests() throws {
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "text action preflight allows normal conversion"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "toggle case disabled"),
        "text action preflight skips disabled toggle case"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "manual conversion disabled"),
        "text action preflight skips manual layout conversion when manually disabled"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "text action preflight keeps toggle-case available when manual conversion is disabled"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "conversion already in progress"),
        "text action preflight skips nested conversion"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "current app disabled"),
        "text action preflight skips disabled application"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: false
        ),
        .blockAndClear(reason: "secure input"),
        "text action preflight clears state for secure input"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "text action preflight clears state for password fields"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "text action preflight gives secure input priority over password field"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .blockAndClear(reason: "password field"),
            kind: .toggleCase
        ),
        "Password field detected - toggle case blocked",
        "text action preflight preserves toggle-case password log"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .skip(reason: "manual conversion disabled"),
            kind: .layoutConversion
        ),
        "Manual conversion disabled, skipping conversion",
        "text action preflight preserves manual-conversion-disabled log"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .skip(reason: "current app disabled"),
            kind: .layoutConversion
        ),
        "Current app disabled, skipping conversion",
        "text action preflight preserves conversion disabled-app log"
    )
}
