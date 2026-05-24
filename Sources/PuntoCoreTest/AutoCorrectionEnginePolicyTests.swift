import Foundation
import PuntoCore

func runAutoCorrectionEngineTests() throws {
    let engine = AutoCorrectionEngine(rules: [
        AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"),
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive)
    ])

    try expect(engine.correction(for: "ghbdtn")?.replacement, "привет", "auto-correction exact rule")
    try expect(engine.correction(for: "Teh")?.replacement, "The", "auto-correction preserves title case")
    try expect(engine.correction(for: "TEH")?.replacement, "THE", "auto-correction preserves uppercase")
    try expect(engine.correction(for: "tEh")?.replacement, "tHe", "auto-correction preserves mixed case by position")
    try expectNil(engine.correction(for: "unknown"), "auto-correction ignores unknown word")

    let symbolRuleEngine = AutoCorrectionEngine(rules: [
        AutoCorrectionRule(trigger: "404", replacement: "not found", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "++", replacement: "increment", matchMode: .caseInsensitive)
    ])
    try expect(
        symbolRuleEngine.correction(for: "404")?.replacement,
        "not found",
        "auto-correction does not uppercase replacement for numeric trigger"
    )
    try expect(
        symbolRuleEngine.correction(for: "++")?.replacement,
        "increment",
        "auto-correction does not uppercase replacement for symbol trigger"
    )

    let normalizedRuleEngine = AutoCorrectionEngine(rules: [
        AutoCorrectionRule(trigger: " ghbdtn ", replacement: " привет\n"),
        AutoCorrectionRule(trigger: " Teh ", replacement: " the ", matchMode: .caseInsensitive)
    ])
    try expect(
        normalizedRuleEngine.correction(for: "ghbdtn")?.replacement,
        "привет",
        "auto-correction trims exact user rule fields"
    )
    try expect(
        normalizedRuleEngine.correction(for: "TEH")?.replacement,
        "THE",
        "auto-correction trims case-insensitive user rule fields"
    )

    let tracker = WordTracker()
    type("ghbdtn ", into: tracker)
    try expect(tracker.consumeCompletedToken(), WordTracker.CompletedToken(word: "ghbdtn", separator: " "), "word tracker exposes completed space token")
    try expectNil(tracker.consumeCompletedToken(), "word tracker consumes completed token once")

    type("teh", into: tracker)
    tracker.trackKeyPress(keyCode: 36, characters: "\r")
    try expect(tracker.consumeCompletedToken(), WordTracker.CompletedToken(word: "teh", separator: "\n"), "word tracker exposes completed return token")
}

