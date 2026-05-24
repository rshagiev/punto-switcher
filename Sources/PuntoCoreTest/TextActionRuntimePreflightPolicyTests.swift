import Foundation
import PuntoCore

func runTextActionRuntimePreflightPolicyTests() throws {
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false
        ),
        .proceed,
        "text action runtime preflight route allows normal conversion"
    )
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false
        ),
        .skip(reason: "manual conversion disabled"),
        "text action runtime preflight route keeps manual-conversion setting in route phase"
    )
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .selectedTextSearch,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false
        ),
        .proceed,
        "text action runtime preflight keeps selected-text search available when manual conversion is disabled"
    )
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .selectedTextSearch,
            isEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false
        ),
        .skip(reason: "selected text search already in progress"),
        "text action runtime preflight route blocks nested selected-text search"
    )
    try expect(
        TextActionRuntimePreflightPolicy.securityAction(
            kind: .selectedTextSearch,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "text action runtime preflight security gives secure input priority"
    )
    try expect(
        TextActionRuntimePreflightPolicy.securityAction(
            kind: .toggleCase,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "text action runtime preflight security blocks password fields"
    )
}
