import Foundation
import PuntoCore

func runInputSourceChangePolicyTests() throws {
    let now = Date(timeIntervalSince1970: 100)
    let future = now.addingTimeInterval(0.75)
    let past = now.addingTimeInterval(-0.01)

    try expect(
        InputSourceChangePolicy.action(
            now: now,
            ignoreChangesUntil: future,
            isConversionInProgress: false
        ),
        .ignoreProgrammaticSwitch(
            logMessage: "Input source changed - ignored (programmatic switch grace window)"
        ),
        "input source policy ignores programmatic switch inside grace window"
    )
    try expect(
        InputSourceChangePolicy.nextIgnoreChangesUntil(
            now: now,
            currentIgnoreChangesUntil: future
        ),
        future,
        "input source policy keeps active grace window"
    )
    try expect(
        InputSourceChangePolicy.action(
            now: now,
            ignoreChangesUntil: past,
            isConversionInProgress: true
        ),
        .ignoreConversionInProgress(
            logMessage: "Input source changed - ignored (conversion in progress)"
        ),
        "input source policy ignores changes during conversion after expired grace"
    )
    try expectNil(
        InputSourceChangePolicy.nextIgnoreChangesUntil(
            now: now,
            currentIgnoreChangesUntil: past
        ),
        "input source policy clears expired grace window"
    )
    try expect(
        InputSourceChangePolicy.action(
            now: now,
            ignoreChangesUntil: nil,
            isConversionInProgress: false
        ),
        .rememberLayoutAndClearTextState(InputSourceChangeRuntimePlan(
            layoutMemoryReason: "input source changed",
            clearTrackedTextReason: "input source changed",
            clearConversionSessionReason: "input source changed",
            logMessage: "Input source changed - WordTracker cleared"
        )),
        "input source policy clears state for ordinary user layout change"
    )
    try expect(
        InputSourceChangePolicy.preferencesChangeAction(),
        InputSourcePreferencesChangeAction(
            shouldRefreshInputSources: true,
            clearTrackedTextReason: "Input source preferences changed",
            clearConversionSessionReason: "Input source preferences changed",
            logMessage: "Input source preferences changed - input sources refreshed"
        ),
        "input source policy owns preference-refresh cleanup plan"
    )
}
