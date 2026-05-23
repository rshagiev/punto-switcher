public enum AccessibilityTraversalPolicy {
    public static let maxDescendantSearchDepth = 5
    public static let maxAncestorRoleDepth = 5

    public static func shouldInspectDescendant(depth: Int) -> Bool {
        depth >= 0 && depth < maxDescendantSearchDepth
    }

    public static func shouldCollectAncestorRole(atDepth depth: Int) -> Bool {
        depth >= 0 && depth <= maxAncestorRoleDepth
    }
}
