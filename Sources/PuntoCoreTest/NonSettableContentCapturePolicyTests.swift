import Foundation
import PuntoCore

func runNonSettableContentCapturePolicyTests() throws {
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "mail selection",
            activeClipboardText: "mail selection",
            accessibilityRoles: ["AXStaticText", "AXWebArea"]
        ),
        CapturedText(
            text: "mail selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy accepts matched non-settable AXWebArea content through active clipboard replacement"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "commit",
            activeClipboardText: "commit",
            accessibilityRoles: ["AXStaticText", "AXWebArea"]
        ),
        CapturedText(
            text: "commit",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy avoids misclassifying AXWebArea selected suffix as terminal-tail rewrite when clipboard confirms content selection"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "parallels selection",
            activeClipboardText: "parallels selection",
            accessibilityRoles: ["AXStaticText", "AXScrollArea"]
        ),
        CapturedText(
            text: "parallels selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy accepts matched AXScrollArea content observed in Punto Switcher Mail/Parallels path"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "static selection",
            activeClipboardText: "static selection",
            accessibilityRoles: ["AXStaticText", "AXGroup"]
        ),
        "capture policy rejects generic non-settable content without observed content roles"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "mail selection",
            activeClipboardText: "different clipboard",
            accessibilityRoles: ["AXWebArea"]
        ),
        "capture policy rejects mismatched active clipboard content selection"
    )
}
