import Foundation

public struct InputSourceCandidate: Equatable {
    public let sourceID: String
    public let languages: [String]
    public let isSelectableKeyboard: Bool
    public let isEnabled: Bool

    public init(sourceID: String, languages: [String], isSelectableKeyboard: Bool, isEnabled: Bool = true) {
        self.sourceID = sourceID
        self.languages = languages
        self.isSelectableKeyboard = isSelectableKeyboard
        self.isEnabled = isEnabled
    }
}

public struct InputSourceSelection: Equatable {
    public let englishSourceID: String?
    public let russianSourceID: String?

    public init(englishSourceID: String?, russianSourceID: String?) {
        self.englishSourceID = englishSourceID
        self.russianSourceID = russianSourceID
    }
}

public enum InputSourceSelectionPolicy {
    public static let observedUndefinedSourceID = "UNDEFINED"

    public static func selection(
        from candidates: [InputSourceCandidate],
        preferredRussianLayoutType: KeyboardLayoutType = KeyboardLayoutTypePolicy.defaultRussianLayoutType,
        preferredEnglishSourceID: String? = nil,
        preferredRussianSourceID: String? = nil
    ) -> InputSourceSelection {
        let selectable = candidates.filter { $0.isSelectableKeyboard && $0.isEnabled }
        let normalizedPreferredEnglishSourceID = normalizedSourceID(preferredEnglishSourceID)
        let normalizedPreferredRussianSourceID = normalizedSourceID(preferredRussianSourceID)

        let englishCandidates = selectable.filter {
            InputSourceLanguagePolicy.isEnglishInputSource(sourceID: $0.sourceID, languages: $0.languages)
        }

        let explicitEnglishSourceID = englishCandidates.first {
            normalizedSourceID($0.sourceID) == normalizedPreferredEnglishSourceID
        }.flatMap { normalizedSourceID($0.sourceID) }

        let defaultEnglishSourceID = englishCandidates.first {
            KeyboardLayoutVariantPolicy.isDefaultEnglishSource($0.sourceID)
        }.flatMap { normalizedSourceID($0.sourceID) }

        let englishSourceID = explicitEnglishSourceID ?? defaultEnglishSourceID ?? englishCandidates.first.flatMap { normalizedSourceID($0.sourceID) }

        let russianCandidates = selectable.filter {
            guard InputSourceLanguagePolicy.isRussianInputSource(sourceID: $0.sourceID, languages: $0.languages),
                  let sourceID = normalizedSourceID($0.sourceID) else {
                return false
            }
            return sourceID != englishSourceID
        }

        let explicitRussianSourceID = russianCandidates.first {
            normalizedSourceID($0.sourceID) == normalizedPreferredRussianSourceID
        }.flatMap { normalizedSourceID($0.sourceID) }

        let preferredRussianSourceID = russianCandidates.first {
            KeyboardLayoutTypePolicy.isPreferredRussianSource(
                sourceID: $0.sourceID,
                layoutType: preferredRussianLayoutType
            )
        }.flatMap { normalizedSourceID($0.sourceID) }

        let russianSourceID = explicitRussianSourceID ?? preferredRussianSourceID ?? russianCandidates.first.flatMap { normalizedSourceID($0.sourceID) }

        return InputSourceSelection(
            englishSourceID: englishSourceID,
            russianSourceID: russianSourceID
        )
    }

    public static func missingRequiredLanguageNames(in selection: InputSourceSelection) -> [String] {
        var missing: [String] = []
        if selection.englishSourceID == nil {
            missing.append("English")
        }
        if selection.russianSourceID == nil {
            missing.append("Russian")
        }
        return missing
    }

    public static func shouldPromptUserToInstallLayouts(selection: InputSourceSelection) -> Bool {
        !missingRequiredLanguageNames(in: selection).isEmpty
    }

    public static func missingRequiredLayoutsLogMessage(selection: InputSourceSelection) -> String? {
        let missing = missingRequiredLanguageNames(in: selection)
        guard !missing.isEmpty else {
            return nil
        }
        return "\(PuntoSwitcherObservedSurface.InputSources.promptUserToInstallLayoutsSelector): missing \(missing.joined(separator: "/")) input source"
    }

    public static func normalizedSourceID(_ sourceID: String?) -> String? {
        guard let sourceID else {
            return nil
        }

        let trimmed = sourceID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if trimmed.caseInsensitiveCompare(observedUndefinedSourceID) == .orderedSame {
            return nil
        }

        return trimmed
    }

}
