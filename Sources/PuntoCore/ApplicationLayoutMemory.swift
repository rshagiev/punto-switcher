import Foundation

public final class ApplicationLayoutMemory {
    private var layoutsByBundleID: [String: String]

    public init(layoutsByBundleID: [String: String] = [:]) {
        self.layoutsByBundleID = Self.normalizedSnapshot(layoutsByBundleID)
    }

    public func remember(bundleID: String?, layoutID: String?) {
        guard let bundleID = ApplicationBundleIDPolicy.normalized(bundleID),
              let layoutID = Self.normalizedLayoutID(layoutID) else {
            return
        }

        layoutsByBundleID[bundleID] = layoutID
    }

    public func layoutID(for bundleID: String?) -> String? {
        guard let bundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return nil
        }
        return layoutsByBundleID[bundleID]
    }

    public func forget(bundleID: String?) {
        guard let bundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return
        }
        layoutsByBundleID.removeValue(forKey: bundleID)
    }

    public func snapshot() -> [String: String] {
        layoutsByBundleID
    }

    public func replaceAll(with layoutsByBundleID: [String: String]) {
        self.layoutsByBundleID = Self.normalizedSnapshot(layoutsByBundleID)
    }

    public static func normalizedSnapshot(_ layoutsByBundleID: [String: String]) -> [String: String] {
        var normalized: [String: String] = [:]
        for (bundleID, layoutID) in layoutsByBundleID {
            guard let normalizedBundleID = ApplicationBundleIDPolicy.normalized(bundleID),
                  let normalizedLayoutID = normalizedLayoutID(layoutID) else {
                continue
            }
            normalized[normalizedBundleID] = normalizedLayoutID
        }
        return normalized
    }

    private static func normalizedLayoutID(_ layoutID: String?) -> String? {
        guard let layoutID else {
            return nil
        }
        let trimmed = layoutID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
