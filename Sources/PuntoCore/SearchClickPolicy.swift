import Foundation

public enum SearchClickPolicy {
    public static let observedCanDoSearchClickSelector = "canDoSearchClick"
    public static let observedShowSearchWindowAutomaticallySelector = "showSearchWindowAutomatically"
    public static let observedShowSearchWindowSelectedTextSelector = "showSearchWindowSelectedText"
    public static let observedSetIsClickSearchSelector = "setIsClickSearch:"

    public static func canDoSearchClick(role: String?, bundleID: String?) -> Bool {
        guard AccessibilityRolePolicy.normalizedRole(role) != nil else {
            return false
        }

        return !AccessibilityRolePolicy.isObservedSearchExceptionRole(
            role: role,
            bundleID: bundleID,
            context: .click
        )
    }

    public static func shouldSearchSelectedTextAfterClick(
        eventTypeRawValue: UInt32,
        clickCount: Int,
        shouldSearchByDoubleClick: Bool,
        canDoSearchClick: Bool
    ) -> Bool {
        guard eventTypeRawValue == PointerEventPolicy.leftMouseDownRawValue else {
            return false
        }
        guard clickCount >= 2 else {
            return false
        }
        return shouldSearchByDoubleClick && canDoSearchClick
    }
}
