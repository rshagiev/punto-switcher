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

public struct SoundResourceDisplayItem: Equatable {
    public let title: String
    public let resourceName: String

    public init(title: String, resourceName: String) {
        self.title = title
        self.resourceName = resourceName
    }
}

public enum SoundFeedbackResourceName {
    public static let replace = "replace"
    public static let reverse = "reverse"
    public static let misprint = "misprint"
    public static let switchLayout = "switch"
    public static let english = "en"
    public static let russian = "ru"
    public static let typedEnglish = "typeeng"
    public static let typedRussian = "typerus"
}

public enum SoundFeedbackPolicy {
    public static let defaultSoundEffectsEnabled = false
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
        SoundFeedbackResourceName.replace,
        SoundFeedbackResourceName.reverse,
        SoundFeedbackResourceName.misprint,
        SoundFeedbackResourceName.switchLayout,
        SoundFeedbackResourceName.english,
        SoundFeedbackResourceName.russian,
        SoundFeedbackResourceName.typedEnglish,
        SoundFeedbackResourceName.typedRussian
    ]

    public static let legacyToggleResourceNamesByKey: [String: Set<String>] = [
        legacyUseSoundLayoutSwitchToRussianKey: [SoundFeedbackResourceName.russian],
        legacyUseSoundLayoutSwitchToEnglishKey: [SoundFeedbackResourceName.english],
        legacyUseSoundConvertationKey: [SoundFeedbackResourceName.replace],
        legacyUseSoundMisprintKey: [SoundFeedbackResourceName.misprint],
        legacyUseSoundAutocorrectionKey: [SoundFeedbackResourceName.misprint],
        legacyUseSoundUndoKey: [SoundFeedbackResourceName.reverse],
        legacyUseSoundKeystrokesKey: [
            SoundFeedbackResourceName.typedEnglish,
            SoundFeedbackResourceName.typedRussian
        ]
    ]

    public static let requiredResourceNames = Set(legacyBitmaskResourceOrder)

    public static let defaultEnabledResourceNames = requiredResourceNames

    public static let displayRows: [[SoundResourceDisplayItem]] = [
        [
            SoundResourceDisplayItem(title: "Replace", resourceName: SoundFeedbackResourceName.replace),
            SoundResourceDisplayItem(title: "Reverse", resourceName: SoundFeedbackResourceName.reverse)
        ],
        [
            SoundResourceDisplayItem(title: "Misprint", resourceName: SoundFeedbackResourceName.misprint),
            SoundResourceDisplayItem(title: "Switch", resourceName: SoundFeedbackResourceName.switchLayout)
        ],
        [
            SoundResourceDisplayItem(title: "English", resourceName: SoundFeedbackResourceName.english),
            SoundResourceDisplayItem(title: "Russian", resourceName: SoundFeedbackResourceName.russian)
        ],
        [
            SoundResourceDisplayItem(title: "Typed EN", resourceName: SoundFeedbackResourceName.typedEnglish),
            SoundResourceDisplayItem(title: "Typed RU", resourceName: SoundFeedbackResourceName.typedRussian)
        ]
    ]

    public static let displayOrder = displayRows.flatMap { $0 }

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
            resourceName = SoundFeedbackResourceName.replace
        case .undo:
            resourceName = SoundFeedbackResourceName.reverse
        case .toggleCase:
            resourceName = SoundFeedbackResourceName.replace
        case .autoCorrection:
            resourceName = SoundFeedbackResourceName.misprint
        case .inputSourceSwitch(let layout):
            switch layout {
            case .english:
                resourceName = SoundFeedbackResourceName.english
            case .russian:
                resourceName = SoundFeedbackResourceName.russian
            case .mixed, .unknown:
                resourceName = SoundFeedbackResourceName.switchLayout
            }
        case .typedText(let layout):
            switch layout {
            case .english:
                resourceName = SoundFeedbackResourceName.typedEnglish
            case .russian:
                resourceName = SoundFeedbackResourceName.typedRussian
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
