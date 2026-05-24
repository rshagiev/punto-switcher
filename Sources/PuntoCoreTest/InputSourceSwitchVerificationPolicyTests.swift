import Foundation
import PuntoCore

func runInputSourceSwitchVerificationPolicyTests() throws {
    try expect(
        InputSourceSwitchVerificationPolicy.result(
            selectStatus: 0,
            targetLayoutID: "com.apple.keylayout.Russian",
            currentLayoutIDAfterSwitch: "com.apple.keylayout.Russian"
        ),
        .switched,
        "input source switch verification accepts confirmed layout change"
    )
    try expect(
        InputSourceSwitchVerificationPolicy.result(
            selectStatus: -50,
            targetLayoutID: "com.apple.keylayout.Russian",
            currentLayoutIDAfterSwitch: "com.apple.keylayout.ABC"
        ),
        .selectFailed(status: -50),
        "input source switch verification preserves TIS select failure status"
    )
    try expect(
        InputSourceSwitchVerificationPolicy.result(
            selectStatus: 0,
            targetLayoutID: "com.apple.keylayout.Russian",
            currentLayoutIDAfterSwitch: "com.apple.keylayout.ABC"
        ),
        .layoutStayedSame(currentLayoutID: "com.apple.keylayout.ABC"),
        "input source switch verification rejects noErr when layout stayed unchanged"
    )
    try expect(
        InputSourceSwitchVerificationPolicy.result(
            selectStatus: 0,
            targetLayoutID: " com.apple.keylayout.Russian ",
            currentLayoutIDAfterSwitch: " com.apple.keylayout.Russian "
        ),
        .switched,
        "input source switch verification normalizes source ids"
    )
    try expect(
        InputSourceSwitchVerificationPolicy.result(
            selectStatus: 0,
            targetLayoutID: "com.apple.keylayout.Russian",
            currentLayoutIDAfterSwitch: nil
        ),
        .layoutStayedSame(currentLayoutID: nil),
        "input source switch verification rejects missing current layout evidence"
    )
}
