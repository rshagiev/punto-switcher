import Foundation
import PuntoCore

import Foundation
import PuntoCore

func runApplicationLayoutMemoryTests() throws {
    let memory = ApplicationLayoutMemory()

    try expectNil(memory.layoutID(for: "com.example.editor"), "empty layout memory")

    memory.remember(bundleID: "com.example.editor", layoutID: "com.apple.keylayout.ABC")
    try expect(
        memory.layoutID(for: "com.example.editor"),
        "com.apple.keylayout.ABC",
        "layout memory stores bundle layout"
    )

    memory.remember(bundleID: "com.example.terminal", layoutID: "com.apple.keylayout.Russian")
    try expect(
        memory.snapshot().count,
        2,
        "layout memory snapshot includes remembered apps"
    )

    memory.forget(bundleID: "com.example.editor")
    try expectNil(memory.layoutID(for: "com.example.editor"), "layout memory forgets app")

    memory.remember(bundleID: "", layoutID: "ignored")
    memory.remember(bundleID: "com.example.empty", layoutID: "")
    try expectNil(memory.layoutID(for: "com.example.empty"), "layout memory ignores empty ids")

    memory.remember(bundleID: "  COM.Example.Editor  ", layoutID: "  com.apple.keylayout.Russian  ")
    try expect(
        memory.layoutID(for: "com.example.editor"),
        "com.apple.keylayout.Russian",
        "layout memory normalizes bundle id case and whitespace on remember"
    )
    try expect(
        memory.snapshot()["com.example.editor"],
        "com.apple.keylayout.Russian",
        "layout memory snapshot stores normalized ids"
    )

    memory.replaceAll(with: [
        " COM.Example.Terminal ": " com.apple.keylayout.ABC ",
        "": "ignored",
        "com.example.empty": " "
    ])
    try expect(
        memory.layoutID(for: "com.example.terminal"),
        "com.apple.keylayout.ABC",
        "layout memory normalizes restored settings snapshot"
    )
    try expectNil(
        memory.layoutID(for: "com.example.empty"),
        "layout memory drops empty restored layout ids"
    )
}

func runApplicationBundleIDPolicyTests() throws {
    try expect(
        ApplicationBundleIDPolicy.normalized("  COM.Example.Editor  "),
        "com.example.editor",
        "application bundle id policy trims and lowercases ids"
    )
    try expectNil(
        ApplicationBundleIDPolicy.normalized("   "),
        "application bundle id policy rejects blank ids"
    )
    try expectNil(
        ApplicationBundleIDPolicy.normalized(nil),
        "application bundle id policy rejects missing ids"
    )
    try expect(
        ApplicationBundleIDPolicy.normalizedSet([" COM.Example.Editor ", "", "com.example.Terminal"]),
        ["com.example.editor", "com.example.terminal"],
        "application bundle id policy normalizes persisted sets"
    )
    try expect(
        ApplicationBundleIDPolicy.isScreenSaverEngine(" COM.Apple.ScreenSaver.Engine "),
        true,
        "application bundle id policy recognizes observed Punto Switcher screen saver engine bundle id"
    )
    try expect(
        ApplicationBundleIDPolicy.screenSaverEngineBundleID,
        ApplicationBundleIDPolicy.normalized(PuntoSwitcherObservedSurface.SystemApplications.screenSaverEngineBundleID),
        "application bundle id policy aligns normalized screen saver bundle id to reverse-audit anchor"
    )
    try expect(
        PuntoSwitcherObservedSurface.SystemApplications.screenSaverEngineBundleID,
        "com.apple.ScreenSaver.Engine",
        "observed surface preserves raw Punto Switcher screen saver engine bundle id casing"
    )
    try expect(
        ApplicationBundleIDPolicy.isVolatileSystemContext("com.apple.ScreenSaver.Engine"),
        true,
        "application bundle id policy treats screen saver engine as volatile system context"
    )
    try expect(
        ApplicationBundleIDPolicy.isVolatileSystemContext("com.example.editor"),
        false,
        "application bundle id policy keeps ordinary apps non-volatile"
    )
    try expect(
        ApplicationDisablePolicy.normalizedSet([" COM.Example.Editor ", "", "com.example.Terminal"]),
        ApplicationBundleIDPolicy.normalizedSet([" COM.Example.Editor ", "", "com.example.Terminal"]),
        "application disable policy shares bundle id normalization"
    )
    try expect(
        AccessibilityApplicationPolicy.isBrowserInjectionBundleID(" COM.Apple.Safari "),
        true,
        "accessibility app policy shares bundle id normalization"
    )

    let session = ConversionSession()
    session.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        contextID: " COM.Example.Editor "
    )
    try expect(
        session.lastConversion?.contextID,
        "com.example.editor",
        "conversion session shares bundle id normalization when recording context"
    )
    try expect(
        session.undoCandidate(contextID: "com.example.editor") != nil,
        true,
        "conversion session shares bundle id normalization when matching context"
    )
}

func runApplicationLayoutPolicyTests() throws {
    try expect(
        ApplicationLayoutPolicy.shouldRecordCurrentLayoutOnApplicationActivation(
            rememberInputSourceForEachApp: false
        ),
        false,
        "layout policy does not record app activation when memory disabled"
    )
    try expect(
        ApplicationLayoutPolicy.shouldRecordCurrentLayoutOnApplicationActivation(
            rememberInputSourceForEachApp: true
        ),
        false,
        "layout policy does not record new frontmost layout under previous app"
    )
    try expect(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        "com.example.editor",
        "layout policy restores remembered layout for external app"
    )
    try expect(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto"
        ),
        "com.example.editor",
        "layout policy normalizes restore bundle id"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto"
        ),
        "layout policy skips restore when Punto window activates"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            isApplicationDisabled: true
        ),
        "layout policy skips restore for disabled application"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: " COM.EXAMPLE.PUNTO ",
            ownBundleID: "com.example.punto"
        ),
        "layout policy normalizes own app id before restore decision"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: nil,
            ownBundleID: "com.example.punto"
        ),
        "layout policy skips restore without active bundle id"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.apple.ScreenSaver.Engine",
            ownBundleID: "com.example.punto"
        ),
        "layout policy skips restore for observed screen saver engine"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: "com.apple.keylayout.Russian",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .switchTo(layoutID: "com.apple.keylayout.Russian"),
        "layout policy switches to remembered layout when current layout differs"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: " com.apple.keylayout.Russian ",
            currentLayoutID: "com.apple.keylayout.Russian"
        ),
        .alreadyActive(layoutID: "com.apple.keylayout.Russian"),
        "layout policy skips TIS restore when remembered layout is already active"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: " com.apple.keylayout.Russian ",
            currentLayoutID: " com.apple.keylayout.Russian "
        ),
        .alreadyActive(layoutID: "com.apple.keylayout.Russian"),
        "layout policy normalizes layout ids before already-active restore decision"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            isApplicationDisabled: true,
            rememberedLayoutID: "com.apple.keylayout.Russian",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .skip,
        "layout policy skips restore action for disabled application"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: "com.apple.keylayout.Russian",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .skip,
        "layout policy skips restore action for Punto app"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: " ",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .skip,
        "layout policy skips restore action without remembered layout"
    )

    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        )?.layoutID,
        "com.apple.keylayout.Russian",
        "layout policy records successful programmatic switch for active app"
    )
    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            targetLayoutID: " com.apple.keylayout.Russian ",
            didSwitch: true
        )?.bundleID,
        "com.example.editor",
        "layout policy normalizes programmatic switch bundle id"
    )
    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            targetLayoutID: " com.apple.keylayout.Russian ",
            didSwitch: true
        )?.layoutID,
        "com.apple.keylayout.Russian",
        "layout policy normalizes programmatic switch layout id"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: false,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy skips programmatic switch memory when disabled"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: false
        ),
        "layout policy skips failed programmatic switch memory"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy skips programmatic switch memory for Punto app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.apple.ScreenSaver.Engine",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy skips programmatic switch memory for observed screen saver engine"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.EXAMPLE.PUNTO ",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy normalizes own app id before programmatic switch memory"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: " ",
            didSwitch: true
        ),
        "layout policy skips blank target layout id"
    )

    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        )?.layoutID,
        "com.apple.keylayout.US",
        "layout policy records observed input-source change for active external app"
    )
    let observedNormalizedUpdate = ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
        rememberInputSourceForEachApp: true,
        activeBundleID: " COM.Example.Editor ",
        frontmostBundleID: " COM.Example.Editor ",
        ownBundleID: "com.example.punto",
        currentLayoutID: " com.apple.keylayout.Russian "
    )
    try expect(
        observedNormalizedUpdate?.bundleID,
        "com.example.editor",
        "layout policy normalizes observed input-source bundle id"
    )
    try expect(
        observedNormalizedUpdate?.layoutID,
        "com.apple.keylayout.Russian",
        "layout policy normalizes observed input-source layout id"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy does not write Punto settings-window layout under last external app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.browser",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy does not write a frontmost app layout under a stale active app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.Example.Editor ",
            frontmostBundleID: " com.example.browser ",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy normalizes before rejecting active/frontmost mismatch"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: nil,
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory without known frontmost app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.punto",
            frontmostBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory for Punto app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.apple.ScreenSaver.Engine",
            frontmostBundleID: "com.apple.ScreenSaver.Engine",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory for observed screen saver engine"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: false,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory when disabled"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            currentLayoutID: " "
        ),
        "layout policy skips observed input-source memory without layout id"
    )
}
