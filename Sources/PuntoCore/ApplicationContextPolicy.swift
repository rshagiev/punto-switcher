import Foundation

public enum ApplicationContextPolicy {
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
