import Foundation
import PuntoCore

func runUndoLearningSettingsPolicyTests() throws {
    try expect(
        UndoLearningSettingsPolicy.defaultSnapshot,
        UndoLearningSettingsSnapshot(
            undoCollectionEnabled: false,
            mustShowUndoWindow: true,
            undoDictionary: [:]
        ),
        "undo learning policy mirrors observed Punto Switcher defaults"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setUndoCollectionEnabledSelector,
        "setUndoCollectionEnabled:",
        "observed surface preserves undo learning collection setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setMustShowUndoWindowSelector,
        "setMustShowUndoWindow:",
        "observed surface preserves undo learning undo-window setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setUndoDictionarySelector,
        "setUndoDictionary:",
        "observed surface preserves undo learning undo dictionary setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowControllerClassName,
        "UndoWindowController",
        "observed surface preserves undo window controller name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowDelegateProtocolName,
        "UndoWindowDelegate",
        "observed surface preserves undo window delegate name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowResourceName,
        "UndoWindow",
        "observed surface preserves undo window resource name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoAlertFormatKey,
        "PMUserRuleUndoAlertFormat",
        "observed surface preserves undo alert format key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.showUndoLearningWindowCheckboxChangedSelector,
        "showUndoLearningWindowCheckboxChanged:",
        "observed surface preserves undo show-window checkbox selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoLearningCheckboxChangedSelector,
        "undoLearningCheckboxChanged:",
        "observed surface preserves undo learning checkbox selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoLearningCheckboxKey,
        "undoLearningCheckbox",
        "observed surface preserves undo learning checkbox key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.showUndoLearningWindowCheckboxKey,
        "showUndoLearningWindowCheckbox",
        "observed surface preserves undo show-window checkbox key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoTriesKey,
        "undoTries",
        "observed surface preserves undo tries key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoPersistsKey,
        "undoPersists",
        "observed surface preserves undo persistence key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWasDoneKey,
        "undoWasDone",
        "observed surface preserves undo completion key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoConvertionSelector,
        "undoConvertion",
        "observed surface preserves legacy undo selector spelling"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.resetUndoBufferSelector,
        "resetUndoBuffer",
        "observed surface preserves undo-buffer reset selector"
    )
    try expectNil(
        UndoLearningSettingsPolicy.snapshot(from: nil),
        "undo learning policy rejects missing dictionary"
    )
    try expect(
        UndoLearningSettingsPolicy.snapshot(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: NSNumber(value: false),
            UndoLearningSettingsPolicy.mustShowUndoWindowKey: NSNumber(value: true),
            UndoLearningSettingsPolicy.undoDictionaryKey: [:]
        ]),
        UndoLearningSettingsPolicy.defaultSnapshot,
        "undo learning policy reads observed Punto Switcher plist shape"
    )
    try expect(
        UndoLearningSettingsPolicy.snapshot(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: "yes",
            UndoLearningSettingsPolicy.mustShowUndoWindowKey: "0",
            UndoLearningSettingsPolicy.undoDictionaryKey: [
                " teh ": " the ",
                "": "ignored",
                "adn": " "
            ]
        ]),
        UndoLearningSettingsSnapshot(
            undoCollectionEnabled: true,
            mustShowUndoWindow: false,
            undoDictionary: ["teh": "the"]
        ),
        "undo learning policy parses imported string-backed values and normalizes undo dictionary"
    )
    try expect(
        UndoLearningSettingsPolicy.legacyUndoCollectionEnabled(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: NSNumber(value: true)
        ]),
        true,
        "undo learning policy exposes imported undoCollectionEnabled for settings fallback"
    )
    try expectNil(
        UndoLearningSettingsPolicy.legacyUndoCollectionEnabled(from: nil),
        "undo learning policy ignores missing undoLearning dictionaries"
    )

    try expect(
        UndoLearningSettingsPolicy.normalizedUndoDictionary([
            " ghbdtn ": " привет ",
            "": "ignored",
            "adn": " "
        ]),
        ["ghbdtn": "привет"],
        "undo learning policy normalizes imported undo dictionary entries"
    )
}
