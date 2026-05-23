import Foundation

public enum ConversionOrigin: Equatable {
    case layoutConversion
    case toggleCase
    case autoCorrection(rule: AutoCorrectionRule)
    case autoCorrectionRedo(rule: AutoCorrectionRule)
    case manualRedo
}

public struct ConversionRecord: Equatable {
    public let originalText: String
    public let convertedText: String
    public let timestamp: Date
    public let replacementMethod: TextReplacementMethod
    public let contextID: String?
    public let origin: ConversionOrigin

    public init(
        originalText: String,
        convertedText: String,
        timestamp: Date,
        replacementMethod: TextReplacementMethod,
        contextID: String? = nil,
        origin: ConversionOrigin = .layoutConversion
    ) {
        self.originalText = originalText
        self.convertedText = convertedText
        self.timestamp = timestamp
        self.replacementMethod = replacementMethod
        self.contextID = contextID
        self.origin = origin
    }
}

public final class ConversionSession {
    public let undoTimeout: TimeInterval
    public private(set) var lastConversion: ConversionRecord?

    public init(undoTimeout: TimeInterval = 3.0) {
        self.undoTimeout = undoTimeout
    }

    public func undoCandidate(now: Date = Date(), contextID: String? = nil) -> ConversionRecord? {
        guard let lastConversion else {
            return nil
        }

        let age = now.timeIntervalSince(lastConversion.timestamp)
        guard age >= 0 else {
            clear(reason: "future-dated undo record")
            return nil
        }

        guard age < undoTimeout else {
            clear(reason: "expired undo record")
            return nil
        }

        guard ApplicationBundleIDPolicy.normalized(lastConversion.contextID) == ApplicationBundleIDPolicy.normalized(contextID) else {
            return nil
        }

        return lastConversion
    }

    public func record(
        originalText: String,
        convertedText: String,
        replacementMethod: TextReplacementMethod,
        now: Date = Date(),
        contextID: String? = nil,
        origin: ConversionOrigin = .layoutConversion
    ) {
        guard !originalText.isEmpty,
              !convertedText.isEmpty,
              originalText != convertedText,
              replacementMethod != .blocked else {
            clear(reason: "invalid conversion record")
            return
        }

        lastConversion = ConversionRecord(
            originalText: originalText,
            convertedText: convertedText,
            timestamp: now,
            replacementMethod: replacementMethod,
            contextID: ApplicationBundleIDPolicy.normalized(contextID),
            origin: origin
        )
    }

    public func clear(reason: String = "unknown") {
        if let lastConversion {
            PuntoLog.debug("ConversionSession: clearing last conversion '\(lastConversion.convertedText)' (reason: \(reason))")
        }
        lastConversion = nil
    }
}
