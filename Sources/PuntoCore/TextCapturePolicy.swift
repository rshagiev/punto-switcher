import Foundation

public enum TextReplacementMethod: Equatable {
    case accessibilitySelection
    case keyboardBackspacePaste
    case keyboardRewriteTail(originalTail: String)
    case blocked
}

public enum SelectedTextReplacementTransport: Equatable {
    case accessibility
    case clipboard
}

public struct CapturedText: Equatable {
    public let text: String
    public let replacementMethod: TextReplacementMethod
    public let source: String
    public let selectedTextReplacementTransport: SelectedTextReplacementTransport

    public init(
        text: String,
        replacementMethod: TextReplacementMethod,
        source: String,
        selectedTextReplacementTransport: SelectedTextReplacementTransport = .accessibility
    ) {
        self.text = text
        self.replacementMethod = replacementMethod
        self.source = source
        self.selectedTextReplacementTransport = selectedTextReplacementTransport
    }
}

public struct BlockedCaptureAction: Equatable {
    public let clearTrackedText: Bool
    public let clearConversionSession: Bool
    public let clearTrackedTextReason: String?
    public let clearConversionSessionReason: String?

    public init(
        clearTrackedText: Bool,
        clearConversionSession: Bool,
        clearTrackedTextReason: String? = nil,
        clearConversionSessionReason: String? = nil
    ) {
        self.clearTrackedText = clearTrackedText
        self.clearConversionSession = clearConversionSession
        self.clearTrackedTextReason = clearTrackedTextReason
        self.clearConversionSessionReason = clearConversionSessionReason
    }
}

public enum TextCapturePolicy {
    public enum AccessibilityObservation: Equatable {
        case selectedText(String, replacementSupported: Bool)
        case emptySelection
        case noFocusedElement
        case failed
    }

    public struct TailRewrite: Equatable {
        public let selectedText: String
        public let originalTail: String

        public init(selectedText: String, originalTail: String) {
            self.selectedText = selectedText
            self.originalTail = originalTail
        }
    }

    public static func shouldStopAfterBlockedCapture(_ capturedText: CapturedText?) -> Bool {
        capturedText?.replacementMethod == .blocked
    }

    public static func actionAfterBlockedCapture(_ capturedText: CapturedText?) -> BlockedCaptureAction {
        guard shouldStopAfterBlockedCapture(capturedText) else {
            return BlockedCaptureAction(clearTrackedText: false, clearConversionSession: false)
        }

        return BlockedCaptureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "blocked unsafe text capture",
            clearConversionSessionReason: "blocked unsafe text capture"
        )
    }

    public static func shouldAttemptActiveClipboardFallbackForNonSettableSelection(
        selectedText: String,
        lastTrackedTail: String?
    ) -> Bool {
        terminalTailRewrite(selectedText: selectedText, lastTrackedTail: lastTrackedTail) == nil
    }

    public static func captureDecision(
        observation: AccessibilityObservation,
        activeClipboardText: String?,
        passiveClipboardText: String?,
        lastTrackedWord: String?,
        lastTrackedTail: String?
    ) -> CapturedText? {
        switch observation {
        case .selectedText(let text, replacementSupported: true):
            return CapturedText(
                text: text,
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            )

        case .selectedText(let text, replacementSupported: false):
            if let rewrite = terminalTailRewrite(selectedText: text, lastTrackedTail: lastTrackedTail) {
                return CapturedText(
                    text: rewrite.selectedText,
                    replacementMethod: .keyboardRewriteTail(originalTail: rewrite.originalTail),
                    source: "AX non-settable command-tail selection"
                )
            }

            if let activeClipboardText,
               let rewrite = terminalTailRewrite(selectedText: activeClipboardText, lastTrackedTail: lastTrackedTail) {
                return CapturedText(
                    text: rewrite.selectedText,
                    replacementMethod: .keyboardRewriteTail(originalTail: rewrite.originalTail),
                    source: "clipboard command-tail selection"
                )
            }

            if let passiveText = passiveClipboardTailSelection(
                clipboardText: passiveClipboardText,
                lastTrackedWord: lastTrackedWord,
                lastTrackedTail: lastTrackedTail
            ) {
                return CapturedText(
                    text: passiveText,
                    replacementMethod: .keyboardBackspacePaste,
                    source: "passive clipboard tail selection"
                )
            }

            return CapturedText(
                text: "",
                replacementMethod: .blocked,
                source: "unsafe non-settable selection"
            )

        case .emptySelection:
            return nil

        case .noFocusedElement:
            guard let activeClipboardText = nonBlankClipboardText(activeClipboardText) else { return nil }
            if let rewrite = terminalTailRewrite(selectedText: activeClipboardText, lastTrackedTail: lastTrackedTail),
               activeClipboardText.trimmingCharacters(in: .whitespacesAndNewlines) != rewrite.selectedText {
                return CapturedText(
                    text: rewrite.selectedText,
                    replacementMethod: .keyboardRewriteTail(originalTail: rewrite.originalTail),
                    source: "active clipboard command-tail selection"
                )
            }
            if hasUnsafeTerminalTailEvidence(selectedText: activeClipboardText, lastTrackedTail: lastTrackedTail) {
                return CapturedText(
                    text: "",
                    replacementMethod: .blocked,
                    source: "unsafe active clipboard terminal tail"
                )
            }
            return CapturedText(
                text: activeClipboardText,
                replacementMethod: .accessibilitySelection,
                source: "active clipboard fallback",
                selectedTextReplacementTransport: .clipboard
            )

        case .failed:
            if let activeClipboardText = nonBlankClipboardText(activeClipboardText) {
                if let rewrite = terminalTailRewrite(selectedText: activeClipboardText, lastTrackedTail: lastTrackedTail),
                   activeClipboardText.trimmingCharacters(in: .whitespacesAndNewlines) != rewrite.selectedText {
                    return CapturedText(
                        text: rewrite.selectedText,
                        replacementMethod: .keyboardRewriteTail(originalTail: rewrite.originalTail),
                        source: "active clipboard command-tail selection"
                    )
                }
                if hasUnsafeTerminalTailEvidence(selectedText: activeClipboardText, lastTrackedTail: lastTrackedTail) {
                    return CapturedText(
                        text: "",
                        replacementMethod: .blocked,
                        source: "unsafe active clipboard terminal tail"
                    )
                }
                return CapturedText(
                    text: activeClipboardText,
                    replacementMethod: .accessibilitySelection,
                    source: "active clipboard fallback",
                    selectedTextReplacementTransport: .clipboard
                )
            }

            if let passiveText = passiveClipboardTailSelection(
                clipboardText: passiveClipboardText,
                lastTrackedWord: lastTrackedWord,
                lastTrackedTail: lastTrackedTail
            ) {
                return CapturedText(
                    text: passiveText,
                    replacementMethod: .keyboardBackspacePaste,
                    source: "passive clipboard tail selection"
                )
            }

            return nil
        }
    }

    private static func nonBlankClipboardText(_ text: String?) -> String? {
        guard let text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return text
    }

    public static func terminalTailRewrite(selectedText: String, lastTrackedTail: String?) -> TailRewrite? {
        guard let lastTrackedTail, !lastTrackedTail.isEmpty else {
            return nil
        }

        let selected = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !selected.isEmpty else {
            return nil
        }

        if selected == lastTrackedTail || (
            selected.hasSuffix(lastTrackedTail) &&
            hasTerminalPromptBoundary(beforeTail: lastTrackedTail, in: selected)
        ) {
            return TailRewrite(selectedText: lastTrackedTail, originalTail: lastTrackedTail)
        }

        if lastTrackedTail.hasSuffix(selected),
           hasTrackedTailBoundary(beforeSuffix: selected, in: lastTrackedTail) {
            return TailRewrite(selectedText: selected, originalTail: lastTrackedTail)
        }

        return nil
    }

    private static func hasTrackedTailBoundary(beforeSuffix suffix: String, in tail: String) -> Bool {
        WordBoundaryPolicy.hasCommandSuffixBoundary(beforeSuffix: suffix, in: tail)
    }

    private static func hasTerminalPromptBoundary(beforeTail tail: String, in selected: String) -> Bool {
        guard selected.hasSuffix(tail), selected.count > tail.count else {
            return false
        }

        let prefix = selected.dropLast(tail.count)
        guard !prefix.isEmpty else {
            return false
        }

        if prefix.last?.isWhitespace == true {
            let trimmedPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let promptMarker = trimmedPrefix.last else {
                return false
            }
            return WordBoundaryPolicy.isTerminalPromptMarker(promptMarker)
        }

        return false
    }

    private static func hasUnsafeTerminalTailEvidence(selectedText: String, lastTrackedTail: String?) -> Bool {
        guard let lastTrackedTail, !lastTrackedTail.isEmpty else {
            return false
        }

        let selected = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard selected.count > lastTrackedTail.count,
              selected.hasSuffix(lastTrackedTail) else {
            return false
        }

        return terminalTailRewrite(selectedText: selected, lastTrackedTail: lastTrackedTail) == nil
    }

    public static func passiveClipboardTailSelection(
        clipboardText: String?,
        lastTrackedWord: String?,
        lastTrackedTail: String?
    ) -> String? {
        guard let lastTrackedWord, !lastTrackedWord.isEmpty,
              let lastTrackedTail, !lastTrackedTail.isEmpty,
              let clipboardText, !clipboardText.isEmpty else {
            return nil
        }

        let trimmed = clipboardText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        guard trimmed == lastTrackedTail,
              trimmed.hasSuffix(lastTrackedWord) else {
            return nil
        }

        return trimmed
    }

    public static func activeClipboardFallbackForNonSettableContentSelection(
        selectedText: String,
        activeClipboardText: String?,
        accessibilityRoles: [String]
    ) -> CapturedText? {
        guard AccessibilityRolePolicy.containsClipboardReplaceableContentRole(accessibilityRoles),
              let activeClipboardText else {
            return nil
        }

        let selected = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let copied = activeClipboardText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !selected.isEmpty,
              !copied.isEmpty else {
            return nil
        }

        if selectedText == activeClipboardText {
            return CapturedText(
                text: activeClipboardText,
                replacementMethod: .accessibilitySelection,
                source: "active clipboard content selection",
                selectedTextReplacementTransport: .clipboard
            )
        }

        guard selected == copied else {
            return nil
        }

        return CapturedText(
            text: copied,
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        )
    }

    public static func activeClipboardFallbackForNonSettableContentSelection(
        selectedText: String,
        activeClipboardText: String?,
        accessibilityRole: String?
    ) -> CapturedText? {
        activeClipboardFallbackForNonSettableContentSelection(
            selectedText: selectedText,
            activeClipboardText: activeClipboardText,
            accessibilityRoles: accessibilityRole.map { [$0] } ?? []
        )
    }

}
