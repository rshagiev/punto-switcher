import Foundation
import PuntoCore

func runAutoCorrectionRuleStoreTests() throws {
    let tsv = """
    # trigger replacement
    ghbdtn\tпривет
    teh\tthe\tcaseInsensitive\ttrue
    invalid-only
    ghbdtn\tздравствуйте
    typo\tfixed\tcaseinsensitive\ttrue
    maybe\tperhaps\tcaseInsensitive\tmaybe
    """

    let importResult = try AutoCorrectionRuleStore.decodeRules(from: Data(tsv.utf8))
    try expect(importResult.rules.count, 2, "rule store parses and deduplicates tsv rules")
    try expect(importResult.rules[0].replacement, "здравствуйте", "rule store last duplicate wins")
    try expect(importResult.rules[1].matchMode, .caseInsensitive, "rule store parses match mode")
    try expect(importResult.skippedLines[4], "invalid-only", "rule store reports malformed line")
    try expect(importResult.skippedLines[6], "typo\tfixed\tcaseinsensitive\ttrue", "rule store reports invalid match mode")
    try expect(importResult.skippedLines[7], "maybe\tperhaps\tcaseInsensitive\tmaybe", "rule store reports invalid preserveCase flag")

    let sparseImport = try AutoCorrectionRuleStore.decodeRules(from: Data("good\tok\n\nbroken-only\nnext\tfine\n".utf8))
    try expect(sparseImport.skippedLines[3], "broken-only", "rule store preserves physical line numbers across blank lines")

    let quotedCommaImport = try AutoCorrectionRuleStore.decodeRules(from: Data("\"cgfcb,j\",спасибо,exact,true\n".utf8))
    try expect(
        quotedCommaImport.rules.first,
        AutoCorrectionRule(trigger: "cgfcb,j", replacement: "спасибо"),
        "rule store parses quoted comma trigger"
    )

    let escapedQuoteImport = try AutoCorrectionRuleStore.decodeRules(from: Data("\"say \"\"hi\"\"\",hello\n".utf8))
    try expect(
        escapedQuoteImport.rules.first,
        AutoCorrectionRule(trigger: "say \"hi\"", replacement: "hello"),
        "rule store parses escaped quotes in quoted csv trigger"
    )

    let malformedCSVImport = try AutoCorrectionRuleStore.decodeRules(from: Data("good,ok\nbad,\"unterminated\nnext,fine\n".utf8))
    try expect(
        malformedCSVImport.skippedLines[2],
        "bad,\"unterminated",
        "rule store reports unterminated quoted csv line"
    )
    try expect(
        malformedCSVImport.rules,
        [
            AutoCorrectionRule(trigger: "good", replacement: "ok"),
            AutoCorrectionRule(trigger: "next", replacement: "fine")
        ],
        "rule store keeps valid csv lines around malformed quoted line"
    )

    let misplacedQuoteImport = try AutoCorrectionRuleStore.decodeRules(from: Data("good,ok\nbad\"quote,value\nnext,fine\n".utf8))
    try expect(
        misplacedQuoteImport.skippedLines[2],
        "bad\"quote,value",
        "rule store reports misplaced csv quote"
    )
    try expect(
        misplacedQuoteImport.rules,
        [
            AutoCorrectionRule(trigger: "good", replacement: "ok"),
            AutoCorrectionRule(trigger: "next", replacement: "fine")
        ],
        "rule store keeps valid csv lines around misplaced quote"
    )

    let jsonData = try AutoCorrectionRuleStore.encodeRules(importResult.rules)
    let jsonResult = try AutoCorrectionRuleStore.decodeRules(from: jsonData)
    try expect(jsonResult.rules, importResult.rules, "rule store json round-trip")
    try expect(
        AutoCorrectionRuleStore.normalizedRules([
            AutoCorrectionRule(trigger: " ", replacement: "ignored"),
            AutoCorrectionRule(trigger: " teh ", replacement: " the ", matchMode: .caseInsensitive),
            AutoCorrectionRule(trigger: "TEH", replacement: "THE", matchMode: .caseInsensitive),
            AutoCorrectionRule(trigger: "empty", replacement: " ")
        ]),
        [AutoCorrectionRule(trigger: "TEH", replacement: "THE", matchMode: .caseInsensitive)],
        "rule store normalizes decoded persisted rules"
    )

    let merged = AutoCorrectionRuleStore.mergedRules(
        existing: [AutoCorrectionRule(trigger: "teh", replacement: "old", matchMode: .caseInsensitive)],
        imported: [AutoCorrectionRule(trigger: "TEH", replacement: "the", matchMode: .caseInsensitive)]
    )
    try expect(merged.count, 1, "rule store merges case-insensitive duplicates")
    try expect(merged[0].replacement, "the", "rule store imported duplicate overrides")

    let catalogRules = [
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "", replacement: "missing"),
        AutoCorrectionRule(trigger: "same", replacement: "same"),
        AutoCorrectionRule(trigger: "TEH", replacement: "THE", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "  ghbdtn  ", replacement: "  привет  ")
    ]
    try expect(
        AutoCorrectionRuleCatalog.filteredRuleIndexes(in: catalogRules, query: "the"),
        [0, 3],
        "rule catalog filters by replacement"
    )
    try expect(
        AutoCorrectionRuleCatalog.filteredRuleIndexes(in: catalogRules, query: "привет"),
        [4],
        "rule catalog filters by normalized replacement"
    )
    try expect(
        AutoCorrectionRuleCatalog.filteredRuleIndexes(in: catalogRules, query: "ghbdtn"),
        [4],
        "rule catalog filters by normalized trigger"
    )
    let issues = AutoCorrectionRuleCatalog.validationIssues(for: catalogRules)
    try expect(issues.contains { $0.severity == .error && $0.ruleIndex == 1 }, true, "rule catalog flags empty trigger")
    try expect(issues.contains { $0.severity == .warning && $0.ruleIndex == 2 }, true, "rule catalog warns identical replacement")
    try expect(issues.contains { $0.severity == .warning && $0.ruleIndex == 3 }, true, "rule catalog warns duplicate trigger")
    try expect(AutoCorrectionRuleCatalog.hasBlockingIssues(catalogRules), true, "rule catalog reports blocking issues")
}
