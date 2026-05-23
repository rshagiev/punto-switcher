import Foundation

public enum InputSourceChangeAction: Equatable {
    case ignoreProgrammaticSwitch(logMessage: String)
    case ignoreConversionInProgress(logMessage: String)
    case rememberLayoutAndClearTextState(InputSourceChangeRuntimePlan)
}

public struct InputSourceChangeRuntimePlan: Equatable {
    public let layoutMemoryReason: String
    public let clearTrackedTextReason: String
    public let clearConversionSessionReason: String
    public let logMessage: String

    public init(
        layoutMemoryReason: String,
        clearTrackedTextReason: String,
        clearConversionSessionReason: String,
        logMessage: String
    ) {
        self.layoutMemoryReason = layoutMemoryReason
        self.clearTrackedTextReason = clearTrackedTextReason
        self.clearConversionSessionReason = clearConversionSessionReason
        self.logMessage = logMessage
    }
}

public struct InputSourcePreferencesChangeAction: Equatable {
    public let shouldRefreshInputSources: Bool
    public let clearTrackedTextReason: String
    public let clearConversionSessionReason: String
    public let logMessage: String

    public init(
        shouldRefreshInputSources: Bool,
        clearTrackedTextReason: String,
        clearConversionSessionReason: String,
        logMessage: String
    ) {
        self.shouldRefreshInputSources = shouldRefreshInputSources
        self.clearTrackedTextReason = clearTrackedTextReason
        self.clearConversionSessionReason = clearConversionSessionReason
        self.logMessage = logMessage
    }
}

public enum InputSourceChangePolicy {
    public static func action(
        now: Date,
        ignoreChangesUntil: Date?,
        isConversionInProgress: Bool
    ) -> InputSourceChangeAction {
        if let ignoreChangesUntil, now < ignoreChangesUntil {
            return .ignoreProgrammaticSwitch(
                logMessage: "Input source changed - ignored (programmatic switch grace window)"
            )
        }

        if isConversionInProgress {
            return .ignoreConversionInProgress(
                logMessage: "Input source changed - ignored (conversion in progress)"
            )
        }

        return .rememberLayoutAndClearTextState(InputSourceChangeRuntimePlan(
            layoutMemoryReason: "input source changed",
            clearTrackedTextReason: "input source changed",
            clearConversionSessionReason: "input source changed",
            logMessage: "Input source changed - WordTracker cleared"
        ))
    }

    public static func nextIgnoreChangesUntil(
        now: Date,
        currentIgnoreChangesUntil: Date?
    ) -> Date? {
        guard let currentIgnoreChangesUntil else {
            return nil
        }

        return now < currentIgnoreChangesUntil ? currentIgnoreChangesUntil : nil
    }

    public static func preferencesChangeAction() -> InputSourcePreferencesChangeAction {
        InputSourcePreferencesChangeAction(
            shouldRefreshInputSources: true,
            clearTrackedTextReason: "Input source preferences changed",
            clearConversionSessionReason: "Input source preferences changed",
            logMessage: "Input source preferences changed - input sources refreshed"
        )
    }
}
