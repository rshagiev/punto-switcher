import Foundation
import PuntoCore

func runApplicationDisablePolicyTests() throws {
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"]
        ),
        true,
        "application disable policy matches bundle prefix"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoft",
            disabledBundleIDs: ["com.microsoft"]
        ),
        true,
        "application disable policy matches exact bundle id"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoftWord",
            disabledBundleIDs: ["com.microsoft"]
        ),
        false,
        "application disable policy rejects glued prefix"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "  COM.MICROSOFT.Excel  ",
            disabledBundleIDs: [" com.microsoft "]
        ),
        true,
        "application disable policy normalizes case and whitespace"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: nil,
            disabledBundleIDs: ["com.microsoft"]
        ),
        false,
        "application disable policy ignores missing bundle id"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: false
        ),
        false,
        "application disable policy keeps exception apps partially disabled by default"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: true
        ),
        true,
        "application disable policy fully disables exception apps when configured"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.example.editor",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: true
        ),
        false,
        "application disable policy does not fully disable unrelated apps"
    )
    try expect(
        ApplicationDisablePolicy.canDisableApplication(
            bundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto"
        ),
        true,
        "application disable policy allows external app disable after normalization"
    )
    try expect(
        ApplicationDisablePolicy.canDisableApplication(
            bundleID: " COM.Example.Punto ",
            ownBundleID: "com.example.punto"
        ),
        false,
        "application disable policy refuses to disable Punto itself after normalization"
    )
    try expect(
        ApplicationDisablePolicy.canDisableApplication(
            bundleID: nil,
            ownBundleID: "com.example.punto"
        ),
        false,
        "application disable policy refuses missing app ids"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: " com.example.App ",
            disabled: true,
            disabledBundleIDs: ["com.other.App"]
        ),
        ["com.example.app", "com.other.app"],
        "application disable policy stores normalized ids"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "COM.MICROSOFT.Word",
            disabled: true,
            disabledBundleIDs: [" com.microsoft ", "com.other.App"]
        ),
        ["com.microsoft.word", "com.other.app"],
        "application disable policy replaces matching prefix with specific disabled app"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft",
            disabled: true,
            disabledBundleIDs: ["com.microsoft.Word", "com.other.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy replaces covered child ids with broader prefix"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft.Word",
            disabled: false,
            disabledBundleIDs: ["com.microsoft", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes matching disabled prefix"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "COM.MICROSOFT.Word",
            disabled: false,
            disabledBundleIDs: [" com.microsoft ", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes matching prefix case-insensitively"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft",
            disabled: false,
            disabledBundleIDs: ["com.microsoft.Word", "com.microsoft.Excel", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes child ids when enabling broader app family"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoftWord",
            disabled: false,
            disabledBundleIDs: ["com.microsoft", "com.other.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy keeps glued prefix when enabling app"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: nil,
            disabled: false,
            disabledBundleIDs: [" com.microsoft ", "", "COM.OTHER.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy normalizes persisted ids when bundle id is missing"
    )
    try expect(
        ApplicationDisablePolicy.normalizedSet([" com.microsoft ", "", "COM.OTHER.App"]),
        ["com.microsoft", "com.other.app"],
        "application disable policy normalizes disabled-app set"
    )
    try expect(
        ApplicationDisablePolicy.toggleAction(
            bundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableToggleAction(
            bundleID: "com.example.editor",
            disabled: true,
            shouldClearState: true,
            clearTrackedTextReason: "disabled current app",
            clearConversionSessionReason: "disabled current app"
        ),
        "application disable policy disables current external app and clears state"
    )
    try expect(
        ApplicationDisablePolicy.toggleAction(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: true
        ),
        ApplicationDisableToggleAction(
            bundleID: "com.example.editor",
            disabled: false,
            shouldClearState: false
        ),
        "application disable policy re-enables current external app without clearing state"
    )
    try expect(
        ApplicationDisablePolicy.toggleLogMessage(
            action: ApplicationDisableToggleAction(
                bundleID: "com.example.editor",
                disabled: true,
                shouldClearState: true,
                clearTrackedTextReason: "disabled current app",
                clearConversionSessionReason: "disabled current app"
            ),
            applicationName: " TextEdit "
        ),
        "Disabled Punto in app 'TextEdit' (com.example.editor)",
        "application disable policy trims display name in toggle log"
    )
    try expect(
        ApplicationDisablePolicy.toggleLogMessage(
            action: ApplicationDisableToggleAction(
                bundleID: "com.example.editor",
                disabled: false,
                shouldClearState: false
            ),
            applicationName: "   "
        ),
        "Enabled Punto in app 'com.example.editor' (com.example.editor)",
        "application disable policy falls back to bundle id in toggle log"
    )
    try expectNil(
        ApplicationDisablePolicy.toggleAction(
            bundleID: " COM.Example.Punto ",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        "application disable policy refuses to disable Punto itself"
    )
    try expectNil(
        ApplicationDisablePolicy.toggleAction(
            bundleID: nil,
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        "application disable policy ignores missing current app id"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            displayName: " TextEdit ",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "Disable in TextEdit",
            isEnabled: true,
            isChecked: false
        ),
        "application disable policy shows enabled disable action for current external app"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            displayName: "TextEdit",
            isCurrentlyDisabled: true
        ),
        ApplicationDisableMenuState(
            title: "Enable in TextEdit",
            isEnabled: true,
            isChecked: true
        ),
        "application disable policy shows checked enable action for disabled current app"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            displayName: "   ",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "Disable in Current App",
            isEnabled: true,
            isChecked: false
        ),
        "application disable policy falls back to generic current app title"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.punto",
            ownBundleID: " COM.Example.Punto ",
            displayName: "Punto",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "No Current App",
            isEnabled: false,
            isChecked: false
        ),
        "application disable policy disables menu action for Punto itself"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: nil,
            ownBundleID: "com.example.punto",
            displayName: "Unknown",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "No Current App",
            isEnabled: false,
            isChecked: false
        ),
        "application disable policy disables menu action without current bundle id"
    )
}
