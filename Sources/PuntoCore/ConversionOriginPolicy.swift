import Foundation

public enum ConversionOriginPolicy {
    public static func originAfterUndo(_ origin: ConversionOrigin) -> ConversionOrigin {
        switch origin {
        case .layoutConversion:
            return .manualRedo
        case .manualRedo:
            return .layoutConversion
        case .toggleCase:
            return .toggleCase
        case .autoCorrection(let rule), .autoCorrectionRedo(let rule):
            return .autoCorrectionRedo(rule: rule)
        }
    }

    public static func originAfterUndo(record: ConversionRecord) -> ConversionOrigin {
        originAfterUndo(record.origin)
    }
}
