import Foundation

public enum ApplicationLayoutRestoreAction: Equatable {
    case skip
    case alreadyActive(layoutID: String)
    case switchTo(layoutID: String)
}

public enum ApplicationLayoutPolicy {
    public static func shouldRecordCurrentLayoutOnApplicationActivation(
        rememberInputSourceForEachApp: Bool
    ) -> Bool {
        guard rememberInputSourceForEachApp else {
            return false
        }

        // didActivateApplication observes the newly frontmost app. The current
        // TIS layout at that point must not be written under the previous app id.
        return false
    }

    public static func bundleIDForLayoutRestoreOnActivation(
        newBundleID: String?,
        ownBundleID: String?,
        isApplicationDisabled: Bool = false
    ) -> String? {
        guard let newBundleID = ApplicationBundleIDPolicy.normalized(newBundleID) else {
            return nil
        }

        guard !ApplicationBundleIDPolicy.isVolatileSystemContext(newBundleID) else {
            return nil
        }

        guard !isApplicationDisabled else {
            return nil
        }

        if newBundleID == ApplicationBundleIDPolicy.normalized(ownBundleID) {
            return nil
        }

        return newBundleID
    }

    public static func restoreActionOnActivation(
        newBundleID: String?,
        ownBundleID: String?,
        isApplicationDisabled: Bool = false,
        rememberedLayoutID: String?,
        currentLayoutID: String?
    ) -> ApplicationLayoutRestoreAction {
        guard bundleIDForLayoutRestoreOnActivation(
            newBundleID: newBundleID,
            ownBundleID: ownBundleID,
            isApplicationDisabled: isApplicationDisabled
        ) != nil,
              let rememberedLayoutID = normalizedLayoutID(rememberedLayoutID) else {
            return .skip
        }

        if normalizedLayoutID(currentLayoutID) == rememberedLayoutID {
            return .alreadyActive(layoutID: rememberedLayoutID)
        }

        return .switchTo(layoutID: rememberedLayoutID)
    }

    public static func layoutMemoryUpdateAfterProgrammaticSwitch(
        rememberInputSourceForEachApp: Bool,
        activeBundleID: String?,
        ownBundleID: String?,
        targetLayoutID: String?,
        didSwitch: Bool
    ) -> (bundleID: String, layoutID: String)? {
        let activeBundleID = ApplicationBundleIDPolicy.normalized(activeBundleID)
        let ownBundleID = ApplicationBundleIDPolicy.normalized(ownBundleID)
        let targetLayoutID = normalizedLayoutID(targetLayoutID)

        guard rememberInputSourceForEachApp,
              didSwitch,
              let activeBundleID,
              activeBundleID != ownBundleID,
              !ApplicationBundleIDPolicy.isVolatileSystemContext(activeBundleID),
              let targetLayoutID else {
            return nil
        }

        return (bundleID: activeBundleID, layoutID: targetLayoutID)
    }

    public static func layoutMemoryUpdateAfterObservedInputSourceChange(
        rememberInputSourceForEachApp: Bool,
        activeBundleID: String?,
        frontmostBundleID: String?,
        ownBundleID: String?,
        currentLayoutID: String?
    ) -> (bundleID: String, layoutID: String)? {
        let activeBundleID = ApplicationBundleIDPolicy.normalized(activeBundleID)
        let frontmostBundleID = ApplicationBundleIDPolicy.normalized(frontmostBundleID)
        let ownBundleID = ApplicationBundleIDPolicy.normalized(ownBundleID)
        let currentLayoutID = normalizedLayoutID(currentLayoutID)

        guard rememberInputSourceForEachApp,
              let activeBundleID,
              activeBundleID != ownBundleID,
              !ApplicationBundleIDPolicy.isVolatileSystemContext(activeBundleID),
              frontmostBundleID == activeBundleID,
              frontmostBundleID != ownBundleID,
              let currentLayoutID else {
            return nil
        }

        return (bundleID: activeBundleID, layoutID: currentLayoutID)
    }

    private static func normalizedLayoutID(_ layoutID: String?) -> String? {
        guard let layoutID else {
            return nil
        }

        let trimmed = layoutID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
