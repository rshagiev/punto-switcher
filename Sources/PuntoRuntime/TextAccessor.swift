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
    private let textCapture: TextCaptureRuntime
    private let keyboardReplacement: KeyboardTextReplacementRuntime
    private let textReplacement: TextReplacementRuntime

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
        textCapture.captureSelectedText(
            lastTrackedWord: lastTrackedWord,
            lastTrackedTail: lastTrackedTail
        )
    }

    // MARK: - Set Selected Text

    /// Replaces the currently selected text with new text
    /// - Parameters:
    ///   - text: The text to insert
    ///   - keepSelection: If true, the inserted text will be selected after insertion (for undo support)
    @discardableResult
    public func setSelectedText(_ text: String, keepSelection: Bool = false) -> Bool {
        textReplacement.setSelectedText(text, keepSelection: keepSelection)
    }

    @discardableResult
    public func replaceCapturedText(_ capturedText: CapturedText, with replacement: String, keepSelection: Bool = false) -> Bool {
        textReplacement.replaceCapturedText(
            capturedText,
            with: replacement,
            keepSelection: keepSelection
        )
    }

    // MARK: - Replace Last Word

    /// Deletes the last word and pastes the replacement via clipboard
    @discardableResult
    public func replaceLastWord(wordLength: Int, with replacement: String) -> Bool {
        textReplacement.replaceLastWord(wordLength: wordLength, with: replacement)
    }

    @discardableResult
    public func replaceRecentText(length: Int, with replacement: String) -> Bool {
        replaceLastWord(wordLength: length, with: replacement)
    }

}
