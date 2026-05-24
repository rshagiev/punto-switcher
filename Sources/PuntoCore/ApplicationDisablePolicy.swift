import Foundation

public struct ApplicationDisableToggleAction: Equatable {
    public let bundleID: String
    public let disabled: Bool
    public let shouldClearState: Bool
    public let clearTrackedTextReason: String?
    public let clearConversionSessionReason: String?

    public init(
        bundleID: String,
        disabled: Bool,
        shouldClearState: Bool,
        clearTrackedTextReason: String? = nil,
        clearConversionSessionReason: String? = nil
    ) {
        self.bundleID = bundleID
        self.disabled = disabled
        self.shouldClearState = shouldClearState
        self.clearTrackedTextReason = clearTrackedTextReason
        self.clearConversionSessionReason = clearConversionSessionReason
    }
}

public struct ApplicationDisableMenuState: Equatable {
    public let title: String
    public let isEnabled: Bool
    public let isChecked: Bool

    public init(title: String, isEnabled: Bool, isChecked: Bool) {
        self.title = title
        self.isEnabled = isEnabled
        self.isChecked = isChecked
    }
}

public enum ApplicationDisablePolicy {
    public static let defaultDisabledBundleIDs: [String] = []
    public static let defaultCompletelyDisableInExceptionApplications = false
    public static let legacyDisabledAppsKey = "disabledApps"
    public static let legacyCompletelyDisableInExceptionApplicationsKey = "CompletelyDisableInExceptionApps"

    public static func isApplicationDisabled(bundleID: String?, disabledBundleIDs: Set<String>) -> Bool {
        guard let bundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return false
        }

        for disabledID in disabledBundleIDs {
            guard let disabledID = ApplicationBundleIDPolicy.normalized(disabledID) else {
                continue
            }

            if bundleID == disabledID || bundleID.hasPrefix(disabledID + ".") {
                return true
            }
        }

        return false
    }

    public static func isApplicationCompletelyDisabled(
        bundleID: String?,
        disabledBundleIDs: Set<String>,
        completelyDisableInExceptionApplications: Bool
    ) -> Bool {
        completelyDisableInExceptionApplications && isApplicationDisabled(
            bundleID: bundleID,
            disabledBundleIDs: disabledBundleIDs
        )
    }

    public static func disabledBundleIDsAfterSet(
        bundleID: String?,
        disabled: Bool,
        disabledBundleIDs: Set<String>
    ) -> Set<String> {
        var ids = normalizedSet(disabledBundleIDs)
        guard let normalizedBundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return ids
        }

        if disabled {
            ids = Set(ids.filter { disabledID in
                normalizedBundleID != disabledID
                    && !normalizedBundleID.hasPrefix(disabledID + ".")
                    && !disabledID.hasPrefix(normalizedBundleID + ".")
            })
            ids.insert(normalizedBundleID)
            return ids
        }

        return Set(ids.filter { normalizedDisabledID in
            return normalizedBundleID != normalizedDisabledID
                && !normalizedBundleID.hasPrefix(normalizedDisabledID + ".")
                && !normalizedDisabledID.hasPrefix(normalizedBundleID + ".")
        })
    }

    public static func normalizedSet(_ bundleIDs: Set<String>) -> Set<String> {
        ApplicationBundleIDPolicy.normalizedSet(bundleIDs)
    }

    public static func effectiveDisabledBundleIDs(
        hasPersistedValue: Bool,
        persistedValue: Set<String>,
        hasLegacyValue: Bool,
        legacyValue: Set<String>,
        defaultValue: [String] = []
    ) -> Set<String> {
        if hasPersistedValue {
            return normalizedSet(persistedValue)
        }

        if hasLegacyValue {
            return normalizedSet(legacyValue)
        }

        return normalizedSet(Set(defaultValue))
    }

    public static func toggleAction(
        bundleID: String?,
        ownBundleID: String?,
        isCurrentlyDisabled: Bool
    ) -> ApplicationDisableToggleAction? {
        guard let bundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return nil
        }

        if let ownBundleID = ApplicationBundleIDPolicy.normalized(ownBundleID),
           bundleID == ownBundleID {
            return nil
        }

        let nextDisabled = !isCurrentlyDisabled
        return ApplicationDisableToggleAction(
            bundleID: bundleID,
            disabled: nextDisabled,
            shouldClearState: nextDisabled,
            clearTrackedTextReason: nextDisabled ? "disabled current app" : nil,
            clearConversionSessionReason: nextDisabled ? "disabled current app" : nil
        )
    }

    public static func toggleLogMessage(
        action: ApplicationDisableToggleAction,
        applicationName: String?
    ) -> String {
        let name = normalizedDisplayName(applicationName) ?? action.bundleID
        return "\(action.disabled ? "Disabled" : "Enabled") Punto in app '\(name)' (\(action.bundleID))"
    }

    public static func menuStateForCurrentApplication(
        bundleID: String?,
        ownBundleID: String?,
        displayName: String?,
        isCurrentlyDisabled: Bool
    ) -> ApplicationDisableMenuState {
        guard let bundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return ApplicationDisableMenuState(
                title: "No Current App",
                isEnabled: false,
                isChecked: false
            )
        }

        if let ownBundleID = ApplicationBundleIDPolicy.normalized(ownBundleID),
           bundleID == ownBundleID {
            return ApplicationDisableMenuState(
                title: "No Current App",
                isEnabled: false,
                isChecked: false
            )
        }

        let name = normalizedDisplayName(displayName) ?? "Current App"
        return ApplicationDisableMenuState(
            title: isCurrentlyDisabled ? "Enable in \(name)" : "Disable in \(name)",
            isEnabled: true,
            isChecked: isCurrentlyDisabled
        )
    }

    private static func normalizedDisplayName(_ displayName: String?) -> String? {
        guard let displayName else {
            return nil
        }

        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
