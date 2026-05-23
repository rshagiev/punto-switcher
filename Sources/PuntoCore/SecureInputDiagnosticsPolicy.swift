import Foundation

public struct SecureInputDiagnosticsSnapshot: Equatable {
    public let secureInputState: Bool
    public let context: String
    public let currentApp: String?
    public let runningApps: [String]
    public let enabledLayouts: [String]

    public init(
        secureInputState: Bool,
        context: String,
        currentApp: String?,
        runningApps: [String],
        enabledLayouts: [String]
    ) {
        self.secureInputState = secureInputState
        self.context = context
        self.currentApp = currentApp
        self.runningApps = runningApps
        self.enabledLayouts = enabledLayouts
    }
}

public enum SecureInputDiagnosticsPolicy {
    public static let observedPlistFilename = "punto.SecureInput.plist"
    public static let secureInputStateKey = "SecureInputState"
    public static let contextKey = "Context"
    public static let currentAppKey = "currentApp"
    public static let runningAppsKey = "runningApps"
    public static let enabledLayoutsKey = "enabledLayouts"

    public static func normalizedBundleIDs(_ bundleIDs: [String?]) -> [String] {
        var seen = Set<String>()
        var normalized: [String] = []
        for bundleID in bundleIDs {
            guard let value = ApplicationBundleIDPolicy.normalized(bundleID),
                  !seen.contains(value) else {
                continue
            }
            seen.insert(value)
            normalized.append(value)
        }
        return normalized
    }

    public static func normalizedLayoutIDs(_ layoutIDs: [String?]) -> [String] {
        var seen = Set<String>()
        var normalized: [String] = []
        for layoutID in layoutIDs {
            guard let value = InputSourceSelectionPolicy.normalizedSourceID(layoutID),
                  !seen.contains(value) else {
                continue
            }
            seen.insert(value)
            normalized.append(value)
        }
        return normalized
    }

    public static func snapshot(
        secureInputState: Bool,
        context: String,
        currentApp: String?,
        runningApps: [String?],
        enabledLayouts: [String?]
    ) -> SecureInputDiagnosticsSnapshot {
        SecureInputDiagnosticsSnapshot(
            secureInputState: secureInputState,
            context: context.trimmingCharacters(in: .whitespacesAndNewlines),
            currentApp: ApplicationBundleIDPolicy.normalized(currentApp),
            runningApps: normalizedBundleIDs(runningApps),
            enabledLayouts: normalizedLayoutIDs(enabledLayouts)
        )
    }

    public static func plistDictionary(from snapshot: SecureInputDiagnosticsSnapshot) -> [String: Any] {
        [
            secureInputStateKey: snapshot.secureInputState,
            contextKey: snapshot.context,
            currentAppKey: snapshot.currentApp ?? "",
            runningAppsKey: snapshot.runningApps,
            enabledLayoutsKey: snapshot.enabledLayouts
        ]
    }
}
