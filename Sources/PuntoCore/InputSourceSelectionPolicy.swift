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
    public let sourceIDsToEnable: [String]

    public init(englishSourceID: String?, russianSourceID: String?, sourceIDsToEnable: [String] = []) {
        self.englishSourceID = englishSourceID
        self.russianSourceID = russianSourceID
        self.sourceIDsToEnable = Array(
            Set(sourceIDsToEnable.compactMap(InputSourceSelectionPolicy.normalizedSourceID))
        ).sorted()
    }
}

public enum InputSourceSelectionPolicy {
    public static let observedUndefinedSourceID = "UNDEFINED"
    public static let inputSourceEnabledLogPrefix = "inputSourceEnabled:"
    public static let handleInputSourcesEnabledLogPrefix = "handleInputSourcesEnabled"
    public static let promptUserToInstallLayoutsLogPrefix = "promptUserToInstallLayouts"

    public static func selection(
        from candidates: [InputSourceCandidate],
        preferredRussianLayoutType: KeyboardLayoutType = KeyboardLayoutTypePolicy.defaultRussianLayoutType,
        preferredEnglishSourceID: String? = nil,
        preferredRussianSourceID: String? = nil
    ) -> InputSourceSelection {
        let selectable = candidates.filter(\.isSelectableKeyboard)
        let normalizedPreferredEnglishSourceID = normalizedSourceID(preferredEnglishSourceID)
        let normalizedPreferredRussianSourceID = normalizedSourceID(preferredRussianSourceID)

        let englishCandidates = selectable.filter {
            InputSourceLanguagePolicy.isEnglishInputSource(sourceID: $0.sourceID, languages: $0.languages)
        }
        let enabledEnglishCandidates = englishCandidates.filter(\.isEnabled)

        let explicitEnglishSourceID = englishCandidates.first {
            normalizedSourceID($0.sourceID) == normalizedPreferredEnglishSourceID
        }

        let defaultEnglishCandidate = enabledEnglishCandidates.first {
            KeyboardLayoutVariantPolicy.isDefaultEnglishSource($0.sourceID)
        }

        let fallbackDisabledEnglishCandidate = englishCandidates.first {
            KeyboardLayoutVariantPolicy.isDefaultEnglishSource($0.sourceID)
        } ?? englishCandidates.first

        let englishCandidate = explicitEnglishSourceID
            ?? defaultEnglishCandidate
            ?? enabledEnglishCandidates.first
            ?? fallbackDisabledEnglishCandidate
        let englishSourceID = englishCandidate.flatMap { normalizedSourceID($0.sourceID) }

        let russianCandidates = selectable.filter {
            guard InputSourceLanguagePolicy.isRussianInputSource(sourceID: $0.sourceID, languages: $0.languages),
                  let sourceID = normalizedSourceID($0.sourceID) else {
                return false
            }
            return sourceID != englishSourceID
        }
        let enabledRussianCandidates = russianCandidates.filter(\.isEnabled)

        let explicitRussianSourceID = russianCandidates.first {
            normalizedSourceID($0.sourceID) == normalizedPreferredRussianSourceID
        }

        let preferredRussianCandidate = russianCandidates.first {
            KeyboardLayoutTypePolicy.isPreferredRussianSource(
                sourceID: $0.sourceID,
                layoutType: preferredRussianLayoutType
            )
        }

        let fallbackDisabledRussianCandidate = russianCandidates.first {
            KeyboardLayoutTypePolicy.isPreferredRussianSource(
                sourceID: $0.sourceID,
                layoutType: preferredRussianLayoutType
            )
        } ?? russianCandidates.first

        let russianCandidate = explicitRussianSourceID
            ?? preferredRussianCandidate
            ?? enabledRussianCandidates.first
            ?? fallbackDisabledRussianCandidate
        let russianSourceID = russianCandidate.flatMap { normalizedSourceID($0.sourceID) }
        let sourceIDsToEnable = [englishCandidate, russianCandidate].compactMap { candidate -> String? in
            guard let candidate, !candidate.isEnabled else {
                return nil
            }
            return normalizedSourceID(candidate.sourceID)
        }

        return InputSourceSelection(
            englishSourceID: englishSourceID,
            russianSourceID: russianSourceID,
            sourceIDsToEnable: sourceIDsToEnable
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
        return "\(promptUserToInstallLayoutsLogPrefix): missing \(missing.joined(separator: "/")) input source"
    }

    public static func shouldEnableInputSource(sourceID: String?, selection: InputSourceSelection) -> Bool {
        guard let sourceID = normalizedSourceID(sourceID) else {
            return false
        }
        return selection.sourceIDsToEnable.contains(sourceID)
    }

    public static func inputSourceEnabledLogMessage(sourceID: String) -> String {
        "\(inputSourceEnabledLogPrefix) \(sourceID)"
    }

    public static func handleInputSourcesEnabledLogMessage(sourceIDs: [String]) -> String? {
        let normalized = Array(Set(sourceIDs.compactMap(normalizedSourceID))).sorted()
        guard !normalized.isEmpty else {
            return nil
        }
        return "\(handleInputSourcesEnabledLogPrefix): \(normalized.joined(separator: ", "))"
    }

    public static func failedToEnableLayoutLogMessage(sourceID: String, status: Int32) -> String {
        "Failed to enable layout \(sourceID)! Error code: \(status)"
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
