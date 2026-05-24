import Foundation
import PuntoCore

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
