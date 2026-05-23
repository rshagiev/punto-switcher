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
    public static let observedSetUndoCollectionEnabledSelector = "setUndoCollectionEnabled:"
    public static let observedSetMustShowUndoWindowSelector = "setMustShowUndoWindow:"
    public static let observedSetUndoDictionarySelector = "setUndoDictionary:"
    public static let observedUndoWindowControllerClassName = "UndoWindowController"
    public static let observedUndoWindowDelegateProtocolName = "UndoWindowDelegate"
    public static let observedUndoWindowResourceName = "UndoWindow"
    public static let observedUndoAlertFormatKey = "PMUserRuleUndoAlertFormat"
    public static let observedShowUndoLearningWindowCheckboxChangedSelector = "showUndoLearningWindowCheckboxChanged:"
    public static let observedUndoLearningCheckboxChangedSelector = "undoLearningCheckboxChanged:"
    public static let observedUndoLearningCheckboxKey = "undoLearningCheckbox"
    public static let observedShowUndoLearningWindowCheckboxKey = "showUndoLearningWindowCheckbox"
    public static let observedUndoTriesKey = "undoTries"
    public static let observedUndoPersistsKey = "undoPersists"
    public static let observedUndoWasDoneKey = "undoWasDone"
    public static let observedUndoConvertionSelector = "undoConvertion"
    public static let observedResetUndoBufferSelector = "resetUndoBuffer"

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
            undoCollectionEnabled: boolValue(dictionary[undoCollectionEnabledKey]) ?? defaultSnapshot.undoCollectionEnabled,
            mustShowUndoWindow: boolValue(dictionary[mustShowUndoWindowKey]) ?? defaultSnapshot.mustShowUndoWindow,
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

    private static func boolValue(_ value: Any?) -> Bool? {
        switch value {
        case let value as Bool:
            return value
        case let value as NSNumber:
            return value.boolValue
        case let value as String:
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "1", "true", "yes":
                return true
            case "0", "false", "no":
                return false
            default:
                return nil
            }
        default:
            return nil
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
