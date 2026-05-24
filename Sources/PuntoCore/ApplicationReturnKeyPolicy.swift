import Foundation

public enum ApplicationReturnKeyPolicy {
    public static let returnKeyCode: UInt16 = 36
    public static let enterKeyCode: UInt16 = 76
    public static let defaultResetBundleComponents: Set<String> = ["telegram"]
    public static let legacyResetOnReturnKey = "switcher.reset_on_return"

    public static func normalizedResetBundleComponents(_ components: Set<String>) -> Set<String> {
        ApplicationBundleIDPolicy.normalizedSet(components)
    }

    public static func effectiveResetBundleComponents(
        hasPersistedComponents: Bool,
        persistedComponents: Set<String>?,
        hasLegacyComponents: Bool = false,
        legacyComponents: Set<String>? = nil,
        defaultComponents: Set<String> = defaultResetBundleComponents
    ) -> Set<String> {
        if hasPersistedComponents {
            guard let persistedComponents else {
                return normalizedResetBundleComponents(defaultComponents)
            }

            return normalizedResetBundleComponents(persistedComponents)
        }

        if hasLegacyComponents {
            guard let legacyComponents else {
                return normalizedResetBundleComponents(defaultComponents)
            }

            return normalizedResetBundleComponents(legacyComponents)
        }

        return normalizedResetBundleComponents(defaultComponents)
    }

    public static func shouldResetTextStateOnReturn(
        bundleID: String?,
        keyCode: UInt16,
        resetBundleComponents: Set<String> = defaultResetBundleComponents
    ) -> Bool {
        guard keyCode == returnKeyCode || keyCode == enterKeyCode else {
            return false
        }

        // Punto Switcher ships reset_on_return as a configurable bundle-token list.
        // Keep this capability as an app-context policy instead of changing
        // WordTracker's general return-key semantics for every editor.
        return isResetOnReturnBundleID(bundleID, resetBundleComponents: resetBundleComponents)
    }

    public static func isTelegramLikeBundleID(_ bundleID: String) -> Bool {
        isResetOnReturnBundleID(bundleID, resetBundleComponents: defaultResetBundleComponents)
    }

    public static func isResetOnReturnBundleID(
        _ bundleID: String?,
        resetBundleComponents: Set<String> = defaultResetBundleComponents
    ) -> Bool {
        guard let normalized = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return false
        }

        let resetComponents = ApplicationBundleIDPolicy.normalizedSet(resetBundleComponents)
        guard !resetComponents.isEmpty else {
            return false
        }

        let components = Set(normalized.split(separator: ".").map(String.init))
        return !components.isDisjoint(with: resetComponents)
    }
}
