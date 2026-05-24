import Foundation

public struct UndoLearningSettingsSnapshot: Equatable {
    public let undoCollectionEnabled: Bool
    public let mustShowUndoWindow: Bool
    public let undoDictionary: [String: String]

    public init(
        undoCollectionEnabled: Bool,
        mustShowUndoWindow: Bool,
        undoDictionary: [String: String]
    ) {
        self.undoCollectionEnabled = undoCollectionEnabled
        self.mustShowUndoWindow = mustShowUndoWindow
        self.undoDictionary = UndoLearningSettingsPolicy.normalizedUndoDictionary(undoDictionary)
    }
}

public enum UndoLearningSettingsPolicy {
    public static let legacySettingsKey = "undoLearning"
    public static let legacyUndoCollectionEnabledKey = "undoCollectionEnabled"
    public static let legacyMustShowUndoWindowKey = "mustShowUndoWindow"
    public static let legacyUndoDictionaryKey = "undoDictionary"

    public static let defaultSnapshot = UndoLearningSettingsSnapshot(
        undoCollectionEnabled: false,
        mustShowUndoWindow: true,
        undoDictionary: [:]
    )

    public static func snapshot(from dictionary: [String: Any]?) -> UndoLearningSettingsSnapshot? {
        guard let dictionary else {
            return nil
        }

        return UndoLearningSettingsSnapshot(
            undoCollectionEnabled: LegacyValuePolicy.bool(
                dictionary[legacyUndoCollectionEnabledKey],
                defaultValue: defaultSnapshot.undoCollectionEnabled
            ),
            mustShowUndoWindow: LegacyValuePolicy.bool(
                dictionary[legacyMustShowUndoWindowKey],
                defaultValue: defaultSnapshot.mustShowUndoWindow
            ),
            undoDictionary: stringDictionary(dictionary[legacyUndoDictionaryKey]) ?? defaultSnapshot.undoDictionary
        )
    }

    public static func legacyUndoCollectionEnabled(from dictionary: [String: Any]?) -> Bool? {
        snapshot(from: dictionary)?.undoCollectionEnabled
    }

    public static func normalizedUndoDictionary(_ dictionary: [String: String]) -> [String: String] {
        dictionary.reduce(into: [:]) { result, entry in
            let key = entry.key.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = entry.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !value.isEmpty else {
                return
            }
            result[key] = value
        }
    }

    private static func stringDictionary(_ value: Any?) -> [String: String]? {
        guard let dictionary = value as? [String: Any] else {
            return nil
        }

        let normalized = dictionary.reduce(into: [String: String]()) { result, entry in
            guard let value = entry.value as? String else {
                return
            }
            result[entry.key] = value
        }
        return normalizedUndoDictionary(normalized)
    }
}
