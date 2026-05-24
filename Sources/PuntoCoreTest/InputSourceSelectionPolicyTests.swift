import Foundation
import PuntoCore

func runInputSourceSelectionPolicyTests() throws {
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
            InputSourceCandidate(sourceID: "UNDEFINED", languages: ["en"], isSelectableKeyboard: true),
            InputSourceCandidate(sourceID: " \n\t ", languages: ["ru"], isSelectableKeyboard: true),
            InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
        ]),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy ignores invalid source ids before choosing language candidates"
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
