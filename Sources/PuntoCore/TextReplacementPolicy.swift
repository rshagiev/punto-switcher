import Foundation

public enum TextReplacementPlan: Equatable {
    case accessibilitySelection(text: String, keepSelection: Bool)
    case clipboardSelection(text: String, selectAfterPaste: Bool)
    case keyboardBackspacePaste(deleteLength: Int, text: String)
    case blocked
}

public enum TextReplacementPolicy {
    public static func plan(
        for capturedText: CapturedText,
        replacement: String,
        keepSelection: Bool
    ) -> TextReplacementPlan {
        switch capturedText.replacementMethod {
        case .accessibilitySelection:
            if capturedText.selectedTextReplacementTransport == .clipboard {
                return .clipboardSelection(text: replacement, selectAfterPaste: keepSelection)
            }
            return .accessibilitySelection(text: replacement, keepSelection: keepSelection)

        case .keyboardBackspacePaste:
            guard !capturedText.text.isEmpty else {
                return .blocked
            }
            return .keyboardBackspacePaste(deleteLength: capturedText.text.count, text: replacement)

        case .keyboardRewriteTail(let originalTail):
            guard let rewrittenTail = rewriteTail(
                originalTail,
                replacing: capturedText.text,
                with: replacement
            ) else {
                return .blocked
            }
            return .keyboardBackspacePaste(deleteLength: originalTail.count, text: rewrittenTail)

        case .blocked:
            return .blocked
        }
    }

    public static func rewriteTail(_ originalTail: String, replacing selectedText: String, with replacement: String) -> String? {
        guard !originalTail.isEmpty,
              !selectedText.isEmpty,
              originalTail.hasSuffix(selectedText),
              hasTrackedTailBoundary(beforeSuffix: selectedText, in: originalTail),
              let range = originalTail.range(of: selectedText, options: .backwards) else {
            return nil
        }

        var result = originalTail
        result.replaceSubrange(range, with: replacement)
        return result
    }

    public static func recordedMethodAfterReplacement(
        capturedText: String,
        replacement: String,
        method: TextReplacementMethod
    ) -> TextReplacementMethod? {
        guard case .keyboardRewriteTail(let originalTail) = method else {
            return method
        }

        guard let rewrittenTail = rewriteTail(originalTail, replacing: capturedText, with: replacement) else {
            return nil
        }

        return .keyboardRewriteTail(originalTail: rewrittenTail)
    }

    public static func trackedTailAfterReplacement(
        capturedText: String,
        replacement: String,
        method: TextReplacementMethod
    ) -> String? {
        guard case .keyboardRewriteTail(let originalTail) = method else {
            return nil
        }

        return rewriteTail(originalTail, replacing: capturedText, with: replacement)
    }

    public static func shouldKeepSelectionAfterReplacement(method: TextReplacementMethod) -> Bool {
        method == .accessibilitySelection
    }

    public static func trackedTailAfterLastWordReplacement(
        lastTrackedTail: String?,
        lastWord: String,
        replacement: String
    ) -> String? {
        guard let lastTrackedTail,
              !lastTrackedTail.isEmpty,
              !lastWord.isEmpty,
              lastTrackedTail.hasSuffix(lastWord),
              hasTrackedTailBoundary(beforeSuffix: lastWord, in: lastTrackedTail) else {
            return nil
        }

        return String(lastTrackedTail.dropLast(lastWord.count)) + replacement
    }

    public static func trackedTailAfterRecentTextReplacement(
        lastTrackedTail: String?,
        original: String,
        replacement: String
    ) -> String {
        guard let lastTrackedTail,
              !lastTrackedTail.isEmpty,
              !original.isEmpty,
              lastTrackedTail.hasSuffix(original),
              hasTrackedTailBoundary(beforeSuffix: original, in: lastTrackedTail) else {
            return replacement
        }

        return String(lastTrackedTail.dropLast(original.count)) + replacement
    }

    public static func trackedTailAfterUndo(
        convertedText: String,
        originalText: String,
        method: TextReplacementMethod
    ) -> String? {
        guard case .keyboardRewriteTail(let convertedTail) = method else {
            return nil
        }

        return rewriteTail(convertedTail, replacing: convertedText, with: originalText)
    }

    public static func recordedMethodAfterUndo(
        convertedText: String,
        originalText: String,
        method: TextReplacementMethod
    ) -> TextReplacementMethod? {
        guard case .keyboardRewriteTail = method else {
            return method
        }

        guard let undoneTail = trackedTailAfterUndo(
            convertedText: convertedText,
            originalText: originalText,
            method: method
        ) else {
            return nil
        }

        return .keyboardRewriteTail(originalTail: undoneTail)
    }

    private static func hasTrackedTailBoundary(beforeSuffix suffix: String, in tail: String) -> Bool {
        WordBoundaryPolicy.hasCommandSuffixBoundary(beforeSuffix: suffix, in: tail)
    }
}
