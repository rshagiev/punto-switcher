import ApplicationServices
import Carbon.HIToolbox
import PuntoCore

/// Handles getting and setting selected text using Accessibility API
/// Falls back to clipboard-based approach for apps that don't support Accessibility
public final class TextAccessor {

    public typealias ReplacementMethod = TextReplacementMethod
    public typealias CapturedText = PuntoCore.CapturedText

    private let runtime: TextAccessorRuntimeContainer

    public convenience init(shouldRestorePasteboard: @escaping () -> Bool = { true }) {
        self.init(
            runtime: TextAccessorRuntimeContainer(
                shouldRestorePasteboard: shouldRestorePasteboard
            )
        )
    }

    init(runtime: TextAccessorRuntimeContainer) {
        self.runtime = runtime
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
        runtime.isPasswordField()
    }

    /// Cheap password-field probe for high-frequency keyDown routing.
    ///
    /// Manual conversions still use `isPasswordField()` with the full fallback
    /// path. The key tracking path avoids retrying AX focus lookup on every
    /// character, because event taps are time-sensitive.
    public func isPasswordFieldFast() -> Bool {
        runtime.isPasswordFieldFast()
    }

    public func canDoSearchClick(bundleID: String?) -> Bool {
        runtime.canDoSearchClick(bundleID: bundleID)
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
        runtime.captureSelectedText(
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
        runtime.setSelectedText(text, keepSelection: keepSelection)
    }

    @discardableResult
    public func replaceCapturedText(_ capturedText: CapturedText, with replacement: String, keepSelection: Bool = false) -> Bool {
        runtime.replaceCapturedText(
            capturedText,
            with: replacement,
            keepSelection: keepSelection
        )
    }

    // MARK: - Replace Last Word

    /// Deletes the last word and pastes the replacement via clipboard
    @discardableResult
    public func replaceLastWord(wordLength: Int, with replacement: String) -> Bool {
        runtime.replaceLastWord(wordLength: wordLength, with: replacement)
    }

    @discardableResult
    public func replaceRecentText(length: Int, with replacement: String) -> Bool {
        replaceLastWord(wordLength: length, with: replacement)
    }

}
