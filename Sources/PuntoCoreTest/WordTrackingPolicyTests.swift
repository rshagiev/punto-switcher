import Foundation
import PuntoCore

func runWordTrackingPolicyTests() throws {
    try expect(
        WordTrackingPolicy.action(keyCode: WordTrackingPolicy.escapeKeyCode, characters: nil),
        .clear(reason: "escape"),
        "word tracking policy clears on Escape"
    )
    try expect(
        WordTrackingPolicy.action(keyCode: 9, characters: nil),
        .clear(reason: "external command (keyCode=9)"),
        "word tracking policy clears nil-character external commands"
    )
    try expect(
        WordTrackingPolicy.action(keyCode: WordTrackingPolicy.deleteKeyCode, characters: "\u{7f}"),
        .removeLastCharacter,
        "word tracking policy removes one character on Backspace"
    )
    try expect(
        WordTrackingPolicy.action(keyCode: WordTrackingPolicy.forwardDeleteKeyCode, characters: nil),
        .clear(reason: "external command (keyCode=117)"),
        "word tracking policy clears Forward Delete without produced characters"
    )
    try expect(
        WordTrackingPolicy.action(keyCode: 123, characters: "\u{F702}"),
        .clear(reason: "navigation key 123"),
        "word tracking policy clears modified cursor movement"
    )
    try expect(
        WordTrackingPolicy.action(keyCode: WordTrackingPolicy.returnKeyCode, characters: "\r"),
        .completeToken(separator: "\n", reason: "return/enter"),
        "word tracking policy completes token on Return"
    )
    try expect(
        WordTrackingPolicy.action(keyCode: WordTrackingPolicy.enterKeyCode, characters: "\r"),
        .completeToken(separator: "\n", reason: "return/enter"),
        "word tracking policy completes token on Enter"
    )
    try expect(
        WordTrackingPolicy.action(keyCode: WordTrackingPolicy.tabKeyCode, characters: "\t"),
        .completeToken(separator: "\t", reason: "tab"),
        "word tracking policy completes token on Tab"
    )
    try expect(
        WordTrackingPolicy.action(keyCode: 0, characters: "a"),
        .trackProducedCharacters,
        "word tracking policy tracks ordinary produced text"
    )
    try expect(
        WordTrackingPolicy.action(keyCode: 0, characters: ""),
        .ignore,
        "word tracking policy ignores empty produced text"
    )
}
