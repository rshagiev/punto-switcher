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

func runConversionProtectionPolicyTests() throws {
    let now = Date(timeIntervalSince1970: 100)
    let dispatchNow = DispatchTime.now()

    try expect(
        ConversionProtectionPolicy.startupPermissionAlertDelay,
        0.5,
        "conversion protection policy keeps startup permission alert delay"
    )
    try expect(
        ConversionProtectionPolicy.inputSourceSwitchGraceInterval,
        0.75,
        "conversion protection policy keeps input source switch grace interval"
    )
    try expect(
        ConversionProtectionPolicy.eventRecaptureProtectionDelay,
        0.3,
        "conversion protection policy keeps event recapture protection delay"
    )
    try expect(
        ConversionProtectionPolicy.inputSourceIgnoreDeadline(now: now),
        now.addingTimeInterval(0.75),
        "conversion protection policy computes input source ignore deadline"
    )
    let replacementWindow = ConversionProtectionPolicy.replacementWindowAction(
        now: now,
        dispatchNow: dispatchNow
    )
    try expect(
        replacementWindow.ignoreAccessibilityNotificationsUntil,
        now.addingTimeInterval(ConversionProtectionPolicy.eventRecaptureProtectionDelay),
        "replacement window action uses recapture interval for accessibility notifications"
    )
    try expect(
        replacementWindow.releaseEventRecaptureAt,
        dispatchNow + ConversionProtectionPolicy.eventRecaptureProtectionDelay,
        "replacement window action uses recapture interval for hotkey release"
    )
    try expect(
        replacementWindow.shouldIgnoreHotkeyEvents,
        true,
        "replacement window action suppresses hotkey recapture while replacing text"
    )
    try expect(
        replacementWindow.markConversionInProgress,
        true,
        "replacement window action marks conversion in progress while replacing text"
    )
}

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

func runInputSourceLanguagePolicyTests() throws {
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.ABC",
            languages: []
        ),
        true,
        "input source language policy detects ABC layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.us",
            languages: []
        ),
        true,
        "input source language policy detects lowercase US layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.Russian",
            languages: [" EN "]
        ),
        true,
        "input source language policy detects normalized English language"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.Russian",
            languages: ["en-US"]
        ),
        true,
        "input source language policy detects English locale language"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.USInternational",
            languages: []
        ),
        true,
        "input source language policy detects USInternational layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.Dvorak",
            languages: []
        ),
        true,
        "input source language policy detects Dvorak English layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.Colemak",
            languages: []
        ),
        true,
        "input source language policy detects Colemak English layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.British-PC",
            languages: []
        ),
        true,
        "input source language policy detects British English layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.Australian",
            languages: []
        ),
        true,
        "input source language policy detects Australian English layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.example.bus",
            languages: []
        ),
        false,
        "input source language policy rejects glued US token"
    )
    try expect(
        InputSourceLanguagePolicy.isRussianInputSource(
            sourceID: "com.apple.keylayout.russian",
            languages: []
        ),
        true,
        "input source language policy detects lowercase Russian layout"
    )
    try expect(
        InputSourceLanguagePolicy.isRussianInputSource(
            sourceID: "com.apple.keylayout.RussianWin",
            languages: []
        ),
        true,
        "input source language policy detects Russian-PC layout"
    )
    try expect(
        KeyboardLayoutTypePolicy.isPreferredRussianSource(
            sourceID: "com.apple.keylayout.RussianWin",
            layoutType: .windows
        ),
        true,
        "keyboard layout type policy prefers RussianWin for Windows layout"
    )
    try expect(
        KeyboardLayoutTypePolicy.isPreferredRussianSource(
            sourceID: "com.apple.keylayout.Russian",
            layoutType: .mac
        ),
        true,
        "keyboard layout type policy prefers Russian for Mac layout"
    )
    try expect(
        KeyboardLayoutTypePolicy.normalized("pc"),
        .windows,
        "keyboard layout type policy normalizes pc alias"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isDefaultEnglishSource(" com.apple.keylayout.US "),
        true,
        "keyboard layout variant policy detects normalized US default English layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isDefaultEnglishSource("com.apple.keylayout.ABC"),
        true,
        "keyboard layout variant policy detects ABC default English layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isDefaultEnglishSource("com.apple.keylayout.USInternational"),
        false,
        "keyboard layout variant policy does not treat USInternational as default US"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.isAppleLayoutSelector,
        "isAppleLayout",
        "keyboard layout variant policy preserves observed Apple-layout selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.isDvorakSelector,
        "isDvorak",
        "keyboard layout variant policy preserves observed Dvorak selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.windowsLayoutUsedSelector,
        "windowsLayoutUsed",
        "keyboard layout variant policy preserves observed Windows-layout selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.fixStringSelector,
        "fixString:isEnglish:isApple:",
        "keyboard layout variant policy preserves observed punctuation-fix selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.createMacToPcMappingSelector,
        "createMacToPcMappingWithString:pcLayoutA:pcLayoutB:",
        "keyboard layout variant policy preserves observed Mac-to-PC mapping selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.convertStringLayoutSelector,
        "convertStringLayout:withMode:isPCLayout:",
        "keyboard layout variant policy preserves observed layout conversion selector"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isDvorakEnglishSource(" COM.APPLE.KEYLAYOUT.DVORAK "),
        true,
        "keyboard layout variant policy detects normalized Dvorak English layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isDvorakEnglishSource("com.example.dvorakish"),
        false,
        "keyboard layout variant policy rejects glued Dvorak token"
    )
    try expect(
        KeyboardLayoutVariantPolicy.englishLayoutVariant(for: " COM.APPLE.KEYLAYOUT.DVORAK "),
        .dvorak,
        "keyboard layout variant policy resolves Dvorak English variant"
    )
    try expect(
        KeyboardLayoutVariantPolicy.englishLayoutVariant(for: " com.apple.keylayout.ABC "),
        .qwerty,
        "keyboard layout variant policy resolves default English variant"
    )
    try expect(
        KeyboardLayoutVariantPolicy.effectiveEnglishLayoutVariant(
            currentSourceID: "com.apple.keylayout.Dvorak",
            selectedEnglishSourceID: "com.apple.keylayout.ABC",
            preferredEnglishSourceID: nil
        ),
        .dvorak,
        "keyboard layout variant policy lets active Dvorak source override selected default English"
    )
    try expect(
        KeyboardLayoutVariantPolicy.effectiveEnglishLayoutVariant(
            currentSourceID: "com.apple.keylayout.Russian",
            selectedEnglishSourceID: "com.apple.keylayout.Dvorak",
            preferredEnglishSourceID: "com.apple.keylayout.ABC"
        ),
        .dvorak,
        "keyboard layout variant policy falls back to selected English source when current source is Russian"
    )
    try expect(
        KeyboardLayoutVariantPolicy.effectiveEnglishLayoutVariant(
            currentSourceID: "com.apple.keylayout.Russian",
            selectedEnglishSourceID: nil,
            preferredEnglishSourceID: "com.apple.keylayout.Dvorak"
        ),
        .dvorak,
        "keyboard layout variant policy falls back to preferred English source before defaulting"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isAppleRussianSource(" com.apple.keylayout.Russian "),
        true,
        "keyboard layout variant policy detects normalized Apple Russian layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isAppleRussianSource("com.apple.keylayout.RussianWin"),
        false,
        "keyboard layout variant policy does not treat RussianWin as Apple Russian layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isWindowsRussianSource(" COM.APPLE.KEYLAYOUT.RUSSIANWIN "),
        true,
        "keyboard layout variant policy detects normalized Windows Russian layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isWindowsRussianSource("com.apple.keylayout.Russian"),
        false,
        "keyboard layout variant policy does not treat Apple Russian as Windows Russian layout"
    )
    try expect(
        InputSourceLanguagePolicy.isRussianInputSource(
            sourceID: "com.apple.keylayout.ABC",
            languages: [" RU "]
        ),
        true,
        "input source language policy detects normalized Russian language"
    )
    try expect(
        InputSourceLanguagePolicy.isRussianInputSource(
            sourceID: "com.apple.keylayout.ABC",
            languages: ["ru_RU"]
        ),
        true,
        "input source language policy detects Russian locale language"
    )
    try expect(
        InputSourceLanguagePolicy.isRussianInputSource(
            sourceID: "com.example.prussian",
            languages: []
        ),
        false,
        "input source language policy rejects glued Russian token"
    )
    try expect(
        InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
        ]),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy picks first selectable English and Russian layouts"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.RussianWin", languages: ["ru"], isSelectableKeyboard: true)
            ],
            preferredRussianLayoutType: .mac,
            preferredEnglishSourceID: " com.apple.keylayout.Dvorak ",
            preferredRussianSourceID: " com.apple.keylayout.RussianWin "
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.Dvorak",
            russianSourceID: "com.apple.keylayout.RussianWin"
        ),
        "input source selection policy honors explicit preferred English and Russian layout ids"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.US", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
            ]
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.US",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy prefers Punto Switcher-style default English layout over Dvorak"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.USInternational", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
            ]
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy prefers modern default ABC over English variants"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.US", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
            ],
            preferredEnglishSourceID: "com.apple.keylayout.Dvorak"
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.Dvorak",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy keeps explicit English layout id stronger than default English"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.RussianWin", languages: ["ru"], isSelectableKeyboard: true)
            ],
            preferredRussianLayoutType: .windows
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.RussianWin"
        ),
        "input source selection policy prefers RussianWin when Windows layout is configured without explicit Russian id"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
            ],
            preferredRussianLayoutType: .windows
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy falls back when RussianWin is unavailable"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true, isEnabled: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.RussianWin", languages: ["ru"], isSelectableKeyboard: true, isEnabled: false)
            ],
            preferredRussianLayoutType: .windows
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.RussianWin",
            sourceIDsToEnable: ["com.apple.keylayout.RussianWin"]
        ),
        "input source selection policy chooses disabled RussianWin for Punto-style enabling when Windows layout is configured"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
            ],
            preferredEnglishSourceID: "com.apple.keylayout.Missing",
            preferredRussianSourceID: "com.apple.keylayout.Missing"
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy falls back when explicit preferred layout ids are unavailable"
    )
    try expect(
        InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: false),
            InputSourceCandidate(sourceID: "com.apple.keylayout.US", languages: [], isSelectableKeyboard: true),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
        ]),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.US",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy ignores non-selectable layout candidates"
    )
    try expect(
        InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true, isEnabled: false),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true, isEnabled: true),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true, isEnabled: false),
            InputSourceCandidate(sourceID: "com.apple.keylayout.RussianWin", languages: ["ru"], isSelectableKeyboard: true, isEnabled: true)
        ]),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.Dvorak",
            russianSourceID: "com.apple.keylayout.Russian",
            sourceIDsToEnable: ["com.apple.keylayout.Russian"]
        ),
        "input source selection policy enables disabled preferred Mac Russian before falling back to Windows Russian"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true, isEnabled: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true, isEnabled: false),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true, isEnabled: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.RussianWin", languages: ["ru"], isSelectableKeyboard: true, isEnabled: false)
            ],
            preferredRussianLayoutType: .windows,
            preferredEnglishSourceID: "com.apple.keylayout.Dvorak",
            preferredRussianSourceID: "com.apple.keylayout.RussianWin"
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.Dvorak",
            russianSourceID: "com.apple.keylayout.RussianWin",
            sourceIDsToEnable: [
                "com.apple.keylayout.Dvorak",
                "com.apple.keylayout.RussianWin"
            ]
        ),
        "input source selection policy chooses disabled explicit preferred layouts for Punto-style enabling"
    )
    let allDisabledSelection = InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true, isEnabled: false),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true, isEnabled: false)
    ])
    try expect(
        allDisabledSelection,
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian",
            sourceIDsToEnable: [
                "com.apple.keylayout.ABC",
                "com.apple.keylayout.Russian"
            ]
        ),
        "input source selection policy chooses disabled required layouts for Punto-style enabling"
    )
    try expect(
        InputSourceSelectionPolicy.shouldEnableInputSource(
            sourceID: " com.apple.keylayout.ABC ",
            selection: allDisabledSelection
        ),
        true,
        "input source selection policy marks selected disabled English source for enabling"
    )
    try expect(
        InputSourceSelectionPolicy.shouldEnableInputSource(
            sourceID: "com.apple.keylayout.US",
            selection: allDisabledSelection
        ),
        false,
        "input source selection policy does not enable unselected sources"
    )
    let missingSelection = InputSourceSelection(englishSourceID: nil, russianSourceID: "com.apple.keylayout.Russian")
    try expect(
        PuntoSwitcherObservedSurface.InputSources.inputSourceEnabledSelector,
        "inputSourceEnabled:",
        "input source selection policy preserves observed enabled selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.InputSources.handleInputSourcesEnabledSelector,
        "handleInputSourcesEnabled",
        "input source selection policy preserves observed enabled handler selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.InputSources.promptUserToInstallLayoutsSelector,
        "promptUserToInstallLayouts",
        "input source selection policy preserves observed install-layouts prompt selector"
    )
    try expect(
        InputSourceSelectionPolicy.inputSourceEnabledLogPrefix,
        PuntoSwitcherObservedSurface.InputSources.inputSourceEnabledSelector,
        "input source selection policy keeps enabled-layout log prefix aligned with reverse-audit anchor"
    )
    try expect(
        InputSourceSelectionPolicy.handleInputSourcesEnabledLogPrefix,
        PuntoSwitcherObservedSurface.InputSources.handleInputSourcesEnabledSelector,
        "input source selection policy keeps enabled-layout handler prefix aligned with reverse-audit anchor"
    )
    try expect(
        InputSourceSelectionPolicy.promptUserToInstallLayoutsLogPrefix,
        PuntoSwitcherObservedSurface.InputSources.promptUserToInstallLayoutsSelector,
        "input source selection policy keeps install-layout prompt prefix aligned with reverse-audit anchor"
    )
    try expect(
        InputSourceSelectionPolicy.missingRequiredLanguageNames(in: missingSelection),
        ["English"],
        "input source selection policy reports missing English layout"
    )
    try expect(
        InputSourceSelectionPolicy.shouldPromptUserToInstallLayouts(selection: missingSelection),
        true,
        "input source selection policy prompts when a required layout is missing"
    )
    try expect(
        InputSourceSelectionPolicy.missingRequiredLayoutsLogMessage(selection: missingSelection),
        "promptUserToInstallLayouts: missing English input source",
        "input source selection policy logs observed prompt path for missing layout"
    )
    try expect(
        InputSourceSelectionPolicy.inputSourceEnabledLogMessage(sourceID: "com.apple.keylayout.Russian"),
        "inputSourceEnabled: com.apple.keylayout.Russian",
        "input source selection policy logs observed enabled-layout selector shape"
    )
    try expect(
        InputSourceSelectionPolicy.handleInputSourcesEnabledLogMessage(sourceIDs: [
            "com.apple.keylayout.Russian",
            " com.apple.keylayout.ABC ",
            "com.apple.keylayout.Russian"
        ]),
        "handleInputSourcesEnabled: com.apple.keylayout.ABC, com.apple.keylayout.Russian",
        "input source selection policy logs observed enabled-layout handler shape"
    )
    try expectNil(
        InputSourceSelectionPolicy.handleInputSourcesEnabledLogMessage(sourceIDs: [" ", "UNDEFINED"]),
        "input source selection policy skips empty enabled-layout handler logs"
    )
    try expect(
        InputSourceSelectionPolicy.failedToEnableLayoutLogMessage(
            sourceID: "com.apple.keylayout.Russian",
            status: -50
        ),
        "Failed to enable layout com.apple.keylayout.Russian! Error code: -50",
        "input source selection policy logs observed failed-enable shape"
    )
    try expectNil(
        InputSourceSelectionPolicy.missingRequiredLayoutsLogMessage(
            selection: InputSourceSelection(
                englishSourceID: "com.apple.keylayout.ABC",
                russianSourceID: "com.apple.keylayout.Russian"
            )
        ),
        "input source selection policy stays quiet when required layouts are present"
    )
    try expect(
        InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: " com.apple.keylayout.ABC ", languages: ["en", "ru"], isSelectableKeyboard: true),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: [], isSelectableKeyboard: true)
        ]),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy keeps English and Russian sources distinct"
    )
    try expect(
        InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en", "ru"], isSelectableKeyboard: true)
        ]),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: nil
        ),
        "input source selection policy does not assign one source to both languages"
    )
    try expect(
        InputSourceSelectionPolicy.normalizedSourceID(" \n\t "),
        nil,
        "input source selection policy rejects blank source id"
    )
}

func runApplicationContextPolicyTests() throws {
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto"
        ),
        .preserveCurrentExternalContext(
            logMessage: "Punto window activated - preserving last external app 'com.example.editor'"
        ),
        "app context policy preserves external context when Punto activates"
    )
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.chat",
            ownBundleID: "com.example.punto"
        ),
        .activateExternal(ApplicationContextActivationPlan(
            shouldResetTextState: true,
            clearTrackedTextReason: "active application changed",
            clearConversionSessionReason: "active application changed"
        )),
        "app context policy plans external app-switch cleanup"
    )
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: nil,
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        .activateExternal(ApplicationContextActivationPlan(
            shouldResetTextState: false,
            clearTrackedTextReason: nil,
            clearConversionSessionReason: nil
        )),
        "app context policy keeps initial external activation clean"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: nil,
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy keeps empty initial context"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy keeps same app context"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: " COM.Example.Editor ",
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy normalizes app context ids"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.chat",
            ownBundleID: "com.example.punto"
        ),
        true,
        "app context policy resets text state on external app switch"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy preserves state when Punto window activates"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: " COM.EXAMPLE.PUNTO ",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy normalizes own app id"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: nil,
            ownBundleID: "com.example.punto"
        ),
        true,
        "app context policy resets when external app context is lost"
    )
}

func runHotkeyRoutingPolicyTests() throws {
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: true, isCurrentApplicationDisabled: false),
        true,
        "hotkey routing handles enabled active app"
    )
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: false, isCurrentApplicationDisabled: false),
        false,
        "hotkey routing passes through when Punto is disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: true, isCurrentApplicationDisabled: true),
        false,
        "hotkey routing passes through disabled application"
    )
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: false, isCurrentApplicationDisabled: true),
        false,
        "hotkey routing passes through when both global and app disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldTrackKeyState(isEnabled: true, isCurrentApplicationDisabled: false),
        true,
        "key-state routing tracks enabled active app"
    )
    try expect(
        HotkeyRoutingPolicy.shouldTrackKeyState(isEnabled: false, isCurrentApplicationDisabled: false),
        false,
        "key-state routing skips when Punto is disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldTrackKeyState(isEnabled: true, isCurrentApplicationDisabled: true),
        false,
        "key-state routing skips disabled application"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: true, isEnabled: false),
        true,
        "enabled transition clears state when Punto is disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: false, isEnabled: true),
        false,
        "enabled transition keeps state when Punto is enabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: true, isEnabled: true),
        false,
        "enabled transition keeps state when enabled stays enabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: false, isEnabled: false),
        false,
        "enabled transition keeps state when disabled stays disabled"
    )
    try expect(
        HotkeyRoutingPolicy.stateClearActionAfterEnabledChange(wasEnabled: true, isEnabled: false),
        HotkeyRoutingStateClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "Punto disabled",
            clearConversionSessionReason: "Punto disabled",
            logMessage: "Punto disabled - cleared text state"
        ),
        "hotkey routing owns global-disable state cleanup action"
    )
    try expect(
        HotkeyRoutingPolicy.stateClearActionAfterEnabledChange(wasEnabled: true, isEnabled: true),
        HotkeyRoutingStateClearAction(clearTrackedText: false, clearConversionSession: false),
        "hotkey routing keeps state when enabled state does not transition to disabled"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .modifierOnlyConvertLayout,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            displayString: "Cmd+Opt+Shift"
        ),
        .handle(logMessage: "Modifier-only hotkey triggered: Cmd+Opt+Shift"),
        "hotkey routing owns modifier-only matched log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .modifierOnlyConvertLayout,
            isEnabled: false,
            isCurrentApplicationDisabled: false,
            displayString: "Cmd+Opt+Shift"
        ),
        .passThrough(logMessage: "Modifier-only hotkey ignored by routing policy"),
        "hotkey routing owns modifier-only pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .convertLayout,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            keyCode: 6
        ),
        .handle(logMessage: "Convert layout hotkey matched! keyCode=6"),
        "hotkey routing owns convert hotkey matched log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .toggleCase,
            isEnabled: false,
            isCurrentApplicationDisabled: false,
            keyCode: 6
        ),
        .passThrough(logMessage: "Toggle case hotkey passed through by routing policy"),
        "hotkey routing owns toggle-case pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .toggleAutoCorrection,
            isEnabled: true,
            isCurrentApplicationDisabled: true,
            keyCode: 0
        ),
        .passThrough(logMessage: "Toggle auto-correction hotkey passed through by routing policy"),
        "hotkey routing owns auto-correction toggle pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .cancelLayoutChange,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            keyCode: 51
        ),
        .handle(logMessage: "Cancel layout change hotkey matched! keyCode=51"),
        "hotkey routing owns cancel-layout matched log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .findInYandex,
            isEnabled: false,
            isCurrentApplicationDisabled: true,
            keyCode: 3
        ),
        .passThrough(logMessage: "Find in Yandex hotkey passed through by routing policy"),
        "hotkey routing owns Yandex search pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .findInSlovari,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            keyCode: 5
        ),
        .handle(logMessage: "Find in Slovari hotkey matched! keyCode=5"),
        "hotkey routing owns Slovari hotkey matched log"
    )
}

func runKeyTrackingRuntimePolicyTests() throws {
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .track,
        "key tracking runtime tracks normal enabled input"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipRouting(logMessage: "Key tracking skipped by routing policy"),
        "key tracking runtime skips when Punto is disabled"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipRouting(logMessage: "Key tracking skipped by routing policy"),
        "key tracking runtime skips disabled applications"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockSecureInput(context: "secure input", logMessage: "Key tracking skipped for secure/password input"),
        "key tracking runtime blocks secure input before tracking text"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockSecureInput(context: "password field", logMessage: "Key tracking skipped for secure/password input"),
        "key tracking runtime blocks password fields before tracking text"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "org.telegram.desktop",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .resetOnReturn,
        "key tracking runtime routes reset-on-return apps away from auto-correction"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "com.apple.TextEdit",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .runAutoCorrection,
        "key tracking runtime keeps ordinary editors eligible for return auto-correction"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "org.telegram.desktop",
            keyCode: 49,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .runAutoCorrection,
        "key tracking runtime ignores non-return keys for reset-on-return apps"
    )
    try expect(
        KeyTrackingRuntimePolicy.resetOnReturnPlan(
            consumedCompletedToken: true,
            bundleID: "org.telegram.desktop"
        ),
        KeyTrackingResetPlan(
            completedTokenStatisticsEvent: .completedWord,
            conversionSessionClearReason: "return in reset-on-return app",
            logMessage: "Auto-correction skipped and text state reset on Return for app 'org.telegram.desktop'"
        ),
        "key tracking runtime records completed word and clears undo for reset-on-return"
    )
    try expect(
        KeyTrackingRuntimePolicy.resetOnReturnPlan(
            consumedCompletedToken: false,
            bundleID: nil
        ),
        KeyTrackingResetPlan(
            completedTokenStatisticsEvent: nil,
            conversionSessionClearReason: "return in reset-on-return app",
            logMessage: "Auto-correction skipped and text state reset on Return for app '?'"
        ),
        "key tracking runtime handles reset-on-return without completed token"
    )
    try expect(
        KeyTrackingRuntimePolicy.conversionSessionClearReasonAfterAutoCorrection(isConversionInProgress: false),
        "key press",
        "key tracking runtime clears stale undo after ordinary non-converting key press"
    )
    try expectNil(
        KeyTrackingRuntimePolicy.conversionSessionClearReasonAfterAutoCorrection(isConversionInProgress: true),
        "key tracking runtime preserves undo while auto-correction conversion window is active"
    )
}

func runTextActionPreflightPolicyTests() throws {
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "text action preflight allows normal conversion"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "toggle case disabled"),
        "text action preflight skips disabled toggle case"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "manual conversion disabled"),
        "text action preflight skips manual layout conversion when manually disabled"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "text action preflight keeps toggle-case available when manual conversion is disabled"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "conversion already in progress"),
        "text action preflight skips nested conversion"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "current app disabled"),
        "text action preflight skips disabled application"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: false
        ),
        .blockAndClear(reason: "secure input"),
        "text action preflight clears state for secure input"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "text action preflight clears state for password fields"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "text action preflight gives secure input priority over password field"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .blockAndClear(reason: "password field"),
            kind: .toggleCase
        ),
        "Password field detected - toggle case blocked",
        "text action preflight preserves toggle-case password log"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .skip(reason: "manual conversion disabled"),
            kind: .layoutConversion
        ),
        "Manual conversion disabled, skipping conversion",
        "text action preflight preserves manual-conversion-disabled log"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .skip(reason: "current app disabled"),
            kind: .layoutConversion
        ),
        "Current app disabled, skipping conversion",
        "text action preflight preserves conversion disabled-app log"
    )
}

func runTextActionRuntimePreflightPolicyTests() throws {
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false
        ),
        .proceed,
        "text action runtime preflight route allows normal conversion"
    )
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false
        ),
        .skip(reason: "manual conversion disabled"),
        "text action runtime preflight route keeps manual-conversion setting in route phase"
    )
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .selectedTextSearch,
            isEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false
        ),
        .skip(reason: "selected text search already in progress"),
        "text action runtime preflight route blocks nested selected-text search"
    )
    try expect(
        TextActionRuntimePreflightPolicy.securityAction(
            kind: .selectedTextSearch,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "text action runtime preflight security gives secure input priority"
    )
    try expect(
        TextActionRuntimePreflightPolicy.securityAction(
            kind: .toggleCase,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "text action runtime preflight security blocks password fields"
    )
}

func runPointerEventPolicyTests() throws {
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on left mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.rightMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on right mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.otherMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on other mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: 2),
        .ignore,
        "pointer event policy ignores mouse up"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: 10),
        .ignore,
        "pointer event policy ignores non-click events"
    )
}

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

func runAccessibilityNotificationPolicyTests() throws {
    let now = Date(timeIntervalSince1970: 1_000)

    try expect(
        AccessibilityNotificationPolicy.supportedNotifications,
        [
            AccessibilityNotificationPolicy.focusedUIElementChanged,
            AccessibilityNotificationPolicy.focusedWindowChanged,
            AccessibilityNotificationPolicy.mainWindowChanged,
            AccessibilityNotificationPolicy.windowCreated,
            AccessibilityNotificationPolicy.selectedTextChanged,
            AccessibilityNotificationPolicy.valueChanged
        ],
        "accessibility notification policy observes focus, main-window, window creation, selection, and value changes"
    )
    try expect(
        AccessibilityNotificationPolicy.supportedNotifications,
        [
            PuntoSwitcherObservedSurface.AccessibilityNotifications.focusedUIElementChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.focusedWindowChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.mainWindowChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.windowCreated,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.selectedTextChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.valueChanged
        ],
        "accessibility notification policy aligns native notification names to reverse-audit anchors"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedUIElementChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXFocusedUIElementChanged"),
        "accessibility notification policy clears state on focused element changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXSelectedTextChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "text mutation notification is diagnostic"),
        "accessibility notification policy keeps typed tracking on noisy selection changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXMainWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXMainWindowChanged"),
        "accessibility notification policy clears state when the main window changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXWindowCreated",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXWindowCreated"),
        "accessibility notification policy clears state when a new window is created"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXValueChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "text mutation notification is diagnostic"),
        "accessibility notification policy observes but does not clear on ordinary value changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: now.addingTimeInterval(0.1),
            isConversionInProgress: false
        ),
        .ignore(reason: "replacement grace window"),
        "accessibility notification policy suppresses replacement-window notifications"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: now,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXFocusedWindowChanged"),
        "accessibility notification policy clears after replacement grace window expires"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: true
        ),
        .ignore(reason: "conversion in progress"),
        "accessibility notification policy suppresses in-flight conversions"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: " COM.Example.Punto ",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "own application"),
        "accessibility notification policy ignores Punto's own windows"
    )
    try expect(
        ConversionProtectionPolicy.eventRecaptureIgnoreDeadline(now: now),
        now.addingTimeInterval(ConversionProtectionPolicy.eventRecaptureProtectionDelay),
        "conversion protection policy shares replacement grace interval with accessibility notifications"
    )
}

func runTextTrackingSecurityPolicyTests() throws {
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: false, isPasswordField: false),
        true,
        "text tracking security allows normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: true, isPasswordField: false),
        false,
        "text tracking security blocks secure input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: false, isPasswordField: true),
        false,
        "text tracking security blocks password fields"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: true, isPasswordField: true),
        false,
        "text tracking security blocks combined secure password context"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: false, isPasswordField: false),
        false,
        "text tracking security keeps state for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: true, isPasswordField: false),
        true,
        "text tracking security clears state for secure input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: false, isPasswordField: true),
        true,
        "text tracking security clears state for password fields"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: true, isPasswordField: true),
        true,
        "text tracking security clears state for combined secure password context"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: false, isPasswordField: false),
        false,
        "text tracking security skips secure diagnostics for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: true, isPasswordField: false),
        true,
        "text tracking security writes secure diagnostics when secure input blocks tracking"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: false, isPasswordField: true),
        true,
        "text tracking security writes secure diagnostics when password fields block tracking"
    )
    try expectNil(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: false, isPasswordField: false),
        "text tracking security omits secure diagnostics context for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: true, isPasswordField: false),
        "secure input",
        "text tracking security reports secure-input diagnostics context"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: false, isPasswordField: true),
        "password field",
        "text tracking security reports password-field diagnostics context"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: true, isPasswordField: true),
        "secure input",
        "text tracking security gives secure input diagnostics priority over password field"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: false, isPasswordField: false),
        TextTrackingSecurityClearAction(clearTrackedText: false, clearConversionSession: false),
        "text tracking security keeps state for normal clear action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: true, isPasswordField: false),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "secure input",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security owns secure-input state cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: false, isPasswordField: true),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "password field",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security owns password-field state cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: true, isPasswordField: true),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "secure input",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security gives secure input priority in combined cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: "AXSecureTextField"),
        true,
        "text tracking security detects secure text subrole"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXSecureTextField", subrole: nil),
        true,
        "text tracking security detects secure text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: " axsecuretextfield ", subrole: nil),
        true,
        "text tracking security normalizes secure text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: " AX Secure Text Field ", subrole: nil),
        true,
        "text tracking security shares AX role normalization with accessibility role policy"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: "AXPasswordTextField"),
        true,
        "text tracking security detects password-like subrole"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: nil),
        false,
        "text tracking security allows ordinary text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXWebArea", subrole: "AXSearchField"),
        false,
        "text tracking security allows ordinary web/search text roles"
    )

    let diagnosticsSnapshot = SecureInputDiagnosticsPolicy.snapshot(
        secureInputState: true,
        context: " secure text input ",
        currentApp: " COM.Apple.Terminal ",
        runningApps: ["com.apple.Terminal", "COM.APPLE.TERMINAL", nil, " "],
        enabledLayouts: ["com.apple.keylayout.ABC", "UNDEFINED", " com.apple.keylayout.Russian "]
    )
    try expect(
        diagnosticsSnapshot,
        SecureInputDiagnosticsSnapshot(
            secureInputState: true,
            context: "secure text input",
            currentApp: "com.apple.terminal",
            runningApps: ["com.apple.terminal"],
            enabledLayouts: ["com.apple.keylayout.ABC", "com.apple.keylayout.Russian"]
        ),
        "secure input diagnostics policy normalizes Punto Switcher-style plist fields"
    )
    let diagnosticsDictionary = SecureInputDiagnosticsPolicy.plistDictionary(from: diagnosticsSnapshot)
    try expect(
        SecureInputDiagnosticsPolicy.secureInputDiagnosticsPlistFilename,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.plistFilename,
        "secure input diagnostics policy aligns plist filename to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.secureInputStateKey] as? Bool,
        true,
        "secure input diagnostics writes SecureInputState key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.secureInputStateKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.secureInputStateKey,
        "secure input diagnostics policy aligns secure input key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.contextKey] as? String,
        "secure text input",
        "secure input diagnostics writes Context key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.contextKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.contextKey,
        "secure input diagnostics policy aligns context key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.currentAppKey] as? String,
        "com.apple.terminal",
        "secure input diagnostics writes currentApp key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.currentAppKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.currentAppKey,
        "secure input diagnostics policy aligns current-app key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.runningAppsKey] as? [String],
        ["com.apple.terminal"],
        "secure input diagnostics writes runningApps key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.runningAppsKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.runningAppsKey,
        "secure input diagnostics policy aligns running-apps key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.enabledLayoutsKey] as? [String],
        ["com.apple.keylayout.ABC", "com.apple.keylayout.Russian"],
        "secure input diagnostics writes enabledLayouts key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.enabledLayoutsKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.enabledLayoutsKey,
        "secure input diagnostics policy aligns enabled-layouts key to reverse-audit anchor"
    )
}

func runAccessibilityRolePolicyTests() throws {
    try expect(
        AccessibilityRolePolicy.normalizedRole(" ax web area "),
        "axwebarea",
        "accessibility role policy normalizes whitespace and case"
    )
    try expectNil(
        AccessibilityRolePolicy.normalizedRole("   "),
        "accessibility role policy rejects blank role"
    )
    try expect(
        AccessibilityRolePolicy.isWebAreaRole("AXWebArea"),
        true,
        "accessibility role policy detects AXWebArea"
    )
    try expect(
        AccessibilityRolePolicy.containsWebAreaRole(["AXStaticText", "AXGroup", "AXWebArea"]),
        true,
        "accessibility role policy detects AXWebArea ancestry"
    )
    try expect(
        AccessibilityRolePolicy.containsWebAreaRole(["AXStaticText", "AXGroup", "AXWindow"]),
        false,
        "accessibility role policy rejects static ancestry without AXWebArea"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityMailReplacement.fullWordReplacementSelector,
        "applyMailBehaviourForFullWords:withEvent:withCharsToSelect:withForceWordEndingCharPresent:",
        "accessibility role policy pins observed Punto Switcher Mail full-word helper selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityMailReplacement.partialWordReplacementSelector,
        "applyMailBehaviourForPartialWords:",
        "accessibility role policy pins observed Punto Switcher Mail partial-word helper selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityMailReplacement.deletionCounterKey,
        "numberOfDeletionsInMail",
        "accessibility role policy pins observed Punto Switcher Mail deletion counter"
    )
    try expect(
        AccessibilityRolePolicy.mailApplicationToken,
        PuntoSwitcherObservedSurface.AccessibilityRoles.mailApplicationToken,
        "accessibility role policy aligns native Mail app token to reverse-audit anchor"
    )
    try expect(
        AccessibilityRolePolicy.parallelsBundleID,
        PuntoSwitcherObservedSurface.AccessibilityRoles.parallelsBundleID,
        "accessibility role policy aligns native Parallels bundle id to reverse-audit anchor"
    )
    try expect(
        AccessibilityRolePolicy.scrollAreaRole,
        PuntoSwitcherObservedSurface.AccessibilityRoles.scrollAreaRole,
        "accessibility role policy aligns native scroll-area role to reverse-audit anchor"
    )
    try expect(
        AccessibilityRolePolicy.isClipboardReplaceableContentRole("AXScrollArea"),
        true,
        "accessibility role policy mirrors observed Punto Switcher AXScrollArea content surface"
    )
    try expect(
        AccessibilityRolePolicy.containsClipboardReplaceableContentRole(["AXStaticText", "AXScrollArea"]),
        true,
        "accessibility role policy detects observed clipboard-replaceable content ancestry"
    )
    try expect(
        AccessibilityRolePolicy.containsClipboardReplaceableContentRole(["AXStaticText", "AXGroup"]),
        false,
        "accessibility role policy rejects generic content ancestry for active clipboard replacement"
    )
    for role in ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"] {
        try expect(
            AccessibilityRolePolicy.isEditableTextRole(role),
            true,
            "accessibility role policy treats \(role) as editable text"
        )
    }
    for role in ["AXStaticText", "AXList", "AXTable", "AXButton", "AXWindow", "AXScrollArea"] {
        try expect(
            AccessibilityRolePolicy.isNonEditableContentRole(role),
            true,
            "accessibility role policy treats \(role) as non-editable content"
        )
    }
    try expect(
        AccessibilityRolePolicy.isEditableTextRole("AXStaticText"),
        false,
        "accessibility role policy does not treat static text as editable"
    )
    try expect(
        AccessibilityRolePolicy.isNonEditableContentRole("AXTextArea"),
        false,
        "accessibility role policy does not treat text area as non-editable content"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXTextArea",
            axEditable: true,
            selectedTextSettable: false
        ),
        true,
        "accessibility role policy accepts editable text area replacement"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXComboBox",
            axEditable: false,
            selectedTextSettable: true
        ),
        true,
        "accessibility role policy accepts settable editable-role replacement"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: nil,
            axEditable: nil,
            selectedTextSettable: true
        ),
        true,
        "accessibility role policy preserves settable replacement for unknown roles"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXStaticText",
            axEditable: true,
            selectedTextSettable: true
        ),
        false,
        "accessibility role policy blocks direct replacement for static content role"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXList",
            axEditable: false,
            selectedTextSettable: true
        ),
        false,
        "accessibility role policy blocks direct replacement for navigation/list role"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXScrollArea",
            axEditable: true,
            selectedTextSettable: true
        ),
        false,
        "accessibility role policy blocks direct replacement for observed AXScrollArea content"
    )
    let editableTextAreaCapability = AccessibilityReplacementCapability(
        role: "AXTextArea",
        axEditable: true,
        selectedTextSettable: false,
        selectedTextSettableErrorCode: -25205
    )
    try expect(
        editableTextAreaCapability.supportsDirectSelectedTextReplacement,
        true,
        "accessibility replacement capability accepts editable text area evidence"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(editableTextAreaCapability),
        true,
        "accessibility role policy accepts typed replacement capability evidence"
    )
    try expect(
        editableTextAreaCapability.logDescription,
        "role=AXTextArea axEditable=true selectedTextSettable=false settableError=-25205",
        "accessibility replacement capability preserves AX evidence for diagnostics"
    )
    let staticContentCapability = AccessibilityReplacementCapability(
        role: "AXStaticText",
        axEditable: true,
        selectedTextSettable: true,
        selectedTextSettableErrorCode: 0
    )
    try expect(
        staticContentCapability.supportsDirectSelectedTextReplacement,
        false,
        "accessibility replacement capability blocks static content despite optimistic AX flags"
    )
    let unknownSettableCapability = AccessibilityReplacementCapability(
        role: nil,
        axEditable: nil,
        selectedTextSettable: true,
        selectedTextSettableErrorCode: 0
    )
    try expect(
        unknownSettableCapability.supportsDirectSelectedTextReplacement,
        true,
        "accessibility replacement capability preserves settable unknown-role support"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXTextField",
            bundleID: nil,
            context: .searchbar
        ),
        true,
        "accessibility role policy mirrors global searchbar editable-role exception"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXApplication",
            bundleID: nil,
            context: .searchbar
        ),
        true,
        "accessibility role policy mirrors AXApplication searchbar-only exception"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXApplication",
            bundleID: nil,
            context: .click
        ),
        false,
        "accessibility role policy keeps AXApplication out of click exceptions"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXGroup",
            bundleID: "com.apple.finder",
            context: .click
        ),
        true,
        "accessibility role policy mirrors Finder click group exception"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXGroup",
            bundleID: "com.apple.finder",
            context: .searchbar
        ),
        false,
        "accessibility role policy keeps Finder group click-only exception scoped"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXMenuItem",
            bundleID: "ORG.MOZILLA.FIREFOX",
            context: .click
        ),
        true,
        "accessibility role policy normalizes app-specific search exception bundle ids"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXGroup",
            bundleID: "com.example.Editor",
            context: .click
        ),
        false,
        "accessibility role policy rejects app-specific roles outside observed apps"
    )
    try expect(
        Set(AccessibilityRolePolicy.searchbarExceptionRoles.keys),
        [
            "*",
            "com.adobe.acc.AdobeCreativeCloud",
            "com.apple.ActivityMonitor",
            "com.apple.Aperture",
            "com.apple.DiskImageMounter",
            "com.apple.FinalCut",
            "com.apple.Notes",
            "com.apple.Photos",
            "com.apple.Preview",
            "com.apple.RemoteDesktop",
            "com.apple.ScreenSharing",
            "com.apple.SystemProfiler",
            "com.apple.dock",
            "com.apple.dt.Xcode",
            "com.apple.finder",
            "com.apple.garageband10",
            "com.apple.iCal",
            "com.apple.iTunes",
            "com.apple.iWork.Keynote",
            "com.apple.iWork.Numbers",
            "com.apple.iWork.Pages",
            "com.apple.logic10",
            "com.apple.loginwindow",
            "com.apple.mail",
            "com.apple.reminders",
            "com.apple.storeuid",
            "com.apple.talagent",
            "com.aspyr",
            "com.bittorrent.uTorrent",
            "com.blizzard",
            "com.bohemiancoding.sketch3",
            "com.google.chrome",
            "com.microsoft",
            "com.mojang",
            "com.parallels.desktop",
            "com.teamviewer.TeamViewer",
            "com.wunderkinder.wunderlistdesktop",
            "it.bloop.airmail",
            "it.bloop.airmail2",
            "org.chromium.chromium",
            "org.mozilla.firefox",
            "org.telegram.desktop",
            "ru.keepcoder.Telegram",
            "ru.yandex.desktop.yandex-browser"
        ],
        "accessibility role policy preserves full observed searchbar exception key set"
    )
    try expect(
        Set(AccessibilityRolePolicy.clickExceptionRoles.keys),
        [
            "*",
            "com.adobe.acc.AdobeCreativeCloud",
            "com.apple.ActivityMonitor",
            "com.apple.Aperture",
            "com.apple.DiskImageMounter",
            "com.apple.DiskUtility",
            "com.apple.FinalCut",
            "com.apple.Notes",
            "com.apple.Photos",
            "com.apple.Preview",
            "com.apple.RemoteDesktop",
            "com.apple.ScreenSharing",
            "com.apple.SystemProfiler",
            "com.apple.dock",
            "com.apple.dt.Xcode",
            "com.apple.finder",
            "com.apple.garageband10",
            "com.apple.iCal",
            "com.apple.iTunes",
            "com.apple.iWork.Keynote",
            "com.apple.iWork.Numbers",
            "com.apple.iWork.Pages",
            "com.apple.logic10",
            "com.apple.loginwindow",
            "com.apple.mail",
            "com.apple.reminders",
            "com.apple.storeuid",
            "com.apple.talagent",
            "com.bittorrent.uTorrent",
            "com.bohemiancoding.sketch3",
            "com.google.chrome",
            "com.microsoft",
            "com.parallels.desktop",
            "com.teamviewer.TeamViewer",
            "com.wunderkinder.wunderlistdesktop",
            "it.bloop.airmail",
            "it.bloop.airmail2",
            "org.chromium.chromium",
            "org.mozilla.firefox",
            "org.telegram.desktop",
            "ru.keepcoder.Telegram",
            "ru.yandex.desktop.yandex-browser"
        ],
        "accessibility role policy preserves full observed click exception key set"
    )
    try expect(
        AccessibilityRolePolicy.searchbarExceptionRoles["*"],
        ["AXTextField", "AXTextArea", "AXComboBox", "AXWindow", "AXUnknown", "AXStaticText", "AXPopUpButton", "AXApplication"],
        "accessibility role policy preserves observed global searchbar roles"
    )
    try expect(
        AccessibilityRolePolicy.clickExceptionRoles["*"],
        ["AXTextField", "AXTextArea", "AXComboBox", "AXWindow", "AXUnknown", "AXStaticText", "AXPopUpButton"],
        "accessibility role policy preserves observed global click roles"
    )
    try expect(
        AccessibilityRolePolicy.searchbarExceptionRoles["com.apple.finder"],
        ["AXList", "AXOutline", "AXGrid", "AXImage"],
        "accessibility role policy preserves Finder searchbar exception roles"
    )
    try expect(
        AccessibilityRolePolicy.clickExceptionRoles["com.apple.finder"],
        ["AXList", "AXOutline", "AXGrid", "AXImage", "AXGroup"],
        "accessibility role policy preserves Finder click exception roles"
    )
    try expect(
        AccessibilityRolePolicy.searchbarExceptionRoles["com.apple.Preview"],
        [],
        "accessibility role policy preserves explicit empty observed app searchbar exception"
    )
    try expect(
        AccessibilityRolePolicy.clickExceptionRoles["com.apple.DiskUtility"],
        [],
        "accessibility role policy preserves explicit empty observed app click exception"
    )
}

func runAccessibilityTraversalPolicyTests() throws {
    try expect(
        AccessibilityTraversalPolicy.maxDescendantSearchDepth,
        5,
        "accessibility traversal policy keeps recursive descendant search bounded"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 0),
        true,
        "accessibility traversal policy inspects root depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 4),
        true,
        "accessibility traversal policy inspects final descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 5),
        false,
        "accessibility traversal policy stops after max descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: -1),
        false,
        "accessibility traversal policy rejects negative descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.maxAncestorRoleDepth,
        5,
        "accessibility traversal policy keeps ancestor role collection bounded"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldCollectAncestorRole(atDepth: 5),
        true,
        "accessibility traversal policy includes final ancestor role depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldCollectAncestorRole(atDepth: 6),
        false,
        "accessibility traversal policy stops ancestor role collection after max depth"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .empty),
        true,
        "accessibility selection search continues after empty wrapper selection"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .failed),
        true,
        "accessibility selection search continues after failed wrapper selection"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .text),
        false,
        "accessibility selection search stops after text is found"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .noFocus),
        false,
        "accessibility selection search stops when no focused element exists"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(false, after: .empty),
        true,
        "accessibility selection search records empty selection probes"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(true, after: .failed),
        true,
        "accessibility selection search preserves previous empty probes through failures"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(false, after: .failed),
        false,
        "accessibility selection search does not invent empty state from unsupported AX probes"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.finalOutcomeAfterSearch(sawEmptySelection: true),
        .empty,
        "accessibility selection search preserves empty selection after alternatives are exhausted"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.finalOutcomeAfterSearch(sawEmptySelection: false),
        .failed,
        "accessibility selection search falls back to failed when no AX source answered"
    )
}

func runKeyboardReplacementPolicyTests() throws {
    try expect(
        KeyboardEventKeyCodePolicy.pasteKeyCode,
        9,
        "keyboard event key code policy uses V key for paste"
    )
    try expect(
        KeyboardEventKeyCodePolicy.backspaceKeyCode,
        51,
        "keyboard event key code policy uses Backspace for exact tail deletion"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftArrowKeyCode,
        123,
        "keyboard event key code policy uses Left Arrow for reselection"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftCommandKeyCode,
        55,
        "keyboard event key code policy exposes left Command for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightCommandKeyCode,
        54,
        "keyboard event key code policy exposes right Command for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftShiftKeyCode,
        56,
        "keyboard event key code policy exposes left Shift for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightShiftKeyCode,
        60,
        "keyboard event key code policy exposes right Shift for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftOptionKeyCode,
        58,
        "keyboard event key code policy exposes left Option for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightOptionKeyCode,
        61,
        "keyboard event key code policy exposes right Option for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftControlKeyCode,
        59,
        "keyboard event key code policy exposes left Control for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightControlKeyCode,
        62,
        "keyboard event key code policy exposes right Control for modifier cleanup"
    )
    try expect(
        KeyDownEventPolicy.copyKeyCode,
        KeyboardEventKeyCodePolicy.copyKeyCode,
        "key down policy shares copy key code policy"
    )
    try expect(
        KeyDownEventPolicy.pasteKeyCode,
        KeyboardEventKeyCodePolicy.pasteKeyCode,
        "key down policy shares paste key code policy"
    )
    try expect(
        KeyDownEventPolicy.deleteKeyCode,
        KeyboardEventKeyCodePolicy.backspaceKeyCode,
        "key down policy shares backspace key code policy"
    )
    try expect(
        WordTrackingPolicy.deleteKeyCode,
        KeyboardEventKeyCodePolicy.backspaceKeyCode,
        "word tracking policy shares backspace key code policy"
    )
    try expect(
        KeyboardEventTimingPolicy.selectionSettleDelay,
        0.02,
        "keyboard event timing policy keeps selection settle delay"
    )
    try expect(
        KeyboardEventTimingPolicy.commandKeyUpDelay,
        0.02,
        "keyboard event timing policy keeps command key-up delay"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldSelectAfterPaste(true, replacementText: "hello"),
        true,
        "selected-text clipboard replacement reselects non-empty pasted text when requested"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldSelectAfterPaste(false, replacementText: "hello"),
        false,
        "selected-text clipboard replacement skips reselection when not requested"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldSelectAfterPaste(true, replacementText: ""),
        false,
        "selected-text clipboard replacement skips reselection for empty text"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 7, replacementChangeCount: 7),
        true,
        "selected-text clipboard replacement restores unchanged replacement clipboard"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 8, replacementChangeCount: 7),
        false,
        "selected-text clipboard replacement preserves externally changed clipboard"
    )
    try expect(
        ClipboardReplacementPolicy.shouldRestoreClipboardAfterReplacementPaste(
            currentChangeCount: 11,
            replacementChangeCount: 11
        ),
        true,
        "shared clipboard replacement policy restores only while replacement paste remains current"
    )
    try expect(
        ClipboardReplacementPolicy.shouldRestoreClipboardAfterReplacementPaste(
            currentChangeCount: 12,
            replacementChangeCount: 11
        ),
        false,
        "shared clipboard replacement policy preserves externally changed clipboard"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.postPasteDelay,
        0.03,
        "selected-text clipboard replacement preserves post-paste delay"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.selectAfterPasteDelay,
        0.02,
        "selected-text clipboard replacement preserves selection delay"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.clipboardRestoreDelay,
        ClipboardReplacementPolicy.clipboardRestoreDelay,
        "selected-text clipboard replacement shares clipboard restore delay"
    )
    try expect(
        KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: 1),
        true,
        "keyboard replacement attempts positive delete length"
    )
    try expect(
        KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: 0),
        false,
        "keyboard replacement rejects zero delete length before events"
    )
    try expect(
        KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: -1),
        false,
        "keyboard replacement rejects negative delete length before events"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: 6, sentCount: 6),
        true,
        "keyboard replacement proceeds after complete backspace sequence"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: 6, sentCount: 5),
        false,
        "keyboard replacement aborts after partial backspace sequence"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: 0, sentCount: 0),
        false,
        "keyboard replacement rejects zero-length delete before paste"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: -1, sentCount: -1),
        false,
        "keyboard replacement rejects invalid negative counts"
    )
    try expect(
        KeyboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 42, replacementChangeCount: 42),
        true,
        "keyboard replacement restores clipboard when replacement remains current"
    )
    try expect(
        KeyboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 43, replacementChangeCount: 42),
        false,
        "keyboard replacement keeps clipboard when another app changed it after paste"
    )
    try expect(
        KeyboardReplacementPolicy.modifierReleaseSettleDelay,
        0.05,
        "keyboard replacement preserves modifier release settle delay"
    )
    try expect(
        KeyboardReplacementPolicy.modifierReleaseMaxWait,
        0.35,
        "keyboard replacement waits briefly for real HID modifier release before destructive keys"
    )
    try expect(
        KeyboardReplacementPolicy.modifierReleasePollInterval,
        0.01,
        "keyboard replacement polls modifier release at short intervals"
    )
    try expect(
        KeyboardReplacementPolicy.shouldStartKeyboardEventsAfterModifierWait(modifiersArePressed: false),
        true,
        "keyboard replacement starts destructive events when modifiers are released"
    )
    try expect(
        KeyboardReplacementPolicy.shouldStartKeyboardEventsAfterModifierWait(modifiersArePressed: true),
        false,
        "keyboard replacement refuses destructive events while modifiers remain pressed"
    )
    try expect(
        KeyboardModifierCleanupPolicy.shouldPostCleanup(
            for: ModifierFlagsSnapshot(command: false, option: false, shift: false, control: false)
        ),
        false,
        "keyboard modifier cleanup skips empty modifier state"
    )
    try expect(
        KeyboardModifierCleanupPolicy.keyUpCodes(
            for: ModifierFlagsSnapshot(command: true, option: false, shift: false, control: false)
        ),
        [
            KeyboardEventKeyCodePolicy.leftCommandKeyCode,
            KeyboardEventKeyCodePolicy.rightCommandKeyCode
        ],
        "keyboard modifier cleanup releases both Command keys for a latched Command flag"
    )
    try expect(
        KeyboardModifierCleanupPolicy.keyUpCodes(
            for: ModifierFlagsSnapshot(command: false, option: true, shift: true, control: true)
        ),
        [
            KeyboardEventKeyCodePolicy.leftOptionKeyCode,
            KeyboardEventKeyCodePolicy.rightOptionKeyCode,
            KeyboardEventKeyCodePolicy.leftShiftKeyCode,
            KeyboardEventKeyCodePolicy.rightShiftKeyCode,
            KeyboardEventKeyCodePolicy.leftControlKeyCode,
            KeyboardEventKeyCodePolicy.rightControlKeyCode
        ],
        "keyboard modifier cleanup releases all latched non-command modifier sides in stable order"
    )
    try expect(
        KeyboardReplacementPolicy.backspaceInterval,
        0.02,
        "keyboard replacement preserves backspace interval"
    )
    try expect(
        KeyboardReplacementPolicy.prePasteDelay,
        0.02,
        "keyboard replacement preserves pre-paste delay"
    )
    try expect(
        KeyboardReplacementPolicy.postPasteDelay,
        0.03,
        "keyboard replacement preserves post-paste delay"
    )
    try expect(
        KeyboardReplacementPolicy.clipboardRestoreDelay,
        ClipboardReplacementPolicy.clipboardRestoreDelay,
        "keyboard replacement shares async clipboard restore delay"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "TextEdit",
                role: "AXTextArea",
                isEnabled: true,
                isFocused: true
            )
        ),
        true,
        "keyboard focus policy accepts typed enabled focused target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "Ghostty",
                role: "AXTextArea",
                isEnabled: true,
                isFocused: false
            )
        ),
        true,
        "keyboard focus policy allows typed enabled target with unreliable focused flag"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "TextEdit",
                role: "AXTextArea",
                isEnabled: false,
                isFocused: true
            )
        ),
        false,
        "keyboard focus policy rejects typed disabled target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "Finder",
                role: "AXButton",
                isEnabled: true,
                isFocused: true
            )
        ),
        false,
        "keyboard focus policy rejects typed non-editable focused role"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "UnknownApp",
                role: nil,
                isEnabled: true,
                isFocused: true
            )
        ),
        true,
        "keyboard focus policy keeps unknown roles eligible"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .noFocusedElement(appName: "TextEdit", errorCode: -25205)
        ),
        false,
        "keyboard focus policy rejects typed missing focused element"
    )
    try expect(
        KeyboardFocusEvidence.focusedElement(
            appName: "TextEdit",
            role: "AXTextArea",
            isEnabled: true,
            isFocused: false
        ).logDescription,
        "app='TextEdit' role='AXTextArea' enabled=true focused=false",
        "keyboard focus evidence preserves legacy log shape"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' role='AXTextArea' enabled=true focused=true"
        ),
        true,
        "keyboard focus policy accepts enabled focused target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='Ghostty' role='AXTextArea' enabled=true focused=false"
        ),
        true,
        "keyboard focus policy allows enabled target with unreliable focused flag"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' role='AXTextArea' enabled=false focused=true"
        ),
        false,
        "keyboard focus policy rejects disabled target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='Finder' role='AXButton' enabled=true focused=true"
        ),
        false,
        "keyboard focus policy rejects non-editable focused role"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='UnknownApp' role='?' enabled=true focused=true"
        ),
        true,
        "keyboard focus policy preserves unknown string role eligibility"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' NO_FOCUSED_ELEMENT (error=-25205)"
        ),
        false,
        "keyboard focus policy rejects missing focused element"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(focusDescription: "  "),
        false,
        "keyboard focus policy rejects empty focus evidence"
    )
}

func runTextReplacementPolicyTests() throws {
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .keyboardBackspacePaste),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "failed keyboard replacement",
            clearConversionSessionReason: "failed keyboard replacement"
        ),
        "replacement failure action clears tracked text and undo after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "failed keyboard replacement",
            clearConversionSessionReason: "failed keyboard replacement"
        ),
        "replacement failure action clears tracked text and undo after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .accessibilitySelection),
        ReplacementFailureAction(clearTrackedText: false, clearConversionSession: false),
        "replacement failure action preserves state after failed AX replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .blocked),
        ReplacementFailureAction(clearTrackedText: false, clearConversionSession: false),
        "replacement failure action ignores blocked plans"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardBackspacePaste),
        true,
        "replacement failure policy clears tracked text after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        true,
        "replacement failure policy clears tracked text after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .accessibilitySelection),
        false,
        "replacement failure policy keeps tracked text after failed AX selection replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .blocked),
        false,
        "replacement failure policy ignores blocked replacement plans"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .keyboardBackspacePaste),
        true,
        "replacement failure policy clears undo session after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        true,
        "replacement failure policy clears undo session after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .accessibilitySelection),
        false,
        "replacement failure policy keeps undo session after failed AX selection replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .blocked),
        false,
        "replacement failure policy keeps undo session for blocked plans"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            replacement: "привет",
            keepSelection: true
        ),
        .accessibilitySelection(text: "привет", keepSelection: true),
        "replacement policy keeps AX selection replacement as AX plan"
    )
    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "browser selection",
                replacementMethod: .accessibilitySelection,
                source: "active clipboard fallback",
                selectedTextReplacementTransport: .clipboard
            ),
            replacement: "браузер",
            keepSelection: true
        ),
        .clipboardSelection(text: "браузер", selectAfterPaste: true),
        "replacement policy routes clipboard selected-text capture directly to clipboard plan"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "hello",
                replacementMethod: .keyboardBackspacePaste,
                source: "passive clipboard tail selection"
            ),
            replacement: "привет",
            keepSelection: true
        ),
        .keyboardBackspacePaste(deleteLength: 5, text: "привет"),
        "replacement policy uses captured length for keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "",
                replacementMethod: .keyboardBackspacePaste,
                source: "empty keyboard capture"
            ),
            replacement: "привет",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks empty keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "commit",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "AX non-settable command-tail selection"
            ),
            replacement: "COMMIT",
            keepSelection: false
        ),
        .keyboardBackspacePaste(deleteLength: 10, text: "git COMMIT"),
        "replacement policy rewrites full terminal tail before keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "missing",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "stale tail"
            ),
            replacement: "MISSING",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks unrewritable terminal tail"
    )
    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "mit",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "stale tail"
            ),
            replacement: "ьше",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks partial-word terminal tail replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(text: "", replacementMethod: .blocked, source: "blocked"),
            replacement: "ignored",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks unsafe capture"
    )
}

func runAccessibilityReplacementPolicyTests() throws {
    try expect(
        AccessibilityReplacementPolicy.selectedTextVerificationDelay,
        0.05,
        "AX replacement policy keeps selected text verification delay"
    )
    try expect(
        AccessibilityReplacementPolicy.focusedApplicationRetryAttempts,
        3,
        "AX replacement policy keeps focused application retry attempts"
    )
    try expect(
        AccessibilityReplacementPolicy.focusedApplicationRetryDelay,
        0.05,
        "AX replacement policy keeps focused application retry delay"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: false,
            originalSelectedText: "hello",
            observedSelectedText: "руддщ",
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects failed set call"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "hello",
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects silent no-op"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "руддщ",
            replacement: "руддщ"
        ),
        true,
        "AX replacement policy accepts observed replacement"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: nil,
            replacement: "руддщ"
        ),
        true,
        "AX replacement policy accepts deselected changed state"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: nil,
            observedSelectedText: nil,
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects success without before or after text evidence"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "hello",
            replacement: "hello"
        ),
        true,
        "AX replacement policy accepts idempotent replacement"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 1),
        true,
        "AX replacement policy retries before final focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 2),
        true,
        "AX replacement policy retries on penultimate focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 3),
        false,
        "AX replacement policy does not sleep after final focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldReadOriginalSelectionRange(keepSelection: true),
        true,
        "AX replacement policy reads original selection range only when selection should be retained"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldReadOriginalSelectionRange(keepSelection: false),
        false,
        "AX replacement policy skips original selection range when selection retention is not needed"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: 5),
        4,
        "AX replacement policy accepts valid original selection range location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: 0),
        4,
        "AX replacement policy accepts collapsed valid selection range location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: -1, length: 5),
        nil,
        "AX replacement policy rejects negative original selection location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: -1),
        nil,
        "AX replacement policy rejects negative original selection length"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "руддщ",
            keepSelection: true
        ),
        AccessibilityReplacementPolicy.SelectionRange(location: 4, length: 5),
        "AX replacement policy reselects replacement at original selection location"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "a😀",
            keepSelection: true
        ),
        AccessibilityReplacementPolicy.SelectionRange(location: 4, length: 3),
        "AX replacement policy uses UTF-16 length for AX selection range"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: nil,
            replacement: "руддщ",
            keepSelection: true
        ),
        nil,
        "AX replacement policy does not guess a selection location when AX range is unavailable"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "руддщ",
            keepSelection: false
        ),
        nil,
        "AX replacement policy skips reselection when selection retention is disabled"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: -1,
            replacement: "руддщ",
            keepSelection: true
        ),
        nil,
        "AX replacement policy rejects invalid negative selection locations"
    )
}
