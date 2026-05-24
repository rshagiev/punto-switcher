import PuntoCore

/// Executes selected-text and captured-text replacement routes.
///
/// `TextReplacementPolicy` owns the pure route decision. This runtime composes
/// the concrete AX, clipboard, and keyboard-tail executors so `TextAccessor`
/// can stay a public facade instead of re-owning replacement mechanics.
final class TextReplacementRuntime {
    private let accessibilitySelection: AccessibilityTextSelectionTransport
    private let accessibilityElements: AccessibilityElementClient
    private let clipboard: ClipboardTransport
    private let keyboardReplacement: KeyboardTextReplacementRuntime

    init(
        accessibilitySelection: AccessibilityTextSelectionTransport,
        accessibilityElements: AccessibilityElementClient,
        clipboard: ClipboardTransport,
        keyboardReplacement: KeyboardTextReplacementRuntime
    ) {
        self.accessibilitySelection = accessibilitySelection
        self.accessibilityElements = accessibilityElements
        self.clipboard = clipboard
        self.keyboardReplacement = keyboardReplacement
    }

    @discardableResult
    func setSelectedText(_ text: String, keepSelection: Bool = false) -> Bool {
        PuntoLog.info("setSelectedText called with \(text.count) chars, keepSelection=\(keepSelection)")

        if accessibilitySelection.replaceSelection(with: text, keepSelection: keepSelection) {
            PuntoLog.info("setSelectedText: Accessibility API succeeded")
            return true
        }

        PuntoLog.info("setSelectedText: Accessibility API failed, using clipboard")
        return pasteSelectedTextViaClipboard(text, selectAfterPaste: keepSelection)
    }

    @discardableResult
    func replaceCapturedText(_ capturedText: CapturedText, with replacement: String, keepSelection: Bool = false) -> Bool {
        PuntoLog.info("replaceCapturedText: method=\(capturedText.replacementMethod), source=\(capturedText.source)")
        switch TextReplacementPolicy.plan(
            for: capturedText,
            replacement: replacement,
            keepSelection: keepSelection
        ) {
        case .accessibilitySelection(let text, let keepSelection):
            return setSelectedText(text, keepSelection: keepSelection)
        case .clipboardSelection(let text, let selectAfterPaste):
            return pasteSelectedTextViaClipboard(text, selectAfterPaste: selectAfterPaste)
        case .keyboardBackspacePaste(let deleteLength, let text):
            return replaceLastWord(wordLength: deleteLength, with: text)
        case .blocked:
            PuntoLog.info("replaceCapturedText: blocked capture or unrewritable tail, no replacement")
            return false
        }
    }

    @discardableResult
    func replaceLastWord(wordLength: Int, with replacement: String) -> Bool {
        keyboardReplacement.replaceLastWord(wordLength: wordLength, with: replacement)
    }

    private func pasteSelectedTextViaClipboard(_ text: String, selectAfterPaste: Bool) -> Bool {
        accessibilitySelection.clearCachedEditableElement()
        let focusEvidence = accessibilityElements.keyboardFocusEvidence()
        PuntoLog.info("setSelectedTextViaClipboard: AX focus check: \(focusEvidence.logDescription)")
        guard ClipboardReplacementPolicy.shouldAttemptSelectedTextClipboardReplacement(
            focusEvidence: focusEvidence
        ) else {
            PuntoLog.info("setSelectedTextViaClipboard: aborting because focused paste target is not verifiable")
            return false
        }
        return clipboard.pasteSelectedText(text, selectAfterPaste: selectAfterPaste)
    }
}
