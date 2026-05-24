import Foundation

public enum SoundFeedbackEvent: Equatable {
    case layoutConversion
    case undo
    case toggleCase
    case autoCorrection
    case inputSourceSwitch(to: LayoutConverter.DetectedLayout)
    case typedText(layout: LayoutConverter.DetectedLayout)
}

public enum InputSourceSwitchSoundContext: Equatable {
    case standalone
    case textReplacement
    case rememberedApplicationRestore
}

public enum SoundFeedbackPolicy {
    public static let legacyIsSoundOnKey = "isSoundOn"
    public static let legacyEnabledSoundsKey = "enabledSounds"
    public static let legacyUseSoundLayoutSwitchToRussianKey = "useSoundLayoutSwitchToRussian"
    public static let legacyUseSoundLayoutSwitchToEnglishKey = "useSoundLayoutSwitchToEnglish"
    public static let legacyUseSoundConvertationKey = "useSoundConvertation"
    public static let legacyUseSoundMisprintKey = "useSoundMisprint"
    public static let legacyUseSoundAutocorrectionKey = "useSoundAutocorrection"
    public static let legacyUseSoundUndoKey = "useSoundUndo"
    public static let legacyUseSoundKeystrokesKey = "useSoundKeystrokes"

    public static let legacyPerResourceToggleKeys = [
        legacyUseSoundLayoutSwitchToRussianKey,
        legacyUseSoundLayoutSwitchToEnglishKey,
        legacyUseSoundConvertationKey,
        legacyUseSoundMisprintKey,
        legacyUseSoundAutocorrectionKey,
        legacyUseSoundUndoKey,
        legacyUseSoundKeystrokesKey
    ]

    public static let legacyBitmaskResourceOrder = [
        "replace",
        "reverse",
        "misprint",
        "switch",
        "en",
        "ru",
        "typeeng",
        "typerus"
    ]

    public static let legacyToggleResourceNamesByKey: [String: Set<String>] = [
        legacyUseSoundLayoutSwitchToRussianKey: ["ru"],
        legacyUseSoundLayoutSwitchToEnglishKey: ["en"],
        legacyUseSoundConvertationKey: ["replace"],
        legacyUseSoundMisprintKey: ["misprint"],
        legacyUseSoundAutocorrectionKey: ["misprint"],
        legacyUseSoundUndoKey: ["reverse"],
        legacyUseSoundKeystrokesKey: ["typeeng", "typerus"]
    ]

    public static let requiredResourceNames: Set<String> = [
        "replace",
        "reverse",
        "misprint",
        "switch",
        "en",
        "ru",
        "typeeng",
        "typerus"
    ]

    public static let defaultEnabledResourceNames = requiredResourceNames

    public static func normalizedEnabledResourceNames(_ names: Set<String>) -> Set<String> {
        names.intersection(requiredResourceNames)
    }

    public static func enabledResourceNames(fromLegacyBitmask bitmask: Int?) -> Set<String>? {
        guard let bitmask else {
            return nil
        }

        var enabledNames = Set<String>()
        for (index, resourceName) in legacyBitmaskResourceOrder.enumerated() {
            if bitmask & (1 << index) != 0 {
                enabledNames.insert(resourceName)
            }
        }
        return normalizedEnabledResourceNames(enabledNames)
    }

    public static func enabledResourceNames(fromLegacyToggles toggles: [String: Bool]) -> Set<String>? {
        var hasKnownToggle = false
        var enabledNames = defaultEnabledResourceNames
        var disabledNames = Set<String>()

        for (key, resources) in legacyToggleResourceNamesByKey {
            guard let isEnabled = toggles[key] else {
                continue
            }

            hasKnownToggle = true
            if isEnabled {
                enabledNames.formUnion(resources)
            } else {
                disabledNames.formUnion(resources)
            }
        }

        guard hasKnownToggle else {
            return nil
        }

        enabledNames.subtract(disabledNames)
        return normalizedEnabledResourceNames(enabledNames)
    }

    public static func eventAfterTextInput(
        characters: String?,
        detectedLayout: LayoutConverter.DetectedLayout
    ) -> SoundFeedbackEvent? {
        guard let characters, !characters.isEmpty else {
            return nil
        }

        switch detectedLayout {
        case .english, .russian:
            return .typedText(layout: detectedLayout)
        case .mixed, .unknown:
            return nil
        }
    }

    public static func eventAfterInputSourceSwitch(
        targetLayout: LayoutConverter.DetectedLayout,
        didSwitch: Bool,
        context: InputSourceSwitchSoundContext = .standalone
    ) -> SoundFeedbackEvent? {
        guard didSwitch else {
            return nil
        }

        guard context == .standalone else {
            return nil
        }

        switch targetLayout {
        case .english, .russian:
            return .inputSourceSwitch(to: targetLayout)
        case .mixed, .unknown:
            return nil
        }
    }

    public static func resourceName(
        for event: SoundFeedbackEvent,
        soundEffectsEnabled: Bool,
        enabledResourceNames: Set<String>? = nil
    ) -> String? {
        guard soundEffectsEnabled else {
            return nil
        }

        let resourceName: String?
        switch event {
        case .layoutConversion:
            resourceName = "replace"
        case .undo:
            resourceName = "reverse"
        case .toggleCase:
            resourceName = "replace"
        case .autoCorrection:
            resourceName = "misprint"
        case .inputSourceSwitch(let layout):
            switch layout {
            case .english:
                resourceName = "en"
            case .russian:
                resourceName = "ru"
            case .mixed, .unknown:
                resourceName = "switch"
            }
        case .typedText(let layout):
            switch layout {
            case .english:
                resourceName = "typeeng"
            case .russian:
                resourceName = "typerus"
            case .mixed, .unknown:
                resourceName = nil
            }
        }

        guard let resourceName else {
            return nil
        }

        let enabledNames = enabledResourceNames.map(normalizedEnabledResourceNames) ?? defaultEnabledResourceNames
        return enabledNames.contains(resourceName) ? resourceName : nil
    }
}
