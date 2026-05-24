import Foundation
import PuntoCore

func runClipboardContentCapturePolicyTests() throws {
    let webContentCapture = try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "browser selection",
            activeClipboardText: "browser selection\n",
            accessibilityRole: "AXWebArea"
        ),
        CapturedText(
            text: "browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy accepts fresh AXWebArea clipboard selection"
    )
    guard let webContentCapture else {
        throw TestFailure(description: "capture policy accepts fresh AXWebArea clipboard selection: expected non-nil capture")
    }
    try expect(
        webContentCapture.selectedTextReplacementTransport,
        .clipboard,
        "capture policy routes web content selection replacement through clipboard"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "nested browser selection",
            activeClipboardText: "nested browser selection",
            accessibilityRoles: ["AXStaticText", "AXGroup", "AXWebArea"]
        ),
        CapturedText(
            text: "nested browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy accepts selected text from descendants inside AXWebArea"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "normalized browser selection",
            activeClipboardText: "normalized browser selection",
            accessibilityRoles: ["AXStaticText", " ax web area "]
        ),
        CapturedText(
            text: "normalized browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy accepts normalized AXWebArea ancestry"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "  browser selection  ",
            activeClipboardText: "  browser selection  ",
            accessibilityRole: "AXWebArea"
        ),
        CapturedText(
            text: "  browser selection  ",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy preserves exact AXWebArea selection whitespace"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "   ",
            activeClipboardText: "   ",
            accessibilityRole: "AXWebArea"
        ),
        "capture policy rejects whitespace-only AXWebArea clipboard selection"
    )
    try expect(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "browser selection",
            activeClipboardText: "browser selection\n",
            accessibilityRole: "AXWebArea"
        ),
        CapturedText(
            text: "browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard content selection",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy trims copied AXWebArea wrapper newline only when raw values differ"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "static selection",
            activeClipboardText: "static selection",
            accessibilityRoles: ["AXStaticText", "AXGroup", "AXWindow"]
        ),
        "capture policy rejects static text without AXWebArea ancestry"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "old scrollback",
            activeClipboardText: "old scrollback",
            accessibilityRole: "AXTextArea"
        ),
        "capture policy does not treat terminal-like text areas as web content"
    )
    try expectNil(
        TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
            selectedText: "browser selection",
            activeClipboardText: "different clipboard",
            accessibilityRole: "AXWebArea"
        ),
        "capture policy rejects stale web content clipboard"
    )

}
