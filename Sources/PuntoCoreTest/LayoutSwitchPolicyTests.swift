import Foundation
import PuntoCore

func runLayoutSwitchPolicyTests() throws {
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .lastWord,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true
        ),
        false,
        "layout switch policy respects global switch-off for last-word conversion"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true
        ),
        false,
        "layout switch policy respects global switch-off for selected-text conversion"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        true,
        "layout switch policy keeps last-word switching when selected-text switching is disabled"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .undo,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        true,
        "layout switch policy keeps undo layout switching when selected-text switching is disabled"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        false,
        "layout switch policy can suppress selected-text layout switching only"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true
        ),
        true,
        "layout switch policy allows selected-text layout switching when both switches are enabled"
    )

    let now = Date(timeIntervalSince1970: 500)
    let expectedDeadline = now.addingTimeInterval(ConversionProtectionPolicy.inputSourceSwitchGraceInterval)
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .lastWord,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .skip,
        "layout switch runtime skips when global switch is disabled"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .skip,
        "layout switch runtime skips selected text when selected-text switch is disabled"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .switchTo(LayoutSwitchRuntimeRequest(
            language: .russian,
            targetLayout: .russian,
            ignoreInputSourceChangesUntil: expectedDeadline
        )),
        "layout switch runtime requests Russian switch with programmatic grace deadline"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .english,
            surface: .undo,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .switchTo(LayoutSwitchRuntimeRequest(
            language: .english,
            targetLayout: .english,
            ignoreInputSourceChangesUntil: expectedDeadline
        )),
        "layout switch runtime requests English switch for undo"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .mixed,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .unsupportedTarget(clearInputSourceIgnoreDeadline: true),
        "layout switch runtime clears programmatic guard for mixed target"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .unknown,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .unsupportedTarget(clearInputSourceIgnoreDeadline: true),
        "layout switch runtime clears programmatic guard for unknown target"
    )
}
