import Foundation

public enum UndoLayoutSwitchPolicy {
    public static func shouldSwitchLayoutAfterUndo(origin: ConversionOrigin) -> Bool {
        switch origin {
        case .layoutConversion, .manualRedo:
            return true
        case .toggleCase, .autoCorrection, .autoCorrectionRedo:
            return false
        }
    }
}
