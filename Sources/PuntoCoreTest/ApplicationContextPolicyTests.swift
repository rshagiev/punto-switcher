import Foundation
import PuntoCore

func runApplicationContextPolicyTests() throws {
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto"
        ),
        .preserveCurrentExternalContext(
            logMessage: "Punto window activated - preserving last external app 'com.example.editor'"
        ),
        "app context policy preserves external context when Punto activates"
    )
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.chat",
            ownBundleID: "com.example.punto"
        ),
        .activateExternal(ApplicationContextActivationPlan(
            shouldResetTextState: true,
            clearTrackedTextReason: "active application changed",
            clearConversionSessionReason: "active application changed"
        )),
        "app context policy plans external app-switch cleanup"
    )
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: nil,
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        .activateExternal(ApplicationContextActivationPlan(
            shouldResetTextState: false,
            clearTrackedTextReason: nil,
            clearConversionSessionReason: nil
        )),
        "app context policy keeps initial external activation clean"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: nil,
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy keeps empty initial context"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy keeps same app context"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: " COM.Example.Editor ",
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy normalizes app context ids"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.chat",
            ownBundleID: "com.example.punto"
        ),
        true,
        "app context policy resets text state on external app switch"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy preserves state when Punto window activates"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: " COM.EXAMPLE.PUNTO ",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy normalizes own app id"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: nil,
            ownBundleID: "com.example.punto"
        ),
        true,
        "app context policy resets when external app context is lost"
    )
}
