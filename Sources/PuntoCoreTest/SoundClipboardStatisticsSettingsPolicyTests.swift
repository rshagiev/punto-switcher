import Foundation
import PuntoCore

func runSoundClipboardStatisticsSettingsPolicyTests() throws {
    try expect(
        SoundFeedbackPolicy.defaultSoundEffectsEnabled,
        false,
        "settings defaults keep sound effects off"
    )
    try expect(
        SoundFeedbackPolicy.legacyIsSoundOnKey,
        "isSoundOn",
        "sound feedback preserves observed global sound key"
    )
    try expect(
        PuntoSwitcherObservedSurface.SoundFeedback.setSoundStateSelector,
        "setSoundState:isSoundOn:",
        "sound feedback preserves observed sound-state setter"
    )
    try expect(
        ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion,
        true,
        "settings defaults restore pasteboard after clipboard fallbacks"
    )
    try expect(
        ClipboardReplacementPolicy.legacyShouldRestorePasteboardKey,
        "shouldRestorePasteboard",
        "clipboard replacement policy preserves observed pasteboard restore setting key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.previousPasteboardContentsKey,
        "previousPasteboardContents",
        "clipboard replacement policy preserves observed previous pasteboard storage key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.pasteboardRestoreTimerKey,
        "pasteboardRestoreTimer",
        "clipboard replacement policy preserves observed pasteboard restore timer key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.generalPasteboardSelector,
        "generalPasteboard",
        "clipboard replacement policy preserves observed general pasteboard selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.getPasteboardStringSelector,
        "getPasteboardString",
        "clipboard replacement policy preserves observed pasteboard read selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.setPasteboardStringSelector,
        "setPasteboardString:",
        "clipboard replacement policy preserves observed pasteboard write selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.restorePasteboardByTimerSelector,
        "restorePasteboardByTimer:",
        "clipboard replacement policy preserves observed AX pasteboard restore selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.restorePasteboardForKeyboardByTimerSelector,
        "restorePasteboardForKeyboardByTimer:",
        "clipboard replacement policy preserves observed keyboard pasteboard restore selector"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: true,
            hasLegacyValue: true,
            legacyValue: false,
            defaultValue: ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion
        ),
        false,
        "settings persistence reads Punto Switcher shouldRestorePasteboard alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: true,
            hasLegacyValue: true,
            legacyValue: false,
            defaultValue: ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion
        ),
        true,
        "settings persistence prefers native pasteboard restore setting over Punto Switcher alias"
    )
    try expect(
        ProductStatisticsPolicy.defaultSnapshot,
        ProductStatisticsSnapshot(),
        "settings defaults start with empty product statistics"
    )
}
