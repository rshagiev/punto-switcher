import Foundation

public enum InputSourceSwitchVerificationResult: Equatable {
    case switched
    case selectFailed(status: Int32)
    case layoutStayedSame(currentLayoutID: String?)
}

public enum InputSourceSwitchVerificationPolicy {
    public static func result(
        selectStatus: Int32,
        targetLayoutID: String?,
        currentLayoutIDAfterSwitch: String?
    ) -> InputSourceSwitchVerificationResult {
        guard selectStatus == 0 else {
            return .selectFailed(status: selectStatus)
        }

        guard let targetLayoutID = InputSourceSelectionPolicy.normalizedSourceID(targetLayoutID) else {
            return .layoutStayedSame(currentLayoutID: InputSourceSelectionPolicy.normalizedSourceID(currentLayoutIDAfterSwitch))
        }

        let currentLayoutID = InputSourceSelectionPolicy.normalizedSourceID(currentLayoutIDAfterSwitch)
        guard currentLayoutID == targetLayoutID else {
            return .layoutStayedSame(currentLayoutID: currentLayoutID)
        }

        return .switched
    }
}
