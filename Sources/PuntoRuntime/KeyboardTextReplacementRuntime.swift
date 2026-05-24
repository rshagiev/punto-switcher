import AppKit
import PuntoCore

/// Executes destructive keyboard-tail replacement.
///
/// `TextAccessor` decides which replacement method is needed. This runner owns
/// the ordered live checks and transports needed for the keyboard backspace +
/// paste path used on terminal-like surfaces.
final class KeyboardTextReplacementRuntime {
    private let keyboardEvents: KeyboardEventTransport
    private let accessibilityElements: AccessibilityElementClient
    private let clipboard: ClipboardTransport
    private let frontmostApplication: () -> NSRunningApplication?
    private let now: () -> Date
    private let sleep: (TimeInterval) -> Void

    init(
        keyboardEvents: KeyboardEventTransport,
        accessibilityElements: AccessibilityElementClient,
        clipboard: ClipboardTransport,
        frontmostApplication: @escaping () -> NSRunningApplication? = { NSWorkspace.shared.frontmostApplication },
        now: @escaping () -> Date = Date.init,
        sleep: @escaping (TimeInterval) -> Void = Thread.sleep
    ) {
        self.keyboardEvents = keyboardEvents
        self.accessibilityElements = accessibilityElements
        self.clipboard = clipboard
        self.frontmostApplication = frontmostApplication
        self.now = now
        self.sleep = sleep
    }

    @discardableResult
    func replaceLastWord(wordLength: Int, with replacement: String) -> Bool {
        let startTime = now()

        guard KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: wordLength) else {
            PuntoLog.info("replaceLastWord: aborting keyboard replacement because delete length is \(wordLength)")
            return false
        }

        logTargetApplicationState()

        let focusEvidence = accessibilityElements.keyboardFocusEvidence()
        PuntoLog.info("replaceLastWord: AX focus check: \(focusEvidence.logDescription)")
        guard KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(focusEvidence: focusEvidence) else {
            PuntoLog.info("replaceLastWord: aborting keyboard replacement because focused editable target is not verifiable")
            return false
        }

        PuntoLog.info("replaceLastWord: deleting \(wordLength) chars, replacing with '\(replacement)'")

        let modifiersBefore = keyboardEvents.currentModifierSnapshot()
        PuntoLog.info("replaceLastWord: modifiers BEFORE delay: \(KeyboardModifierCleanupPolicy.description(for: modifiersBefore))")
        keyboardEvents.releaseLatchedModifiers(modifiersBefore)

        let modifiersAfter = keyboardEvents.waitForModifierRelease()
        PuntoLog.info("replaceLastWord: modifiers AFTER release wait: \(KeyboardModifierCleanupPolicy.description(for: modifiersAfter))")
        guard KeyboardReplacementPolicy.shouldStartKeyboardEventsAfterModifierWait(
            modifiersArePressed: !modifiersAfter.noModifiersPressed
        ) else {
            PuntoLog.info("replaceLastWord: aborting keyboard replacement because modifiers are still pressed after release wait")
            return false
        }

        PuntoLog.info("replaceLastWord: sending \(wordLength) backspaces via cghidEventTap (after \(Int(KeyboardReplacementPolicy.modifierReleaseSettleDelay * 1000))ms delay)")
        let backspacesSent = keyboardEvents.postBackspaces(count: wordLength)
        let backspaceTime = now().timeIntervalSince(startTime) * 1000
        PuntoLog.info("replaceLastWord: \(backspacesSent)/\(wordLength) backspaces sent in \(String(format: "%.1f", backspaceTime))ms, waiting \(Int(KeyboardReplacementPolicy.prePasteDelay * 1000))ms")
        guard KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(
            expectedCount: wordLength,
            sentCount: backspacesSent
        ) else {
            PuntoLog.info("replaceLastWord: aborting paste because not all backspaces were sent")
            return false
        }

        sleep(KeyboardReplacementPolicy.prePasteDelay)
        guard clipboard.pasteKeyboardReplacement(replacement) else {
            return false
        }

        let totalTime = now().timeIntervalSince(startTime) * 1000
        PuntoLog.info("replaceLastWord: completed in \(String(format: "%.1f", totalTime))ms (sent \(backspacesSent) backspaces + Cmd+V with '\(replacement)')")
        return true
    }

    private func logTargetApplicationState() {
        guard let frontApp = frontmostApplication() else {
            return
        }

        PuntoLog.info("replaceLastWord: target app='\(frontApp.localizedName ?? "?")' isActive=\(frontApp.isActive) isHidden=\(frontApp.isHidden) pid=\(frontApp.processIdentifier)")
    }
}
