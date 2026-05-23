import Foundation

public enum ApplicationContextActivationAction: Equatable {
    case preserveCurrentExternalContext(logMessage: String)
    case activateExternal(ApplicationContextActivationPlan)
}

public struct ApplicationContextActivationPlan: Equatable {
    public let shouldResetTextState: Bool
    public let clearTrackedTextReason: String?
    public let clearConversionSessionReason: String?

    public init(
        shouldResetTextState: Bool,
        clearTrackedTextReason: String?,
        clearConversionSessionReason: String?
    ) {
        self.shouldResetTextState = shouldResetTextState
        self.clearTrackedTextReason = clearTrackedTextReason
        self.clearConversionSessionReason = clearConversionSessionReason
    }
}

public enum ApplicationContextPolicy {
    public static func activationAction(
        previousBundleID: String?,
        newBundleID: String?,
        ownBundleID: String?
    ) -> ApplicationContextActivationAction {
        if ApplicationBundleIDPolicy.normalized(newBundleID) == ApplicationBundleIDPolicy.normalized(ownBundleID),
           ApplicationBundleIDPolicy.normalized(ownBundleID) != nil {
            let preservedID = ApplicationBundleIDPolicy.normalized(previousBundleID) ?? "?"
            return .preserveCurrentExternalContext(
                logMessage: "Punto window activated - preserving last external app '\(preservedID)'"
            )
        }

        let shouldReset = shouldResetTextState(
            previousBundleID: previousBundleID,
            newBundleID: newBundleID,
            ownBundleID: ownBundleID
        )

        return .activateExternal(ApplicationContextActivationPlan(
            shouldResetTextState: shouldReset,
            clearTrackedTextReason: shouldReset ? "active application changed" : nil,
            clearConversionSessionReason: shouldReset ? "active application changed" : nil
        ))
    }

    public static func shouldResetTextState(
        previousBundleID: String?,
        newBundleID: String?,
        ownBundleID: String?
    ) -> Bool {
        let previousBundleID = ApplicationBundleIDPolicy.normalized(previousBundleID)
        let newBundleID = ApplicationBundleIDPolicy.normalized(newBundleID)
        let ownBundleID = ApplicationBundleIDPolicy.normalized(ownBundleID)

        guard let newBundleID else {
            return previousBundleID != nil
        }

        if newBundleID == ownBundleID {
            return false
        }

        guard let previousBundleID, !previousBundleID.isEmpty else {
            return false
        }

        return previousBundleID != newBundleID
    }
}
