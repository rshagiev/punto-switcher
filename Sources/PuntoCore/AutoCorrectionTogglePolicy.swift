import Foundation

public struct AutoCorrectionToggleAction: Equatable {
    public let newEnabledValue: Bool
    public let clearTrackedTextReason: String
    public let clearConversionSessionReason: String
    public let logMessage: String
    public let shouldFlashIcon: Bool

    public init(
        newEnabledValue: Bool,
        clearTrackedTextReason: String,
        clearConversionSessionReason: String,
        logMessage: String,
        shouldFlashIcon: Bool
    ) {
        self.newEnabledValue = newEnabledValue
        self.clearTrackedTextReason = clearTrackedTextReason
        self.clearConversionSessionReason = clearConversionSessionReason
        self.logMessage = logMessage
        self.shouldFlashIcon = shouldFlashIcon
    }
}

public enum AutoCorrectionTogglePolicy {
    public static func action(wasEnabled: Bool) -> AutoCorrectionToggleAction {
        let isEnabled = !wasEnabled
        return AutoCorrectionToggleAction(
            newEnabledValue: isEnabled,
            clearTrackedTextReason: "auto-correction toggled",
            clearConversionSessionReason: "auto-correction toggled",
            logMessage: "Auto-correction \(isEnabled ? "enabled" : "disabled") by hotkey",
            shouldFlashIcon: true
        )
    }
}
