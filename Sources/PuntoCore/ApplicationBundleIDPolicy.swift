import Foundation

public enum ApplicationBundleIDPolicy {
    public static let screenSaverEngineBundleID = "com.apple.screensaver.engine"

    public static func normalized(_ bundleID: String?) -> String? {
        guard let bundleID else {
            return nil
        }

        let trimmed = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed.lowercased()
    }

    public static func normalizedSet(_ bundleIDs: Set<String>) -> Set<String> {
        Set(bundleIDs.compactMap(normalized))
    }

    public static func isScreenSaverEngine(_ bundleID: String?) -> Bool {
        normalized(bundleID) == screenSaverEngineBundleID
    }

    public static func isVolatileSystemContext(_ bundleID: String?) -> Bool {
        isScreenSaverEngine(bundleID)
    }
}
