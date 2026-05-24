import Foundation
import PuntoCore

func runEventTapLifecyclePolicyTests() throws {
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: true,
            isDisabledByUserInput: false
        ),
        .reenableTap(reason: "tap disabled by timeout"),
        "event tap lifecycle policy re-enables tap disabled by timeout"
    )
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: false,
            isDisabledByUserInput: true
        ),
        .reenableTap(reason: "tap disabled by user input"),
        "event tap lifecycle policy re-enables tap disabled by user input"
    )
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: true,
            isDisabledByUserInput: true
        ),
        .reenableTap(reason: "tap disabled by timeout"),
        "event tap lifecycle policy gives timeout a stable priority"
    )
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: false,
            isDisabledByUserInput: false
        ),
        .ignore,
        "event tap lifecycle policy ignores ordinary events"
    )
}
