import Foundation

public enum SearchClickPolicy {
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
