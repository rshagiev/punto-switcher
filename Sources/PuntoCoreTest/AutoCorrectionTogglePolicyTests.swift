import Foundation
import PuntoCore

func runAutoCorrectionTogglePolicyTests() throws {
    try expect(
        AutoCorrectionTogglePolicy.action(wasEnabled: true),
        AutoCorrectionToggleAction(
            newEnabledValue: false,
            clearTrackedTextReason: "auto-correction toggled",
            clearConversionSessionReason: "auto-correction toggled",
            logMessage: "Auto-correction disabled by hotkey",
            shouldFlashIcon: true
        ),
        "auto-correction toggle policy disables enabled setting and clears runtime state"
    )
    try expect(
        AutoCorrectionTogglePolicy.action(wasEnabled: false),
        AutoCorrectionToggleAction(
            newEnabledValue: true,
            clearTrackedTextReason: "auto-correction toggled",
            clearConversionSessionReason: "auto-correction toggled",
            logMessage: "Auto-correction enabled by hotkey",
            shouldFlashIcon: true
        ),
        "auto-correction toggle policy enables disabled setting and clears runtime state"
    )
}
