import AppKit
import PuntoCore

/// App-side pasteboard transport for capture and paste-based replacement.
///
/// Policy modules own timing, stale-copy checks, and restore guards. This
/// adapter owns NSPasteboard snapshots, writes, async restores, and keyboard
/// paste/copy transport composition.
final class ClipboardTransport {
    private let shouldRestorePasteboard: () -> Bool
    private let keyboardEvents: KeyboardEventTransport

    init(
        shouldRestorePasteboard: @escaping () -> Bool,
        keyboardEvents: KeyboardEventTransport
    ) {
        self.shouldRestorePasteboard = shouldRestorePasteboard
        self.keyboardEvents = keyboardEvents
    }

    func currentText() -> String? {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            PuntoLog.info("currentClipboardText: clipboard empty")
            return nil
        }

        return text
    }

    func captureSelectedText() -> String? {
        PuntoLog.info("getSelectedTextViaClipboard: using Cmd+C fallback")

        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard)
        let previousClipboardText = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        let copyBaselineChangeCount = pasteboard.changeCount

        _ = keyboardEvents.postCommandCopyAnnotated()

        for i in 1...ClipboardCapturePolicy.maxPollAttempts {
            Thread.sleep(forTimeInterval: ClipboardCapturePolicy.pollInterval)
            let pasteboardChanged = pasteboard.changeCount != copyBaselineChangeCount
            if ClipboardCapturePolicy.shouldStopPolling(pasteboardChanged: pasteboardChanged) {
                break
            }
            if ClipboardCapturePolicy.shouldAttemptHIDFallback(pollAttempt: i, pasteboardChanged: pasteboardChanged) {
                _ = keyboardEvents.postCommandCopyHID()
            }
        }

        let copyChangedPasteboard = pasteboard.changeCount != copyBaselineChangeCount
        guard let text = ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: pasteboard.string(forType: .string),
            pasteboardChanged: copyChangedPasteboard,
            previousClipboardText: previousClipboardText
        ) else {
            PuntoLog.info("getSelectedTextViaClipboard: no text in clipboard")
            restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "clipboard capture failed")
            return nil
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        PuntoLog.info("getSelectedTextViaClipboard: got '\(trimmed.prefix(30))' (raw \(text.count) chars, trimmed \(trimmed.count) chars)")
        restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "clipboard capture completed")
        return text
    }

    @discardableResult
    func pasteSelectedText(_ text: String, selectAfterPaste: Bool) -> Bool {
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let replacementChangeCount = pasteboard.changeCount

        PuntoLog.info("setSelectedTextViaClipboard: pasting \(text.count) chars")

        guard keyboardEvents.postCommandPasteHID() else {
            PuntoLog.info("setSelectedTextViaClipboard: failed to send Cmd+V")
            restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "selected-text clipboard paste failed")
            return false
        }
        Thread.sleep(forTimeInterval: SelectedTextClipboardReplacementPolicy.postPasteDelay)

        PuntoLog.info("setSelectedTextViaClipboard: paste completed")

        if SelectedTextClipboardReplacementPolicy.shouldSelectAfterPaste(selectAfterPaste, replacementText: text) {
            Thread.sleep(forTimeInterval: SelectedTextClipboardReplacementPolicy.selectAfterPasteDelay)
            keyboardEvents.selectBackwards(characterCount: text.count)
            PuntoLog.info("setSelectedTextViaClipboard: selected backwards")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + SelectedTextClipboardReplacementPolicy.clipboardRestoreDelay) {
            if SelectedTextClipboardReplacementPolicy.shouldRestoreClipboardAfterPaste(
                currentChangeCount: pasteboard.changeCount,
                replacementChangeCount: replacementChangeCount
            ) {
                self.restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "selected-text clipboard replacement")
            }
        }
        return true
    }

    @discardableResult
    func pasteKeyboardReplacement(_ replacement: String) -> Bool {
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(replacement, forType: .string)
        let replacementChangeCount = pasteboard.changeCount

        let pasteStartTime = Date()
        guard keyboardEvents.postCommandPasteHID() else {
            PuntoLog.info("replaceLastWord: aborting because Cmd+V events could not be created")
            restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "keyboard replacement paste failed")
            return false
        }
        Thread.sleep(forTimeInterval: KeyboardReplacementPolicy.postPasteDelay)
        let pasteTime = Date().timeIntervalSince(pasteStartTime) * 1000
        PuntoLog.info("replaceLastWord: paste took \(String(format: "%.1f", pasteTime))ms")

        let clipboardAfterPaste = pasteboard.string(forType: .string)
        if clipboardAfterPaste == replacement {
            PuntoLog.info("replaceLastWord: clipboard still contains replacement (paste likely succeeded)")
        } else {
            PuntoLog.info("replaceLastWord: clipboard changed to '\(clipboardAfterPaste?.prefix(20) ?? "nil")' (app may have modified it)")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + KeyboardReplacementPolicy.clipboardRestoreDelay) {
            if KeyboardReplacementPolicy.shouldRestoreClipboardAfterPaste(
                currentChangeCount: pasteboard.changeCount,
                replacementChangeCount: replacementChangeCount
            ) {
                self.restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "keyboard replacement")
                PuntoLog.debug("replaceLastWord: clipboard restored to original")
            }
        }

        return true
    }

    private func restorePasteboardIfEnabled(_ snapshot: PasteboardSnapshot, to pasteboard: NSPasteboard, reason: String) {
        guard shouldRestorePasteboard() else {
            PuntoLog.info("Pasteboard restore skipped by setting (reason: \(reason))")
            return
        }

        snapshot.restore(to: pasteboard)
    }
}
