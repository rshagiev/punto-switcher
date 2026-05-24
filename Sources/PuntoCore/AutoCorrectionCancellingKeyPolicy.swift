import Foundation

public struct AutoCorrectionCancellingKeyDisplayItem: Equatable {
    public let name: String
    public let title: String
    public let keyCode: UInt16

    public init(name: String, title: String, keyCode: UInt16) {
        self.name = name
        self.title = title
        self.keyCode = keyCode
    }
}

public enum AutoCorrectionCancellingKeyPolicy {
    public static let legacyCancellingKeysBitmaskKey = "cancellingKeys"
    public static let legacyBackspaceName = "dontAutoconvertWordWithBackspace"
    public static let legacyDeleteName = "dontAutoconvertWordWithDelete"
    public static let legacyLeftArrowName = "dontAutoconvertWordWithLeftArrow"
    public static let legacyRightArrowName = "dontAutoconvertWordWithRightArrow"
    public static let legacyUpArrowName = "dontAutoconvertWordWithUpArrow"
    public static let legacyDownArrowName = "dontAutoconvertWordWithDownArrow"
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

    public static let displayOrder: [AutoCorrectionCancellingKeyDisplayItem] = [
        AutoCorrectionCancellingKeyDisplayItem(
            name: backspace,
            title: "Backspace",
            keyCode: WordTrackingPolicy.deleteKeyCode
        ),
        AutoCorrectionCancellingKeyDisplayItem(
            name: delete,
            title: "Delete",
            keyCode: WordTrackingPolicy.forwardDeleteKeyCode
        ),
        AutoCorrectionCancellingKeyDisplayItem(
            name: leftArrow,
            title: "Left",
            keyCode: WordTrackingPolicy.leftArrowKeyCode
        ),
        AutoCorrectionCancellingKeyDisplayItem(
            name: rightArrow,
            title: "Right",
            keyCode: WordTrackingPolicy.rightArrowKeyCode
        ),
        AutoCorrectionCancellingKeyDisplayItem(
            name: upArrow,
            title: "Up",
            keyCode: WordTrackingPolicy.upArrowKeyCode
        ),
        AutoCorrectionCancellingKeyDisplayItem(
            name: downArrow,
            title: "Down",
            keyCode: WordTrackingPolicy.downArrowKeyCode
        )
    ]

    public static let defaultEnabledKeyNames = Set(displayOrder.map(\.name))
    public static let defaultEnabledKeyNameList = Array(defaultEnabledKeyNames).sorted()

    public static let supportedKeyNames: Set<String> = defaultEnabledKeyNames

    private static let legacyNamesByCanonicalName: [String: String] = [
        legacyBackspaceName: backspace,
        legacyDeleteName: delete,
        legacyLeftArrowName: leftArrow,
        legacyRightArrowName: rightArrow,
        legacyUpArrowName: upArrow,
        legacyDownArrowName: downArrow,
        legacyBackspaceSelectorAlias: backspace,
        legacyDeleteSelectorAlias: delete,
        legacyLeftArrowSelectorAlias: leftArrow,
        legacyRightArrowSelectorAlias: rightArrow,
        legacyUpArrowSelectorAlias: upArrow,
        legacyDownArrowSelectorAlias: downArrow
    ]

    private static let canonicalNamesByLowercaseName: [String: String] = {
        var names = Dictionary(uniqueKeysWithValues: supportedKeyNames.map { ($0.lowercased(), $0) })
        for (legacyName, canonicalName) in legacyNamesByCanonicalName {
            names[legacyName.lowercased()] = canonicalName
        }
        return names
    }()

    public static func normalizedEnabledKeyNames(_ keyNames: Set<String>) -> Set<String> {
        Set(
            keyNames
                .compactMap { canonicalNamesByLowercaseName[$0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] }
        )
    }

    public static func legacyEnabledKeyNames(from bitmask: Int?) -> Set<String>? {
        guard let bitmask else {
            return nil
        }

        guard bitmask == 0 else {
            return nil
        }

        return []
    }

    public static func effectiveEnabledKeyNames(
        hasPersistedValue: Bool,
        persistedValue: Set<String>,
        hasLegacyValue: Bool,
        legacyBitmask: Int?
    ) -> Set<String> {
        if hasPersistedValue {
            return normalizedEnabledKeyNames(persistedValue)
        }

        if hasLegacyValue, let legacyKeyNames = legacyEnabledKeyNames(from: legacyBitmask) {
            return legacyKeyNames
        }

        return normalizedEnabledKeyNames(defaultEnabledKeyNames)
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
        displayOrder.first { $0.keyCode == keyCode }?.name
    }
}
