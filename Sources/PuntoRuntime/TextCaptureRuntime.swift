import PuntoCore

/// Executes capability-based selected-text capture.
///
/// The core policies decide which capture evidence is safe. This runtime
/// composes AX selection evidence with active/passive clipboard observations
/// and keeps terminal-like non-settable surfaces away from direct AX mutation.
final class TextCaptureRuntime {
    private let accessibilityElements: AccessibilityElementClient
    private let accessibilitySelection: AccessibilityTextSelectionTransport
    private let clipboard: ClipboardTransport

    init(
        accessibilityElements: AccessibilityElementClient,
        accessibilitySelection: AccessibilityTextSelectionTransport,
        clipboard: ClipboardTransport
    ) {
        self.accessibilityElements = accessibilityElements
        self.accessibilitySelection = accessibilitySelection
        self.clipboard = clipboard
    }

    func captureSelectedText(lastTrackedWord: String?, lastTrackedTail: String?) -> CapturedText? {
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
                    activeClipboardText = captureSelectedTextViaClipboardIfFocused()
                    passiveClipboardText = clipboard.currentText()
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
            activeClipboardText = captureSelectedTextViaClipboardIfFocused()

        case .failed:
            passiveClipboardText = clipboard.currentText()
            let focusEvidence = accessibilityElements.keyboardFocusEvidence()
            if TextCapturePolicy.shouldAttemptActiveClipboardFallbackAfterFailedSelection(
                focusEvidence: focusEvidence,
                lastTrackedTail: lastTrackedTail
            ) {
                activeClipboardText = captureSelectedTextViaClipboardIfFocused(focusEvidence: focusEvidence)
            } else {
                PuntoLog.info("captureSelectedText: skipping active clipboard fallback after failed AX selection because tracked editable tail is available")
            }
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

    private func captureSelectedTextViaClipboardIfFocused() -> String? {
        let focusEvidence = accessibilityElements.keyboardFocusEvidence()
        return captureSelectedTextViaClipboardIfFocused(focusEvidence: focusEvidence)
    }

    private func captureSelectedTextViaClipboardIfFocused(focusEvidence: KeyboardFocusEvidence) -> String? {
        PuntoLog.info("getSelectedTextViaClipboard: AX focus check: \(focusEvidence.logDescription)")
        guard ClipboardCapturePolicy.shouldAttemptActiveClipboardCapture(
            focusEvidence: focusEvidence
        ) else {
            PuntoLog.info("getSelectedTextViaClipboard: aborting because focused copy target is not verifiable")
            return nil
        }

        return clipboard.captureSelectedText()
    }
}
