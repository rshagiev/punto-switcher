import Foundation

public enum LayoutConversionSurface: Equatable {
    case selectedText
    case lastWord
    case undo
}

public enum LayoutSwitchPolicy {
    public static let defaultSwitchLayoutAfterConversion = false
    public static let defaultSwitchLayoutAfterSelectedTextConversion = true
    public static let legacySwitchLayoutOnSelectedTextSwitchKey = "switchLayoutOnSelectedTextSwitch"

    public static func shouldSwitchLayoutAfterConversion(
        surface: LayoutConversionSurface,
        switchLayoutAfterConversion: Bool,
        switchLayoutAfterSelectedTextConversion: Bool
    ) -> Bool {
        guard switchLayoutAfterConversion else {
            return false
        }

        switch surface {
        case .selectedText:
            return switchLayoutAfterSelectedTextConversion
        case .lastWord, .undo:
            return true
        }
    }
}

public enum LayoutSwitchTargetLanguage: Equatable {
    case english
    case russian
}

public struct LayoutSwitchRuntimeRequest: Equatable {
    public let language: LayoutSwitchTargetLanguage
    public let targetLayout: LayoutConverter.DetectedLayout
    public let ignoreInputSourceChangesUntil: Date

    public init(
        language: LayoutSwitchTargetLanguage,
        targetLayout: LayoutConverter.DetectedLayout,
        ignoreInputSourceChangesUntil: Date
    ) {
        self.language = language
        self.targetLayout = targetLayout
        self.ignoreInputSourceChangesUntil = ignoreInputSourceChangesUntil
    }
}

public enum LayoutSwitchRuntimePlan: Equatable {
    case skip
    case unsupportedTarget(clearInputSourceIgnoreDeadline: Bool)
    case switchTo(LayoutSwitchRuntimeRequest)
}

public enum LayoutSwitchRuntimePolicy {
    public static func plan(
        targetLayout: LayoutConverter.DetectedLayout,
        surface: LayoutConversionSurface,
        switchLayoutAfterConversion: Bool,
        switchLayoutAfterSelectedTextConversion: Bool,
        now: Date = Date()
    ) -> LayoutSwitchRuntimePlan {
        guard LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: surface,
            switchLayoutAfterConversion: switchLayoutAfterConversion,
            switchLayoutAfterSelectedTextConversion: switchLayoutAfterSelectedTextConversion
        ) else {
            return .skip
        }

        let ignoreDeadline = ConversionProtectionPolicy.inputSourceIgnoreDeadline(now: now)
        switch targetLayout {
        case .english:
            return .switchTo(LayoutSwitchRuntimeRequest(
                language: .english,
                targetLayout: targetLayout,
                ignoreInputSourceChangesUntil: ignoreDeadline
            ))
        case .russian:
            return .switchTo(LayoutSwitchRuntimeRequest(
                language: .russian,
                targetLayout: targetLayout,
                ignoreInputSourceChangesUntil: ignoreDeadline
            ))
        case .mixed, .unknown:
            return .unsupportedTarget(clearInputSourceIgnoreDeadline: true)
        }
    }
}
