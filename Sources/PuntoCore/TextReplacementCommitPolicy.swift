import Foundation

public struct TrackedTailCommit: Equatable {
    public let text: String
    public let reason: String
    public let suppressAutoCorrectionForCurrentToken: Bool

    public init(
        text: String,
        reason: String,
        suppressAutoCorrectionForCurrentToken: Bool = false
    ) {
        self.text = text
        self.reason = reason
        self.suppressAutoCorrectionForCurrentToken = suppressAutoCorrectionForCurrentToken
    }
}

public struct LayoutSwitchCommit: Equatable {
    public let targetLayout: LayoutConverter.DetectedLayout
    public let surface: LayoutConversionSurface

    public init(targetLayout: LayoutConverter.DetectedLayout, surface: LayoutConversionSurface) {
        self.targetLayout = targetLayout
        self.surface = surface
    }
}

public struct ConversionRecordCommit: Equatable {
    public let originalText: String
    public let convertedText: String
    public let replacementMethod: TextReplacementMethod
    public let origin: ConversionOrigin

    public init(
        originalText: String,
        convertedText: String,
        replacementMethod: TextReplacementMethod,
        origin: ConversionOrigin
    ) {
        self.originalText = originalText
        self.convertedText = convertedText
        self.replacementMethod = replacementMethod
        self.origin = origin
    }
}

public struct TextReplacementCommitPlan: Equatable {
    public let clearTrackedTextBeforeTailCommit: Bool
    public let trackedTailCommit: TrackedTailCommit?
    public let layoutSwitchCommit: LayoutSwitchCommit?
    public let soundFeedbackEvent: SoundFeedbackEvent
    public let productStatisticsEvent: ProductStatisticsEvent?
    public let conversionRecordCommit: ConversionRecordCommit

    public init(
        clearTrackedTextBeforeTailCommit: Bool = false,
        trackedTailCommit: TrackedTailCommit?,
        layoutSwitchCommit: LayoutSwitchCommit?,
        soundFeedbackEvent: SoundFeedbackEvent,
        productStatisticsEvent: ProductStatisticsEvent?,
        conversionRecordCommit: ConversionRecordCommit
    ) {
        self.clearTrackedTextBeforeTailCommit = clearTrackedTextBeforeTailCommit
        self.trackedTailCommit = trackedTailCommit
        self.layoutSwitchCommit = layoutSwitchCommit
        self.soundFeedbackEvent = soundFeedbackEvent
        self.productStatisticsEvent = productStatisticsEvent
        self.conversionRecordCommit = conversionRecordCommit
    }
}

public enum TextReplacementCommitPolicy {
    public static func manualSelectedText(
        _ replacement: LayoutConversionReplacement,
        suppressAutoCorrectionAfterManualConversion: Bool
    ) -> TextReplacementCommitPlan {
        TextReplacementCommitPlan(
            trackedTailCommit: replacement.trackedTailAfterReplacement.map {
                TrackedTailCommit(
                    text: $0,
                    reason: "terminal selection conversion completed",
                    suppressAutoCorrectionForCurrentToken: suppressAutoCorrectionAfterManualConversion
                )
            },
            layoutSwitchCommit: LayoutSwitchCommit(targetLayout: replacement.targetLayout, surface: .selectedText),
            soundFeedbackEvent: .layoutConversion,
            productStatisticsEvent: .manualSwitch,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: replacement.capturedText.text,
                convertedText: replacement.convertedText,
                replacementMethod: replacement.undoMethod,
                origin: .layoutConversion
            )
        )
    }

    public static func manualLastWord(
        _ replacement: LayoutConversionReplacement,
        suppressAutoCorrectionAfterManualConversion: Bool
    ) -> TextReplacementCommitPlan {
        TextReplacementCommitPlan(
            clearTrackedTextBeforeTailCommit: true,
            trackedTailCommit: replacement.trackedTailAfterReplacement.map {
                TrackedTailCommit(
                    text: $0,
                    reason: "last-word conversion completed",
                    suppressAutoCorrectionForCurrentToken: suppressAutoCorrectionAfterManualConversion
                )
            },
            layoutSwitchCommit: LayoutSwitchCommit(targetLayout: replacement.targetLayout, surface: .lastWord),
            soundFeedbackEvent: .layoutConversion,
            productStatisticsEvent: .manualSwitch,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: replacement.capturedText.text,
                convertedText: replacement.convertedText,
                replacementMethod: replacement.undoMethod,
                origin: .layoutConversion
            )
        )
    }

    public static func toggleCase(_ replacement: ToggleCaseReplacement) -> TextReplacementCommitPlan {
        TextReplacementCommitPlan(
            trackedTailCommit: replacement.trackedTailAfterReplacement.map {
                TrackedTailCommit(text: $0, reason: "toggle-case completed")
            },
            layoutSwitchCommit: nil,
            soundFeedbackEvent: .toggleCase,
            productStatisticsEvent: nil,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: replacement.originalText,
                convertedText: replacement.toggledText,
                replacementMethod: replacement.undoMethod,
                origin: .toggleCase
            )
        )
    }

    public static func autoCorrection(
        decision: AutoCorrectionDecision,
        replacement: AutoCorrectionReplacement
    ) -> TextReplacementCommitPlan {
        TextReplacementCommitPlan(
            trackedTailCommit: TrackedTailCommit(
                text: replacement.trackedTailAfterReplacement,
                reason: "auto-correction completed"
            ),
            layoutSwitchCommit: nil,
            soundFeedbackEvent: .autoCorrection,
            productStatisticsEvent: .automaticSwitch,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: replacement.originalText,
                convertedText: replacement.replacementText,
                replacementMethod: replacement.undoMethod,
                origin: .autoCorrection(rule: decision.rule)
            )
        )
    }
}
