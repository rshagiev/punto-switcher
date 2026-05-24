import Foundation

public enum AutoCorrectionCancellingKeyPolicy {
    public static let observedBackspaceName = "dontAutoconvertWordWithBackspace"
    public static let observedDeleteName = "dontAutoconvertWordWithDelete"
    public static let observedLeftArrowName = "dontAutoconvertWordWithLeftArrow"
    public static let observedRightArrowName = "dontAutoconvertWordWithRightArrow"
    public static let observedUpArrowName = "dontAutoconvertWordWithUpArrow"
    public static let observedDownArrowName = "dontAutoconvertWordWithDownArrow"
    public static let legacyBackspaceSelectorAlias = "dontAutoconvertWordWithBackspace:"
    public static let legacyDeleteSelectorAlias = "dontAutoconvertWordWithDelete:"
    public static let legacyLeftArrowSelectorAlias = "dontAutoconvertWordWithLeftArrow:"
    public static let legacyRightArrowSelectorAlias = "dontAutoconvertWordWithRightArrow:"
    public static let legacyUpArrowSelectorAlias = "dontAutoconvertWordWithUpArrow:"
    public static let legacyDownArrowSelectorAlias = "dontAutoconvertWordWithDownArrow:"
    public static let backspace = "backspace"
    public static let delete = "delete"
    public static let leftArrow = "leftArrow"
    public static let rightArrow = "rightArrow"
    public static let upArrow = "upArrow"
    public static let downArrow = "downArrow"

    public static let defaultEnabledKeyNames: Set<String> = [
        backspace,
        delete,
        leftArrow,
        rightArrow,
        upArrow,
        downArrow
    ]

    public static let supportedKeyNames: Set<String> = defaultEnabledKeyNames

    public static let displayOrder: [(name: String, title: String)] = [
        (backspace, "Backspace"),
        (delete, "Delete"),
        (leftArrow, "Left"),
        (rightArrow, "Right"),
        (upArrow, "Up"),
        (downArrow, "Down")
    ]

    private static let observedNamesByCanonicalName: [String: String] = [
        observedBackspaceName: backspace,
        observedDeleteName: delete,
        observedLeftArrowName: leftArrow,
        observedRightArrowName: rightArrow,
        observedUpArrowName: upArrow,
        observedDownArrowName: downArrow,
        legacyBackspaceSelectorAlias: backspace,
        legacyDeleteSelectorAlias: delete,
        legacyLeftArrowSelectorAlias: leftArrow,
        legacyRightArrowSelectorAlias: rightArrow,
        legacyUpArrowSelectorAlias: upArrow,
        legacyDownArrowSelectorAlias: downArrow
    ]

    private static let canonicalNamesByLowercaseName: [String: String] = {
        var names = Dictionary(uniqueKeysWithValues: supportedKeyNames.map { ($0.lowercased(), $0) })
        for (observedName, canonicalName) in observedNamesByCanonicalName {
            names[observedName.lowercased()] = canonicalName
        }
        return names
    }()

    public static func normalizedEnabledKeyNames(_ keyNames: Set<String>) -> Set<String> {
        Set(
            keyNames
                .compactMap { canonicalNamesByLowercaseName[$0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] }
        )
    }

    public static func shouldSuppressAutoCorrection(
        keyCode: UInt16,
        enabledKeyNames: Set<String> = defaultEnabledKeyNames
    ) -> Bool {
        guard let keyName = cancellingKeyName(for: keyCode) else {
            return false
        }
        return normalizedEnabledKeyNames(enabledKeyNames).contains(keyName)
    }

    public static func cancellingKeyName(for keyCode: UInt16) -> String? {
        switch keyCode {
        case WordTrackingPolicy.deleteKeyCode:
            return backspace
        case WordTrackingPolicy.forwardDeleteKeyCode:
            return delete
        case WordTrackingPolicy.leftArrowKeyCode:
            return leftArrow
        case WordTrackingPolicy.rightArrowKeyCode:
            return rightArrow
        case WordTrackingPolicy.upArrowKeyCode:
            return upArrow
        case WordTrackingPolicy.downArrowKeyCode:
            return downArrow
        default:
            return nil
        }
    }
}
