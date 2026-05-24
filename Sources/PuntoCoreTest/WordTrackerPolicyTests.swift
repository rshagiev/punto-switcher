import Foundation
import PuntoCore

func runWordTrackerTests() throws {
    do {
        try expect(
            AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames([" BackSpace ", "DELETE", "leftArrow", "unknown"]),
            [
                AutoCorrectionCancellingKeyPolicy.backspace,
                AutoCorrectionCancellingKeyPolicy.delete,
                AutoCorrectionCancellingKeyPolicy.leftArrow
            ],
            "auto-correction cancelling key policy normalizes supported key names"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.supportedKeyNames,
            [
                AutoCorrectionCancellingKeyPolicy.backspace,
                AutoCorrectionCancellingKeyPolicy.delete,
                AutoCorrectionCancellingKeyPolicy.leftArrow,
                AutoCorrectionCancellingKeyPolicy.rightArrow,
                AutoCorrectionCancellingKeyPolicy.upArrow,
                AutoCorrectionCancellingKeyPolicy.downArrow
            ],
            "auto-correction cancelling key policy mirrors supported Punto Switcher cancelling key names"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.displayOrder,
            [
                AutoCorrectionCancellingKeyDisplayItem(
                    name: AutoCorrectionCancellingKeyPolicy.backspace,
                    title: "Backspace",
                    keyCode: WordTrackingPolicy.deleteKeyCode
                ),
                AutoCorrectionCancellingKeyDisplayItem(
                    name: AutoCorrectionCancellingKeyPolicy.delete,
                    title: "Delete",
                    keyCode: WordTrackingPolicy.forwardDeleteKeyCode
                ),
                AutoCorrectionCancellingKeyDisplayItem(
                    name: AutoCorrectionCancellingKeyPolicy.leftArrow,
                    title: "Left",
                    keyCode: WordTrackingPolicy.leftArrowKeyCode
                ),
                AutoCorrectionCancellingKeyDisplayItem(
                    name: AutoCorrectionCancellingKeyPolicy.rightArrow,
                    title: "Right",
                    keyCode: WordTrackingPolicy.rightArrowKeyCode
                ),
                AutoCorrectionCancellingKeyDisplayItem(
                    name: AutoCorrectionCancellingKeyPolicy.upArrow,
                    title: "Up",
                    keyCode: WordTrackingPolicy.upArrowKeyCode
                ),
                AutoCorrectionCancellingKeyDisplayItem(
                    name: AutoCorrectionCancellingKeyPolicy.downArrow,
                    title: "Down",
                    keyCode: WordTrackingPolicy.downArrowKeyCode
                )
            ],
            "auto-correction cancelling key policy owns settings display order and runtime key codes"
        )
        try expect(
            Set(AutoCorrectionCancellingKeyPolicy.displayOrder.map(\.name)),
            AutoCorrectionCancellingKeyPolicy.supportedKeyNames,
            "auto-correction cancelling key display covers every supported key"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.displayOrder.count,
            AutoCorrectionCancellingKeyPolicy.supportedKeyNames.count,
            "auto-correction cancelling key display lists every supported key exactly once"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.setCancellingKeyStateSelector,
            "setCancellingKeyState:doEnable:",
            "observed surface preserves auto-correction cancelling-key setter selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.backspaceName,
            "dontAutoconvertWordWithBackspace",
            "observed surface preserves auto-correction cancelling-key backspace name"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.deleteName,
            "dontAutoconvertWordWithDelete",
            "observed surface preserves auto-correction cancelling-key delete name"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.leftArrowName,
            "dontAutoconvertWordWithLeftArrow",
            "observed surface preserves auto-correction cancelling-key left-arrow name"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.rightArrowName,
            "dontAutoconvertWordWithRightArrow",
            "observed surface preserves auto-correction cancelling-key right-arrow name"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.upArrowName,
            "dontAutoconvertWordWithUpArrow",
            "observed surface preserves auto-correction cancelling-key up-arrow name"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.downArrowName,
            "dontAutoconvertWordWithDownArrow",
            "observed surface preserves auto-correction cancelling-key down-arrow name"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyBackspaceName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.backspaceName,
            "auto-correction cancelling key policy keeps backspace name alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyDeleteName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.deleteName,
            "auto-correction cancelling key policy keeps delete name alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyLeftArrowName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.leftArrowName,
            "auto-correction cancelling key policy keeps left-arrow name alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyRightArrowName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.rightArrowName,
            "auto-correction cancelling key policy keeps right-arrow name alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyUpArrowName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.upArrowName,
            "auto-correction cancelling key policy keeps up-arrow name alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyDownArrowName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.downArrowName,
            "auto-correction cancelling key policy keeps down-arrow name alias aligned with reverse-audit anchor"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.backspaceSelector,
            "dontAutoconvertWordWithBackspace:",
            "observed surface preserves auto-correction cancelling-key backspace selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.deleteSelector,
            "dontAutoconvertWordWithDelete:",
            "observed surface preserves auto-correction cancelling-key delete selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.leftArrowSelector,
            "dontAutoconvertWordWithLeftArrow:",
            "observed surface preserves auto-correction cancelling-key left-arrow selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.rightArrowSelector,
            "dontAutoconvertWordWithRightArrow:",
            "observed surface preserves auto-correction cancelling-key right-arrow selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.upArrowSelector,
            "dontAutoconvertWordWithUpArrow:",
            "observed surface preserves auto-correction cancelling-key up-arrow selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.downArrowSelector,
            "dontAutoconvertWordWithDownArrow:",
            "observed surface preserves auto-correction cancelling-key down-arrow selector"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyBackspaceSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.backspaceSelector,
            "auto-correction cancelling key policy keeps backspace selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyDeleteSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.deleteSelector,
            "auto-correction cancelling key policy keeps delete selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyLeftArrowSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.leftArrowSelector,
            "auto-correction cancelling key policy keeps left-arrow selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyRightArrowSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.rightArrowSelector,
            "auto-correction cancelling key policy keeps right-arrow selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyUpArrowSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.upArrowSelector,
            "auto-correction cancelling key policy keeps up-arrow selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyDownArrowSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.downArrowSelector,
            "auto-correction cancelling key policy keeps down-arrow selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames([
                " dontAutoconvertWordWithBackspace ",
                "dontAutoconvertWordWithDelete",
                "dontAutoconvertWordWithLeftArrow",
                "dontAutoconvertWordWithRightArrow",
                "dontAutoconvertWordWithUpArrow",
                "dontAutoconvertWordWithDownArrow"
            ]),
            AutoCorrectionCancellingKeyPolicy.supportedKeyNames,
            "auto-correction cancelling key policy accepts observed Punto Switcher per-key names"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames([
                " \(PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.backspaceSelector) ",
                PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.deleteSelector,
                PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.leftArrowSelector,
                PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.rightArrowSelector,
                PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.upArrowSelector,
                PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.downArrowSelector
            ]),
            AutoCorrectionCancellingKeyPolicy.supportedKeyNames,
            "auto-correction cancelling key policy accepts observed Punto Switcher selector names"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.shouldSuppressAutoCorrection(keyCode: 51, enabledKeyNames: ["backspace"]),
            true,
            "auto-correction cancelling key policy suppresses backspace when enabled"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.shouldSuppressAutoCorrection(
                keyCode: 51,
                enabledKeyNames: [AutoCorrectionCancellingKeyPolicy.legacyBackspaceName]
            ),
            true,
            "auto-correction cancelling key policy suppresses backspace from observed name"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.shouldSuppressAutoCorrection(keyCode: 51, enabledKeyNames: []),
            false,
            "auto-correction cancelling key policy allows disabling backspace suppression"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.shouldSuppressAutoCorrection(
                keyCode: WordTrackingPolicy.forwardDeleteKeyCode,
                enabledKeyNames: [AutoCorrectionCancellingKeyPolicy.delete]
            ),
            true,
            "auto-correction cancelling key policy maps Forward Delete"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.cancellingKeyName(for: WordTrackingPolicy.leftArrowKeyCode),
            AutoCorrectionCancellingKeyPolicy.leftArrow,
            "auto-correction cancelling key policy maps Left Arrow"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.cancellingKeyName(for: WordTrackingPolicy.rightArrowKeyCode),
            AutoCorrectionCancellingKeyPolicy.rightArrow,
            "auto-correction cancelling key policy maps Right Arrow"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.cancellingKeyName(for: WordTrackingPolicy.upArrowKeyCode),
            AutoCorrectionCancellingKeyPolicy.upArrow,
            "auto-correction cancelling key policy maps Up Arrow"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.cancellingKeyName(for: WordTrackingPolicy.downArrowKeyCode),
            AutoCorrectionCancellingKeyPolicy.downArrow,
            "auto-correction cancelling key policy maps Down Arrow"
        )
    }

    do {
        let tracker = WordTracker()
        type("git commit", into: tracker)
        try expect(tracker.getLastWord(), "commit", "word and tail last word")
        try expect(tracker.getTypedTail(), "git commit", "word and tail typed tail")
    }

    do {
        let tracker = WordTracker()
        type("teh quick ", into: tracker)
        try expect(tracker.getTypedTail(), "teh quick", "typed tail trims boundary whitespace for terminal matching")
        try expect(
            tracker.getTypedTailPreservingBoundaryWhitespace(),
            "teh quick ",
            "typed tail preserves completed separator for auto-correction"
        )
    }

    do {
        let tracker = WordTracker()
        type("hello", into: tracker)
        tracker.trackKeyPress(keyCode: 51, characters: "\u{7f}")
        try expect(tracker.getLastWord(), "hell", "backspace updates word")
        try expect(tracker.getTypedTail(), "hell", "backspace updates tail")
    }

    do {
        let tracker = WordTracker()
        type("ghbdt", into: tracker)
        tracker.trackKeyPress(keyCode: 51, characters: "\u{7f}")
        type("tn ", into: tracker)
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "ghbdtn", separator: " ", isAutoCorrectionSuppressed: true),
            "backspace marks edited completed token as auto-correction suppressed"
        )
    }

    do {
        let tracker = WordTracker()
        type("ghbdt", into: tracker)
        tracker.trackKeyPress(
            keyCode: 51,
            characters: "\u{7f}",
            autoCorrectionCancellingKeyNames: []
        )
        type("tn ", into: tracker)
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "ghbdtn", separator: " "),
            "disabled backspace cancelling key keeps edited completed token eligible for auto-correction"
        )
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(keyCode: 51, characters: "\u{7f}")
        type("ghbdtn ", into: tracker)
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "ghbdtn", separator: " "),
            "backspace before a word does not suppress the next completed token"
        )
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(keyCode: 0, characters: "hello")
        try expect(tracker.getLastWord(), "hello", "multi-character input updates full word")
        try expect(tracker.getTypedTail(), "hello", "multi-character input updates full tail")
    }

    do {
        let tracker = WordTracker()
        tracker.replaceTrackedTail(
            with: "the",
            reason: "manual conversion test",
            suppressAutoCorrectionForCurrentToken: true
        )
        tracker.trackKeyPress(keyCode: 49, characters: " ")
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "the", separator: " ", isAutoCorrectionSuppressed: true),
            "manual conversion tail replacement can suppress next auto-correction"
        )
    }

    do {
        let tracker = WordTracker()
        tracker.replaceTrackedTail(with: "the", reason: "manual conversion test")
        tracker.trackKeyPress(keyCode: 49, characters: " ")
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "the", separator: " "),
            "manual conversion tail replacement keeps next auto-correction eligible when suppression is disabled"
        )
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(keyCode: 0, characters: "hello world")
        try expect(tracker.getLastWord(), "world", "multi-character input honors embedded word boundary")
        try expect(tracker.getTypedTail(), "hello world", "multi-character input preserves typed tail across embedded boundary")
        try expect(tracker.consumeCompletedToken(), WordTracker.CompletedToken(word: "hello", separator: " "), "multi-character input records completed token at embedded boundary")
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(keyCode: 0, characters: "\\", russianLayoutType: .mac)
        try expect(tracker.getLastWord(), "\\", "word tracker keeps Mac backslash key in last word")
        tracker.trackKeyPress(keyCode: 0, characters: "|", russianLayoutType: .mac)
        try expect(tracker.getLastWord(), "\\|", "word tracker keeps Mac shifted backslash key in last word")
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(keyCode: 0, characters: "\\", russianLayoutType: .windows)
        try expectNil(tracker.getLastWord(), "word tracker treats Windows backslash as word boundary")
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(keyCode: 0, characters: "ghbdtn@#$^&", russianLayoutType: .windows)
        try expect(
            tracker.getLastWord(),
            "ghbdtn@#$^&",
            "word tracker keeps Windows shifted-number mapped punctuation in last word"
        )
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(
            keyCode: 0,
            characters: "idxeyb-",
            englishLayoutVariant: .dvorak,
            russianLayoutType: .windows
        )
        try expect(
            tracker.getLastWord(),
            "idxeyb-",
            "word tracker keeps Dvorak punctuation mapped to Russian letters in last word"
        )
    }

    do {
        let tracker = WordTracker()
        tracker.replaceTrackedTail(with: "\\|", reason: "Mac tail replacement test", russianLayoutType: .mac)
        try expect(tracker.getLastWord(), "\\|", "replaceTrackedTail keeps Mac backslash and pipe in last word")
        try expect(tracker.getTypedTail(), "\\|", "replaceTrackedTail keeps Mac backslash and pipe in typed tail")
    }

    do {
        let tracker = WordTracker()
        tracker.replaceTrackedTail(with: "\\|", reason: "Windows tail replacement compatibility test")
        try expectNil(tracker.getLastWord(), "replaceTrackedTail keeps Windows default boundary behavior")
        try expect(tracker.getTypedTail(), "\\|", "replaceTrackedTail preserves typed tail even when Windows word is cleared")
    }

    do {
        let tracker = WordTracker()
        tracker.replaceTrackedTail(
            with: "idxeyb-",
            reason: "Dvorak tail replacement test",
            englishLayoutVariant: .dvorak,
            russianLayoutType: .windows
        )
        try expect(
            tracker.getLastWord(),
            "idxeyb-",
            "replaceTrackedTail keeps Dvorak punctuation mapped to Russian letters in last word"
        )
    }

    do {
        let tracker = WordTracker()
        type("ghbdtn/", into: tracker)
        try expect(tracker.getLastWord(), "ghbdtn/", "slash stays in wrong-layout word for period conversion")
        try expect(tracker.getTypedTail(), "ghbdtn/", "slash stays in typed tail for terminal conversion")
    }

    do {
        let tracker = WordTracker()
        type("ghbdtn?", into: tracker)
        try expect(tracker.getLastWord(), "ghbdtn?", "question mark stays in wrong-layout word for comma conversion")
        try expect(tracker.getTypedTail(), "ghbdtn?", "question mark stays in typed tail for terminal conversion")
    }

    do {
        let tracker = WordTracker()
        type("ghbdtn-", into: tracker)
        try expectNil(tracker.getLastWord(), "dash suffix completes wrong-layout word")
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "ghbdtn", separator: "-"),
            "dash suffix records completed token for auto-correction"
        )
        try expect(tracker.getTypedTail(), "ghbdtn-", "dash suffix remains in typed tail")
    }

    do {
        let tracker = WordTracker()
        type("git commit ghbdtn", into: tracker)
        tracker.replaceTrackedTail(with: "git commit привет", reason: "test")
        try expect(tracker.getLastWord(), "привет", "replaceTrackedTail keeps last word")
        try expectNil(tracker.getTypedTail(), "mixed command tail rejected")
    }

    do {
        let tracker = WordTracker()
        type("hello world", into: tracker)
        tracker.trackKeyPress(keyCode: 123, characters: nil)
        try expectNil(tracker.getLastWord(), "navigation clears word")
        try expectNil(tracker.getTypedTail(), "navigation clears tail")
    }

    do {
        let tracker = WordTracker()
        type("hello", into: tracker)
        tracker.trackKeyPress(keyCode: 53, characters: nil)
        try expectNil(tracker.getLastWord(), "escape clears word")
        try expectNil(tracker.getTypedTail(), "escape clears tail")
    }

    do {
        let tracker = WordTracker()
        type("helло", into: tracker)
        try expectNil(tracker.getLastWord(), "mixed word rejected")
        try expectNil(tracker.getTypedTail(), "mixed word clears tail")
    }

    do {
        let tracker = WordTracker(maxSize: 5)
        type("abcdefgh", into: tracker)
        try expect(tracker.getLastWord(), "defgh", "word ring buffer")
        try expect(tracker.getTypedTail(), "defgh", "tail ring buffer")
    }

    do {
        let tracker = WordTracker(maxSize: 5, maxTailSize: 12)
        type("abcdefghijklmnop", into: tracker)
        try expect(tracker.getLastWord(), "lmnop", "word ring buffer remains compact with larger tail")
        try expect(tracker.getTypedTail(), "efghijklmnop", "typed tail can retain longer terminal command context")
    }
}
