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
    public static let settingsKey = "undoLearning"
    public static let undoCollectionEnabledKey = "undoCollectionEnabled"
    public static let mustShowUndoWindowKey = "mustShowUndoWindow"
    public static let undoDictionaryKey = "undoDictionary"

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
                dictionary[undoCollectionEnabledKey],
                defaultValue: defaultSnapshot.undoCollectionEnabled
            ),
            mustShowUndoWindow: LegacyValuePolicy.bool(
                dictionary[mustShowUndoWindowKey],
                defaultValue: defaultSnapshot.mustShowUndoWindow
            ),
            undoDictionary: stringDictionary(dictionary[undoDictionaryKey]) ?? defaultSnapshot.undoDictionary
        )
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
