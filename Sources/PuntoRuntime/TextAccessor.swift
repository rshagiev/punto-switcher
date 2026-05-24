import AppKit
import ApplicationServices
import Carbon.HIToolbox
import PuntoCore

/// Handles getting and setting selected text using Accessibility API
/// Falls back to clipboard-based approach for apps that don't support Accessibility
public final class TextAccessor {

    public typealias ReplacementMethod = TextReplacementMethod
    public typealias CapturedText = PuntoCore.CapturedText

    private let keyboardEvents: KeyboardEventTransport
    private let accessibilityElements: AccessibilityElementClient
    private let accessibilitySelection: AccessibilityTextSelectionTransport
    private let clipboard: ClipboardTransport

    public convenience init(shouldRestorePasteboard: @escaping () -> Bool = { true }) {
        self.init(
            shouldRestorePasteboard: shouldRestorePasteboard,
            keyboardEvents: KeyboardEventTransport(),
            accessibilityElements: AccessibilityElementClient()
        )
    }

    init(
        shouldRestorePasteboard: @escaping () -> Bool,
        keyboardEvents: KeyboardEventTransport = KeyboardEventTransport(),
        accessibilityElements: AccessibilityElementClient = AccessibilityElementClient(),
        accessibilitySelection: AccessibilityTextSelectionTransport? = nil,
        clipboard: ClipboardTransport? = nil
    ) {
        self.keyboardEvents = keyboardEvents
        self.accessibilityElements = accessibilityElements
        self.accessibilitySelection = accessibilitySelection ?? AccessibilityTextSelectionTransport(
            accessibilityElements: accessibilityElements
        )
        self.clipboard = clipboard ?? ClipboardTransport(
            shouldRestorePasteboard: shouldRestorePasteboard,
            keyboardEvents: keyboardEvents
        )
    }

    // MARK: - Security Detection

    /// Checks if Secure Keyboard Input is enabled (e.g., in Terminal password prompts)
    /// When enabled, CGEvent simulation is blocked for security
    public func isSecureInputEnabled() -> Bool {
        return IsSecureEventInputEnabled()
    }

    /// Checks if focused element is a secure/password text field
    /// Used to skip conversion in browser password fields
    public func isPasswordField() -> Bool {
        accessibilityElements.isPasswordField()
    }

    public func canDoSearchClick(bundleID: String?) -> Bool {
        accessibilityElements.canDoSearchClick(bundleID: bundleID)
    }

    // MARK: - Get Selected Text

    /// Captures a usable text selection and the safest way to replace it.
    ///
    /// The decision is capability based:
    /// - AX selections are used only when the focused element appears editable and
    ///   can set selected text.
    /// - Non-editable text surfaces are treated as terminal-like. We only accept
    ///   passive clipboard selection when it ends with the tracked input tail.
    /// - Apps without useful AX selection still get the active Cmd+C fallback.
    public func captureSelectedText(lastTrackedWord: String?, lastTrackedTail: String?) -> CapturedText? {
        let axResult = accessibilitySelection.captureSelection()
        let observation = axResult.observation
        var activeClipboardText: String?
        var passiveClipboardText: String?
        var overrideCapturedText: CapturedText?

        switch axResult {
        case .text(let text, let element, let replacementSupported):
            if !replacementSupported {
                let accessibilityRoles = accessibilityElements.rolesFromElementToAncestors(
                    element,
                    maxDepth: AccessibilityTraversalPolicy.maxAncestorRoleDepth
                )
                if TextCapturePolicy.shouldPreferActiveClipboardFallbackForNonSettableContentSelection(
                    accessibilityRoles: accessibilityRoles
                ) || TextCapturePolicy.shouldAttemptActiveClipboardFallbackForNonSettableSelection(
                    selectedText: text,
                    lastTrackedTail: lastTrackedTail
                ) {
                    PuntoLog.info("captureSelectedText: trying active clipboard copy for non-settable AX selection")
                    activeClipboardText = getSelectedTextViaClipboard()
                    passiveClipboardText = currentClipboardText()
                    overrideCapturedText = TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
                        selectedText: text,
                        activeClipboardText: activeClipboardText,
                        accessibilityRoles: accessibilityRoles
                    )
                }
            }

        case .empty:
            break

        case .noFocus:
            PuntoLog.info("captureSelectedText: noFocus, trying active clipboard fallback")
            activeClipboardText = getSelectedTextViaClipboard()

        case .failed:
            passiveClipboardText = currentClipboardText()
            activeClipboardText = getSelectedTextViaClipboard()
        }

        let captured = overrideCapturedText ?? TextCapturePolicy.captureDecision(
            observation: observation,
            activeClipboardText: activeClipboardText,
            passiveClipboardText: passiveClipboardText,
            lastTrackedWord: lastTrackedWord,
            lastTrackedTail: lastTrackedTail
        )

        if captured?.replacementMethod == .blocked {
            accessibilitySelection.clearCachedEditableElement()
            PuntoLog.info("captureSelectedText: blocking fallback because non-settable selection is not current command tail")
        }
        if captured?.replacementMethod != .accessibilitySelection {
            accessibilitySelection.clearCachedEditableElement()
        }

        return captured
    }

    // MARK: - Clipboard Fallback

    private func getSelectedTextViaClipboard() -> String? {
        clipboard.captureSelectedText()
    }

    private func currentClipboardText() -> String? {
        clipboard.currentText()
    }

    // MARK: - Set Selected Text

    /// Replaces the currently selected text with new text
    /// - Parameters:
    ///   - text: The text to insert
    ///   - keepSelection: If true, the inserted text will be selected after insertion (for undo support)
    @discardableResult
    public func setSelectedText(_ text: String, keepSelection: Bool = false) -> Bool {
        PuntoLog.info("setSelectedText called with \(text.count) chars, keepSelection=\(keepSelection)")

        // Try Accessibility API first
        if setSelectedTextViaAccessibility(text, keepSelection: keepSelection) {
            PuntoLog.info("setSelectedText: Accessibility API succeeded")
            return true
        }

        PuntoLog.info("setSelectedText: Accessibility API failed, using clipboard")
        // Fall back to clipboard method
        return setSelectedTextViaClipboard(text, selectAfterPaste: keepSelection)
    }

    @discardableResult
    public func replaceCapturedText(_ capturedText: CapturedText, with replacement: String, keepSelection: Bool = false) -> Bool {
        PuntoLog.info("replaceCapturedText: method=\(capturedText.replacementMethod), source=\(capturedText.source)")
        switch TextReplacementPolicy.plan(
            for: capturedText,
            replacement: replacement,
            keepSelection: keepSelection
        ) {
        case .accessibilitySelection(let text, let keepSelection):
            return setSelectedText(text, keepSelection: keepSelection)
        case .clipboardSelection(let text, let selectAfterPaste):
            return setSelectedTextViaClipboard(text, selectAfterPaste: selectAfterPaste)
        case .keyboardBackspacePaste(let deleteLength, let text):
            return replaceLastWord(wordLength: deleteLength, with: text)
        case .blocked:
            PuntoLog.info("replaceCapturedText: blocked capture or unrewritable tail, no replacement")
            return false
        }
    }

    private func setSelectedTextViaAccessibility(_ text: String, keepSelection: Bool = false) -> Bool {
        accessibilitySelection.replaceSelection(with: text, keepSelection: keepSelection)
    }

    private func setSelectedTextViaClipboard(_ text: String, selectAfterPaste: Bool = false) -> Bool {
        accessibilitySelection.clearCachedEditableElement()
        return clipboard.pasteSelectedText(text, selectAfterPaste: selectAfterPaste)
    }

    // MARK: - Replace Last Word

    /// Deletes the last word and pastes the replacement via clipboard
    @discardableResult
    public func replaceLastWord(wordLength: Int, with replacement: String) -> Bool {
        let startTime = Date()

        guard KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: wordLength) else {
            PuntoLog.info("replaceLastWord: aborting keyboard replacement because delete length is \(wordLength)")
            return false
        }

        // Log active app state before sending events
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let isActive = frontApp.isActive
            let isHidden = frontApp.isHidden
            PuntoLog.info("replaceLastWord: target app='\(frontApp.localizedName ?? "?")' isActive=\(isActive) isHidden=\(isHidden) pid=\(frontApp.processIdentifier)")
        }

        // Check keyboard focus via AX before sending events
        let axFocusEvidence = checkKeyboardFocusEvidence()
        PuntoLog.info("replaceLastWord: AX focus check: \(axFocusEvidence.logDescription)")
        if !KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(focusEvidence: axFocusEvidence) {
            PuntoLog.info("replaceLastWord: aborting keyboard replacement because focused editable target is not verifiable")
            return false
        }

        PuntoLog.info("replaceLastWord: deleting \(wordLength) chars, replacing with '\(replacement)'")

        // Check current modifier state BEFORE delay
        let modifiersBefore = CGEventSource.flagsState(.hidSystemState)
        let modDescBefore = describeModifiers(modifiersBefore)
        PuntoLog.info("replaceLastWord: modifiers BEFORE delay: \(modDescBefore)")
        releaseLatchedKeyboardModifiers(modifiersBefore)

        // Wait until the hotkey modifiers are fully released before sending destructive keys.
        let modifiersAfter = waitForModifierRelease()
        let modDescAfter = describeModifiers(modifiersAfter)
        PuntoLog.info("replaceLastWord: modifiers AFTER release wait: \(modDescAfter)")
        if !KeyboardReplacementPolicy.shouldStartKeyboardEventsAfterModifierWait(
            modifiersArePressed: hasKeyboardModifiers(modifiersAfter)
        ) {
            PuntoLog.info("replaceLastWord: aborting keyboard replacement because modifiers are still pressed after release wait")
            return false
        }

        // Delete characters one by one using Backspace (keyCode 51)
        // Using .cghidEventTap which works for most apps
        // Do not use line-kill shortcuts here: this path must delete exactly the captured tail.
        PuntoLog.info("replaceLastWord: sending \(wordLength) backspaces via cghidEventTap (after \(Int(KeyboardReplacementPolicy.modifierReleaseSettleDelay * 1000))ms delay)")
        let backspacesSent = keyboardEvents.postBackspaces(count: wordLength)
        let backspaceTime = Date().timeIntervalSince(startTime) * 1000
        PuntoLog.info("replaceLastWord: \(backspacesSent)/\(wordLength) backspaces sent in \(String(format: "%.1f", backspaceTime))ms, waiting \(Int(KeyboardReplacementPolicy.prePasteDelay * 1000))ms")
        guard KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: wordLength, sentCount: backspacesSent) else {
            PuntoLog.info("replaceLastWord: aborting paste because not all backspaces were sent")
            return false
        }
        Thread.sleep(forTimeInterval: KeyboardReplacementPolicy.prePasteDelay)

        guard clipboard.pasteKeyboardReplacement(replacement) else {
            return false
        }

        // Note: Active verification via select+copy is destructive - removed
        // Instead rely on AX focus check and clipboard state for diagnostics

        let totalTime = Date().timeIntervalSince(startTime) * 1000
        PuntoLog.info("replaceLastWord: completed in \(String(format: "%.1f", totalTime))ms (sent \(backspacesSent) backspaces + Cmd+V with '\(replacement)')")
        return true
    }

    @discardableResult
    public func replaceRecentText(length: Int, with replacement: String) -> Bool {
        replaceLastWord(wordLength: length, with: replacement)
    }

    // MARK: - Helpers

    // MARK: - Debugging Helpers

    /// Describes current modifier key state
    private func describeModifiers(_ flags: CGEventFlags) -> String {
        var parts: [String] = []
        if flags.contains(.maskCommand) { parts.append("⌘") }
        if flags.contains(.maskAlternate) { parts.append("⌥") }
        if flags.contains(.maskShift) { parts.append("⇧") }
        if flags.contains(.maskControl) { parts.append("⌃") }
        return parts.isEmpty ? "none" : parts.joined()
    }

    private func waitForModifierRelease() -> CGEventFlags {
        Thread.sleep(forTimeInterval: KeyboardReplacementPolicy.modifierReleaseSettleDelay)

        let deadline = Date().addingTimeInterval(KeyboardReplacementPolicy.modifierReleaseMaxWait)
        var flags = CGEventSource.flagsState(.hidSystemState)
        while hasKeyboardModifiers(flags), Date() < deadline {
            Thread.sleep(forTimeInterval: KeyboardReplacementPolicy.modifierReleasePollInterval)
            flags = CGEventSource.flagsState(.hidSystemState)
        }

        return flags
    }

    private func releaseLatchedKeyboardModifiers(_ flags: CGEventFlags) {
        let snapshot = ModifierFlagsSnapshot(
            command: flags.contains(.maskCommand),
            option: flags.contains(.maskAlternate),
            shift: flags.contains(.maskShift),
            control: flags.contains(.maskControl)
        )
        guard KeyboardModifierCleanupPolicy.shouldPostCleanup(for: snapshot) else {
            return
        }

        _ = keyboardEvents.postKeyUps(KeyboardModifierCleanupPolicy.keyUpCodes(for: snapshot))
        PuntoLog.info("replaceLastWord: sent modifier key-up cleanup for \(describeModifiers(flags))")
    }

    private func hasKeyboardModifiers(_ flags: CGEventFlags) -> Bool {
        flags.contains(.maskCommand)
            || flags.contains(.maskAlternate)
            || flags.contains(.maskShift)
            || flags.contains(.maskControl)
    }

    /// Checks keyboard focus state via AX API.
    private func checkKeyboardFocusEvidence() -> KeyboardFocusEvidence {
        accessibilityElements.keyboardFocusEvidence()
    }

}
