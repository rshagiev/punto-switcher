import Foundation
import PuntoCore

func runAutoCorrectionStarterCatalogTests() throws {
    let rules = AutoCorrectionStarterCatalog.rules
    try expect(rules.isEmpty, false, "starter catalog is not empty")
    try expect(AutoCorrectionRuleCatalog.hasBlockingIssues(rules), false, "starter catalog has no blocking issues")

    let converter = LayoutConverter()
    for rule in rules.prefix(36) {
        try expect(converter.convert(rule.trigger), rule.replacement, "starter wrong-layout rule \(rule.trigger)")
    }

    let engine = AutoCorrectionEngine(rules: rules)
    try expect(engine.correction(for: "ghbdtn")?.replacement, "привет", "starter catalog fixes wrong-layout привет")
    try expect(engine.correction(for: "cgfcb,j")?.replacement, "спасибо", "starter catalog fixes wrong-layout спасибо")
    try expect(engine.correction(for: "Teh")?.replacement, "The", "starter catalog fixes english typo with title case")
    try expect(engine.correction(for: "ADN")?.replacement, "AND", "starter catalog fixes english typo with uppercase")
}
