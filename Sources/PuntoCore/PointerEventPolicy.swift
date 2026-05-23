import Foundation

public enum PointerEventAction: Equatable {
    case clearTrackedText(reason: String)
    case ignore
}

public enum PointerEventPolicy {
    public static let leftMouseDownRawValue: UInt32 = 1
    public static let rightMouseDownRawValue: UInt32 = 3
    public static let otherMouseDownRawValue: UInt32 = 25

    public static func action(eventTypeRawValue: UInt32) -> PointerEventAction {
        switch eventTypeRawValue {
        case leftMouseDownRawValue, rightMouseDownRawValue, otherMouseDownRawValue:
            return .clearTrackedText(reason: "pointer click")
        default:
            return .ignore
        }
    }
}
