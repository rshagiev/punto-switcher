import PuntoCore

/// Owns the live text-access runtime graph behind `TextAccessor`.
///
/// The public facade stays small and stable for app coordinators. This container
/// wires AX, clipboard, keyboard, capture, and replacement runtimes together so
/// construction details do not drift back into the facade.
final class TextAccessorRuntimeContainer {
    private let keyboardEvents: KeyboardEventTransport
    private let accessibilityElements: AccessibilityElementClient
    private let accessibilitySelection: AccessibilityTextSelectionTransport
    private let clipboard: ClipboardTransport
    private let textCapture: TextCaptureRuntime
    private let keyboardReplacement: KeyboardTextReplacementRuntime
    private let textReplacement: TextReplacementRuntime

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
        self.textCapture = TextCaptureRuntime(
            accessibilityElements: self.accessibilityElements,
            accessibilitySelection: self.accessibilitySelection,
            clipboard: self.clipboard
        )
        self.keyboardReplacement = KeyboardTextReplacementRuntime(
            keyboardEvents: self.keyboardEvents,
            accessibilityElements: self.accessibilityElements,
            clipboard: self.clipboard
        )
        self.textReplacement = TextReplacementRuntime(
            accessibilitySelection: self.accessibilitySelection,
            clipboard: self.clipboard,
            keyboardReplacement: self.keyboardReplacement
        )
    }

    func isPasswordField() -> Bool {
        accessibilityElements.isPasswordField()
    }

    func canDoSearchClick(bundleID: String?) -> Bool {
        accessibilityElements.canDoSearchClick(bundleID: bundleID)
    }

    func captureSelectedText(lastTrackedWord: String?, lastTrackedTail: String?) -> CapturedText? {
        textCapture.captureSelectedText(
            lastTrackedWord: lastTrackedWord,
            lastTrackedTail: lastTrackedTail
        )
    }

    @discardableResult
    func setSelectedText(_ text: String, keepSelection: Bool = false) -> Bool {
        textReplacement.setSelectedText(text, keepSelection: keepSelection)
    }

    @discardableResult
    func replaceCapturedText(_ capturedText: CapturedText, with replacement: String, keepSelection: Bool = false) -> Bool {
        textReplacement.replaceCapturedText(
            capturedText,
            with: replacement,
            keepSelection: keepSelection
        )
    }

    @discardableResult
    func replaceLastWord(wordLength: Int, with replacement: String) -> Bool {
        textReplacement.replaceLastWord(wordLength: wordLength, with: replacement)
    }
}
