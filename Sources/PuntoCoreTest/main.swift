import Foundation
import PuntoCore

private struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

@discardableResult
private func expect<T: Equatable>(_ actual: @autoclosure () -> T, _ expected: T, _ message: String) throws -> T {
    let value = actual()
    guard value == expected else {
        throw TestFailure(description: "\(message): expected \(expected), got \(value)")
    }
    print("PASS \(message)")
    return value
}

private func expectNil<T>(_ actual: @autoclosure () -> T?, _ message: String) throws {
    let value = actual()
    guard value == nil else {
        throw TestFailure(description: "\(message): expected nil, got \(String(describing: value))")
    }
    print("PASS \(message)")
}

private func type(_ text: String, into tracker: WordTracker) {
    for char in text {
        let keyCode: UInt16 = char == " " ? 49 : 0
        tracker.trackKeyPress(keyCode: keyCode, characters: String(char))
    }
}

private func runWordBoundaryPolicyTests() throws {
    for character in [";", "'", ":", "\"", ",", ".", "/", "?", "[", "]", "{", "}", "<", ">", "`", "~"] as [Character] {
        try expect(
            WordBoundaryPolicy.isLayoutMappedPunctuation(character),
            true,
            "word boundary policy treats \(character) as layout-mapped punctuation"
        )
        try expect(
            WordBoundaryPolicy.isTypedWordBoundary(character, keyCode: 0),
            false,
            "word boundary policy keeps \(character) inside wrong-layout word"
        )
    }

    for character in ["!", "(", ")", "\\", "|", "@", "#", "$", "%", "^", "&", "*", "+", "=", "-", "_"] as [Character] {
        try expect(
            WordBoundaryPolicy.isTypedWordBoundary(character, keyCode: 0),
            true,
            "word boundary policy treats \(character) as typed-word boundary"
        )
    }

    for character in ["\\", "|", "@", "#", "$", "%", "^", "&", "*"] as [Character] {
        try expect(
            WordBoundaryPolicy.isLayoutMappedPunctuation(character, russianLayoutType: .mac),
            true,
            "word boundary policy treats \(character) as Mac layout-mapped punctuation"
        )
        try expect(
            WordBoundaryPolicy.isTypedWordBoundary(character, keyCode: 0, russianLayoutType: .mac),
            false,
            "word boundary policy keeps \(character) inside Mac wrong-layout word"
        )
    }

    try expect(
        WordBoundaryPolicy.isTypedWordBoundary("+", keyCode: 0, russianLayoutType: .mac),
        true,
        "word boundary policy keeps unmapped Mac plus as typed-word boundary"
    )

    try expect(
        WordBoundaryPolicy.isTypedWordBoundary("x", keyCode: WordBoundaryPolicy.spaceKeyCode),
        true,
        "word boundary policy treats space keyCode as boundary even with synthesized characters"
    )
    for character in [" ", "\n", "\t", "&", "|", ";", "(", ")", "<", ">", "=", "-"] as [Character] {
        try expect(
            WordBoundaryPolicy.isCommandSuffixBoundary(character),
            true,
            "word boundary policy treats \(character) as command suffix boundary"
        )
    }
    try expect(
        WordBoundaryPolicy.isCommandSuffixBoundary("a"),
        false,
        "word boundary policy rejects ordinary letters as command suffix boundary"
    )
    try expect(
        WordBoundaryPolicy.isCommandSuffixBoundary("."),
        false,
        "word boundary policy keeps layout-mapped punctuation out of command suffix boundaries"
    )
    try expect(
        WordBoundaryPolicy.hasCommandSuffixBoundary(beforeSuffix: "commit", in: "git commit"),
        true,
        "word boundary policy accepts suffix after whitespace boundary"
    )
    try expect(
        WordBoundaryPolicy.hasCommandSuffixBoundary(beforeSuffix: "ghbdtn", in: "FOO=ghbdtn"),
        true,
        "word boundary policy accepts suffix after shell assignment boundary"
    )
    try expect(
        WordBoundaryPolicy.hasCommandSuffixBoundary(beforeSuffix: "commit", in: "commit"),
        true,
        "word boundary policy accepts whole text as suffix boundary"
    )
    try expect(
        WordBoundaryPolicy.hasCommandSuffixBoundary(beforeSuffix: "mit", in: "commit"),
        false,
        "word boundary policy rejects partial-word suffix"
    )
    try expect(
        WordBoundaryPolicy.hasCommandSuffixBoundary(beforeSuffix: "commit", in: "git.commit"),
        false,
        "word boundary policy rejects layout-mapped punctuation before suffix"
    )
    try expect(
        WordBoundaryPolicy.hasCommandSuffixBoundary(beforeSuffix: "push", in: "git commit"),
        false,
        "word boundary policy rejects missing suffix"
    )
    for character in ["%", "$", "#", ">", "➜", "❯", "λ", "✗", "✔", "±", "●"] as [Character] {
        try expect(
            WordBoundaryPolicy.isTerminalPromptMarker(character),
            true,
            "word boundary policy treats \(character) as terminal prompt marker"
        )
    }
    try expect(
        WordBoundaryPolicy.isTerminalPromptMarker("a"),
        false,
        "word boundary policy rejects ordinary letters as terminal prompt markers"
    )
    try expect(
        WordBoundaryPolicy.isTerminalPromptMarker(" "),
        false,
        "word boundary policy rejects whitespace as terminal prompt marker"
    )
}

private func runWordTrackingPolicyTests() throws {
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

private func runLayoutConverterTests() throws {
    let converter = LayoutConverter()

    try expect(converter.convert("ghbdtn"), "привет", "wrong-layout RU word")
    try expect(converter.convert(";jgf"), "жопа", "wrong-layout RU word with punctuation key")
    try expect(converter.convert("руддщ"), "hello", "wrong-layout EN word")
    try expect(converter.convert("Hello World"), "Руддщ Цщкдв", "multi-word conversion")
    try expect(converter.convert("Привет"), "Ghbdtn", "capitalized reverse conversion")
    try expect(converter.convert("HeLLo"), "РуДДщ", "mixed-case conversion")
    try expect(converter.convert("hELLO"), "рУДДЩ", "inverted-case conversion")
    try expect(converter.convert("hello, world"), "руддщб цщкдв", "punctuation with text conversion")
    try expect(converter.convert("123abc"), "123фис", "leading numbers with text conversion")

    let symbolConversions: [(String, String, String)] = [
        ("@", "\"", "shift-2 symbol"),
        ("#", "№", "shift-3 symbol"),
        ("$", ";", "shift-4 symbol"),
        ("^", ":", "shift-6 symbol"),
        ("&", "?", "shift-7 symbol"),
        ("|", "/", "pipe symbol"),
        ("ё", "`", "russian yo reverse"),
        ("Ё", "~", "russian uppercase yo reverse"),
        ("ж", ";", "russian semicolon reverse"),
        ("э", "'", "russian apostrophe reverse"),
        ("б", ",", "russian comma reverse"),
        ("ю", ".", "russian period reverse")
    ]
    for (input, expected, name) in symbolConversions {
        try expect(converter.convert(input), expected, "symbol conversion \(name)")
    }

    try expect(
        converter.convertToRussian("\\", russianLayoutType: .mac),
        "ё",
        "Mac Russian layout maps backslash to yo"
    )
    try expect(
        converter.convertToRussian("`", russianLayoutType: .mac),
        "]",
        "Mac Russian layout maps backtick to closing bracket"
    )
    try expect(
        converter.convertToRussian("~", russianLayoutType: .mac),
        "[",
        "Mac Russian layout maps shifted backtick to opening bracket"
    )
    try expect(
        converter.convertToRussian("$%^&*", russianLayoutType: .mac),
        "%:,.;",
        "Mac Russian layout uses Apple punctuation row"
    )
    try expect(
        converter.convertToRussian("/?", russianLayoutType: .mac),
        "/?",
        "Mac Russian layout keeps slash key punctuation"
    )
    try expect(
        converter.convertToEnglish("ё", russianLayoutType: .mac),
        "\\",
        "Mac Russian layout reverses yo to backslash"
    )
    try expect(
        converter.convertToEnglish("][", russianLayoutType: .mac),
        "`~",
        "Mac Russian layout reverses bracket punctuation to backtick key"
    )
    try expect(
        converter.convertToEnglish("%:,.;", russianLayoutType: .mac),
        "$%^&*",
        "Mac Russian layout reverses Apple punctuation row"
    )
    let macPunctuation = converter.convertWithResult("\\", russianLayoutType: .mac)
    try expect(macPunctuation.text, "ё", "Mac Russian convertWithResult converts backslash to yo")
    try expect(macPunctuation.targetLayout, .russian, "Mac Russian convertWithResult reports Russian target")

    for sample in ["hello", "привет", "HELLO", "ПРИВЕТ", "Hello World", "HeLLo", "hello world", "test123", "123abc", "data[0]", "test'case", "[test]", ";',./"] {
        let converted = converter.convert(sample)
        try expect(converter.convert(converted), sample, "round-trip \(sample)")
    }

    let selectedTextSamples: [(String, String)] = [
        ("selected single wrong-layout word", "ghbdtn"),
        ("selected two wrong-layout words", "ghbdtn vbh"),
        ("selected wrong-layout sentence", "ghbdtn vbh 'nj ntcn"),
        ("selected wrong-layout paragraph", String(repeating: "ghbdtn ", count: 15)),
        ("selected large wrong-layout text", String(repeating: "ghbdtn vbh ", count: 50)),
        ("selected very large wrong-layout text", String(repeating: "ntrcn ", count: 170)),
        ("selected mixed-case wrong-layout text", "Ghbdtn Vbh"),
        ("selected punctuation wrong-layout text", "ghbdtn, vbh!"),
        ("selected multiline wrong-layout text", "ghbdtn\nvbh\nntrcn"),
        ("selected wrong-layout text with numbers", "ntrcn123 ghbdtn456")
    ]
    for (name, sample) in selectedTextSamples {
        let converted = converter.convert(sample)
        try expect(converted != sample, true, "\(name) changes text")
        try expect(converter.convert(converted), sample, "\(name) round-trip")
    }

    try expect(converter.detectLayout("123"), .unknown, "numbers layout")
    try expect(converter.detectLayout("hello123"), .english, "english plus numbers layout")
    try expect(converter.detectLayout("привет123"), .russian, "russian plus numbers layout")
    try expect(converter.detectLayout("heллo"), .mixed, "mixed layout")
    try expect(converter.convert("teстing"), "teстing", "convert leaves mixed text unchanged")

    let english = converter.convertWithResult("ghbdtn")
    try expect(english.text, "привет", "convertWithResult text EN to RU")
    try expect(english.targetLayout, .russian, "convertWithResult target EN to RU")

    let russian = converter.convertWithResult("руддщ")
    try expect(russian.text, "hello", "convertWithResult text RU to EN")
    try expect(russian.targetLayout, .english, "convertWithResult target RU to EN")

    let unknown = converter.convertWithResult("123")
    try expect(unknown.text, "123", "convertWithResult leaves unknown no-op text unchanged")
    try expect(unknown.targetLayout, .unknown, "convertWithResult does not switch layout for unknown no-op text")
    try expect(unknown.shouldApply, false, "convertWithResult marks unknown no-op as non-applicable")

    let mixed = converter.convertWithResult("teстing")
    try expect(mixed.text, "teстing", "convertWithResult leaves mixed text unchanged")
    try expect(mixed.targetLayout, .unknown, "convertWithResult does not switch layout for mixed text")
    try expect(mixed.shouldApply, false, "convertWithResult marks mixed text as non-applicable")

    let punctuation = converter.convertWithResult(";'")
    try expect(punctuation.text, "жэ", "convertWithResult converts punctuation-only wrong-layout text")
    try expect(punctuation.targetLayout, .russian, "convertWithResult reports target for punctuation-only conversion")
    try expect(punctuation.shouldApply, true, "convertWithResult marks punctuation conversion as applicable")

    let passthroughSymbol = converter.convertWithResult("\\")
    try expect(passthroughSymbol.text, "\\", "convertWithResult leaves passthrough symbol unchanged")
    try expect(passthroughSymbol.targetLayout, .unknown, "convertWithResult does not switch layout for passthrough-only symbol")
    try expect(passthroughSymbol.shouldApply, false, "convertWithResult marks passthrough-only symbol as non-applicable")

    let symbol = converter.convertWithResult("|")
    try expect(symbol.text, "/", "convertWithResult converts symbol-only wrong-layout text")
    try expect(symbol.targetLayout, .russian, "convertWithResult reports target for symbol-only conversion")
    try expect(symbol.shouldApply, true, "convertWithResult marks symbol-only conversion as applicable")

    for (sample, description) in [
        ("a;b", "one letter with mapped punctuation"),
        (";a;", "mapped punctuation around one letter"),
        ("test;test", "words joined by mapped punctuation")
    ] {
        let converted = converter.convert(sample)
        let roundTrip = converter.convert(converted)
        try expect(roundTrip, sample, "punctuation-heavy conversion round-trips for \(description)")
    }

    for sample in ["abcdйцу", "abcdйцуe", "abcdйцук"] {
        let result = converter.convertWithResult(sample)
        try expect(converter.detectLayout(sample), .mixed, "near-threshold sample remains mixed: \(sample)")
        try expect(result.text, sample, "near-threshold mixed sample is not converted: \(sample)")
        try expect(result.targetLayout, .unknown, "near-threshold mixed sample has no target layout: \(sample)")
        try expect(result.shouldApply, false, "near-threshold mixed sample is marked non-applicable: \(sample)")
    }

    for sample in ["é", "ñ", "ü", "中文", "🎉", "👨‍👩‍👧", "\u{0301}", "e\u{0301}"] {
        let result = converter.convertWithResult(sample)
        try expect(result.text, sample, "non EN/RU Unicode passes through unchanged: \(sample.debugDescription)")
        try expect(result.targetLayout, .unknown, "non EN/RU Unicode has no target layout: \(sample.debugDescription)")
        try expect(result.shouldApply, false, "non EN/RU Unicode is marked non-applicable: \(sample.debugDescription)")
        try expect(converter.convert(converter.convert(sample)), sample, "non EN/RU Unicode round-trips: \(sample.debugDescription)")
    }

    for sample in ["\0", "\u{0007}", "\u{001B}", "\u{007F}", "hello\0world"] {
        let converted = converter.convert(sample)
        try expect(converter.convert(converted), sample, "control-character sample round-trips: \(sample.debugDescription)")
    }
}

private func runLayoutDetectionPolicyTests() throws {
    try expect(
        LayoutDetectionPolicy.detectedLayout(englishCount: 0, russianCount: 0),
        .unknown,
        "layout detection policy treats no letters as unknown"
    )
    try expect(
        LayoutDetectionPolicy.detectedLayout(englishCount: 4, russianCount: 1),
        .mixed,
        "layout detection policy keeps exact 80 percent English mixed"
    )
    try expect(
        LayoutDetectionPolicy.detectedLayout(englishCount: 5, russianCount: 1),
        .english,
        "layout detection policy accepts above 80 percent English"
    )
    try expect(
        LayoutDetectionPolicy.detectedLayout(englishCount: 1, russianCount: 4),
        .mixed,
        "layout detection policy keeps exact 20 percent English mixed"
    )
    try expect(
        LayoutDetectionPolicy.detectedLayout(englishCount: 1, russianCount: 5),
        .russian,
        "layout detection policy accepts below 20 percent English as Russian"
    )
    try expect(
        LayoutDetectionPolicy.isEnglishLetter("a"),
        true,
        "layout detection policy detects ASCII English"
    )
    try expect(
        LayoutDetectionPolicy.isRussianLetter("я"),
        true,
        "layout detection policy detects Cyrillic Russian"
    )
    for character in ["é", "ñ", "ü", "中", "🎉", "\u{0301}", "e\u{0301}"] as [Character] {
        try expect(
            LayoutDetectionPolicy.isEnglishLetter(character) || LayoutDetectionPolicy.isRussianLetter(character),
            false,
            "layout detection policy treats \(character) as non EN/RU"
        )
    }
}

private func runWordTrackerTests() throws {
    do {
        try expect(
            AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames([" BackSpace ", "DELETE", "leftArrow", "unknown"]),
            [
                AutoCorrectionCancellingKeyPolicy.backspace,
                AutoCorrectionCancellingKeyPolicy.delete,
                AutoCorrectionCancellingKeyPolicy.leftArrow
            ],
            "auto-correction cancelling key policy normalizes supported key names"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.supportedKeyNames,
            [
                AutoCorrectionCancellingKeyPolicy.backspace,
                AutoCorrectionCancellingKeyPolicy.delete,
                AutoCorrectionCancellingKeyPolicy.leftArrow,
                AutoCorrectionCancellingKeyPolicy.rightArrow,
                AutoCorrectionCancellingKeyPolicy.upArrow,
                AutoCorrectionCancellingKeyPolicy.downArrow
            ],
            "auto-correction cancelling key policy mirrors supported Punto Switcher cancelling key names"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.setCancellingKeyStateSelector,
            "setCancellingKeyState:doEnable:",
            "observed surface preserves auto-correction cancelling-key setter selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.backspaceName,
            "dontAutoconvertWordWithBackspace",
            "observed surface preserves auto-correction cancelling-key backspace name"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.deleteName,
            "dontAutoconvertWordWithDelete",
            "observed surface preserves auto-correction cancelling-key delete name"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.leftArrowName,
            "dontAutoconvertWordWithLeftArrow",
            "observed surface preserves auto-correction cancelling-key left-arrow name"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.rightArrowName,
            "dontAutoconvertWordWithRightArrow",
            "observed surface preserves auto-correction cancelling-key right-arrow name"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.upArrowName,
            "dontAutoconvertWordWithUpArrow",
            "observed surface preserves auto-correction cancelling-key up-arrow name"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.downArrowName,
            "dontAutoconvertWordWithDownArrow",
            "observed surface preserves auto-correction cancelling-key down-arrow name"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyBackspaceName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.backspaceName,
            "auto-correction cancelling key policy keeps backspace name alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyDeleteName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.deleteName,
            "auto-correction cancelling key policy keeps delete name alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyLeftArrowName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.leftArrowName,
            "auto-correction cancelling key policy keeps left-arrow name alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyRightArrowName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.rightArrowName,
            "auto-correction cancelling key policy keeps right-arrow name alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyUpArrowName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.upArrowName,
            "auto-correction cancelling key policy keeps up-arrow name alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyDownArrowName,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.downArrowName,
            "auto-correction cancelling key policy keeps down-arrow name alias aligned with reverse-audit anchor"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.backspaceSelector,
            "dontAutoconvertWordWithBackspace:",
            "observed surface preserves auto-correction cancelling-key backspace selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.deleteSelector,
            "dontAutoconvertWordWithDelete:",
            "observed surface preserves auto-correction cancelling-key delete selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.leftArrowSelector,
            "dontAutoconvertWordWithLeftArrow:",
            "observed surface preserves auto-correction cancelling-key left-arrow selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.rightArrowSelector,
            "dontAutoconvertWordWithRightArrow:",
            "observed surface preserves auto-correction cancelling-key right-arrow selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.upArrowSelector,
            "dontAutoconvertWordWithUpArrow:",
            "observed surface preserves auto-correction cancelling-key up-arrow selector"
        )
        try expect(
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.downArrowSelector,
            "dontAutoconvertWordWithDownArrow:",
            "observed surface preserves auto-correction cancelling-key down-arrow selector"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyBackspaceSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.backspaceSelector,
            "auto-correction cancelling key policy keeps backspace selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyDeleteSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.deleteSelector,
            "auto-correction cancelling key policy keeps delete selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyLeftArrowSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.leftArrowSelector,
            "auto-correction cancelling key policy keeps left-arrow selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyRightArrowSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.rightArrowSelector,
            "auto-correction cancelling key policy keeps right-arrow selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyUpArrowSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.upArrowSelector,
            "auto-correction cancelling key policy keeps up-arrow selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.legacyDownArrowSelectorAlias,
            PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.downArrowSelector,
            "auto-correction cancelling key policy keeps down-arrow selector alias aligned with reverse-audit anchor"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames([
                " dontAutoconvertWordWithBackspace ",
                "dontAutoconvertWordWithDelete",
                "dontAutoconvertWordWithLeftArrow",
                "dontAutoconvertWordWithRightArrow",
                "dontAutoconvertWordWithUpArrow",
                "dontAutoconvertWordWithDownArrow"
            ]),
            AutoCorrectionCancellingKeyPolicy.supportedKeyNames,
            "auto-correction cancelling key policy accepts observed Punto Switcher per-key names"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames([
                " \(PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.backspaceSelector) ",
                PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.deleteSelector,
                PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.leftArrowSelector,
                PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.rightArrowSelector,
                PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.upArrowSelector,
                PuntoSwitcherObservedSurface.AutoCorrectionCancellingKeys.downArrowSelector
            ]),
            AutoCorrectionCancellingKeyPolicy.supportedKeyNames,
            "auto-correction cancelling key policy accepts observed Punto Switcher selector names"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.shouldSuppressAutoCorrection(keyCode: 51, enabledKeyNames: ["backspace"]),
            true,
            "auto-correction cancelling key policy suppresses backspace when enabled"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.shouldSuppressAutoCorrection(
                keyCode: 51,
                enabledKeyNames: [AutoCorrectionCancellingKeyPolicy.legacyBackspaceName]
            ),
            true,
            "auto-correction cancelling key policy suppresses backspace from observed name"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.shouldSuppressAutoCorrection(keyCode: 51, enabledKeyNames: []),
            false,
            "auto-correction cancelling key policy allows disabling backspace suppression"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.shouldSuppressAutoCorrection(
                keyCode: WordTrackingPolicy.forwardDeleteKeyCode,
                enabledKeyNames: [AutoCorrectionCancellingKeyPolicy.delete]
            ),
            true,
            "auto-correction cancelling key policy maps Forward Delete"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.cancellingKeyName(for: WordTrackingPolicy.leftArrowKeyCode),
            AutoCorrectionCancellingKeyPolicy.leftArrow,
            "auto-correction cancelling key policy maps Left Arrow"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.cancellingKeyName(for: WordTrackingPolicy.rightArrowKeyCode),
            AutoCorrectionCancellingKeyPolicy.rightArrow,
            "auto-correction cancelling key policy maps Right Arrow"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.cancellingKeyName(for: WordTrackingPolicy.upArrowKeyCode),
            AutoCorrectionCancellingKeyPolicy.upArrow,
            "auto-correction cancelling key policy maps Up Arrow"
        )
        try expect(
            AutoCorrectionCancellingKeyPolicy.cancellingKeyName(for: WordTrackingPolicy.downArrowKeyCode),
            AutoCorrectionCancellingKeyPolicy.downArrow,
            "auto-correction cancelling key policy maps Down Arrow"
        )
    }

    do {
        let tracker = WordTracker()
        type("git commit", into: tracker)
        try expect(tracker.getLastWord(), "commit", "word and tail last word")
        try expect(tracker.getTypedTail(), "git commit", "word and tail typed tail")
    }

    do {
        let tracker = WordTracker()
        type("teh quick ", into: tracker)
        try expect(tracker.getTypedTail(), "teh quick", "typed tail trims boundary whitespace for terminal matching")
        try expect(
            tracker.getTypedTailPreservingBoundaryWhitespace(),
            "teh quick ",
            "typed tail preserves completed separator for auto-correction"
        )
    }

    do {
        let tracker = WordTracker()
        type("hello", into: tracker)
        tracker.trackKeyPress(keyCode: 51, characters: "\u{7f}")
        try expect(tracker.getLastWord(), "hell", "backspace updates word")
        try expect(tracker.getTypedTail(), "hell", "backspace updates tail")
    }

    do {
        let tracker = WordTracker()
        type("ghbdt", into: tracker)
        tracker.trackKeyPress(keyCode: 51, characters: "\u{7f}")
        type("tn ", into: tracker)
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "ghbdtn", separator: " ", isAutoCorrectionSuppressed: true),
            "backspace marks edited completed token as auto-correction suppressed"
        )
    }

    do {
        let tracker = WordTracker()
        type("ghbdt", into: tracker)
        tracker.trackKeyPress(
            keyCode: 51,
            characters: "\u{7f}",
            autoCorrectionCancellingKeyNames: []
        )
        type("tn ", into: tracker)
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "ghbdtn", separator: " "),
            "disabled backspace cancelling key keeps edited completed token eligible for auto-correction"
        )
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(keyCode: 51, characters: "\u{7f}")
        type("ghbdtn ", into: tracker)
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "ghbdtn", separator: " "),
            "backspace before a word does not suppress the next completed token"
        )
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(keyCode: 0, characters: "hello")
        try expect(tracker.getLastWord(), "hello", "multi-character input updates full word")
        try expect(tracker.getTypedTail(), "hello", "multi-character input updates full tail")
    }

    do {
        let tracker = WordTracker()
        tracker.replaceTrackedTail(
            with: "the",
            reason: "manual conversion test",
            suppressAutoCorrectionForCurrentToken: true
        )
        tracker.trackKeyPress(keyCode: 49, characters: " ")
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "the", separator: " ", isAutoCorrectionSuppressed: true),
            "manual conversion tail replacement can suppress next auto-correction"
        )
    }

    do {
        let tracker = WordTracker()
        tracker.replaceTrackedTail(with: "the", reason: "manual conversion test")
        tracker.trackKeyPress(keyCode: 49, characters: " ")
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "the", separator: " "),
            "manual conversion tail replacement keeps next auto-correction eligible when suppression is disabled"
        )
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(keyCode: 0, characters: "hello world")
        try expect(tracker.getLastWord(), "world", "multi-character input honors embedded word boundary")
        try expect(tracker.getTypedTail(), "hello world", "multi-character input preserves typed tail across embedded boundary")
        try expect(tracker.consumeCompletedToken(), WordTracker.CompletedToken(word: "hello", separator: " "), "multi-character input records completed token at embedded boundary")
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(keyCode: 0, characters: "\\", russianLayoutType: .mac)
        try expect(tracker.getLastWord(), "\\", "word tracker keeps Mac backslash key in last word")
        tracker.trackKeyPress(keyCode: 0, characters: "|", russianLayoutType: .mac)
        try expect(tracker.getLastWord(), "\\|", "word tracker keeps Mac shifted backslash key in last word")
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(keyCode: 0, characters: "\\", russianLayoutType: .windows)
        try expectNil(tracker.getLastWord(), "word tracker treats Windows backslash as word boundary")
    }

    do {
        let tracker = WordTracker()
        tracker.replaceTrackedTail(with: "\\|", reason: "Mac tail replacement test", russianLayoutType: .mac)
        try expect(tracker.getLastWord(), "\\|", "replaceTrackedTail keeps Mac backslash and pipe in last word")
        try expect(tracker.getTypedTail(), "\\|", "replaceTrackedTail keeps Mac backslash and pipe in typed tail")
    }

    do {
        let tracker = WordTracker()
        tracker.replaceTrackedTail(with: "\\|", reason: "Windows tail replacement compatibility test")
        try expectNil(tracker.getLastWord(), "replaceTrackedTail keeps Windows default boundary behavior")
        try expect(tracker.getTypedTail(), "\\|", "replaceTrackedTail preserves typed tail even when Windows word is cleared")
    }

    do {
        let tracker = WordTracker()
        type("ghbdtn/", into: tracker)
        try expect(tracker.getLastWord(), "ghbdtn/", "slash stays in wrong-layout word for period conversion")
        try expect(tracker.getTypedTail(), "ghbdtn/", "slash stays in typed tail for terminal conversion")
    }

    do {
        let tracker = WordTracker()
        type("ghbdtn?", into: tracker)
        try expect(tracker.getLastWord(), "ghbdtn?", "question mark stays in wrong-layout word for comma conversion")
        try expect(tracker.getTypedTail(), "ghbdtn?", "question mark stays in typed tail for terminal conversion")
    }

    do {
        let tracker = WordTracker()
        type("ghbdtn-", into: tracker)
        try expectNil(tracker.getLastWord(), "dash suffix completes wrong-layout word")
        try expect(
            tracker.consumeCompletedToken(),
            WordTracker.CompletedToken(word: "ghbdtn", separator: "-"),
            "dash suffix records completed token for auto-correction"
        )
        try expect(tracker.getTypedTail(), "ghbdtn-", "dash suffix remains in typed tail")
    }

    do {
        let tracker = WordTracker()
        type("git commit ghbdtn", into: tracker)
        tracker.replaceTrackedTail(with: "git commit привет", reason: "test")
        try expect(tracker.getLastWord(), "привет", "replaceTrackedTail keeps last word")
        try expectNil(tracker.getTypedTail(), "mixed command tail rejected")
    }

    do {
        let tracker = WordTracker()
        type("hello world", into: tracker)
        tracker.trackKeyPress(keyCode: 123, characters: nil)
        try expectNil(tracker.getLastWord(), "navigation clears word")
        try expectNil(tracker.getTypedTail(), "navigation clears tail")
    }

    do {
        let tracker = WordTracker()
        type("hello", into: tracker)
        tracker.trackKeyPress(keyCode: 53, characters: nil)
        try expectNil(tracker.getLastWord(), "escape clears word")
        try expectNil(tracker.getTypedTail(), "escape clears tail")
    }

    do {
        let tracker = WordTracker()
        type("helло", into: tracker)
        try expectNil(tracker.getLastWord(), "mixed word rejected")
        try expectNil(tracker.getTypedTail(), "mixed word clears tail")
    }

    do {
        let tracker = WordTracker(maxSize: 5)
        type("abcdefgh", into: tracker)
        try expect(tracker.getLastWord(), "defgh", "word ring buffer")
        try expect(tracker.getTypedTail(), "defgh", "tail ring buffer")
    }

    do {
        let tracker = WordTracker(maxSize: 5, maxTailSize: 12)
        type("abcdefghijklmnop", into: tracker)
        try expect(tracker.getLastWord(), "lmnop", "word ring buffer remains compact with larger tail")
        try expect(tracker.getTypedTail(), "efghijklmnop", "typed tail can retain longer terminal command context")
    }
}

private func runTextCapturePolicyTests() throws {
    try expect(
        KeyboardEventKeyCodePolicy.copyKeyCode,
        8,
        "keyboard event key code policy uses C key for copy"
    )
    try expect(
        ClipboardCapturePolicy.copyKeyCode,
        KeyboardEventKeyCodePolicy.copyKeyCode,
        "clipboard capture shares copy key code policy"
    )
    try expect(
        ClipboardCapturePolicy.keyUpDelay,
        0.01,
        "clipboard capture preserves copy key-up delay"
    )
    try expect(
        ClipboardCapturePolicy.pollInterval,
        0.02,
        "clipboard capture preserves polling interval"
    )
    try expect(
        ClipboardCapturePolicy.maxPollAttempts,
        10,
        "clipboard capture preserves max poll attempts"
    )
    try expect(
        ClipboardCapturePolicy.shouldAttemptHIDFallback(pollAttempt: 3, pasteboardChanged: false),
        true,
        "clipboard capture tries HID fallback on third unchanged poll"
    )
    try expect(
        ClipboardCapturePolicy.shouldAttemptHIDFallback(pollAttempt: 3, pasteboardChanged: true),
        false,
        "clipboard capture skips HID fallback after pasteboard change"
    )
    try expect(
        ClipboardCapturePolicy.shouldAttemptHIDFallback(pollAttempt: 2, pasteboardChanged: false),
        false,
        "clipboard capture waits before HID fallback"
    )
    try expect(
        ClipboardCapturePolicy.shouldStopPolling(pasteboardChanged: true),
        true,
        "clipboard capture stops polling after pasteboard change"
    )
    try expect(
        ClipboardCapturePolicy.shouldStopPolling(pasteboardChanged: false),
        false,
        "clipboard capture continues polling while pasteboard is unchanged"
    )
    try expect(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: "browser selection",
            pasteboardChanged: true,
            previousClipboardText: nil
        ),
        "browser selection",
        "clipboard capture accepts changed non-empty copied text"
    )
    try expect(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: "browser selection",
            pasteboardChanged: false,
            previousClipboardText: "browser selection"
        ),
        "browser selection",
        "clipboard capture accepts unchanged text when it matches previous clipboard"
    )
    try expectNil(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: "stale clipboard",
            pasteboardChanged: false,
            previousClipboardText: "different previous"
        ),
        "clipboard capture rejects unchanged stale clipboard mismatch"
    )
    try expectNil(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: " \n\t ",
            pasteboardChanged: true,
            previousClipboardText: nil
        ),
        "clipboard capture rejects whitespace-only copied text"
    )

    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "commit", lastTrackedTail: "git commit")?.originalTail,
        "git commit",
        "terminal rewrite accepts selected suffix inside tracked tail"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: " commit\n", lastTrackedTail: "git commit")?.selectedText,
        "commit",
        "terminal rewrite trims copied selection"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "user@host % git commit\n", lastTrackedTail: "git commit"),
        TextCapturePolicy.TailRewrite(selectedText: "git commit", originalTail: "git commit"),
        "terminal rewrite extracts typed tail from prompt-prefixed selection"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "Last login\nuser@host % git commit\n", lastTrackedTail: "git commit"),
        TextCapturePolicy.TailRewrite(selectedText: "git commit", originalTail: "git commit"),
        "terminal rewrite extracts typed tail from multiline prompt selection"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "Punto ➜ git commit\n", lastTrackedTail: "git commit"),
        TextCapturePolicy.TailRewrite(selectedText: "git commit", originalTail: "git commit"),
        "terminal rewrite extracts typed tail from zsh arrow prompt"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "➜  Punto git:(main) ✗ git commit\n", lastTrackedTail: "git commit"),
        TextCapturePolicy.TailRewrite(selectedText: "git commit", originalTail: "git commit"),
        "terminal rewrite extracts typed tail from dirty git zsh prompt"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "λ git commit\n", lastTrackedTail: "git commit"),
        TextCapturePolicy.TailRewrite(selectedText: "git commit", originalTail: "git commit"),
        "terminal rewrite extracts typed tail from lambda prompt"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "old > scrollback git commit", lastTrackedTail: "git commit"),
        "terminal rewrite rejects prompt marker that is not at prompt boundary"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "oldgit commit", lastTrackedTail: "git commit"),
        "terminal rewrite rejects glued prefix before tracked tail"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "old scrollback git commit", lastTrackedTail: "git commit"),
        "terminal rewrite rejects promptless scrollback before tracked tail"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "old scrollback\ngit commit", lastTrackedTail: "git commit"),
        "terminal rewrite rejects promptless multiline scrollback before tracked tail"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "old clipboard", lastTrackedTail: "git commit"),
        "terminal rewrite rejects unrelated selection"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "git", lastTrackedTail: "git commit"),
        "terminal rewrite rejects prefix-only selection"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "it com", lastTrackedTail: "git commit"),
        "terminal rewrite rejects middle selection"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "mit", lastTrackedTail: "git commit"),
        "terminal rewrite rejects partial-word suffix selection"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "make test&&ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "make test&&ghbdtn"),
        "terminal rewrite accepts suffix after shell and boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "make test||ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "make test||ghbdtn"),
        "terminal rewrite accepts suffix after shell or boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "make test;ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "make test;ghbdtn"),
        "terminal rewrite accepts suffix after shell semicolon boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "echo $(ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "echo $(ghbdtn"),
        "terminal rewrite accepts suffix after shell grouping boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "cat<ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "cat<ghbdtn"),
        "terminal rewrite accepts suffix after shell redirection boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "FOO=ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "FOO=ghbdtn"),
        "terminal rewrite accepts suffix after shell assignment boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "ghbdtn", lastTrackedTail: "--ghbdtn"),
        TextCapturePolicy.TailRewrite(selectedText: "ghbdtn", originalTail: "--ghbdtn"),
        "terminal rewrite accepts suffix after shell option boundary"
    )
    try expect(
        TextCapturePolicy.terminalTailRewrite(selectedText: "user@host % commit", lastTrackedTail: "commit"),
        TextCapturePolicy.TailRewrite(selectedText: "commit", originalTail: "commit"),
        "terminal rewrite accepts single-word AX command tail"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(selectedText: "git commit old prompt", lastTrackedTail: "git commit"),
        "terminal rewrite rejects non-current command tail selection"
    )

    try expect(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "git commit",
        "passive clipboard accepts exact typed tail"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects missing clipboard text"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "git commit",
            lastTrackedWord: nil,
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects missing tracked word"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: nil
        ),
        "passive clipboard rejects missing tracked tail"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "old clipboard",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects unrelated clipboard text"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "prompt % git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects prompt-prefixed garbage"
    )
    try expect(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "commit"
        ),
        "commit",
        "passive clipboard accepts exact single-word typed tail"
    )
    try expect(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "git commit\n",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "git commit",
        "passive clipboard trims trailing newline from exact typed tail"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "commit",
            lastTrackedWord: "push",
            lastTrackedTail: "commit"
        ),
        "passive clipboard rejects tail that does not end with tracked last word"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "old clipboard commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects stale clipboard ending with last word"
    )
    try expectNil(
        TextCapturePolicy.passiveClipboardTailSelection(
            clipboardText: "last command\ngit commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        "passive clipboard rejects multiline terminal garbage"
    )
    try expect(
        TextCapturePolicy.shouldAttemptActiveClipboardFallbackForNonSettableSelection(
            selectedText: "commit",
            lastTrackedTail: "git commit"
        ),
        false,
        "capture policy skips active clipboard copy when AX non-settable selection is already a safe tail"
    )
    try expect(
        TextCapturePolicy.shouldAttemptActiveClipboardFallbackForNonSettableSelection(
            selectedText: "user@host % git commit\n",
            lastTrackedTail: "git commit"
        ),
        false,
        "capture policy skips active clipboard copy for prompt-prefixed safe AX tail"
    )
    try expect(
        TextCapturePolicy.shouldAttemptActiveClipboardFallbackForNonSettableSelection(
            selectedText: "old scrollback",
            lastTrackedTail: "git commit"
        ),
        true,
        "capture policy attempts active clipboard copy after unsafe non-settable AX mismatch"
    )
    try expect(
        TextCapturePolicy.shouldAttemptActiveClipboardFallbackForNonSettableSelection(
            selectedText: "browser selection",
            lastTrackedTail: nil
        ),
        true,
        "capture policy attempts active clipboard copy when non-settable AX text has no tracked tail"
    )
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

    try expect(
        TextReplacementPolicy.rewriteTail("git commit ghbdtn", replacing: "ghbdtn", with: "привет"),
        "git commit привет",
        "rewrite tail replaces selected suffix"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("лол лол", replacing: "лол лол", with: "kjk kjk"),
        "kjk kjk",
        "rewrite tail replaces whole terminal tail"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("лол лол", replacing: "лол", with: "kjk"),
        "лол kjk",
        "rewrite tail replaces repeated selected suffix only"
    )
    try expectNil(
        TextReplacementPolicy.rewriteTail("abc def", replacing: "abc", with: "фис"),
        "rewrite tail rejects selected first word in tail"
    )
    try expectNil(
        TextReplacementPolicy.rewriteTail("abc def", replacing: "xyz", with: "чнп"),
        "rewrite tail rejects selection outside tail"
    )
    try expectNil(
        TextReplacementPolicy.rewriteTail("ghbdtn && echo done", replacing: "ghbdtn", with: "привет"),
        "rewrite tail rejects stale middle match"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterReplacement(
            capturedText: "ghbdtn",
            replacement: "привет",
            method: .keyboardRewriteTail(originalTail: "git commit ghbdtn")
        ),
        "git commit привет",
        "replacement policy computes rewritten tracked tail"
    )
    try expect(
        TextReplacementPolicy.recordedMethodAfterReplacement(
            capturedText: "ghbdtn",
            replacement: "привет",
            method: .keyboardRewriteTail(originalTail: "git commit ghbdtn")
        ),
        .keyboardRewriteTail(originalTail: "git commit привет"),
        "replacement policy records rewritten tail for undo"
    )
    try expect(
        TextReplacementPolicy.recordedMethodAfterReplacement(
            capturedText: "hello",
            replacement: "руддщ",
            method: .accessibilitySelection
        ),
        .accessibilitySelection,
        "replacement policy preserves accessibility method"
    )
    try expectNil(
        TextReplacementPolicy.recordedMethodAfterReplacement(
            capturedText: "missing",
            replacement: "привет",
            method: .keyboardRewriteTail(originalTail: "git commit ghbdtn")
        ),
        "replacement policy rejects unrewritable tail"
    )
    try expectNil(
        TextReplacementPolicy.recordedMethodAfterReplacement(
            capturedText: "ghbdtn",
            replacement: "привет",
            method: .keyboardRewriteTail(originalTail: "ghbdtn && echo done")
        ),
        "replacement policy rejects stale non-suffix tail"
    )
    try expect(
        TextReplacementPolicy.recordedMethodAfterUndo(
            convertedText: "привет",
            originalText: "ghbdtn",
            method: .keyboardRewriteTail(originalTail: "git commit привет")
        ),
        .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
        "replacement policy records full original tail after undo"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterUndo(
            convertedText: "привет",
            originalText: "ghbdtn",
            method: .keyboardRewriteTail(originalTail: "git commit привет")
        ),
        "git commit ghbdtn",
        "replacement policy computes full tracked tail after undo"
    )
    try expectNil(
        TextReplacementPolicy.recordedMethodAfterUndo(
            convertedText: "missing",
            originalText: "ghbdtn",
            method: .keyboardRewriteTail(originalTail: "git commit привет")
        ),
        "replacement policy rejects unrewritable undo tail"
    )
    try expectNil(
        TextReplacementPolicy.recordedMethodAfterUndo(
            convertedText: "привет",
            originalText: "ghbdtn",
            method: .keyboardRewriteTail(originalTail: "привет && echo done")
        ),
        "replacement policy rejects stale non-suffix undo tail"
    )
    try expect(
        TextReplacementPolicy.recordedMethodAfterUndo(
            convertedText: "руддщ",
            originalText: "hello",
            method: .keyboardBackspacePaste
        ),
        .keyboardBackspacePaste,
        "replacement policy preserves non-tail method after undo"
    )
    try expect(
        TextReplacementPolicy.shouldKeepSelectionAfterReplacement(method: .accessibilitySelection),
        true,
        "replacement policy keeps editable AX selection selected"
    )
    try expect(
        TextReplacementPolicy.shouldKeepSelectionAfterReplacement(method: .keyboardBackspacePaste),
        false,
        "replacement policy does not keep keyboard replacement selected"
    )
    try expect(
        TextReplacementPolicy.shouldKeepSelectionAfterReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        false,
        "replacement policy does not keep terminal tail replacement selected"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterLastWordReplacement(
            lastTrackedTail: "git commit ghbdtn",
            lastWord: "ghbdtn",
            replacement: "привет"
        ),
        "git commit привет",
        "last-word policy rewrites suffix in tracked tail"
    )
    try expectNil(
        TextReplacementPolicy.trackedTailAfterLastWordReplacement(
            lastTrackedTail: "otherghbdtn",
            lastWord: "ghbdtn",
            replacement: "привет"
        ),
        "last-word policy rejects glued suffix in tracked tail"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterLastWordReplacement(
            lastTrackedTail: "ghbdtn",
            lastWord: "ghbdtn",
            replacement: "привет"
        ),
        "привет",
        "last-word policy rewrites single-word tail"
    )
    try expectNil(
        TextReplacementPolicy.trackedTailAfterLastWordReplacement(
            lastTrackedTail: "git commit stale",
            lastWord: "ghbdtn",
            replacement: "привет"
        ),
        "last-word policy rejects stale tracked tail"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterRecentTextReplacement(
            lastTrackedTail: "git commit teh ",
            original: "teh ",
            replacement: "the "
        ),
        "git commit the ",
        "recent-text policy rewrites completed token suffix"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterRecentTextReplacement(
            lastTrackedTail: "otherteh ",
            original: "teh ",
            replacement: "the "
        ),
        "the ",
        "recent-text policy rejects glued completed token suffix"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterRecentTextReplacement(
            lastTrackedTail: nil,
            original: "ghbdtn ",
            replacement: "привет "
        ),
        "привет ",
        "recent-text policy falls back to replacement without tracked tail"
    )
    try expect(
        TextReplacementPolicy.trackedTailAfterRecentTextReplacement(
            lastTrackedTail: "git commit stale ",
            original: "ghbdtn ",
            replacement: "привет "
        ),
        "привет ",
        "recent-text policy discards stale tracked tail"
    )
    try expectNil(
        TextReplacementPolicy.rewriteTail("git commit", replacing: "mit", with: "ьше"),
        "rewrite tail rejects partial-word suffix replacement"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("make test&&ghbdtn", replacing: "ghbdtn", with: "привет"),
        "make test&&привет",
        "rewrite tail accepts suffix after shell and boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("make test||ghbdtn", replacing: "ghbdtn", with: "привет"),
        "make test||привет",
        "rewrite tail accepts suffix after shell or boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("make test;ghbdtn", replacing: "ghbdtn", with: "привет"),
        "make test;привет",
        "rewrite tail accepts suffix after shell semicolon boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("echo $(ghbdtn", replacing: "ghbdtn", with: "привет"),
        "echo $(привет",
        "rewrite tail accepts suffix after shell grouping boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("cat<ghbdtn", replacing: "ghbdtn", with: "привет"),
        "cat<привет",
        "rewrite tail accepts suffix after shell redirection boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("FOO=ghbdtn", replacing: "ghbdtn", with: "привет"),
        "FOO=привет",
        "rewrite tail accepts suffix after shell assignment boundary"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("--ghbdtn", replacing: "ghbdtn", with: "привет"),
        "--привет",
        "rewrite tail accepts suffix after shell option boundary"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("hello", replacementSupported: true),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: nil,
            lastTrackedTail: nil
        ),
        CapturedText(text: "hello", replacementMethod: .accessibilitySelection, source: "AX editable selection"),
        "capture policy accepts editable AX selection"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("commit", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "AX non-settable command-tail selection"),
        "capture policy rewrites non-settable AX command tail"
    )
    let terminalToggleCapture = try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("hello", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: "hello",
            lastTrackedTail: "git hello"
        ),
        CapturedText(text: "hello", replacementMethod: .keyboardRewriteTail(originalTail: "git hello"), source: "AX non-settable command-tail selection"),
        "capture policy supports terminal tail capture for toggle-case"
    )
    guard let terminalToggleCapture else {
        throw TestFailure(description: "capture policy supports terminal tail capture for toggle-case: expected non-nil capture")
    }
    try expect(
        TextReplacementPolicy.trackedTailAfterReplacement(
            capturedText: terminalToggleCapture.text,
            replacement: CaseConverter.toggleCase(terminalToggleCapture.text),
            method: terminalToggleCapture.replacementMethod
        ),
        "git HELLO",
        "capture policy updates terminal tail after toggle-case replacement"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("user@host % git commit\n", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "AX non-settable command-tail selection"),
        "capture policy extracts prompt-prefixed AX command tail"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("old scrollback", replacementSupported: false),
            activeClipboardText: "git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "clipboard command-tail selection"),
        "capture policy uses active clipboard command tail after non-settable AX mismatch"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("old scrollback", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardBackspacePaste, source: "passive clipboard tail selection"),
        "capture policy accepts passive clipboard command tail"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("old scrollback", replacementSupported: false),
            activeClipboardText: "prompt % old",
            passiveClipboardText: "prompt % old",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "", replacementMethod: .blocked, source: "unsafe non-settable selection"),
        "capture policy blocks unsafe non-settable fallback"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(
            CapturedText(text: "", replacementMethod: .blocked, source: "unsafe non-settable selection")
        ),
        true,
        "capture policy stops conversion after blocked capture"
    )
    try expect(
        TextCapturePolicy.actionAfterBlockedCapture(
            CapturedText(text: "", replacementMethod: .blocked, source: "unsafe non-settable selection")
        ),
        BlockedCaptureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "blocked unsafe text capture",
            clearConversionSessionReason: "blocked unsafe text capture"
        ),
        "capture policy clears stale state after blocked capture"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(
            CapturedText(text: "hello", replacementMethod: .accessibilitySelection, source: "AX editable selection")
        ),
        false,
        "capture policy continues after safe capture"
    )
    try expect(
        TextCapturePolicy.actionAfterBlockedCapture(
            CapturedText(text: "hello", replacementMethod: .accessibilitySelection, source: "AX editable selection")
        ),
        BlockedCaptureAction(clearTrackedText: false, clearConversionSession: false),
        "capture policy preserves state after safe capture"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(nil),
        false,
        "capture policy continues when nothing was captured"
    )
    try expect(
        TextCapturePolicy.actionAfterBlockedCapture(nil),
        BlockedCaptureAction(clearTrackedText: false, clearConversionSession: false),
        "capture policy preserves state when nothing was captured"
    )

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

    try expectNil(
        TextCapturePolicy.captureDecision(
            observation: .emptySelection,
            activeClipboardText: "ignored",
            passiveClipboardText: "ignored",
            lastTrackedWord: "ignored",
            lastTrackedTail: "ignored"
        ),
        "capture policy returns nil for empty AX selection"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "browser selection",
            passiveClipboardText: nil,
            lastTrackedWord: nil,
            lastTrackedTail: nil
        ),
        CapturedText(
            text: "browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy uses active clipboard for no-focus fallback"
    )
    try expectNil(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: " \n\t ",
            passiveClipboardText: nil,
            lastTrackedWord: nil,
            lastTrackedTail: nil
        ),
        "capture policy rejects whitespace-only no-focus active clipboard fallback"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "user@host % git commit\n",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "active clipboard command-tail selection"),
        "capture policy extracts prompt-prefixed command tail after no-focus active clipboard"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "old > scrollback git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "", replacementMethod: .blocked, source: "unsafe active clipboard terminal tail"),
        "capture policy blocks prompt-like scrollback before no-focus active clipboard fallback"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(
            TextCapturePolicy.captureDecision(
                observation: .noFocusedElement,
                activeClipboardText: "old > scrollback git commit",
                passiveClipboardText: nil,
                lastTrackedWord: "commit",
                lastTrackedTail: "git commit"
            )
        ),
        true,
        "capture policy stops after unsafe no-focus terminal clipboard"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(
            text: "git commit",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy keeps exact no-focus active clipboard as selected-text fallback"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "browser selection",
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(
            text: "browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy prefers fresh active clipboard selection over stale passive tail after AX failure"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: " \n\t ",
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardBackspacePaste, source: "passive clipboard tail selection"),
        "capture policy ignores whitespace-only active clipboard and uses valid passive tail after AX failure"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "user@host % git commit\n",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "active clipboard command-tail selection"),
        "capture policy extracts terminal command tail from active clipboard after AX failure"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(
            text: "git commit",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy keeps exact AX-failed active clipboard as selected-text fallback"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "old > scrollback git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "", replacementMethod: .blocked, source: "unsafe active clipboard terminal tail"),
        "capture policy blocks prompt-like scrollback after AX failure"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: nil,
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardBackspacePaste, source: "passive clipboard tail selection"),
        "capture policy uses passive command tail only when active clipboard is unavailable"
    )
}

private func runLayoutConversionReplacementPolicyTests() throws {
    let converter = LayoutConverter()

    try expect(
        LayoutConversionReplacementPolicy.replacement(
            for: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            conversionResult: converter.convertWithResult("hello")
        ),
        LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            convertedText: "руддщ",
            targetLayout: .russian,
            keepSelection: true,
            undoMethod: .accessibilitySelection,
            trackedTailAfterReplacement: nil
        ),
        "layout conversion policy plans AX selected-text replacement"
    )

    try expect(
        LayoutConversionReplacementPolicy.replacement(
            for: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                source: "AX non-settable command-tail selection"
            ),
            conversionResult: converter.convertWithResult("ghbdtn")
        ),
        LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                source: "AX non-settable command-tail selection"
            ),
            convertedText: "привет",
            targetLayout: .russian,
            keepSelection: false,
            undoMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
            trackedTailAfterReplacement: "git commit привет"
        ),
        "layout conversion policy plans terminal-tail replacement"
    )

    try expect(
        LayoutConversionReplacementPolicy.lastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "git commit ghbdtn"
        ),
        LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardBackspacePaste,
                source: "last word"
            ),
            convertedText: "привет",
            targetLayout: .russian,
            keepSelection: false,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: "git commit привет"
        ),
        "layout conversion policy plans last-word replacement and tail update"
    )

    try expect(
        LayoutConversionReplacementPolicy.lastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: nil
        ),
        LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardBackspacePaste,
                source: "last word"
            ),
            convertedText: "привет",
            targetLayout: .russian,
            keepSelection: false,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: nil
        ),
        "layout conversion policy permits last-word replacement without tracked tail"
    )

    try expectNil(
        LayoutConversionReplacementPolicy.lastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "git commit stale"
        ),
        "layout conversion policy rejects stale last-word tracked tail"
    )
    try expectNil(
        LayoutConversionReplacementPolicy.lastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "otherghbdtn"
        ),
        "layout conversion policy rejects glued last-word tracked tail"
    )
    try expect(
        LayoutConversionReplacementPolicy.shouldClearTrackedTextAfterSkippedLastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "git commit stale"
        ),
        true,
        "layout conversion policy clears tracker after stale last-word tail skip"
    )
    try expect(
        LayoutConversionReplacementPolicy.shouldClearTrackedTextAfterSkippedLastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "otherghbdtn"
        ),
        true,
        "layout conversion policy clears tracker after glued last-word tail skip"
    )
    try expect(
        LayoutConversionReplacementPolicy.shouldClearTrackedTextAfterSkippedLastWordReplacement(
            lastWord: "ghbdtn",
            conversionResult: converter.convertWithResult("ghbdtn"),
            lastTrackedTail: "git commit ghbdtn"
        ),
        false,
        "layout conversion policy keeps tracker when last-word tail is current"
    )
    try expect(
        LayoutConversionReplacementPolicy.shouldClearTrackedTextAfterSkippedLastWordReplacement(
            lastWord: "teстing",
            conversionResult: converter.convertWithResult("teстing"),
            lastTrackedTail: "teстing"
        ),
        false,
        "layout conversion policy keeps tracker after non-applicable mixed last word"
    )

    try expectNil(
        LayoutConversionReplacementPolicy.replacement(
            for: CapturedText(
                text: "missing",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                source: "stale terminal tail"
            ),
            conversionResult: converter.convertWithResult("missing")
        ),
        "layout conversion policy rejects unrewritable terminal-tail replacement"
    )

    try expectNil(
        LayoutConversionReplacementPolicy.lastWordReplacement(
            lastWord: "teстing",
            conversionResult: converter.convertWithResult("teстing"),
            lastTrackedTail: "teстing"
        ),
        "layout conversion policy rejects mixed last-word no-op"
    )
}

private func runManualLayoutConversionPolicyTests() throws {
    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            lastWord: "ghbdtn",
            lastTrackedTail: "git commit ghbdtn"
        ),
        .selectedText(LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            convertedText: "руддщ",
            targetLayout: .russian,
            keepSelection: true,
            undoMethod: .accessibilitySelection,
            trackedTailAfterReplacement: nil
        )),
        "manual layout conversion policy gives selected text priority over last word"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: CapturedText(
                text: "user@host % git commit\n",
                replacementMethod: .blocked,
                source: "unsafe non-settable selection"
            ),
            lastWord: "ghbdtn",
            lastTrackedTail: "git commit ghbdtn"
        ),
        .blockedCapture(CapturedText(
            text: "user@host % git commit\n",
            replacementMethod: .blocked,
            source: "unsafe non-settable selection"
        )),
        "manual layout conversion policy stops on blocked capture instead of falling back to last word"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                source: "AX non-settable command-tail selection"
            ),
            lastWord: "ignored",
            lastTrackedTail: "git commit ghbdtn"
        ),
        .selectedText(LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                source: "AX non-settable command-tail selection"
            ),
            convertedText: "привет",
            targetLayout: .russian,
            keepSelection: false,
            undoMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
            trackedTailAfterReplacement: "git commit привет"
        )),
        "manual layout conversion policy plans terminal-tail selected text conversion"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: nil,
            lastWord: "ghbdtn",
            lastTrackedTail: "git commit ghbdtn"
        ),
        .lastWord(LayoutConversionReplacement(
            capturedText: CapturedText(
                text: "ghbdtn",
                replacementMethod: .keyboardBackspacePaste,
                source: "last word"
            ),
            convertedText: "привет",
            targetLayout: .russian,
            keepSelection: false,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: "git commit привет"
        )),
        "manual layout conversion policy falls back to current last word"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: nil,
            lastWord: "ghbdtn",
            lastTrackedTail: "otherghbdtn"
        ),
        .clearTrackedTextAfterSkippedLastWord,
        "manual layout conversion policy reports stale glued last-word tail cleanup"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: nil,
            lastWord: "teстing",
            lastTrackedTail: "teстing"
        ),
        .skipped(reason: "last-word replacement unavailable"),
        "manual layout conversion policy skips mixed last-word no-op without cleanup"
    )

    try expect(
        ManualLayoutConversionPolicy.plan(
            capturedText: nil,
            lastWord: nil,
            lastTrackedTail: nil
        ),
        .noText,
        "manual layout conversion policy reports no text"
    )
}

private func runManualLayoutConversionRuntimePolicyTests() throws {
    let selectedReplacement = LayoutConversionReplacement(
        capturedText: CapturedText(
            text: "commit",
            replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
            source: "passive clipboard tail"
        ),
        convertedText: "сщььше",
        targetLayout: .russian,
        keepSelection: false,
        undoMethod: .keyboardRewriteTail(originalTail: "git сщььше"),
        trackedTailAfterReplacement: "git сщььше"
    )
    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .selectedText(selectedReplacement),
            suppressAutoCorrectionAfterManualConversion: true
        ),
        .replace(ManualLayoutReplacementRuntimePlan(
            replacement: selectedReplacement,
            captureTimingLabel: "getSelectedText",
            originalTextLogMessage: "Converting captured text (passive clipboard tail): 'commit'",
            convertedTextLogMessage: "Converted to: 'сщььше'",
            replacementTimingLabel: "setSelectedText",
            failedReplacementLogMessage: "Captured text replacement aborted",
            failedReplacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
            commitPlan: TextReplacementCommitPolicy.manualSelectedText(
                selectedReplacement,
                suppressAutoCorrectionAfterManualConversion: true
            )
        )),
        "manual conversion runtime plans selected-text replacement side effects"
    )

    let lastWordReplacement = LayoutConversionReplacement(
        capturedText: CapturedText(text: "ghbdtn", replacementMethod: .keyboardBackspacePaste, source: "last word"),
        convertedText: "привет",
        targetLayout: .russian,
        keepSelection: false,
        undoMethod: .keyboardBackspacePaste,
        trackedTailAfterReplacement: "git commit привет"
    )
    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .lastWord(lastWordReplacement),
            suppressAutoCorrectionAfterManualConversion: false
        ),
        .replace(ManualLayoutReplacementRuntimePlan(
            replacement: lastWordReplacement,
            captureTimingLabel: "getSelectedText (empty)",
            originalTextLogMessage: "Converting last word: 'ghbdtn'",
            convertedTextLogMessage: "Converted to: 'привет'",
            replacementTimingLabel: "replaceLastWord",
            failedReplacementLogMessage: "Last-word replacement aborted",
            failedReplacementMethod: .keyboardBackspacePaste,
            commitPlan: TextReplacementCommitPolicy.manualLastWord(
                lastWordReplacement,
                suppressAutoCorrectionAfterManualConversion: false
            )
        )),
        "manual conversion runtime plans last-word replacement side effects"
    )

    let blockedCapture = CapturedText(
        text: "user@host % git commit\n",
        replacementMethod: .blocked,
        source: "unsafe non-settable selection"
    )
    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .blockedCapture(blockedCapture),
            suppressAutoCorrectionAfterManualConversion: true
        ),
        .blockedCapture(
            capturedText: blockedCapture,
            logMessage: "Blocked unsafe selection fallback: unsafe non-settable selection"
        ),
        "manual conversion runtime preserves blocked capture for stale-state cleanup"
    )

    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .clearTrackedTextAfterSkippedLastWord,
            suppressAutoCorrectionAfterManualConversion: true
        ),
        .clearTrackedText(
            reason: "stale last-word tracked tail",
            logMessage: "Last-word conversion skipped: replacement plan could not be derived"
        ),
        "manual conversion runtime clears stale tracked tail after unsafe last-word plan"
    )

    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .skipped(reason: "captured text replacement unavailable"),
            suppressAutoCorrectionAfterManualConversion: true
        ),
        .skip(logMessage: "Layout conversion skipped: captured text replacement unavailable"),
        "manual conversion runtime reports skipped conversion reason"
    )

    try expect(
        ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: .noText,
            suppressAutoCorrectionAfterManualConversion: true
        ),
        .noText(logMessage: "No text to convert"),
        "manual conversion runtime reports no-text branch"
    )
}

private func runConversionSessionTests() throws {
    let session = ConversionSession(undoTimeout: 3)
    let now = Date(timeIntervalSince1970: 100)

    try expectNil(session.undoCandidate(now: now), "empty session has no undo")

    session.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor",
        origin: .autoCorrection(rule: AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"))
    )

    try expect(session.undoCandidate(now: now.addingTimeInterval(2), contextID: "com.example.editor")?.originalText, "ghbdtn", "undo available inside timeout")
    try expect(
        session.undoCandidate(now: now.addingTimeInterval(2), contextID: " COM.EXAMPLE.Editor ")?.originalText,
        "ghbdtn",
        "undo matches normalized app context id"
    )
    try expect(
        session.lastConversion?.contextID,
        "com.example.editor",
        "undo session stores normalized context id"
    )
    try expect(
        session.undoCandidate(now: now.addingTimeInterval(2), contextID: "com.example.editor")?.origin,
        .autoCorrection(rule: AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")),
        "undo preserves conversion origin"
    )
    try expectNil(session.undoCandidate(now: now.addingTimeInterval(2), contextID: "com.example.chat"), "undo rejected in different app context")
    try expect(session.lastConversion?.originalText, "ghbdtn", "context mismatch keeps undo session for original app")

    let futureSession = ConversionSession(undoTimeout: 3)
    futureSession.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(futureSession.undoCandidate(now: now.addingTimeInterval(-0.1), contextID: "com.example.editor"), "undo rejects future-dated conversion record")
    try expectNil(futureSession.lastConversion, "undo clears future-dated conversion record")

    let timeoutBoundarySession = ConversionSession(undoTimeout: 3)
    timeoutBoundarySession.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(timeoutBoundarySession.undoCandidate(now: now.addingTimeInterval(3), contextID: "com.example.editor"), "undo expires at exact timeout boundary")
    try expectNil(timeoutBoundarySession.lastConversion, "undo clears record at exact timeout boundary")

    let expiredSession = ConversionSession(undoTimeout: 3)
    expiredSession.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(expiredSession.undoCandidate(now: now.addingTimeInterval(3.1), contextID: "com.example.editor"), "undo expires after timeout")
    try expectNil(expiredSession.lastConversion, "undo clears expired conversion record")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: " "
    )
    try expectNil(session.lastConversion?.contextID, "undo session normalizes blank context id to nil")
    try expect(
        session.undoCandidate(now: now.addingTimeInterval(1), contextID: nil)?.originalText,
        "hello",
        "undo matches nil context after blank normalization"
    )

    session.clear(reason: "test")
    try expectNil(session.undoCandidate(now: now), "clear removes undo")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "same",
        convertedText: "same",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects no-op conversion records")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects empty original records")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "hello",
        convertedText: "",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects empty converted records")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "unsafe",
        convertedText: "blocked",
        replacementMethod: .blocked,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects blocked replacement records")

    let commitSession = ConversionSession(undoTimeout: 3)
    commitSession.record(
        ConversionRecordCommit(
            originalText: "hello",
            convertedText: "руддщ",
            replacementMethod: .keyboardBackspacePaste,
            origin: .layoutConversion
        ),
        now: now,
        contextID: "com.example.editor"
    )
    try expect(
        commitSession.undoCandidate(now: now.addingTimeInterval(1), contextID: "com.example.editor")?.convertedText,
        "руддщ",
        "undo session records conversion commit payloads"
    )
    try expect(
        commitSession.undoCandidate(now: now.addingTimeInterval(1), contextID: "com.example.editor")?.origin,
        .layoutConversion,
        "undo session preserves commit payload origin"
    )
}

private func runUndoReplacementPolicyTests() throws {
    let now = Date(timeIntervalSince1970: 100)

    try expect(
        UndoReplacementPolicy.replacement(
            for: ConversionRecord(
                originalText: "hello",
                convertedText: "руддщ",
                timestamp: now,
                replacementMethod: .accessibilitySelection,
                contextID: "com.example.editor"
            )
        ),
        UndoReplacement(
            capturedText: CapturedText(text: "руддщ", replacementMethod: .accessibilitySelection, source: "undo"),
            replacementText: "hello",
            keepSelection: true,
            nextReplacementMethod: .accessibilitySelection,
            trackedTailAfterUndo: nil
        ),
        "undo policy plans AX selected-text undo with selection retained"
    )

    try expect(
        UndoReplacementPolicy.replacement(
            for: ConversionRecord(
                originalText: "ghbdtn",
                convertedText: "привет",
                timestamp: now,
                replacementMethod: .keyboardBackspacePaste,
                contextID: "com.example.editor"
            )
        ),
        UndoReplacement(
            capturedText: CapturedText(text: "привет", replacementMethod: .keyboardBackspacePaste, source: "undo"),
            replacementText: "ghbdtn",
            keepSelection: false,
            nextReplacementMethod: .keyboardBackspacePaste,
            trackedTailAfterUndo: nil
        ),
        "undo policy plans keyboard replacement undo"
    )

    try expect(
        UndoReplacementPolicy.replacement(
            for: ConversionRecord(
                originalText: "ghbdtn",
                convertedText: "привет",
                timestamp: now,
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
                contextID: "com.example.terminal"
            )
        ),
        UndoReplacement(
            capturedText: CapturedText(text: "привет", replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"), source: "undo"),
            replacementText: "ghbdtn",
            keepSelection: false,
            nextReplacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
            trackedTailAfterUndo: "git commit ghbdtn"
        ),
        "undo policy plans terminal-tail undo and next redo method"
    )

    try expectNil(
        UndoReplacementPolicy.replacement(
            for: ConversionRecord(
                originalText: "ghbdtn",
                convertedText: "missing",
                timestamp: now,
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
                contextID: "com.example.terminal"
            )
        ),
        "undo policy rejects unrewritable terminal-tail undo"
    )
    try expect(
        UndoReplacementPolicy.shouldClearSessionAfterFailedReplacement(),
        true,
        "undo policy clears stale undo session after failed replacement"
    )
    try expect(
        UndoReplacementPolicy.actionAfterFailedReplacement(method: .keyboardBackspacePaste),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "undo replacement failed",
            clearConversionSessionReason: "undo replacement failed"
        ),
        "undo policy clears tracked text and session after failed keyboard undo"
    )
    try expect(
        UndoReplacementPolicy.actionAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit привет")),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "undo replacement failed",
            clearConversionSessionReason: "undo replacement failed"
        ),
        "undo policy clears tracked text and session after failed terminal-tail undo"
    )
    try expect(
        UndoReplacementPolicy.actionAfterFailedReplacement(method: .accessibilitySelection),
        ReplacementFailureAction(clearTrackedText: false, clearConversionSession: false),
        "undo policy keeps tracked text and session after failed AX undo"
    )
    try expect(
        UndoReplacementPolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardBackspacePaste),
        true,
        "undo policy clears tracked text after failed keyboard undo"
    )
    try expect(
        UndoReplacementPolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit привет")),
        true,
        "undo policy clears tracked text after failed terminal-tail undo"
    )
    try expect(
        UndoReplacementPolicy.shouldClearTrackedTextAfterFailedReplacement(method: .accessibilitySelection),
        false,
        "undo policy keeps tracked text after failed AX undo"
    )

    try expect(
        UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(origin: .layoutConversion),
        true,
        "undo layout policy switches after layout conversion undo"
    )
    try expect(
        UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(origin: .manualRedo),
        true,
        "undo layout policy switches after manual redo"
    )
    try expect(
        UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(origin: .toggleCase),
        false,
        "undo layout policy skips toggle-case undo"
    )
    try expect(
        UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(
            origin: .autoCorrection(rule: AutoCorrectionRule(trigger: "teh", replacement: "the"))
        ),
        false,
        "undo layout policy skips auto-correction undo"
    )
    try expect(
        UndoLayoutSwitchPolicy.shouldSwitchLayoutAfterUndo(
            origin: .autoCorrectionRedo(rule: AutoCorrectionRule(trigger: "teh", replacement: "the"))
        ),
        false,
        "undo layout policy skips auto-correction redo"
    )
}

private func runUndoRuntimePolicyTests() throws {
    let now = Date(timeIntervalSince1970: 100)
    let layoutRecord = ConversionRecord(
        originalText: "ghbdtn",
        convertedText: "привет",
        timestamp: now,
        replacementMethod: .keyboardBackspacePaste,
        contextID: "com.example.editor",
        origin: .layoutConversion
    )

    try expect(
        UndoRuntimePolicy.plan(
            record: nil,
            autoCorrectionRules: [],
            isUndoLearningEnabled: true
        ),
        .noCandidate,
        "undo runtime reports missing candidate"
    )

    try expect(
        UndoRuntimePolicy.plan(
            record: layoutRecord,
            autoCorrectionRules: [],
            isUndoLearningEnabled: true
        ),
        .replacement(UndoRuntimeReplacement(
            record: layoutRecord,
            undoReplacement: UndoReplacement(
                capturedText: CapturedText(text: "привет", replacementMethod: .keyboardBackspacePaste, source: "undo"),
                replacementText: "ghbdtn",
                keepSelection: false,
                nextReplacementMethod: .keyboardBackspacePaste,
                trackedTailAfterUndo: nil
            ),
            shouldSwitchLayoutAfterUndo: true,
            redoOrigin: .manualRedo,
            learnedAutoCorrectionRules: nil
        )),
        "undo runtime plans layout undo with layout switch and manual redo origin"
    )
    try expect(
        UndoRuntimePolicy.planFailureAction(record: layoutRecord),
        UndoPlanFailureAction(
            clearConversionSession: true,
            clearConversionSessionReason: "undo plan derivation failed",
            logMessage: "Undo aborted: replacement plan could not be derived"
        ),
        "undo runtime owns plan-failure cleanup and log action"
    )
    if case .replacement(let layoutUndoPlan) = UndoRuntimePolicy.plan(
        record: layoutRecord,
        autoCorrectionRules: [],
        isUndoLearningEnabled: true
    ) {
        let commitPlan = UndoRuntimePolicy.appliedCommitPlan(for: layoutUndoPlan)
        try expect(commitPlan.layoutSwitchTarget, .english, "undo commit plan switches back to original text layout")
        try expectNil(commitPlan.skippedLayoutSwitchLogMessage, "undo commit plan has no skip log when layout switch is planned")
        try expect(commitPlan.soundFeedbackEvent, .undo, "undo commit plan plays undo sound")
        try expect(commitPlan.productStatisticsEvent, .revert, "undo commit plan records revert statistics")
        try expectNil(commitPlan.trackedTailCommit, "undo commit plan has no tail replay for ordinary keyboard replacement")
        try expectNil(commitPlan.learnedAutoCorrectionRules, "undo commit plan has no learned rules for manual layout undo")
        try expect(
            commitPlan.conversionRecordCommit,
            ConversionRecordCommit(
                originalText: "привет",
                convertedText: "ghbdtn",
                replacementMethod: .keyboardBackspacePaste,
                origin: .manualRedo
            ),
            "undo commit plan records manual redo candidate after layout undo"
        )
    } else {
        throw TestFailure(description: "undo runtime commit plan for layout undo: expected replacement plan")
    }

    let terminalRecord = ConversionRecord(
        originalText: "ghbdtn",
        convertedText: "привет",
        timestamp: now,
        replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
        contextID: "com.example.terminal",
        origin: .manualRedo
    )
    try expect(
        UndoRuntimePolicy.plan(
            record: terminalRecord,
            autoCorrectionRules: [],
            isUndoLearningEnabled: true
        ),
        .replacement(UndoRuntimeReplacement(
            record: terminalRecord,
            undoReplacement: UndoReplacement(
                capturedText: CapturedText(
                    text: "привет",
                    replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
                    source: "undo"
                ),
                replacementText: "ghbdtn",
                keepSelection: false,
                nextReplacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                trackedTailAfterUndo: "git commit ghbdtn"
            ),
            shouldSwitchLayoutAfterUndo: true,
            redoOrigin: .layoutConversion,
            learnedAutoCorrectionRules: nil
        )),
        "undo runtime plans terminal-tail undo with rewritten redo tail"
    )
    if case .replacement(let terminalUndoPlan) = UndoRuntimePolicy.plan(
        record: terminalRecord,
        autoCorrectionRules: [],
        isUndoLearningEnabled: true
    ) {
        let commitPlan = UndoRuntimePolicy.appliedCommitPlan(for: terminalUndoPlan)
        try expect(commitPlan.layoutSwitchTarget, .english, "terminal undo commit plan switches back to original text layout")
        try expect(
            commitPlan.trackedTailCommit,
            TrackedTailCommit(text: "git commit ghbdtn", reason: "undo completed"),
            "terminal undo commit plan replays rewritten command tail"
        )
        try expect(
            commitPlan.conversionRecordCommit,
            ConversionRecordCommit(
                originalText: "привет",
                convertedText: "ghbdtn",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit ghbdtn"),
                origin: .layoutConversion
            ),
            "terminal undo commit plan records tail-aware redo candidate"
        )
    } else {
        throw TestFailure(description: "undo runtime commit plan for terminal undo: expected replacement plan")
    }

    let badTailRecord = ConversionRecord(
        originalText: "ghbdtn",
        convertedText: "missing",
        timestamp: now,
        replacementMethod: .keyboardRewriteTail(originalTail: "git commit привет"),
        contextID: "com.example.terminal",
        origin: .layoutConversion
    )
    try expect(
        UndoRuntimePolicy.plan(
            record: badTailRecord,
            autoCorrectionRules: [],
            isUndoLearningEnabled: true
        ),
        .planFailure(record: badTailRecord),
        "undo runtime reports replacement plan failure"
    )

    let undoneRule = AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive)
    let otherRule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let autoCorrectionRecord = ConversionRecord(
        originalText: "teh ",
        convertedText: "the ",
        timestamp: now,
        replacementMethod: .keyboardBackspacePaste,
        contextID: "com.example.editor",
        origin: .autoCorrection(rule: undoneRule)
    )
    try expect(
        UndoRuntimePolicy.plan(
            record: autoCorrectionRecord,
            autoCorrectionRules: [undoneRule, otherRule],
            isUndoLearningEnabled: true
        ),
        .replacement(UndoRuntimeReplacement(
            record: autoCorrectionRecord,
            undoReplacement: UndoReplacement(
                capturedText: CapturedText(text: "the ", replacementMethod: .keyboardBackspacePaste, source: "undo"),
                replacementText: "teh ",
                keepSelection: false,
                nextReplacementMethod: .keyboardBackspacePaste,
                trackedTailAfterUndo: nil
            ),
            shouldSwitchLayoutAfterUndo: false,
            redoOrigin: .autoCorrectionRedo(rule: undoneRule),
            learnedAutoCorrectionRules: [otherRule]
        )),
        "undo runtime plans auto-correction undo learning and redo origin"
    )
    if case .replacement(let autoCorrectionUndoPlan) = UndoRuntimePolicy.plan(
        record: autoCorrectionRecord,
        autoCorrectionRules: [undoneRule, otherRule],
        isUndoLearningEnabled: true
    ) {
        let commitPlan = UndoRuntimePolicy.appliedCommitPlan(for: autoCorrectionUndoPlan)
        try expectNil(commitPlan.layoutSwitchTarget, "auto-correction undo commit plan skips layout switching")
        try expect(
            commitPlan.skippedLayoutSwitchLogMessage?.hasPrefix("Undo: skipped layout switch for origin autoCorrection"),
            true,
            "auto-correction undo commit plan preserves skipped layout-switch log"
        )
        try expect(commitPlan.learnedAutoCorrectionRules, [otherRule], "auto-correction undo commit plan learns by removing undone rule")
        try expect(
            commitPlan.learnedRuleLogMessage,
            "Auto-correction undo learned exception for 'teh'",
            "auto-correction undo commit plan trims learned-rule log text"
        )
        try expect(
            commitPlan.conversionRecordCommit,
            ConversionRecordCommit(
                originalText: "the ",
                convertedText: "teh ",
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrectionRedo(rule: undoneRule)
            ),
            "auto-correction undo commit plan records auto-correction redo origin"
        )
    } else {
        throw TestFailure(description: "undo runtime commit plan for auto-correction undo: expected replacement plan")
    }

    if case .replacement(let disabledLearningPlan) = UndoRuntimePolicy.plan(
        record: autoCorrectionRecord,
        autoCorrectionRules: [undoneRule, otherRule],
        isUndoLearningEnabled: false
    ) {
        try expectNil(
            disabledLearningPlan.learnedAutoCorrectionRules,
            "undo runtime keeps rules when undo learning is disabled"
        )
    } else {
        throw TestFailure(description: "undo runtime keeps rules when undo learning is disabled: expected replacement plan")
    }

    let repeatSession = ConversionSession(undoTimeout: 3)
    let repeatContextID = "com.example.editor"
    var currentText = "руддщ"
    var currentTime = now
    repeatSession.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: currentTime,
        contextID: repeatContextID,
        origin: .layoutConversion
    )

    for index in 0..<10 {
        currentTime = currentTime.addingTimeInterval(0.2)
        guard let record = repeatSession.undoCandidate(now: currentTime, contextID: repeatContextID) else {
            throw TestFailure(description: "repeat undo/redo scenario step \(index): expected undo candidate")
        }
        try expect(
            record.convertedText,
            currentText,
            "repeat undo/redo scenario step \(index) targets current text"
        )

        guard case .replacement(let repeatPlan) = UndoRuntimePolicy.plan(
            record: record,
            autoCorrectionRules: [],
            isUndoLearningEnabled: false
        ) else {
            throw TestFailure(description: "repeat undo/redo scenario step \(index): expected replacement plan")
        }

        let commitPlan = UndoRuntimePolicy.appliedCommitPlan(for: repeatPlan)
        currentText = commitPlan.conversionRecordCommit.convertedText
        repeatSession.record(commitPlan.conversionRecordCommit, now: currentTime, contextID: repeatContextID)
    }

    try expect(currentText, "руддщ", "repeat undo/redo scenario returns to original visible text after even presses")
    try expect(
        repeatSession.undoCandidate(now: currentTime.addingTimeInterval(0.1), contextID: repeatContextID)?.originalText,
        "hello",
        "repeat undo/redo scenario leaves next undo original ready"
    )
    try expect(
        repeatSession.undoCandidate(now: currentTime.addingTimeInterval(0.1), contextID: repeatContextID)?.convertedText,
        "руддщ",
        "repeat undo/redo scenario leaves next undo converted ready"
    )
    try expect(
        repeatSession.undoCandidate(now: currentTime.addingTimeInterval(0.1), contextID: repeatContextID)?.origin,
        .layoutConversion,
        "repeat undo/redo scenario restores layout-conversion origin after even presses"
    )
}

private func runTextReplacementCommitPolicyTests() throws {
    let selectedReplacement = LayoutConversionReplacement(
        capturedText: CapturedText(
            text: "commit",
            replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
            source: "passive clipboard tail"
        ),
        convertedText: "сщььше",
        targetLayout: .russian,
        keepSelection: false,
        undoMethod: .keyboardRewriteTail(originalTail: "git сщььше"),
        trackedTailAfterReplacement: "git сщььше"
    )
    try expect(
        TextReplacementCommitPolicy.manualSelectedText(
            selectedReplacement,
            suppressAutoCorrectionAfterManualConversion: true
        ),
        TextReplacementCommitPlan(
            trackedTailCommit: TrackedTailCommit(
                text: "git сщььше",
                reason: "terminal selection conversion completed",
                suppressAutoCorrectionForCurrentToken: true
            ),
            layoutSwitchCommit: LayoutSwitchCommit(targetLayout: .russian, surface: .selectedText),
            soundFeedbackEvent: .layoutConversion,
            productStatisticsEvent: .manualSwitch,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: "commit",
                convertedText: "сщььше",
                replacementMethod: .keyboardRewriteTail(originalTail: "git сщььше"),
                origin: .layoutConversion
            )
        ),
        "commit policy describes manual selected terminal conversion side effects"
    )

    let lastWordReplacement = LayoutConversionReplacement(
        capturedText: CapturedText(text: "ghbdtn", replacementMethod: .keyboardBackspacePaste, source: "last word"),
        convertedText: "привет",
        targetLayout: .russian,
        keepSelection: false,
        undoMethod: .keyboardBackspacePaste,
        trackedTailAfterReplacement: "привет"
    )
    try expect(
        TextReplacementCommitPolicy.manualLastWord(
            lastWordReplacement,
            suppressAutoCorrectionAfterManualConversion: false
        ),
        TextReplacementCommitPlan(
            clearTrackedTextBeforeTailCommit: true,
            trackedTailCommit: TrackedTailCommit(text: "привет", reason: "last-word conversion completed"),
            layoutSwitchCommit: LayoutSwitchCommit(targetLayout: .russian, surface: .lastWord),
            soundFeedbackEvent: .layoutConversion,
            productStatisticsEvent: .manualSwitch,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: "ghbdtn",
                convertedText: "привет",
                replacementMethod: .keyboardBackspacePaste,
                origin: .layoutConversion
            )
        ),
        "commit policy describes manual last-word conversion side effects"
    )

    let toggleReplacement = ToggleCaseReplacement(
        originalText: "Hello",
        toggledText: "hELLO",
        undoMethod: .accessibilitySelection,
        trackedTailAfterReplacement: nil
    )
    try expect(
        TextReplacementCommitPolicy.toggleCase(toggleReplacement),
        TextReplacementCommitPlan(
            trackedTailCommit: nil,
            layoutSwitchCommit: nil,
            soundFeedbackEvent: .toggleCase,
            productStatisticsEvent: nil,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: "Hello",
                convertedText: "hELLO",
                replacementMethod: .accessibilitySelection,
                origin: .toggleCase
            )
        ),
        "commit policy describes toggle-case side effects without layout/stat switch"
    )

    let rule = AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive)
    let decision = AutoCorrectionDecision(original: "Teh", replacement: "The", rule: rule)
    let autoReplacement = AutoCorrectionReplacement(
        originalText: "Teh ",
        replacementText: "The ",
        replacementLength: 4,
        undoMethod: .keyboardBackspacePaste,
        trackedTailAfterReplacement: "The "
    )
    try expect(
        TextReplacementCommitPolicy.autoCorrection(decision: decision, replacement: autoReplacement),
        TextReplacementCommitPlan(
            trackedTailCommit: TrackedTailCommit(text: "The ", reason: "auto-correction completed"),
            layoutSwitchCommit: nil,
            soundFeedbackEvent: .autoCorrection,
            productStatisticsEvent: .automaticSwitch,
            conversionRecordCommit: ConversionRecordCommit(
                originalText: "Teh ",
                convertedText: "The ",
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: rule)
            )
        ),
        "commit policy describes auto-correction side effects"
    )
}

private func runConversionOriginPolicyTests() throws {
    let rule = AutoCorrectionRule(trigger: "teh", replacement: "the")

    try expect(
        ConversionOriginPolicy.originAfterUndo(.layoutConversion),
        .manualRedo,
        "conversion origin policy records manual redo after layout conversion undo"
    )
    try expect(
        ConversionOriginPolicy.originAfterUndo(.manualRedo),
        .layoutConversion,
        "conversion origin policy alternates manual redo back to layout conversion"
    )
    try expect(
        ConversionOriginPolicy.originAfterUndo(.toggleCase),
        .toggleCase,
        "conversion origin policy preserves toggle-case undo chain"
    )
    try expect(
        ConversionOriginPolicy.originAfterUndo(.autoCorrection(rule: rule)),
        .autoCorrectionRedo(rule: rule),
        "conversion origin policy records auto-correction redo after undo"
    )
    try expect(
        ConversionOriginPolicy.originAfterUndo(.autoCorrectionRedo(rule: rule)),
        .autoCorrectionRedo(rule: rule),
        "conversion origin policy keeps auto-correction redo non-learning"
    )
    try expect(
        ConversionOriginPolicy.originAfterUndo(record: ConversionRecord(
            originalText: "hello",
            convertedText: "руддщ",
            timestamp: Date(timeIntervalSince1970: 100),
            replacementMethod: .keyboardBackspacePaste,
            origin: .layoutConversion
        )),
        .manualRedo,
        "conversion origin policy reads origin from conversion record"
    )
}

private func runApplicationLayoutMemoryTests() throws {
    let memory = ApplicationLayoutMemory()

    try expectNil(memory.layoutID(for: "com.example.editor"), "empty layout memory")

    memory.remember(bundleID: "com.example.editor", layoutID: "com.apple.keylayout.ABC")
    try expect(
        memory.layoutID(for: "com.example.editor"),
        "com.apple.keylayout.ABC",
        "layout memory stores bundle layout"
    )

    memory.remember(bundleID: "com.example.terminal", layoutID: "com.apple.keylayout.Russian")
    try expect(
        memory.snapshot().count,
        2,
        "layout memory snapshot includes remembered apps"
    )

    memory.forget(bundleID: "com.example.editor")
    try expectNil(memory.layoutID(for: "com.example.editor"), "layout memory forgets app")

    memory.remember(bundleID: "", layoutID: "ignored")
    memory.remember(bundleID: "com.example.empty", layoutID: "")
    try expectNil(memory.layoutID(for: "com.example.empty"), "layout memory ignores empty ids")

    memory.remember(bundleID: "  COM.Example.Editor  ", layoutID: "  com.apple.keylayout.Russian  ")
    try expect(
        memory.layoutID(for: "com.example.editor"),
        "com.apple.keylayout.Russian",
        "layout memory normalizes bundle id case and whitespace on remember"
    )
    try expect(
        memory.snapshot()["com.example.editor"],
        "com.apple.keylayout.Russian",
        "layout memory snapshot stores normalized ids"
    )

    memory.replaceAll(with: [
        " COM.Example.Terminal ": " com.apple.keylayout.ABC ",
        "": "ignored",
        "com.example.empty": " "
    ])
    try expect(
        memory.layoutID(for: "com.example.terminal"),
        "com.apple.keylayout.ABC",
        "layout memory normalizes restored settings snapshot"
    )
    try expectNil(
        memory.layoutID(for: "com.example.empty"),
        "layout memory drops empty restored layout ids"
    )
}

private func runApplicationBundleIDPolicyTests() throws {
    try expect(
        ApplicationBundleIDPolicy.normalized("  COM.Example.Editor  "),
        "com.example.editor",
        "application bundle id policy trims and lowercases ids"
    )
    try expectNil(
        ApplicationBundleIDPolicy.normalized("   "),
        "application bundle id policy rejects blank ids"
    )
    try expectNil(
        ApplicationBundleIDPolicy.normalized(nil),
        "application bundle id policy rejects missing ids"
    )
    try expect(
        ApplicationBundleIDPolicy.normalizedSet([" COM.Example.Editor ", "", "com.example.Terminal"]),
        ["com.example.editor", "com.example.terminal"],
        "application bundle id policy normalizes persisted sets"
    )
    try expect(
        ApplicationBundleIDPolicy.isObservedScreenSaverEngine(" COM.Apple.ScreenSaver.Engine "),
        true,
        "application bundle id policy recognizes observed Punto Switcher screen saver engine bundle id"
    )
    try expect(
        ApplicationBundleIDPolicy.isVolatileSystemContext("com.apple.ScreenSaver.Engine"),
        true,
        "application bundle id policy treats screen saver engine as volatile system context"
    )
    try expect(
        ApplicationBundleIDPolicy.isVolatileSystemContext("com.example.editor"),
        false,
        "application bundle id policy keeps ordinary apps non-volatile"
    )
    try expect(
        ApplicationDisablePolicy.normalizedSet([" COM.Example.Editor ", "", "com.example.Terminal"]),
        ApplicationBundleIDPolicy.normalizedSet([" COM.Example.Editor ", "", "com.example.Terminal"]),
        "application disable policy shares bundle id normalization"
    )
    try expect(
        AccessibilityApplicationPolicy.isObservedBrowserInjectionBundleID(" COM.Apple.Safari "),
        true,
        "accessibility app policy shares bundle id normalization"
    )

    let session = ConversionSession()
    session.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        contextID: " COM.Example.Editor "
    )
    try expect(
        session.lastConversion?.contextID,
        "com.example.editor",
        "conversion session shares bundle id normalization when recording context"
    )
    try expect(
        session.undoCandidate(contextID: "com.example.editor") != nil,
        true,
        "conversion session shares bundle id normalization when matching context"
    )
}

private func runApplicationLayoutPolicyTests() throws {
    try expect(
        ApplicationLayoutPolicy.shouldRecordCurrentLayoutOnApplicationActivation(
            rememberInputSourceForEachApp: false
        ),
        false,
        "layout policy does not record app activation when memory disabled"
    )
    try expect(
        ApplicationLayoutPolicy.shouldRecordCurrentLayoutOnApplicationActivation(
            rememberInputSourceForEachApp: true
        ),
        false,
        "layout policy does not record new frontmost layout under previous app"
    )
    try expect(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        "com.example.editor",
        "layout policy restores remembered layout for external app"
    )
    try expect(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto"
        ),
        "com.example.editor",
        "layout policy normalizes restore bundle id"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto"
        ),
        "layout policy skips restore when Punto window activates"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            isApplicationDisabled: true
        ),
        "layout policy skips restore for disabled application"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: " COM.EXAMPLE.PUNTO ",
            ownBundleID: "com.example.punto"
        ),
        "layout policy normalizes own app id before restore decision"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: nil,
            ownBundleID: "com.example.punto"
        ),
        "layout policy skips restore without active bundle id"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.apple.ScreenSaver.Engine",
            ownBundleID: "com.example.punto"
        ),
        "layout policy skips restore for observed screen saver engine"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: "com.apple.keylayout.Russian",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .switchTo(layoutID: "com.apple.keylayout.Russian"),
        "layout policy switches to remembered layout when current layout differs"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: " com.apple.keylayout.Russian ",
            currentLayoutID: "com.apple.keylayout.Russian"
        ),
        .alreadyActive(layoutID: "com.apple.keylayout.Russian"),
        "layout policy skips TIS restore when remembered layout is already active"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: " com.apple.keylayout.Russian ",
            currentLayoutID: " com.apple.keylayout.Russian "
        ),
        .alreadyActive(layoutID: "com.apple.keylayout.Russian"),
        "layout policy normalizes layout ids before already-active restore decision"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            isApplicationDisabled: true,
            rememberedLayoutID: "com.apple.keylayout.Russian",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .skip,
        "layout policy skips restore action for disabled application"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: "com.apple.keylayout.Russian",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .skip,
        "layout policy skips restore action for Punto app"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: " ",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .skip,
        "layout policy skips restore action without remembered layout"
    )

    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        )?.layoutID,
        "com.apple.keylayout.Russian",
        "layout policy records successful programmatic switch for active app"
    )
    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            targetLayoutID: " com.apple.keylayout.Russian ",
            didSwitch: true
        )?.bundleID,
        "com.example.editor",
        "layout policy normalizes programmatic switch bundle id"
    )
    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            targetLayoutID: " com.apple.keylayout.Russian ",
            didSwitch: true
        )?.layoutID,
        "com.apple.keylayout.Russian",
        "layout policy normalizes programmatic switch layout id"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: false,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy skips programmatic switch memory when disabled"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: false
        ),
        "layout policy skips failed programmatic switch memory"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy skips programmatic switch memory for Punto app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.apple.ScreenSaver.Engine",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy skips programmatic switch memory for observed screen saver engine"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.EXAMPLE.PUNTO ",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy normalizes own app id before programmatic switch memory"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: " ",
            didSwitch: true
        ),
        "layout policy skips blank target layout id"
    )

    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        )?.layoutID,
        "com.apple.keylayout.US",
        "layout policy records observed input-source change for active external app"
    )
    let observedNormalizedUpdate = ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
        rememberInputSourceForEachApp: true,
        activeBundleID: " COM.Example.Editor ",
        frontmostBundleID: " COM.Example.Editor ",
        ownBundleID: "com.example.punto",
        currentLayoutID: " com.apple.keylayout.Russian "
    )
    try expect(
        observedNormalizedUpdate?.bundleID,
        "com.example.editor",
        "layout policy normalizes observed input-source bundle id"
    )
    try expect(
        observedNormalizedUpdate?.layoutID,
        "com.apple.keylayout.Russian",
        "layout policy normalizes observed input-source layout id"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy does not write Punto settings-window layout under last external app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.browser",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy does not write a frontmost app layout under a stale active app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.Example.Editor ",
            frontmostBundleID: " com.example.browser ",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy normalizes before rejecting active/frontmost mismatch"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: nil,
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory without known frontmost app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.punto",
            frontmostBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory for Punto app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.apple.ScreenSaver.Engine",
            frontmostBundleID: "com.apple.ScreenSaver.Engine",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory for observed screen saver engine"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: false,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory when disabled"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            currentLayoutID: " "
        ),
        "layout policy skips observed input-source memory without layout id"
    )
}

private func runSettingsPersistencePolicyTests() throws {
    try expect(
        SettingsPersistencePolicy.defaultIsEnabled,
        true,
        "settings defaults keep Punto enabled"
    )
    try expect(
        SettingsPersistencePolicy.nativeIsEnabledKey,
        "isEnabled",
        "settings persistence preserves observed global enable key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setEnabledSelector,
        "setEnabled:",
        "settings persistence preserves observed global enable setter"
    )
    try expect(
        StartupPresentationPolicy.defaultIsFirstLaunch,
        true,
        "settings defaults treat missing first-launch marker as first launch"
    )
    try expect(
        SettingsPersistencePolicy.defaultShowInMenuBar,
        true,
        "settings defaults show menu bar icon"
    )
    try expect(
        SettingsPersistencePolicy.defaultShowAdvancedSettings,
        false,
        "settings defaults hide advanced settings like observed Punto Switcher plist"
    )
    try expect(
        SettingsPersistencePolicy.nativeShowAdvancedSettingsKey,
        "showAdvancedSettings",
        "settings persistence preserves observed advanced-settings key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setShowAdvancedSettingsSelector,
        "setShowAdvancedSettings:",
        "settings persistence preserves observed advanced-settings setter"
    )
    try expect(
        LoginItemPolicy.defaultLaunchAtLogin,
        false,
        "settings defaults do not launch at login"
    )
    try expect(
        LoginItemPolicy.legacyLaunchesOnStartupKey,
        "launchesOnStartup",
        "settings persistence preserves observed launch-at-login alias key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setLaunchesOnStartupSelector,
        "setLaunchesOnStartup:",
        "settings persistence preserves observed launch-at-login setter"
    )
    try expect(
        LayoutSwitchPolicy.defaultSwitchLayoutAfterConversion,
        false,
        "settings defaults do not switch input source after conversion"
    )
    try expect(
        LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion,
        true,
        "settings defaults allow selected-text layout switching when global switching is enabled"
    )
    try expect(
        LayoutSwitchPolicy.legacySwitchLayoutOnSelectedTextSwitchKey,
        "switchLayoutOnSelectedTextSwitch",
        "settings persistence preserves observed selected-text switch key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setSwitchLanguageWhenChangingSelectionLayoutSelector,
        "setSwitchLanguageWhenChangingSelectionLayout:",
        "settings persistence preserves observed selected-text switch setter"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion
        ),
        true,
        "settings persistence reads Punto Switcher switchLayoutOnSelectedTextSwitch alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion
        ),
        false,
        "settings persistence prefers native selected-text layout switch over Punto Switcher alias"
    )
    try expect(
        KeyboardLayoutTypePolicy.defaultRussianLayoutTypeRawValue,
        "mac",
        "settings defaults use Mac Russian keyboard layout"
    )
    try expect(
        TextActionPreflightPolicy.defaultManualConversionDisabled,
        false,
        "settings defaults keep manual conversion enabled"
    )
    try expect(
        TextActionPreflightPolicy.legacyIsManualConversionDisabledKey,
        "isManualConversionDisabled",
        "settings persistence preserves observed manual-conversion-disable key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setIsManualConversionDisabledSelector,
        "setIsManualConversionDisabled:",
        "settings persistence preserves observed manual-conversion-disable setter"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: TextActionPreflightPolicy.defaultManualConversionDisabled
        ),
        true,
        "settings persistence reads Punto Switcher isManualConversionDisabled alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: TextActionPreflightPolicy.defaultManualConversionDisabled
        ),
        false,
        "settings persistence prefers native manual conversion setting over Punto Switcher alias"
    )
    try expect(
        ApplicationLayoutPolicy.defaultRememberInputSourceForEachApp,
        false,
        "settings defaults keep per-app layout memory off"
    )
    try expect(
        ApplicationLayoutPolicy.legacyShouldRememberInputSourceForEachAppKey,
        "shouldRememberInputSourceForEachApp",
        "settings persistence preserves observed per-app layout memory key"
    )
    try expect(
        ApplicationLayoutMemory.defaultSnapshot,
        [:],
        "settings defaults start with empty remembered layout snapshot"
    )
    try expect(
        ApplicationDisablePolicy.defaultDisabledBundleIDs,
        [],
        "settings defaults start with no disabled applications"
    )
    try expect(
        ApplicationDisablePolicy.legacyDisabledAppsKey,
        "disabledApps",
        "settings persistence preserves observed disabled-apps key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setDisabledApplicationsSelector,
        "setDisabledApplications:",
        "settings persistence preserves observed disabled-apps setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.disabledAppsPreferencesControllerKey,
        "disabledAppsPreferencesController",
        "settings persistence preserves observed disabled-apps preferences controller key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setDisabledAppsPreferencesControllerSelector,
        "setDisabledAppsPreferencesController:",
        "settings persistence preserves observed disabled-apps preferences controller setter"
    )
    try expect(
        ApplicationDisablePolicy.defaultCompletelyDisableInExceptionApplications,
        false,
        "settings defaults keep exception apps partially disabled"
    )
    try expect(
        ApplicationDisablePolicy.legacyCompletelyDisableInExceptionApplicationsKey,
        "CompletelyDisableInExceptionApps",
        "settings persistence preserves observed full-disable exception-apps key"
    )
    try expect(
        AutoCorrectionPreflightPolicy.defaultAutoCorrectionEnabled,
        false,
        "settings defaults keep auto-correction off"
    )
    try expect(
        AutoCorrectionPreflightPolicy.legacyIsAutocorrectionActiveKey,
        "isAutocorrectionActive",
        "settings persistence preserves observed auto-correction active key"
    )
    try expect(
        AutoCorrectionUndoLearningPolicy.defaultUndoLearningEnabled,
        false,
        "settings defaults keep auto-correction undo learning off"
    )
    try expect(
        TextReplacementCommitPolicy.defaultSuppressAutoCorrectionAfterManualConversion,
        true,
        "settings defaults suppress auto-correction after manual conversion"
    )
    try expect(
        TextReplacementCommitPolicy.legacyShouldNotAutoconvertAfterConvertionKey,
        "shouldNotAutoconvertAfterConvertion",
        "settings persistence preserves observed post-conversion suppression key"
    )
    try expect(
        AutoCorrectionPreflightPolicy.legacyShouldNotAutoconvertWithTabOrEnterKey,
        "shouldNotAutoconvertWithTabOrEnter",
        "settings persistence owns observed Enter/Tab suppression key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.dontAutoconvertWordAfterConvertionSelector,
        "dontAutoconvertWordAfterConvertion:",
        "settings persistence preserves observed post-conversion suppression selector"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            invertedLegacyValue: false,
            defaultValue: TextReplacementCommitPolicy.defaultSuppressAutoCorrectionAfterManualConversion
        ),
        true,
        "settings persistence reads observed shouldNotAutoconvertAfterConvertion=false as suppression enabled"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            invertedLegacyValue: true,
            defaultValue: TextReplacementCommitPolicy.defaultSuppressAutoCorrectionAfterManualConversion
        ),
        false,
        "settings persistence reads observed shouldNotAutoconvertAfterConvertion=true as suppression disabled"
    )
    try expect(
        AutoCorrectionCancellingKeyPolicy.legacyCancellingKeysBitmaskKey,
        "cancellingKeys",
        "settings persistence owns observed cancelling-keys bitmask key"
    )
    try expect(
        AutoCorrectionCancellingKeyPolicy.legacyEnabledKeyNames(from: 0),
        [],
        "settings persistence reads observed Punto Switcher cancellingKeys=0 as no cancelling keys"
    )
    try expectNil(
        AutoCorrectionCancellingKeyPolicy.legacyEnabledKeyNames(from: 1),
        "settings persistence does not guess unknown Punto Switcher cancellingKeys bit order"
    )
    try expect(
        AutoCorrectionCancellingKeyPolicy.effectiveEnabledKeyNames(
            hasPersistedValue: false,
            persistedValue: [],
            hasLegacyValue: true,
            legacyBitmask: 0
        ),
        [],
        "settings persistence applies observed Punto Switcher cancellingKeys=0 alias"
    )
    try expect(
        AutoCorrectionCancellingKeyPolicy.effectiveEnabledKeyNames(
            hasPersistedValue: true,
            persistedValue: ["backspace"],
            hasLegacyValue: true,
            legacyBitmask: 0
        ),
        ["backspace"],
        "settings persistence prefers native cancelling-key names over legacy bitmask"
    )
    try expect(
        SoundFeedbackPolicy.defaultSoundEffectsEnabled,
        false,
        "settings defaults keep sound effects off"
    )
    try expect(
        SoundFeedbackPolicy.legacyIsSoundOnKey,
        "isSoundOn",
        "sound feedback preserves observed global sound key"
    )
    try expect(
        PuntoSwitcherObservedSurface.SoundFeedback.setSoundStateSelector,
        "setSoundState:isSoundOn:",
        "sound feedback preserves observed sound-state setter"
    )
    try expect(
        ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion,
        true,
        "settings defaults restore pasteboard after clipboard fallbacks"
    )
    try expect(
        ClipboardReplacementPolicy.legacyShouldRestorePasteboardKey,
        "shouldRestorePasteboard",
        "clipboard replacement policy preserves observed pasteboard restore setting key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.previousPasteboardContentsKey,
        "previousPasteboardContents",
        "clipboard replacement policy preserves observed previous pasteboard storage key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.pasteboardRestoreTimerKey,
        "pasteboardRestoreTimer",
        "clipboard replacement policy preserves observed pasteboard restore timer key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.generalPasteboardSelector,
        "generalPasteboard",
        "clipboard replacement policy preserves observed general pasteboard selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.getPasteboardStringSelector,
        "getPasteboardString",
        "clipboard replacement policy preserves observed pasteboard read selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.setPasteboardStringSelector,
        "setPasteboardString:",
        "clipboard replacement policy preserves observed pasteboard write selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.restorePasteboardByTimerSelector,
        "restorePasteboardByTimer:",
        "clipboard replacement policy preserves observed AX pasteboard restore selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.restorePasteboardForKeyboardByTimerSelector,
        "restorePasteboardForKeyboardByTimer:",
        "clipboard replacement policy preserves observed keyboard pasteboard restore selector"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: true,
            hasLegacyValue: true,
            legacyValue: false,
            defaultValue: ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion
        ),
        false,
        "settings persistence reads Punto Switcher shouldRestorePasteboard alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: true,
            hasLegacyValue: true,
            legacyValue: false,
            defaultValue: ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion
        ),
        true,
        "settings persistence prefers native pasteboard restore setting over Punto Switcher alias"
    )
    try expect(
        ProductStatisticsPolicy.defaultSnapshot,
        ProductStatisticsSnapshot(),
        "settings defaults start with empty product statistics"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBool(
            hasPersistedValue: false,
            persistedValue: false,
            defaultValue: true
        ),
        true,
        "settings persistence uses boolean default before a value is saved"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBool(
            hasPersistedValue: true,
            persistedValue: false,
            defaultValue: true
        ),
        false,
        "settings persistence preserves explicit false boolean value"
    )
    try expect(
        LegacyValuePolicy.bool(" YES "),
        true,
        "legacy value policy parses string-backed true boolean imports"
    )
    try expect(
        LegacyValuePolicy.bool("0"),
        false,
        "legacy value policy parses string-backed false boolean imports"
    )
    try expectNil(
        LegacyValuePolicy.bool("maybe"),
        "legacy value policy rejects unknown string-backed boolean imports"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: false
        ),
        true,
        "settings persistence reads Punto Switcher-style legacy boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            legacyValue: LegacyValuePolicy.bool("on"),
            defaultValue: false
        ),
        true,
        "settings persistence reads string-backed Punto Switcher-style legacy boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: LegacyValuePolicy.bool("0"),
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: true
        ),
        false,
        "settings persistence prefers string-backed native boolean key over legacy alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: true
        ),
        false,
        "settings persistence prefers native boolean key over legacy alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            invertedLegacyValue: false,
            defaultValue: false
        ),
        true,
        "settings persistence reads inverted Punto Switcher-style boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            invertedLegacyValue: LegacyValuePolicy.bool("false"),
            defaultValue: false
        ),
        true,
        "settings persistence reads string-backed inverted Punto Switcher-style boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            invertedLegacyValue: false,
            defaultValue: true
        ),
        false,
        "settings persistence prefers native boolean key over inverted legacy alias"
    )
    try expect(
        ApplicationDisablePolicy.normalizedSet([
            " COM.Example.Editor ",
            "",
            "com.example.Terminal"
        ]),
        ["com.example.editor", "com.example.terminal"],
        "settings persistence normalizes disabled app ids"
    )
    try expect(
        ApplicationDisablePolicy.effectiveDisabledBundleIDs(
            hasPersistedValue: false,
            persistedValue: [],
            hasLegacyValue: true,
            legacyValue: [" COM.Example.Legacy ", ""]
        ),
        ["com.example.legacy"],
        "settings persistence reads Punto Switcher-style disabledApps alias"
    )
    try expect(
        ApplicationDisablePolicy.effectiveDisabledBundleIDs(
            hasPersistedValue: true,
            persistedValue: ["com.example.native"],
            hasLegacyValue: true,
            legacyValue: ["com.example.legacy"]
        ),
        ["com.example.native"],
        "settings persistence prefers native disabled app ids over legacy alias"
    )
    try expect(
        AutoCorrectionPreflightPolicy.defaultAutoCorrectOnEnterAndTab,
        true,
        "settings persistence defaults to auto-correction on Enter and Tab"
    )
    try expect(
        AutoCorrectionPreflightPolicy.legacyShouldNotAutoconvertWithTabOrEnterKey,
        "shouldNotAutoconvertWithTabOrEnter",
        "settings persistence preserves observed Enter/Tab suppression key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setDontAutoconvertWithEnterOrTabSelector,
        "setDontAutoconvertWithEnterOrTab:",
        "settings persistence preserves observed Enter/Tab suppression selector"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            invertedLegacyValue: false,
            defaultValue: AutoCorrectionPreflightPolicy.defaultAutoCorrectOnEnterAndTab
        ),
        true,
        "settings persistence reads observed shouldNotAutoconvertWithTabOrEnter=false as Enter/Tab auto-correction enabled"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            invertedLegacyValue: true,
            defaultValue: AutoCorrectionPreflightPolicy.defaultAutoCorrectOnEnterAndTab
        ),
        false,
        "settings persistence reads observed shouldNotAutoconvertWithTabOrEnter=true as Enter/Tab auto-correction disabled"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.defaultStarterRulesEnabled,
        true,
        "settings persistence defaults to Punto Switcher old-rules starter catalog"
    )
    try expect(
        KeyboardLayoutTypePolicy.normalized(" Windows "),
        .windows,
        "settings persistence normalizes Windows Russian keyboard layout type"
    )
    try expect(
        KeyboardLayoutTypePolicy.normalized("appl"),
        .mac,
        "settings persistence normalizes observed Punto Switcher Mac keyboard layout type"
    )
    try expect(
        KeyboardLayoutTypePolicy.normalized("unknown"),
        .mac,
        "settings persistence falls back to Mac Russian keyboard layout type"
    )
    try expect(
        KeyboardLayoutTypePolicy.effectiveRussianKeyboardLayoutType(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            legacyValue: "pc"
        ),
        .windows,
        "settings persistence reads Punto Switcher-style kbdLayoutType alias"
    )
    try expect(
        KeyboardLayoutTypePolicy.legacyRussianKeyboardLayoutTypeKey,
        "kbdLayoutType",
        "settings persistence owns observed Russian keyboard layout type key"
    )
    try expect(
        InputSourceSelectionPolicy.legacyEnglishInputSourceIDKey,
        "englishLayoutID",
        "settings persistence owns observed English input-source id key"
    )
    try expect(
        InputSourceSelectionPolicy.legacyRussianInputSourceIDKey,
        "russianLayoutID",
        "settings persistence owns observed Russian input-source id key"
    )
    try expect(
        KeyboardLayoutTypePolicy.effectiveRussianKeyboardLayoutType(
            hasPersistedValue: true,
            persistedValue: "mac",
            hasLegacyValue: true,
            legacyValue: "pc"
        ),
        .mac,
        "settings persistence prefers native keyboard layout type over legacy alias"
    )
    try expect(
        InputSourceSelectionPolicy.normalizedSourceID(" com.apple.keylayout.Dvorak "),
        "com.apple.keylayout.Dvorak",
        "settings persistence normalizes preferred input source ids"
    )
    try expectNil(
        InputSourceSelectionPolicy.normalizedSourceID(" \n\t "),
        "settings persistence rejects blank preferred input source ids"
    )
    try expectNil(
        InputSourceSelectionPolicy.normalizedSourceID(" undefined "),
        "settings persistence treats Punto Switcher UNDEFINED layout id as unset"
    )
    try expect(
        InputSourceSelectionPolicy.effectiveInputSourceID(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            legacyValue: " com.apple.keylayout.ABC "
        ),
        "com.apple.keylayout.ABC",
        "settings persistence reads Punto Switcher-style layout id alias"
    )
    try expectNil(
        InputSourceSelectionPolicy.effectiveInputSourceID(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            legacyValue: "UNDEFINED"
        ),
        "settings persistence ignores Punto Switcher UNDEFINED layout id alias"
    )
    try expect(
        InputSourceSelectionPolicy.effectiveInputSourceID(
            hasPersistedValue: true,
            persistedValue: "com.apple.keylayout.Dvorak",
            hasLegacyValue: true,
            legacyValue: "com.apple.keylayout.ABC"
        ),
        "com.apple.keylayout.Dvorak",
        "settings persistence prefers native input source id over legacy alias"
    )
    try expect(
        ApplicationReturnKeyPolicy.normalizedResetBundleComponents([
            " Telegram ",
            "",
            "SLACK"
        ]),
        ["telegram", "slack"],
        "settings persistence normalizes reset-on-return components"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: false,
            persistedComponents: nil
        ),
        ApplicationReturnKeyPolicy.defaultResetBundleComponents,
        "settings persistence uses default reset-on-return components before user config"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: false,
            persistedComponents: nil,
            hasLegacyComponents: true,
            legacyComponents: [" Telegram ", "", "SLACK"]
        ),
        ["telegram", "slack"],
        "settings persistence reads Punto Switcher switcher.reset_on_return alias"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: true,
            persistedComponents: [],
            hasLegacyComponents: true,
            legacyComponents: ["telegram"]
        ),
        [],
        "settings persistence prefers intentionally empty native reset-on-return override"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: true,
            persistedComponents: nil,
            hasLegacyComponents: true,
            legacyComponents: ["telegram"]
        ),
        ApplicationReturnKeyPolicy.defaultResetBundleComponents,
        "settings persistence falls back to default for unreadable reset-on-return config"
    )

    let layouts = ApplicationLayoutMemory.normalizedSnapshot([
        " COM.Example.Editor ": " com.apple.keylayout.Russian ",
        "": "ignored",
        "com.example.empty": " ",
        "com.example.Terminal": "com.apple.keylayout.ABC"
    ])
    try expect(
        layouts["com.example.editor"],
        "com.apple.keylayout.Russian",
        "settings persistence normalizes remembered layout app ids"
    )
    try expect(
        layouts["com.example.terminal"],
        "com.apple.keylayout.ABC",
        "settings persistence preserves valid remembered layout ids"
    )
    try expectNil(
        layouts["com.example.empty"],
        "settings persistence drops blank remembered layout ids"
    )
    try expectNil(
        layouts[""],
        "settings persistence drops blank remembered app ids"
    )
}

private func runLegacyValuePolicyTests() throws {
    let legacyDate = Date(timeIntervalSince1970: 1_230_757_200)

    try expect(
        LegacyValuePolicy.bool(" on "),
        true,
        "legacy value policy parses on-style true strings"
    )
    try expect(
        LegacyValuePolicy.bool("OFF"),
        false,
        "legacy value policy parses off-style false strings"
    )
    try expectNil(
        LegacyValuePolicy.bool("maybe"),
        "legacy value policy rejects unknown boolean strings"
    )
    try expect(
        LegacyValuePolicy.bool("maybe", defaultValue: true),
        true,
        "legacy value policy falls back for unknown boolean strings"
    )
    try expect(
        LegacyValuePolicy.int(" 42 "),
        42,
        "legacy value policy parses string-backed integers"
    )
    try expectNil(
        LegacyValuePolicy.int("4.2"),
        "legacy value policy rejects non-integer numeric strings"
    )
    try expect(
        LegacyValuePolicy.nonNegativeInt("-3", defaultValue: 7),
        0,
        "legacy value policy clamps negative integers"
    )
    try expect(
        LegacyValuePolicy.nonNegativeInt("bad", defaultValue: 7),
        7,
        "legacy value policy falls back for unreadable integers"
    )
    try expect(
        LegacyValuePolicy.date("2009-01-01 00:00:00 +0300"),
        legacyDate,
        "legacy value policy parses Punto Switcher date strings"
    )
    try expectNil(
        LegacyValuePolicy.date("1230757200"),
        "legacy value policy does not parse numeric date strings unless requested"
    )
    try expect(
        LegacyValuePolicy.date("1230757200", allowNumericString: true),
        legacyDate,
        "legacy value policy parses numeric date strings for policies that already accepted them"
    )
    try expect(
        LegacyValuePolicy.normalizedStringArray([" COM.Example.App ", "", "com.example.app", "org.example.Editor"]),
        ["com.example.app", "org.example.editor"],
        "legacy value policy normalizes bundle-id arrays"
    )
}

private func runUndoLearningSettingsPolicyTests() throws {
    try expect(
        UndoLearningSettingsPolicy.defaultSnapshot,
        UndoLearningSettingsSnapshot(
            undoCollectionEnabled: false,
            mustShowUndoWindow: true,
            undoDictionary: [:]
        ),
        "undo learning policy mirrors observed Punto Switcher defaults"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setUndoCollectionEnabledSelector,
        "setUndoCollectionEnabled:",
        "observed surface preserves undo learning collection setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setMustShowUndoWindowSelector,
        "setMustShowUndoWindow:",
        "observed surface preserves undo learning undo-window setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setUndoDictionarySelector,
        "setUndoDictionary:",
        "observed surface preserves undo learning undo dictionary setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowControllerClassName,
        "UndoWindowController",
        "observed surface preserves undo window controller name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowDelegateProtocolName,
        "UndoWindowDelegate",
        "observed surface preserves undo window delegate name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowResourceName,
        "UndoWindow",
        "observed surface preserves undo window resource name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoAlertFormatKey,
        "PMUserRuleUndoAlertFormat",
        "observed surface preserves undo alert format key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.showUndoLearningWindowCheckboxChangedSelector,
        "showUndoLearningWindowCheckboxChanged:",
        "observed surface preserves undo show-window checkbox selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoLearningCheckboxChangedSelector,
        "undoLearningCheckboxChanged:",
        "observed surface preserves undo learning checkbox selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoLearningCheckboxKey,
        "undoLearningCheckbox",
        "observed surface preserves undo learning checkbox key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.showUndoLearningWindowCheckboxKey,
        "showUndoLearningWindowCheckbox",
        "observed surface preserves undo show-window checkbox key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoTriesKey,
        "undoTries",
        "observed surface preserves undo tries key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoPersistsKey,
        "undoPersists",
        "observed surface preserves undo persistence key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWasDoneKey,
        "undoWasDone",
        "observed surface preserves undo completion key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoConvertionSelector,
        "undoConvertion",
        "observed surface preserves legacy undo selector spelling"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.resetUndoBufferSelector,
        "resetUndoBuffer",
        "observed surface preserves undo-buffer reset selector"
    )
    try expectNil(
        UndoLearningSettingsPolicy.snapshot(from: nil),
        "undo learning policy rejects missing dictionary"
    )
    try expect(
        UndoLearningSettingsPolicy.snapshot(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: NSNumber(value: false),
            UndoLearningSettingsPolicy.mustShowUndoWindowKey: NSNumber(value: true),
            UndoLearningSettingsPolicy.undoDictionaryKey: [:]
        ]),
        UndoLearningSettingsPolicy.defaultSnapshot,
        "undo learning policy reads observed Punto Switcher plist shape"
    )
    try expect(
        UndoLearningSettingsPolicy.snapshot(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: "yes",
            UndoLearningSettingsPolicy.mustShowUndoWindowKey: "0",
            UndoLearningSettingsPolicy.undoDictionaryKey: [
                " teh ": " the ",
                "": "ignored",
                "adn": " "
            ]
        ]),
        UndoLearningSettingsSnapshot(
            undoCollectionEnabled: true,
            mustShowUndoWindow: false,
            undoDictionary: ["teh": "the"]
        ),
        "undo learning policy parses imported string-backed values and normalizes undo dictionary"
    )
    try expect(
        UndoLearningSettingsPolicy.legacyUndoCollectionEnabled(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: NSNumber(value: true)
        ]),
        true,
        "undo learning policy exposes imported undoCollectionEnabled for settings fallback"
    )
    try expectNil(
        UndoLearningSettingsPolicy.legacyUndoCollectionEnabled(from: nil),
        "undo learning policy ignores missing undoLearning dictionaries"
    )

    try expect(
        UndoLearningSettingsPolicy.normalizedUndoDictionary([
            " ghbdtn ": " привет ",
            "": "ignored",
            "adn": " "
        ]),
        ["ghbdtn": "привет"],
        "undo learning policy normalizes imported undo dictionary entries"
    )
}

private func runProductStatisticsPolicyTests() throws {
    var utcCalendar = Calendar(identifier: .gregorian)
    utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let today = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01 00:00:00 +0000
    let laterToday = Date(timeIntervalSince1970: 1_704_110_400) // 2024-01-01 12:00:00 +0000
    let tomorrow = Date(timeIntervalSince1970: 1_704_153_600) // 2024-01-02 00:00:00 +0000
    let lastProductStatDate = Date(timeIntervalSince1970: 1_704_024_000)

    let legacyNativeData = Data("""
    {"typedWords":2,"typedSymbols":3,"automaticSwitches":4,"manualSwitches":5}
    """.utf8)
    let legacyNativeSnapshot = try JSONDecoder().decode(ProductStatisticsSnapshot.self, from: legacyNativeData)
    try expect(
        legacyNativeSnapshot,
        ProductStatisticsSnapshot(typedWords: 2, typedSymbols: 3, automaticSwitches: 4, manualSwitches: 5, reverts: 0),
        "product statistics snapshot decodes older native payloads without reverts"
    )

    try expect(
        ProductStatisticsPolicy.normalized(ProductStatisticsSnapshot(
            typedWords: -1,
            typedSymbols: -2,
            automaticSwitches: -3,
            manualSwitches: -4,
            reverts: -5
        )),
        ProductStatisticsSnapshot(),
        "product statistics policy clamps negative persisted counters"
    )

    var snapshot = ProductStatisticsSnapshot()
    snapshot = ProductStatisticsPolicy.snapshot(after: .typedText("ab в\n "), current: snapshot, now: today, calendar: utcCalendar)
    try expect(
        snapshot,
        ProductStatisticsSnapshot(
            typedWords: 0,
            typedSymbols: 3,
            automaticSwitches: 0,
            manualSwitches: 0,
            lastDayuseDate: today
        ),
        "product statistics policy counts typed non-whitespace symbols"
    )
    snapshot = ProductStatisticsPolicy.snapshot(after: .completedWord, current: snapshot, now: today, calendar: utcCalendar)
    snapshot = ProductStatisticsPolicy.snapshot(after: .manualSwitch, current: snapshot, now: today, calendar: utcCalendar)
    snapshot = ProductStatisticsPolicy.snapshot(after: .automaticSwitch, current: snapshot, now: today, calendar: utcCalendar)
    snapshot = ProductStatisticsPolicy.snapshot(after: .revert, current: snapshot, now: today, calendar: utcCalendar)
    try expect(
        snapshot,
        ProductStatisticsSnapshot(
            typedWords: 1,
            typedSymbols: 3,
            automaticSwitches: 1,
            manualSwitches: 1,
            reverts: 1,
            lastDayuseDate: today
        ),
        "product statistics policy increments Punto Switcher-style counters"
    )
    try expect(
        ProductStatisticsPolicy.typedSymbolCount(nil),
        0,
        "product statistics policy ignores missing typed text"
    )
    try expect(
        ProductStatisticsPolicy.snapshot(after: .typedText("\n\t "), current: snapshot, now: laterToday, calendar: utcCalendar),
        snapshot,
        "product statistics policy ignores whitespace-only typed text"
    )
    try expect(
        ProductStatisticsPolicy.eventAfterCompletedTokenConsumption(true),
        .completedWord,
        "product statistics policy records completed words when a token is consumed outside autocorrect"
    )
    try expect(
        ProductStatisticsPolicy.eventAfterCompletedTokenConsumption(false),
        nil,
        "product statistics policy skips completed-word event without a consumed token"
    )
    try expect(
        ProductStatisticsPolicy.snapshot(
            after: .completedWord,
            current: ProductStatisticsSnapshot(
                typedWords: 2,
                typedSymbols: 9,
                automaticSwitches: 3,
                manualSwitches: 4,
                reverts: 5,
                lastDayuseDate: today,
                lastProductStatDate: lastProductStatDate
            ),
            now: tomorrow,
            calendar: utcCalendar
        ),
        ProductStatisticsSnapshot(
            typedWords: 1,
            typedSymbols: 0,
            automaticSwitches: 0,
            manualSwitches: 0,
            reverts: 0,
            lastDayuseDate: tomorrow,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy resets day-use counters when the day changes"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacyCounters(
            typedWords: 2,
            typedSymbols: -1,
            automaticSwitches: nil,
            manualSwitches: 3,
            reverts: 4,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        ProductStatisticsSnapshot(
            typedWords: 2,
            typedSymbols: 0,
            automaticSwitches: 0,
            manualSwitches: 3,
            reverts: 4,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy reads Punto Switcher-style individual counters"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacyCounters(
            typedWords: nil,
            typedSymbols: nil,
            automaticSwitches: nil,
            manualSwitches: nil,
            reverts: nil,
            lastDayuseDate: nil,
            lastProductStatDate: nil
        ),
        nil,
        "product statistics policy ignores missing legacy counters"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromDayuseSettings([
            "TypedWords": 109879,
            "TypedSymbols": NSNumber(value: 375547),
            "AutoSwitches": -1,
            "ManualSwitches": 901,
            "Reverts": 12,
            "LastDayuseDate": today,
            "LastProductStatDate": lastProductStatDate
        ]),
        ProductStatisticsSnapshot(
            typedWords: 109879,
            typedSymbols: 375547,
            automaticSwitches: 0,
            manualSwitches: 901,
            reverts: 12,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy reads Punto Switcher PSDayuseSettings counters and dates"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromDayuseSettings([
            "TypedWords": " 109879 ",
            "TypedSymbols": "375547",
            "AutoSwitches": "-1",
            "ManualSwitches": "901",
            "Reverts": "12",
            "LastDayuseDate": "2024-01-01 00:00:00 +0000",
            "LastProductStatDate": "2023-12-31 12:00:00 +0000"
        ]),
        ProductStatisticsSnapshot(
            typedWords: 109879,
            typedSymbols: 375547,
            automaticSwitches: 0,
            manualSwitches: 901,
            reverts: 12,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy reads string-backed Punto Switcher PSDayuseSettings counters and dates"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacySources(
            typedWords: 10,
            typedSymbols: nil,
            automaticSwitches: nil,
            manualSwitches: 40,
            reverts: nil,
            dayuseSettings: [
                "TypedWords": 1,
                "TypedSymbols": 20,
                "AutoSwitches": 30,
                "ManualSwitches": 4,
                "Reverts": 50,
                "LastDayuseDate": today,
                "LastProductStatDate": lastProductStatDate
            ]
        ),
        ProductStatisticsSnapshot(
            typedWords: 10,
            typedSymbols: 20,
            automaticSwitches: 30,
            manualSwitches: 40,
            reverts: 50,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy merges partial legacy counters with Punto Switcher PSDayuseSettings"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacySources(
            typedWords: nil,
            typedSymbols: -2,
            automaticSwitches: nil,
            manualSwitches: nil,
            reverts: nil,
            dayuseSettings: [
                "TypedWords": 1,
                "TypedSymbols": 20,
                "AutoSwitches": 30,
                "ManualSwitches": 40,
                "Reverts": 50
            ]
        ),
        ProductStatisticsSnapshot(
            typedWords: 1,
            typedSymbols: 0,
            automaticSwitches: 30,
            manualSwitches: 40,
            reverts: 50
        ),
        "product statistics policy lets present stale individual counters override matching dayuse fields only"
    )
    try expect(
        ProductStatisticsPolicy.dayuseSettingsKey,
        "PSDayuseSettings",
        "product statistics policy preserves observed dayuse settings key"
    )
    try expect(
        ProductStatisticsPolicy.legacyTypedWordsKey,
        "typedWords",
        "product statistics policy owns legacy typed-words counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyTypedSymbolsKey,
        "typedSymbols",
        "product statistics policy owns legacy typed-symbols counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyAutomaticSwitchesKey,
        "automaticSwitches",
        "product statistics policy owns legacy automatic-switch counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyManualSwitchesKey,
        "manualSwitches",
        "product statistics policy owns legacy manual-switch counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyRevertsKey,
        "reverts",
        "product statistics policy owns legacy revert counter key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.dayuseStatClassName,
        "PSDayuseStat",
        "product statistics policy preserves observed dayuse stat class boundary"
    )
    try expect(
        ProductStatisticsPolicy.dayuseLastDayuseDateKey,
        "LastDayuseDate",
        "product statistics policy preserves observed dayuse date key"
    )
    try expect(
        ProductStatisticsPolicy.dayuseLastProductStatDateKey,
        "LastProductStatDate",
        "product statistics policy preserves observed product stat date key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setDayuseSelector,
        "setDayuse:",
        "product statistics policy preserves observed setDayuse selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setTypedWordsSelector,
        "setTypedWords:",
        "product statistics policy preserves observed typed words setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setTypedSymbolsSelector,
        "setTypedSymbols:",
        "product statistics policy preserves observed typed symbols setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setAutomaticSwitchesSelector,
        "setAutomaticSwitches:",
        "product statistics policy preserves observed automatic switches setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setManualSwitchesSelector,
        "setManualSwitches:",
        "product statistics policy preserves observed manual switches setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setRevertsSelector,
        "setReverts:",
        "product statistics policy preserves observed reverts setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.typedSymbolMetricName,
        "product.typed.symbol",
        "product statistics policy preserves observed typed-symbol metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.typedWordMetricName,
        "product.typed.word",
        "product statistics policy preserves observed typed-word metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.automaticSwitchMetricName,
        "product.switch.auto",
        "product statistics policy preserves observed automatic-switch metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.manualSwitchMetricName,
        "product.switch.manual",
        "product statistics policy preserves observed manual-switch metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.revertMetricName,
        "product.switch.reverse",
        "product statistics policy preserves observed revert metric name"
    )
    try expect(
        ProductStatisticsPolicy.typedSymbolMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.typedSymbolMetricName,
        "product statistics policy keeps typed-symbol metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.typedWordMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.typedWordMetricName,
        "product statistics policy keeps typed-word metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.automaticSwitchMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.automaticSwitchMetricName,
        "product statistics policy keeps automatic-switch metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.manualSwitchMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.manualSwitchMetricName,
        "product statistics policy keeps manual-switch metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.revertMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.revertMetricName,
        "product statistics policy keeps revert metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .typedText("a ")),
        "product.typed.symbol",
        "product statistics policy maps typed-symbol events to observed metric name"
    )
    try expectNil(
        ProductStatisticsPolicy.metricName(for: .typedText("\n\t ")),
        "product statistics policy skips observed typed-symbol metric for whitespace-only text"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .completedWord),
        "product.typed.word",
        "product statistics policy maps completed words to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .automaticSwitch),
        "product.switch.auto",
        "product statistics policy maps automatic switches to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .manualSwitch),
        "product.switch.manual",
        "product statistics policy maps manual switches to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .revert),
        "product.switch.reverse",
        "product statistics policy maps reverts to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.effectiveSnapshot(
            persistedSnapshot: ProductStatisticsSnapshot(typedWords: 5),
            legacyCountersSnapshot: ProductStatisticsSnapshot(typedWords: 1)
        ),
        ProductStatisticsSnapshot(typedWords: 5),
        "product statistics policy prefers native snapshot over legacy counters"
    )
    try expect(
        ProductStatisticsPolicy.effectiveSnapshot(
            persistedSnapshot: nil,
            legacyCountersSnapshot: ProductStatisticsSnapshot(typedSymbols: 7)
        ),
        ProductStatisticsSnapshot(typedSymbols: 7),
        "product statistics policy falls back to legacy counters"
    )
}

private func runApplicationUpdateSettingsPolicyTests() throws {
    try expect(
        ApplicationUpdateSettingsPolicy.configVersionKey,
        "configVersion",
        "update settings policy preserves observed config-version key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isFirstInstallationKey,
        "isFirstInstallation",
        "update settings policy preserves observed first-install key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isJustInstalledKey,
        "isJustInstalled",
        "update settings policy preserves observed just-installed key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isJustUpdatedKey,
        "isJustUpdated",
        "update settings policy preserves observed just-updated key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isUpdatingKey,
        "isUpdating",
        "update settings policy preserves observed updating key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.shouldCheckForUpdatesAutomaticallyKey,
        "shouldCheckForUpdatesAutomatically",
        "update settings policy preserves observed automatic-update-check key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey,
        "updateRequestRateInDays",
        "update settings policy preserves observed update-request-rate key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.lastStatisticsRequestDateKey,
        "lastStatisticsRequestDate",
        "update settings policy preserves observed statistics-request date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.lastUpdateRequestDateKey,
        "lastUpdateRequestDate",
        "update settings policy preserves observed update-request date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.lastUpdateShownDateKey,
        "lastUpdateShownDate",
        "update settings policy preserves observed update-shown date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.configVersion,
        8,
        "update settings policy defaults to observed Punto Switcher config version"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.isUpdating,
        false,
        "update settings policy defaults to non-updating state"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.shouldCheckForUpdatesAutomatically,
        true,
        "update settings policy mirrors observed automatic update check preference"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.updateRequestRateInDays,
        0,
        "update settings policy mirrors observed update request rate"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.lastStatisticsRequestDate,
        ApplicationUpdateSettingsPolicy.legacyInitialDate,
        "update settings policy mirrors observed initial statistics date"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.snapshot(from: [
            ApplicationUpdateSettingsPolicy.configVersionKey: NSNumber(value: 8),
            ApplicationUpdateSettingsPolicy.isFirstInstallationKey: NSNumber(value: true),
            ApplicationUpdateSettingsPolicy.isJustInstalledKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.isJustUpdatedKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.isUpdatingKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.shouldCheckForUpdatesAutomaticallyKey: NSNumber(value: true),
            ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey: NSNumber(value: 0),
            ApplicationUpdateSettingsPolicy.lastStatisticsRequestDateKey: "2008-12-31 21:00:00 +0000",
            ApplicationUpdateSettingsPolicy.lastUpdateShownDateKey: "2008-12-31 21:00:00 +0000"
        ]),
        ApplicationUpdateSettingsPolicy.defaultSnapshot,
        "update settings policy reads observed Punto Switcher updater/install state"
    )

    let updateRequestDate = Date(timeIntervalSince1970: 1_768_132_509)
    let snapshot = ApplicationUpdateSettingsPolicy.snapshot(from: [
        ApplicationUpdateSettingsPolicy.configVersionKey: "9",
        ApplicationUpdateSettingsPolicy.isFirstInstallationKey: "0",
        ApplicationUpdateSettingsPolicy.isJustInstalledKey: "yes",
        ApplicationUpdateSettingsPolicy.isJustUpdatedKey: NSNumber(value: true),
        ApplicationUpdateSettingsPolicy.isUpdatingKey: "false",
        ApplicationUpdateSettingsPolicy.shouldCheckForUpdatesAutomaticallyKey: "no",
        ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey: " 14 ",
        ApplicationUpdateSettingsPolicy.lastStatisticsRequestDateKey: ApplicationUpdateSettingsPolicy.legacyInitialDate,
        ApplicationUpdateSettingsPolicy.lastUpdateRequestDateKey: updateRequestDate.timeIntervalSince1970,
        ApplicationUpdateSettingsPolicy.lastUpdateShownDateKey: "2008-12-31 21:00:00 +0000"
    ])
    try expect(snapshot.configVersion, 9, "update settings policy parses string config version")
    try expect(snapshot.isFirstInstallation, false, "update settings policy parses string first-install flag")
    try expect(snapshot.isJustInstalled, true, "update settings policy parses yes boolean")
    try expect(snapshot.isJustUpdated, true, "update settings policy parses NSNumber boolean")
    try expect(snapshot.isUpdating, false, "update settings policy parses false boolean")
    try expect(snapshot.shouldCheckForUpdatesAutomatically, false, "update settings policy parses no boolean")
    try expect(snapshot.updateRequestRateInDays, 14, "update settings policy parses string update request rate")
    try expect(snapshot.lastUpdateRequestDate, updateRequestDate, "update settings policy parses numeric date")

    let clamped = ApplicationUpdateSettingsPolicy.snapshot(from: [
        ApplicationUpdateSettingsPolicy.configVersionKey: -1,
        ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey: -7
    ])
    try expect(clamped.configVersion, 0, "update settings policy clamps negative config version")
    try expect(clamped.updateRequestRateInDays, 0, "update settings policy clamps negative update request rate")

    let encoded = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(ApplicationUpdateSettingsSnapshot.self, from: encoded)
    try expect(decoded, snapshot, "update settings snapshot supports native Codable persistence")

    let normalized = ApplicationUpdateSettingsPolicy.normalized(
        ApplicationUpdateSettingsSnapshot(
            configVersion: -2,
            isFirstInstallation: false,
            isJustInstalled: true,
            isJustUpdated: true,
            isUpdating: false,
            shouldCheckForUpdatesAutomatically: false,
            updateRequestRateInDays: -5,
            lastStatisticsRequestDate: nil,
            lastUpdateRequestDate: updateRequestDate,
            lastUpdateShownDate: nil
        )
    )
    try expect(normalized.configVersion, 0, "update settings native snapshot clamps config version")
    try expect(normalized.updateRequestRateInDays, 0, "update settings native snapshot clamps update rate")
    try expect(normalized.isJustInstalled, true, "update settings native snapshot preserves install flag")
    try expect(normalized.lastUpdateRequestDate, updateRequestDate, "update settings native snapshot preserves update date")
}

private func runStartupPresentationPolicyTests() throws {
    try expect(
        StartupPresentationPolicy.installArgument,
        "--install",
        "startup presentation policy preserves observed installer argument"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.handleInstallArgumentSelector,
        "handleInstallArgument",
        "startup presentation policy preserves observed install handler selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.installedTooltipKey,
        "tooltip-app-installed",
        "startup presentation policy preserves observed installed tooltip key"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.showUpdateFinishedTooltipSelector,
        "showUpdateFinishedTooltip",
        "startup presentation policy preserves observed update-finished tooltip selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.shouldDisplayWelcomeSelector,
        "shouldDisplayWelcome",
        "startup presentation policy preserves observed welcome selector"
    )
    try expect(
        StartupPresentationPolicy.installArgumentHandlerLogName,
        PuntoSwitcherObservedSurface.StartupPresentation.handleInstallArgumentSelector,
        "startup presentation policy keeps install handler log aligned with reverse-audit anchor"
    )
    try expect(
        StartupPresentationPolicy.updateFinishedTooltipLogName,
        PuntoSwitcherObservedSurface.StartupPresentation.showUpdateFinishedTooltipSelector,
        "startup presentation policy keeps update-finished log aligned with reverse-audit anchor"
    )
    try expect(
        StartupPresentationPolicy.welcomeLogMessage,
        "Displaying welcome screen...",
        "startup presentation policy preserves observed welcome log"
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: true,
            updateSettings: ApplicationUpdateSettingsPolicy.defaultSnapshot
        ),
        true,
        "startup presentation policy shows welcome on native first launch"
    )
    let alreadyInstalled = ApplicationUpdateSettingsSnapshot(
        configVersion: 8,
        isFirstInstallation: false,
        isJustInstalled: false,
        isJustUpdated: false,
        isUpdating: false,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: false,
            updateSettings: alreadyInstalled
        ),
        false,
        "startup presentation policy skips welcome after first-install flags are consumed"
    )
    let justInstalled = ApplicationUpdateSettingsSnapshot(
        configVersion: 8,
        isFirstInstallation: false,
        isJustInstalled: true,
        isJustUpdated: false,
        isUpdating: false,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: false,
            updateSettings: justInstalled
        ),
        true,
        "startup presentation policy shows welcome for observed just-installed flag"
    )
    let consumed = StartupPresentationPolicy.updateSettingsAfterWelcome(justInstalled)
    try expect(consumed.isFirstInstallation, false, "startup presentation policy consumes first-install flag")
    try expect(consumed.isJustInstalled, false, "startup presentation policy consumes just-installed flag")
    try expect(consumed.configVersion, justInstalled.configVersion, "startup presentation policy preserves config version")

    try expect(
        StartupPresentationPolicy.shouldHandleInstallArgument(["/Applications/Punto.app/Contents/MacOS/Punto", "--install"]),
        true,
        "startup presentation policy detects observed installer launch argument"
    )
    try expect(
        StartupPresentationPolicy.shouldHandleInstallArgument(["/Applications/Punto.app/Contents/MacOS/Punto", "--not-install"]),
        false,
        "startup presentation policy rejects non-matching installer argument"
    )

    let afterInstallArgument = StartupPresentationPolicy.updateSettingsAfterInstallArgument(alreadyInstalled)
    try expect(afterInstallArgument.isJustInstalled, true, "startup presentation policy marks just-installed after installer argument")
    try expect(afterInstallArgument.isUpdating, false, "startup presentation policy clears updating after installer argument")
    try expect(afterInstallArgument.configVersion, alreadyInstalled.configVersion, "startup presentation policy preserves config version after installer argument")
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(isFirstLaunch: false, updateSettings: afterInstallArgument),
        true,
        "startup presentation policy shows welcome after installer argument"
    )

    let justUpdated = ApplicationUpdateSettingsSnapshot(
        configVersion: 9,
        isFirstInstallation: false,
        isJustInstalled: false,
        isJustUpdated: true,
        isUpdating: true,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayUpdateFinishedTooltip(updateSettings: justUpdated),
        true,
        "startup presentation policy shows update-finished tooltip for observed just-updated flag"
    )
    let afterUpdateTooltip = StartupPresentationPolicy.updateSettingsAfterUpdateFinishedTooltip(justUpdated)
    try expect(afterUpdateTooltip.isJustUpdated, false, "startup presentation policy consumes just-updated flag")
    try expect(afterUpdateTooltip.isUpdating, false, "startup presentation policy clears updating after update-finished tooltip")
    try expect(afterUpdateTooltip.configVersion, justUpdated.configVersion, "startup presentation policy preserves config version after update-finished tooltip")
}

private func runLayoutSwitchPolicyTests() throws {
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .lastWord,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true
        ),
        false,
        "layout switch policy respects global switch-off for last-word conversion"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true
        ),
        false,
        "layout switch policy respects global switch-off for selected-text conversion"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        true,
        "layout switch policy keeps last-word switching when selected-text switching is disabled"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .undo,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        true,
        "layout switch policy keeps undo layout switching when selected-text switching is disabled"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        false,
        "layout switch policy can suppress selected-text layout switching only"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true
        ),
        true,
        "layout switch policy allows selected-text layout switching when both switches are enabled"
    )

    let now = Date(timeIntervalSince1970: 500)
    let expectedDeadline = now.addingTimeInterval(ConversionProtectionPolicy.inputSourceSwitchGraceInterval)
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .lastWord,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .skip,
        "layout switch runtime skips when global switch is disabled"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .skip,
        "layout switch runtime skips selected text when selected-text switch is disabled"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .switchTo(LayoutSwitchRuntimeRequest(
            language: .russian,
            targetLayout: .russian,
            ignoreInputSourceChangesUntil: expectedDeadline
        )),
        "layout switch runtime requests Russian switch with programmatic grace deadline"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .english,
            surface: .undo,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .switchTo(LayoutSwitchRuntimeRequest(
            language: .english,
            targetLayout: .english,
            ignoreInputSourceChangesUntil: expectedDeadline
        )),
        "layout switch runtime requests English switch for undo"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .mixed,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .unsupportedTarget(clearInputSourceIgnoreDeadline: true),
        "layout switch runtime clears programmatic guard for mixed target"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .unknown,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .unsupportedTarget(clearInputSourceIgnoreDeadline: true),
        "layout switch runtime clears programmatic guard for unknown target"
    )
}

private func runApplicationDisablePolicyTests() throws {
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"]
        ),
        true,
        "application disable policy matches bundle prefix"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoft",
            disabledBundleIDs: ["com.microsoft"]
        ),
        true,
        "application disable policy matches exact bundle id"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoftWord",
            disabledBundleIDs: ["com.microsoft"]
        ),
        false,
        "application disable policy rejects glued prefix"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "  COM.MICROSOFT.Excel  ",
            disabledBundleIDs: [" com.microsoft "]
        ),
        true,
        "application disable policy normalizes case and whitespace"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: nil,
            disabledBundleIDs: ["com.microsoft"]
        ),
        false,
        "application disable policy ignores missing bundle id"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: false
        ),
        false,
        "application disable policy keeps exception apps partially disabled by default"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: true
        ),
        true,
        "application disable policy fully disables exception apps when configured"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.example.editor",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: true
        ),
        false,
        "application disable policy does not fully disable unrelated apps"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: " com.example.App ",
            disabled: true,
            disabledBundleIDs: ["com.other.App"]
        ),
        ["com.example.app", "com.other.app"],
        "application disable policy stores normalized ids"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "COM.MICROSOFT.Word",
            disabled: true,
            disabledBundleIDs: [" com.microsoft ", "com.other.App"]
        ),
        ["com.microsoft.word", "com.other.app"],
        "application disable policy replaces matching prefix with specific disabled app"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft",
            disabled: true,
            disabledBundleIDs: ["com.microsoft.Word", "com.other.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy replaces covered child ids with broader prefix"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft.Word",
            disabled: false,
            disabledBundleIDs: ["com.microsoft", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes matching disabled prefix"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "COM.MICROSOFT.Word",
            disabled: false,
            disabledBundleIDs: [" com.microsoft ", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes matching prefix case-insensitively"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft",
            disabled: false,
            disabledBundleIDs: ["com.microsoft.Word", "com.microsoft.Excel", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes child ids when enabling broader app family"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoftWord",
            disabled: false,
            disabledBundleIDs: ["com.microsoft", "com.other.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy keeps glued prefix when enabling app"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: nil,
            disabled: false,
            disabledBundleIDs: [" com.microsoft ", "", "COM.OTHER.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy normalizes persisted ids when bundle id is missing"
    )
    try expect(
        ApplicationDisablePolicy.normalizedSet([" com.microsoft ", "", "COM.OTHER.App"]),
        ["com.microsoft", "com.other.app"],
        "application disable policy normalizes disabled-app set"
    )
    try expect(
        ApplicationDisablePolicy.toggleAction(
            bundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableToggleAction(
            bundleID: "com.example.editor",
            disabled: true,
            shouldClearState: true,
            clearTrackedTextReason: "disabled current app",
            clearConversionSessionReason: "disabled current app"
        ),
        "application disable policy disables current external app and clears state"
    )
    try expect(
        ApplicationDisablePolicy.toggleAction(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: true
        ),
        ApplicationDisableToggleAction(
            bundleID: "com.example.editor",
            disabled: false,
            shouldClearState: false
        ),
        "application disable policy re-enables current external app without clearing state"
    )
    try expect(
        ApplicationDisablePolicy.toggleLogMessage(
            action: ApplicationDisableToggleAction(
                bundleID: "com.example.editor",
                disabled: true,
                shouldClearState: true,
                clearTrackedTextReason: "disabled current app",
                clearConversionSessionReason: "disabled current app"
            ),
            applicationName: " TextEdit "
        ),
        "Disabled Punto in app 'TextEdit' (com.example.editor)",
        "application disable policy trims display name in toggle log"
    )
    try expect(
        ApplicationDisablePolicy.toggleLogMessage(
            action: ApplicationDisableToggleAction(
                bundleID: "com.example.editor",
                disabled: false,
                shouldClearState: false
            ),
            applicationName: "   "
        ),
        "Enabled Punto in app 'com.example.editor' (com.example.editor)",
        "application disable policy falls back to bundle id in toggle log"
    )
    try expectNil(
        ApplicationDisablePolicy.toggleAction(
            bundleID: " COM.Example.Punto ",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        "application disable policy refuses to disable Punto itself"
    )
    try expectNil(
        ApplicationDisablePolicy.toggleAction(
            bundleID: nil,
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        "application disable policy ignores missing current app id"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            displayName: " TextEdit ",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "Disable in TextEdit",
            isEnabled: true,
            isChecked: false
        ),
        "application disable policy shows enabled disable action for current external app"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            displayName: "TextEdit",
            isCurrentlyDisabled: true
        ),
        ApplicationDisableMenuState(
            title: "Enable in TextEdit",
            isEnabled: true,
            isChecked: true
        ),
        "application disable policy shows checked enable action for disabled current app"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            displayName: "   ",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "Disable in Current App",
            isEnabled: true,
            isChecked: false
        ),
        "application disable policy falls back to generic current app title"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.punto",
            ownBundleID: " COM.Example.Punto ",
            displayName: "Punto",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "No Current App",
            isEnabled: false,
            isChecked: false
        ),
        "application disable policy disables menu action for Punto itself"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: nil,
            ownBundleID: "com.example.punto",
            displayName: "Unknown",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "No Current App",
            isEnabled: false,
            isChecked: false
        ),
        "application disable policy disables menu action without current bundle id"
    )
}

private func runAutoCorrectionTogglePolicyTests() throws {
    try expect(
        AutoCorrectionTogglePolicy.action(wasEnabled: true),
        AutoCorrectionToggleAction(
            newEnabledValue: false,
            clearTrackedTextReason: "auto-correction toggled",
            clearConversionSessionReason: "auto-correction toggled",
            logMessage: "Auto-correction disabled by hotkey",
            shouldFlashIcon: true
        ),
        "auto-correction toggle policy disables enabled setting and clears runtime state"
    )
    try expect(
        AutoCorrectionTogglePolicy.action(wasEnabled: false),
        AutoCorrectionToggleAction(
            newEnabledValue: true,
            clearTrackedTextReason: "auto-correction toggled",
            clearConversionSessionReason: "auto-correction toggled",
            logMessage: "Auto-correction enabled by hotkey",
            shouldFlashIcon: true
        ),
        "auto-correction toggle policy enables disabled setting and clears runtime state"
    )
}

private func runStatusIconPolicyTests() throws {
    try expect(
        PuntoSwitcherObservedSurface.StatusIcon.updateMenubarIconSelector,
        "updateMenubarIcon:",
        "status icon policy preserves observed Punto Switcher menu bar update selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.StatusIcon.resourceNames,
        [
            "icon_active",
            "icon_inactive",
            "icon_disabled",
            "icon_active_w",
            "icon_inactive_w",
            "icon_disabled_w"
        ],
        "status icon policy preserves observed Punto Switcher resource names"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: true, isCurrentApplicationDisabled: false),
        .active,
        "status icon policy marks enabled external app as active"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: false, isCurrentApplicationDisabled: false),
        .inactive,
        "status icon policy marks globally disabled Punto as inactive"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: true, isCurrentApplicationDisabled: true),
        .disabled,
        "status icon policy marks disabled current app separately"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: false, isCurrentApplicationDisabled: true),
        .inactive,
        "status icon policy gives global inactive state priority over app exception"
    )
    try expect(
        StatusIconPolicy.accessibilityDescription(for: .disabled),
        "Punto disabled in current app",
        "status icon policy exposes disabled state description"
    )
}

private func runAccessibilityPreferencesPolicyTests() throws {
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.launchAccessibilityPreferencesSelector,
        "launchAccessibilityPreferences",
        "accessibility preferences policy pins observed launch selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.openAccessibilityPrefPaneSelector,
        "openAccesibilityPrefPane:",
        "accessibility preferences policy pins observed Accessibility pane opener selector"
    )
    try expect(
        AccessibilityPreferencesPolicy.securityPrivacyPaneID,
        "com.apple.preference.security",
        "accessibility preferences policy preserves observed security pane id"
    )
    try expect(
        AccessibilityPreferencesPolicy.accessibilityPrivacyAnchor,
        "Privacy_Accessibility",
        "accessibility preferences policy preserves observed accessibility anchor"
    )
    try expect(
        AccessibilityPreferencesPolicy.preferencesURL.absoluteString,
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        "accessibility preferences policy builds observed System Settings URL"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.accessibilityAlertMessageKey,
        "accessibility-alert-message",
        "accessibility preferences policy preserves observed modern alert message key"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.accessibilityAlertLegacyMessageKey,
        "accessibility-alert-messageLegacy",
        "accessibility preferences policy preserves observed legacy alert message key"
    )
    try expect(
        AccessibilityPreferencesPolicy.permissionRequestMessage.contains("System Settings > Privacy & Security > Accessibility"),
        true,
        "accessibility preferences policy keeps native permission copy on the observed Accessibility path"
    )
    try expect(
        AccessibilityPreferencesPolicy.openSettingsButtonTitle,
        "Open System Settings",
        "accessibility preferences policy centralizes open-settings button copy"
    )
    try expect(
        AccessibilityPreferencesPolicy.legacyAppleScriptSource.contains("tell application \"System Preferences\""),
        true,
        "accessibility preferences policy preserves observed System Preferences fallback"
    )
    try expect(
        AccessibilityPreferencesPolicy.legacyAppleScriptSource.contains("reveal anchor \"Privacy_Accessibility\" of pane id \"com.apple.preference.security\""),
        true,
        "accessibility preferences policy reveals observed Accessibility privacy anchor"
    )
    try expect(
        AccessibilityPreferencesPolicy.shouldRunLegacyFallback(openedURL: false),
        true,
        "accessibility preferences policy falls back when URL open fails"
    )
    try expect(
        AccessibilityPreferencesPolicy.shouldRunLegacyFallback(openedURL: true),
        false,
        "accessibility preferences policy skips fallback after successful URL open"
    )
}

private func runInputSourceChangePolicyTests() throws {
    let now = Date(timeIntervalSince1970: 100)
    let future = now.addingTimeInterval(0.75)
    let past = now.addingTimeInterval(-0.01)

    try expect(
        InputSourceChangePolicy.action(
            now: now,
            ignoreChangesUntil: future,
            isConversionInProgress: false
        ),
        .ignoreProgrammaticSwitch(
            logMessage: "Input source changed - ignored (programmatic switch grace window)"
        ),
        "input source policy ignores programmatic switch inside grace window"
    )
    try expect(
        InputSourceChangePolicy.nextIgnoreChangesUntil(
            now: now,
            currentIgnoreChangesUntil: future
        ),
        future,
        "input source policy keeps active grace window"
    )
    try expect(
        InputSourceChangePolicy.action(
            now: now,
            ignoreChangesUntil: past,
            isConversionInProgress: true
        ),
        .ignoreConversionInProgress(
            logMessage: "Input source changed - ignored (conversion in progress)"
        ),
        "input source policy ignores changes during conversion after expired grace"
    )
    try expectNil(
        InputSourceChangePolicy.nextIgnoreChangesUntil(
            now: now,
            currentIgnoreChangesUntil: past
        ),
        "input source policy clears expired grace window"
    )
    try expect(
        InputSourceChangePolicy.action(
            now: now,
            ignoreChangesUntil: nil,
            isConversionInProgress: false
        ),
        .rememberLayoutAndClearTextState(InputSourceChangeRuntimePlan(
            layoutMemoryReason: "input source changed",
            clearTrackedTextReason: "input source changed",
            clearConversionSessionReason: "input source changed",
            logMessage: "Input source changed - WordTracker cleared"
        )),
        "input source policy clears state for ordinary user layout change"
    )
    try expect(
        InputSourceChangePolicy.preferencesChangeAction(),
        InputSourcePreferencesChangeAction(
            shouldRefreshInputSources: true,
            clearTrackedTextReason: "Input source preferences changed",
            clearConversionSessionReason: "Input source preferences changed",
            logMessage: "Input source preferences changed - input sources refreshed"
        ),
        "input source policy owns preference-refresh cleanup plan"
    )
}

private func runConversionProtectionPolicyTests() throws {
    let now = Date(timeIntervalSince1970: 100)
    let dispatchNow = DispatchTime.now()

    try expect(
        ConversionProtectionPolicy.startupPermissionAlertDelay,
        0.5,
        "conversion protection policy keeps startup permission alert delay"
    )
    try expect(
        ConversionProtectionPolicy.inputSourceSwitchGraceInterval,
        0.75,
        "conversion protection policy keeps input source switch grace interval"
    )
    try expect(
        ConversionProtectionPolicy.eventRecaptureProtectionDelay,
        0.3,
        "conversion protection policy keeps event recapture protection delay"
    )
    try expect(
        ConversionProtectionPolicy.inputSourceIgnoreDeadline(now: now),
        now.addingTimeInterval(0.75),
        "conversion protection policy computes input source ignore deadline"
    )
    let replacementWindow = ConversionProtectionPolicy.replacementWindowAction(
        now: now,
        dispatchNow: dispatchNow
    )
    try expect(
        replacementWindow.ignoreAccessibilityNotificationsUntil,
        now.addingTimeInterval(ConversionProtectionPolicy.eventRecaptureProtectionDelay),
        "replacement window action uses recapture interval for accessibility notifications"
    )
    try expect(
        replacementWindow.releaseEventRecaptureAt,
        dispatchNow + ConversionProtectionPolicy.eventRecaptureProtectionDelay,
        "replacement window action uses recapture interval for hotkey release"
    )
    try expect(
        replacementWindow.shouldIgnoreHotkeyEvents,
        true,
        "replacement window action suppresses hotkey recapture while replacing text"
    )
    try expect(
        replacementWindow.markConversionInProgress,
        true,
        "replacement window action marks conversion in progress while replacing text"
    )
}

private func runInputSourceSwitchVerificationPolicyTests() throws {
    try expect(
        InputSourceSwitchVerificationPolicy.result(
            selectStatus: 0,
            targetLayoutID: "com.apple.keylayout.Russian",
            currentLayoutIDAfterSwitch: "com.apple.keylayout.Russian"
        ),
        .switched,
        "input source switch verification accepts confirmed layout change"
    )
    try expect(
        InputSourceSwitchVerificationPolicy.result(
            selectStatus: -50,
            targetLayoutID: "com.apple.keylayout.Russian",
            currentLayoutIDAfterSwitch: "com.apple.keylayout.ABC"
        ),
        .selectFailed(status: -50),
        "input source switch verification preserves TIS select failure status"
    )
    try expect(
        InputSourceSwitchVerificationPolicy.result(
            selectStatus: 0,
            targetLayoutID: "com.apple.keylayout.Russian",
            currentLayoutIDAfterSwitch: "com.apple.keylayout.ABC"
        ),
        .layoutStayedSame(currentLayoutID: "com.apple.keylayout.ABC"),
        "input source switch verification rejects noErr when layout stayed unchanged"
    )
    try expect(
        InputSourceSwitchVerificationPolicy.result(
            selectStatus: 0,
            targetLayoutID: " com.apple.keylayout.Russian ",
            currentLayoutIDAfterSwitch: " com.apple.keylayout.Russian "
        ),
        .switched,
        "input source switch verification normalizes source ids"
    )
    try expect(
        InputSourceSwitchVerificationPolicy.result(
            selectStatus: 0,
            targetLayoutID: "com.apple.keylayout.Russian",
            currentLayoutIDAfterSwitch: nil
        ),
        .layoutStayedSame(currentLayoutID: nil),
        "input source switch verification rejects missing current layout evidence"
    )
}

private func runInputSourceLanguagePolicyTests() throws {
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.ABC",
            languages: []
        ),
        true,
        "input source language policy detects ABC layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.us",
            languages: []
        ),
        true,
        "input source language policy detects lowercase US layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.Russian",
            languages: [" EN "]
        ),
        true,
        "input source language policy detects normalized English language"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.Russian",
            languages: ["en-US"]
        ),
        true,
        "input source language policy detects English locale language"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.USInternational",
            languages: []
        ),
        true,
        "input source language policy detects USInternational layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.Dvorak",
            languages: []
        ),
        true,
        "input source language policy detects Dvorak English layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.Colemak",
            languages: []
        ),
        true,
        "input source language policy detects Colemak English layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.British-PC",
            languages: []
        ),
        true,
        "input source language policy detects British English layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.apple.keylayout.Australian",
            languages: []
        ),
        true,
        "input source language policy detects Australian English layout"
    )
    try expect(
        InputSourceLanguagePolicy.isEnglishInputSource(
            sourceID: "com.example.bus",
            languages: []
        ),
        false,
        "input source language policy rejects glued US token"
    )
    try expect(
        InputSourceLanguagePolicy.isRussianInputSource(
            sourceID: "com.apple.keylayout.russian",
            languages: []
        ),
        true,
        "input source language policy detects lowercase Russian layout"
    )
    try expect(
        InputSourceLanguagePolicy.isRussianInputSource(
            sourceID: "com.apple.keylayout.RussianWin",
            languages: []
        ),
        true,
        "input source language policy detects Russian-PC layout"
    )
    try expect(
        KeyboardLayoutTypePolicy.isPreferredRussianSource(
            sourceID: "com.apple.keylayout.RussianWin",
            layoutType: .windows
        ),
        true,
        "keyboard layout type policy prefers RussianWin for Windows layout"
    )
    try expect(
        KeyboardLayoutTypePolicy.isPreferredRussianSource(
            sourceID: "com.apple.keylayout.Russian",
            layoutType: .mac
        ),
        true,
        "keyboard layout type policy prefers Russian for Mac layout"
    )
    try expect(
        KeyboardLayoutTypePolicy.normalized("pc"),
        .windows,
        "keyboard layout type policy normalizes pc alias"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isDefaultEnglishSource(" com.apple.keylayout.US "),
        true,
        "keyboard layout variant policy detects normalized US default English layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isDefaultEnglishSource("com.apple.keylayout.ABC"),
        true,
        "keyboard layout variant policy detects ABC default English layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isDefaultEnglishSource("com.apple.keylayout.USInternational"),
        false,
        "keyboard layout variant policy does not treat USInternational as default US"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.isAppleLayoutSelector,
        "isAppleLayout",
        "keyboard layout variant policy preserves observed Apple-layout selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.isDvorakSelector,
        "isDvorak",
        "keyboard layout variant policy preserves observed Dvorak selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.windowsLayoutUsedSelector,
        "windowsLayoutUsed",
        "keyboard layout variant policy preserves observed Windows-layout selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.fixStringSelector,
        "fixString:isEnglish:isApple:",
        "keyboard layout variant policy preserves observed punctuation-fix selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.createMacToPcMappingSelector,
        "createMacToPcMappingWithString:pcLayoutA:pcLayoutB:",
        "keyboard layout variant policy preserves observed Mac-to-PC mapping selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.KeyboardLayoutVariant.convertStringLayoutSelector,
        "convertStringLayout:withMode:isPCLayout:",
        "keyboard layout variant policy preserves observed layout conversion selector"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isDvorakEnglishSource(" COM.APPLE.KEYLAYOUT.DVORAK "),
        true,
        "keyboard layout variant policy detects normalized Dvorak English layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isDvorakEnglishSource("com.example.dvorakish"),
        false,
        "keyboard layout variant policy rejects glued Dvorak token"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isAppleRussianSource(" com.apple.keylayout.Russian "),
        true,
        "keyboard layout variant policy detects normalized Apple Russian layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isAppleRussianSource("com.apple.keylayout.RussianWin"),
        false,
        "keyboard layout variant policy does not treat RussianWin as Apple Russian layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isWindowsRussianSource(" COM.APPLE.KEYLAYOUT.RUSSIANWIN "),
        true,
        "keyboard layout variant policy detects normalized Windows Russian layout"
    )
    try expect(
        KeyboardLayoutVariantPolicy.isWindowsRussianSource("com.apple.keylayout.Russian"),
        false,
        "keyboard layout variant policy does not treat Apple Russian as Windows Russian layout"
    )
    try expect(
        InputSourceLanguagePolicy.isRussianInputSource(
            sourceID: "com.apple.keylayout.ABC",
            languages: [" RU "]
        ),
        true,
        "input source language policy detects normalized Russian language"
    )
    try expect(
        InputSourceLanguagePolicy.isRussianInputSource(
            sourceID: "com.apple.keylayout.ABC",
            languages: ["ru_RU"]
        ),
        true,
        "input source language policy detects Russian locale language"
    )
    try expect(
        InputSourceLanguagePolicy.isRussianInputSource(
            sourceID: "com.example.prussian",
            languages: []
        ),
        false,
        "input source language policy rejects glued Russian token"
    )
    try expect(
        InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
        ]),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy picks first selectable English and Russian layouts"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.RussianWin", languages: ["ru"], isSelectableKeyboard: true)
            ],
            preferredRussianLayoutType: .mac,
            preferredEnglishSourceID: " com.apple.keylayout.Dvorak ",
            preferredRussianSourceID: " com.apple.keylayout.RussianWin "
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.Dvorak",
            russianSourceID: "com.apple.keylayout.RussianWin"
        ),
        "input source selection policy honors explicit preferred English and Russian layout ids"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.US", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
            ]
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.US",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy prefers Punto Switcher-style default English layout over Dvorak"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.USInternational", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
            ]
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy prefers modern default ABC over English variants"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.US", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
            ],
            preferredEnglishSourceID: "com.apple.keylayout.Dvorak"
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.Dvorak",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy keeps explicit English layout id stronger than default English"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.RussianWin", languages: ["ru"], isSelectableKeyboard: true)
            ],
            preferredRussianLayoutType: .windows
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.RussianWin"
        ),
        "input source selection policy prefers RussianWin when Windows layout is configured without explicit Russian id"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
            ],
            preferredRussianLayoutType: .windows
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy falls back when RussianWin is unavailable"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true, isEnabled: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.RussianWin", languages: ["ru"], isSelectableKeyboard: true, isEnabled: false)
            ],
            preferredRussianLayoutType: .windows
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.RussianWin",
            sourceIDsToEnable: ["com.apple.keylayout.RussianWin"]
        ),
        "input source selection policy chooses disabled RussianWin for Punto-style enabling when Windows layout is configured"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
            ],
            preferredEnglishSourceID: "com.apple.keylayout.Missing",
            preferredRussianSourceID: "com.apple.keylayout.Missing"
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy falls back when explicit preferred layout ids are unavailable"
    )
    try expect(
        InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: false),
            InputSourceCandidate(sourceID: "com.apple.keylayout.US", languages: [], isSelectableKeyboard: true),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true)
        ]),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.US",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy ignores non-selectable layout candidates"
    )
    try expect(
        InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true, isEnabled: false),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true, isEnabled: true),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true, isEnabled: false),
            InputSourceCandidate(sourceID: "com.apple.keylayout.RussianWin", languages: ["ru"], isSelectableKeyboard: true, isEnabled: true)
        ]),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.Dvorak",
            russianSourceID: "com.apple.keylayout.Russian",
            sourceIDsToEnable: ["com.apple.keylayout.Russian"]
        ),
        "input source selection policy enables disabled preferred Mac Russian before falling back to Windows Russian"
    )
    try expect(
        InputSourceSelectionPolicy.selection(
            from: [
                InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true, isEnabled: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Dvorak", languages: ["en"], isSelectableKeyboard: true, isEnabled: false),
                InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true, isEnabled: true),
                InputSourceCandidate(sourceID: "com.apple.keylayout.RussianWin", languages: ["ru"], isSelectableKeyboard: true, isEnabled: false)
            ],
            preferredRussianLayoutType: .windows,
            preferredEnglishSourceID: "com.apple.keylayout.Dvorak",
            preferredRussianSourceID: "com.apple.keylayout.RussianWin"
        ),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.Dvorak",
            russianSourceID: "com.apple.keylayout.RussianWin",
            sourceIDsToEnable: [
                "com.apple.keylayout.Dvorak",
                "com.apple.keylayout.RussianWin"
            ]
        ),
        "input source selection policy chooses disabled explicit preferred layouts for Punto-style enabling"
    )
    let allDisabledSelection = InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en"], isSelectableKeyboard: true, isEnabled: false),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: ["ru"], isSelectableKeyboard: true, isEnabled: false)
    ])
    try expect(
        allDisabledSelection,
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian",
            sourceIDsToEnable: [
                "com.apple.keylayout.ABC",
                "com.apple.keylayout.Russian"
            ]
        ),
        "input source selection policy chooses disabled required layouts for Punto-style enabling"
    )
    try expect(
        InputSourceSelectionPolicy.shouldEnableInputSource(
            sourceID: " com.apple.keylayout.ABC ",
            selection: allDisabledSelection
        ),
        true,
        "input source selection policy marks selected disabled English source for enabling"
    )
    try expect(
        InputSourceSelectionPolicy.shouldEnableInputSource(
            sourceID: "com.apple.keylayout.US",
            selection: allDisabledSelection
        ),
        false,
        "input source selection policy does not enable unselected sources"
    )
    let missingSelection = InputSourceSelection(englishSourceID: nil, russianSourceID: "com.apple.keylayout.Russian")
    try expect(
        PuntoSwitcherObservedSurface.InputSources.inputSourceEnabledSelector,
        "inputSourceEnabled:",
        "input source selection policy preserves observed enabled selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.InputSources.handleInputSourcesEnabledSelector,
        "handleInputSourcesEnabled",
        "input source selection policy preserves observed enabled handler selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.InputSources.promptUserToInstallLayoutsSelector,
        "promptUserToInstallLayouts",
        "input source selection policy preserves observed install-layouts prompt selector"
    )
    try expect(
        InputSourceSelectionPolicy.inputSourceEnabledLogPrefix,
        PuntoSwitcherObservedSurface.InputSources.inputSourceEnabledSelector,
        "input source selection policy keeps enabled-layout log prefix aligned with reverse-audit anchor"
    )
    try expect(
        InputSourceSelectionPolicy.handleInputSourcesEnabledLogPrefix,
        PuntoSwitcherObservedSurface.InputSources.handleInputSourcesEnabledSelector,
        "input source selection policy keeps enabled-layout handler prefix aligned with reverse-audit anchor"
    )
    try expect(
        InputSourceSelectionPolicy.promptUserToInstallLayoutsLogPrefix,
        PuntoSwitcherObservedSurface.InputSources.promptUserToInstallLayoutsSelector,
        "input source selection policy keeps install-layout prompt prefix aligned with reverse-audit anchor"
    )
    try expect(
        InputSourceSelectionPolicy.missingRequiredLanguageNames(in: missingSelection),
        ["English"],
        "input source selection policy reports missing English layout"
    )
    try expect(
        InputSourceSelectionPolicy.shouldPromptUserToInstallLayouts(selection: missingSelection),
        true,
        "input source selection policy prompts when a required layout is missing"
    )
    try expect(
        InputSourceSelectionPolicy.missingRequiredLayoutsLogMessage(selection: missingSelection),
        "promptUserToInstallLayouts: missing English input source",
        "input source selection policy logs observed prompt path for missing layout"
    )
    try expect(
        InputSourceSelectionPolicy.inputSourceEnabledLogMessage(sourceID: "com.apple.keylayout.Russian"),
        "inputSourceEnabled: com.apple.keylayout.Russian",
        "input source selection policy logs observed enabled-layout selector shape"
    )
    try expect(
        InputSourceSelectionPolicy.handleInputSourcesEnabledLogMessage(sourceIDs: [
            "com.apple.keylayout.Russian",
            " com.apple.keylayout.ABC ",
            "com.apple.keylayout.Russian"
        ]),
        "handleInputSourcesEnabled: com.apple.keylayout.ABC, com.apple.keylayout.Russian",
        "input source selection policy logs observed enabled-layout handler shape"
    )
    try expectNil(
        InputSourceSelectionPolicy.handleInputSourcesEnabledLogMessage(sourceIDs: [" ", "UNDEFINED"]),
        "input source selection policy skips empty enabled-layout handler logs"
    )
    try expect(
        InputSourceSelectionPolicy.failedToEnableLayoutLogMessage(
            sourceID: "com.apple.keylayout.Russian",
            status: -50
        ),
        "Failed to enable layout com.apple.keylayout.Russian! Error code: -50",
        "input source selection policy logs observed failed-enable shape"
    )
    try expectNil(
        InputSourceSelectionPolicy.missingRequiredLayoutsLogMessage(
            selection: InputSourceSelection(
                englishSourceID: "com.apple.keylayout.ABC",
                russianSourceID: "com.apple.keylayout.Russian"
            )
        ),
        "input source selection policy stays quiet when required layouts are present"
    )
    try expect(
        InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: " com.apple.keylayout.ABC ", languages: ["en", "ru"], isSelectableKeyboard: true),
            InputSourceCandidate(sourceID: "com.apple.keylayout.Russian", languages: [], isSelectableKeyboard: true)
        ]),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: "com.apple.keylayout.Russian"
        ),
        "input source selection policy keeps English and Russian sources distinct"
    )
    try expect(
        InputSourceSelectionPolicy.selection(from: [
            InputSourceCandidate(sourceID: "com.apple.keylayout.ABC", languages: ["en", "ru"], isSelectableKeyboard: true)
        ]),
        InputSourceSelection(
            englishSourceID: "com.apple.keylayout.ABC",
            russianSourceID: nil
        ),
        "input source selection policy does not assign one source to both languages"
    )
    try expect(
        InputSourceSelectionPolicy.normalizedSourceID(" \n\t "),
        nil,
        "input source selection policy rejects blank source id"
    )
}

private func runApplicationContextPolicyTests() throws {
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto"
        ),
        .preserveCurrentExternalContext(
            logMessage: "Punto window activated - preserving last external app 'com.example.editor'"
        ),
        "app context policy preserves external context when Punto activates"
    )
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.chat",
            ownBundleID: "com.example.punto"
        ),
        .activateExternal(ApplicationContextActivationPlan(
            shouldResetTextState: true,
            clearTrackedTextReason: "active application changed",
            clearConversionSessionReason: "active application changed"
        )),
        "app context policy plans external app-switch cleanup"
    )
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: nil,
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        .activateExternal(ApplicationContextActivationPlan(
            shouldResetTextState: false,
            clearTrackedTextReason: nil,
            clearConversionSessionReason: nil
        )),
        "app context policy keeps initial external activation clean"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: nil,
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy keeps empty initial context"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy keeps same app context"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: " COM.Example.Editor ",
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy normalizes app context ids"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.chat",
            ownBundleID: "com.example.punto"
        ),
        true,
        "app context policy resets text state on external app switch"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy preserves state when Punto window activates"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: " COM.EXAMPLE.PUNTO ",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy normalizes own app id"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: nil,
            ownBundleID: "com.example.punto"
        ),
        true,
        "app context policy resets when external app context is lost"
    )
}

private func runHotkeyRoutingPolicyTests() throws {
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: true, isCurrentApplicationDisabled: false),
        true,
        "hotkey routing handles enabled active app"
    )
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: false, isCurrentApplicationDisabled: false),
        false,
        "hotkey routing passes through when Punto is disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: true, isCurrentApplicationDisabled: true),
        false,
        "hotkey routing passes through disabled application"
    )
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: false, isCurrentApplicationDisabled: true),
        false,
        "hotkey routing passes through when both global and app disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldTrackKeyState(isEnabled: true, isCurrentApplicationDisabled: false),
        true,
        "key-state routing tracks enabled active app"
    )
    try expect(
        HotkeyRoutingPolicy.shouldTrackKeyState(isEnabled: false, isCurrentApplicationDisabled: false),
        false,
        "key-state routing skips when Punto is disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldTrackKeyState(isEnabled: true, isCurrentApplicationDisabled: true),
        false,
        "key-state routing skips disabled application"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: true, isEnabled: false),
        true,
        "enabled transition clears state when Punto is disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: false, isEnabled: true),
        false,
        "enabled transition keeps state when Punto is enabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: true, isEnabled: true),
        false,
        "enabled transition keeps state when enabled stays enabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: false, isEnabled: false),
        false,
        "enabled transition keeps state when disabled stays disabled"
    )
    try expect(
        HotkeyRoutingPolicy.stateClearActionAfterEnabledChange(wasEnabled: true, isEnabled: false),
        HotkeyRoutingStateClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "Punto disabled",
            clearConversionSessionReason: "Punto disabled",
            logMessage: "Punto disabled - cleared text state"
        ),
        "hotkey routing owns global-disable state cleanup action"
    )
    try expect(
        HotkeyRoutingPolicy.stateClearActionAfterEnabledChange(wasEnabled: true, isEnabled: true),
        HotkeyRoutingStateClearAction(clearTrackedText: false, clearConversionSession: false),
        "hotkey routing keeps state when enabled state does not transition to disabled"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .modifierOnlyConvertLayout,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            displayString: "Cmd+Opt+Shift"
        ),
        .handle(logMessage: "Modifier-only hotkey triggered: Cmd+Opt+Shift"),
        "hotkey routing owns modifier-only matched log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .modifierOnlyConvertLayout,
            isEnabled: false,
            isCurrentApplicationDisabled: false,
            displayString: "Cmd+Opt+Shift"
        ),
        .passThrough(logMessage: "Modifier-only hotkey ignored by routing policy"),
        "hotkey routing owns modifier-only pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .convertLayout,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            keyCode: 6
        ),
        .handle(logMessage: "Convert layout hotkey matched! keyCode=6"),
        "hotkey routing owns convert hotkey matched log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .toggleCase,
            isEnabled: false,
            isCurrentApplicationDisabled: false,
            keyCode: 6
        ),
        .passThrough(logMessage: "Toggle case hotkey passed through by routing policy"),
        "hotkey routing owns toggle-case pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .toggleAutoCorrection,
            isEnabled: true,
            isCurrentApplicationDisabled: true,
            keyCode: 0
        ),
        .passThrough(logMessage: "Toggle auto-correction hotkey passed through by routing policy"),
        "hotkey routing owns auto-correction toggle pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .cancelLayoutChange,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            keyCode: 51
        ),
        .handle(logMessage: "Cancel layout change hotkey matched! keyCode=51"),
        "hotkey routing owns cancel-layout matched log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .findInYandex,
            isEnabled: false,
            isCurrentApplicationDisabled: true,
            keyCode: 3
        ),
        .passThrough(logMessage: "Find in Yandex hotkey passed through by routing policy"),
        "hotkey routing owns Yandex search pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .findInSlovari,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            keyCode: 5
        ),
        .handle(logMessage: "Find in Slovari hotkey matched! keyCode=5"),
        "hotkey routing owns Slovari hotkey matched log"
    )
}

private func runKeyTrackingRuntimePolicyTests() throws {
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .track,
        "key tracking runtime tracks normal enabled input"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipRouting(logMessage: "Key tracking skipped by routing policy"),
        "key tracking runtime skips when Punto is disabled"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipRouting(logMessage: "Key tracking skipped by routing policy"),
        "key tracking runtime skips disabled applications"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockSecureInput(context: "secure input", logMessage: "Key tracking skipped for secure/password input"),
        "key tracking runtime blocks secure input before tracking text"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockSecureInput(context: "password field", logMessage: "Key tracking skipped for secure/password input"),
        "key tracking runtime blocks password fields before tracking text"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "org.telegram.desktop",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .resetOnReturn,
        "key tracking runtime routes reset-on-return apps away from auto-correction"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "com.apple.TextEdit",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .runAutoCorrection,
        "key tracking runtime keeps ordinary editors eligible for return auto-correction"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "org.telegram.desktop",
            keyCode: 49,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .runAutoCorrection,
        "key tracking runtime ignores non-return keys for reset-on-return apps"
    )
    try expect(
        KeyTrackingRuntimePolicy.resetOnReturnPlan(
            consumedCompletedToken: true,
            bundleID: "org.telegram.desktop"
        ),
        KeyTrackingResetPlan(
            completedTokenStatisticsEvent: .completedWord,
            conversionSessionClearReason: "return in reset-on-return app",
            logMessage: "Auto-correction skipped and text state reset on Return for app 'org.telegram.desktop'"
        ),
        "key tracking runtime records completed word and clears undo for reset-on-return"
    )
    try expect(
        KeyTrackingRuntimePolicy.resetOnReturnPlan(
            consumedCompletedToken: false,
            bundleID: nil
        ),
        KeyTrackingResetPlan(
            completedTokenStatisticsEvent: nil,
            conversionSessionClearReason: "return in reset-on-return app",
            logMessage: "Auto-correction skipped and text state reset on Return for app '?'"
        ),
        "key tracking runtime handles reset-on-return without completed token"
    )
    try expect(
        KeyTrackingRuntimePolicy.conversionSessionClearReasonAfterAutoCorrection(isConversionInProgress: false),
        "key press",
        "key tracking runtime clears stale undo after ordinary non-converting key press"
    )
    try expectNil(
        KeyTrackingRuntimePolicy.conversionSessionClearReasonAfterAutoCorrection(isConversionInProgress: true),
        "key tracking runtime preserves undo while auto-correction conversion window is active"
    )
}

private func runTextActionPreflightPolicyTests() throws {
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "text action preflight allows normal conversion"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "toggle case disabled"),
        "text action preflight skips disabled toggle case"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "manual conversion disabled"),
        "text action preflight skips manual layout conversion when manually disabled"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "text action preflight keeps toggle-case available when manual conversion is disabled"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "conversion already in progress"),
        "text action preflight skips nested conversion"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "current app disabled"),
        "text action preflight skips disabled application"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: false
        ),
        .blockAndClear(reason: "secure input"),
        "text action preflight clears state for secure input"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "text action preflight clears state for password fields"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "text action preflight gives secure input priority over password field"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .blockAndClear(reason: "password field"),
            kind: .toggleCase
        ),
        "Password field detected - toggle case blocked",
        "text action preflight preserves toggle-case password log"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .skip(reason: "manual conversion disabled"),
            kind: .layoutConversion
        ),
        "Manual conversion disabled, skipping conversion",
        "text action preflight preserves manual-conversion-disabled log"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .skip(reason: "current app disabled"),
            kind: .layoutConversion
        ),
        "Current app disabled, skipping conversion",
        "text action preflight preserves conversion disabled-app log"
    )
}

private func runTextActionRuntimePreflightPolicyTests() throws {
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false
        ),
        .proceed,
        "text action runtime preflight route allows normal conversion"
    )
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false
        ),
        .skip(reason: "manual conversion disabled"),
        "text action runtime preflight route keeps manual-conversion setting in route phase"
    )
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .selectedTextSearch,
            isEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false
        ),
        .skip(reason: "selected text search already in progress"),
        "text action runtime preflight route blocks nested selected-text search"
    )
    try expect(
        TextActionRuntimePreflightPolicy.securityAction(
            kind: .selectedTextSearch,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "text action runtime preflight security gives secure input priority"
    )
    try expect(
        TextActionRuntimePreflightPolicy.securityAction(
            kind: .toggleCase,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "text action runtime preflight security blocks password fields"
    )
}

private func runPointerEventPolicyTests() throws {
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on left mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.rightMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on right mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.otherMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on other mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: 2),
        .ignore,
        "pointer event policy ignores mouse up"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: 10),
        .ignore,
        "pointer event policy ignores non-click events"
    )
}

private func runEventTapLifecyclePolicyTests() throws {
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: true,
            isDisabledByUserInput: false
        ),
        .reenableTap(reason: "tap disabled by timeout"),
        "event tap lifecycle policy re-enables tap disabled by timeout"
    )
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: false,
            isDisabledByUserInput: true
        ),
        .reenableTap(reason: "tap disabled by user input"),
        "event tap lifecycle policy re-enables tap disabled by user input"
    )
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: true,
            isDisabledByUserInput: true
        ),
        .reenableTap(reason: "tap disabled by timeout"),
        "event tap lifecycle policy gives timeout a stable priority"
    )
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: false,
            isDisabledByUserInput: false
        ),
        .ignore,
        "event tap lifecycle policy ignores ordinary events"
    )
}

private func runAccessibilityNotificationPolicyTests() throws {
    let now = Date(timeIntervalSince1970: 1_000)

    try expect(
        AccessibilityNotificationPolicy.observedNotifications,
        [
            AccessibilityNotificationPolicy.focusedUIElementChanged,
            AccessibilityNotificationPolicy.focusedWindowChanged,
            AccessibilityNotificationPolicy.mainWindowChanged,
            AccessibilityNotificationPolicy.windowCreated,
            AccessibilityNotificationPolicy.selectedTextChanged,
            AccessibilityNotificationPolicy.valueChanged
        ],
        "accessibility notification policy observes focus, main-window, window creation, selection, and value changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedUIElementChanged",
            observedBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXFocusedUIElementChanged"),
        "accessibility notification policy clears state on focused element changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXSelectedTextChanged",
            observedBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "text mutation notification is diagnostic"),
        "accessibility notification policy keeps typed tracking on noisy selection changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXMainWindowChanged",
            observedBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXMainWindowChanged"),
        "accessibility notification policy clears state when the main window changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXWindowCreated",
            observedBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXWindowCreated"),
        "accessibility notification policy clears state when a new window is created"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXValueChanged",
            observedBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "text mutation notification is diagnostic"),
        "accessibility notification policy observes but does not clear on ordinary value changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            observedBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: now.addingTimeInterval(0.1),
            isConversionInProgress: false
        ),
        .ignore(reason: "replacement grace window"),
        "accessibility notification policy suppresses replacement-window notifications"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            observedBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: now,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXFocusedWindowChanged"),
        "accessibility notification policy clears after replacement grace window expires"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            observedBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: true
        ),
        .ignore(reason: "conversion in progress"),
        "accessibility notification policy suppresses in-flight conversions"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            observedBundleID: " COM.Example.Punto ",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "own application"),
        "accessibility notification policy ignores Punto's own windows"
    )
    try expect(
        ConversionProtectionPolicy.eventRecaptureIgnoreDeadline(now: now),
        now.addingTimeInterval(ConversionProtectionPolicy.eventRecaptureProtectionDelay),
        "conversion protection policy shares replacement grace interval with accessibility notifications"
    )
}

private func runTextTrackingSecurityPolicyTests() throws {
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: false, isPasswordField: false),
        true,
        "text tracking security allows normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: true, isPasswordField: false),
        false,
        "text tracking security blocks secure input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: false, isPasswordField: true),
        false,
        "text tracking security blocks password fields"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: true, isPasswordField: true),
        false,
        "text tracking security blocks combined secure password context"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: false, isPasswordField: false),
        false,
        "text tracking security keeps state for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: true, isPasswordField: false),
        true,
        "text tracking security clears state for secure input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: false, isPasswordField: true),
        true,
        "text tracking security clears state for password fields"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: true, isPasswordField: true),
        true,
        "text tracking security clears state for combined secure password context"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: false, isPasswordField: false),
        false,
        "text tracking security skips secure diagnostics for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: true, isPasswordField: false),
        true,
        "text tracking security writes secure diagnostics when secure input blocks tracking"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: false, isPasswordField: true),
        true,
        "text tracking security writes secure diagnostics when password fields block tracking"
    )
    try expectNil(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: false, isPasswordField: false),
        "text tracking security omits secure diagnostics context for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: true, isPasswordField: false),
        "secure input",
        "text tracking security reports secure-input diagnostics context"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: false, isPasswordField: true),
        "password field",
        "text tracking security reports password-field diagnostics context"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: true, isPasswordField: true),
        "secure input",
        "text tracking security gives secure input diagnostics priority over password field"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: false, isPasswordField: false),
        TextTrackingSecurityClearAction(clearTrackedText: false, clearConversionSession: false),
        "text tracking security keeps state for normal clear action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: true, isPasswordField: false),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "secure input",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security owns secure-input state cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: false, isPasswordField: true),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "password field",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security owns password-field state cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: true, isPasswordField: true),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "secure input",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security gives secure input priority in combined cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: "AXSecureTextField"),
        true,
        "text tracking security detects secure text subrole"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXSecureTextField", subrole: nil),
        true,
        "text tracking security detects secure text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: " axsecuretextfield ", subrole: nil),
        true,
        "text tracking security normalizes secure text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: " AX Secure Text Field ", subrole: nil),
        true,
        "text tracking security shares AX role normalization with accessibility role policy"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: "AXPasswordTextField"),
        true,
        "text tracking security detects password-like subrole"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: nil),
        false,
        "text tracking security allows ordinary text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXWebArea", subrole: "AXSearchField"),
        false,
        "text tracking security allows ordinary web/search text roles"
    )

    let diagnosticsSnapshot = SecureInputDiagnosticsPolicy.snapshot(
        secureInputState: true,
        context: " secure text input ",
        currentApp: " COM.Apple.Terminal ",
        runningApps: ["com.apple.Terminal", "COM.APPLE.TERMINAL", nil, " "],
        enabledLayouts: ["com.apple.keylayout.ABC", "UNDEFINED", " com.apple.keylayout.Russian "]
    )
    try expect(
        diagnosticsSnapshot,
        SecureInputDiagnosticsSnapshot(
            secureInputState: true,
            context: "secure text input",
            currentApp: "com.apple.terminal",
            runningApps: ["com.apple.terminal"],
            enabledLayouts: ["com.apple.keylayout.ABC", "com.apple.keylayout.Russian"]
        ),
        "secure input diagnostics policy normalizes Punto Switcher-style plist fields"
    )
    let diagnosticsDictionary = SecureInputDiagnosticsPolicy.plistDictionary(from: diagnosticsSnapshot)
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.secureInputStateKey] as? Bool,
        true,
        "secure input diagnostics writes SecureInputState key"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.contextKey] as? String,
        "secure text input",
        "secure input diagnostics writes Context key"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.currentAppKey] as? String,
        "com.apple.terminal",
        "secure input diagnostics writes currentApp key"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.runningAppsKey] as? [String],
        ["com.apple.terminal"],
        "secure input diagnostics writes runningApps key"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.enabledLayoutsKey] as? [String],
        ["com.apple.keylayout.ABC", "com.apple.keylayout.Russian"],
        "secure input diagnostics writes enabledLayouts key"
    )
}

private func runAccessibilityRolePolicyTests() throws {
    try expect(
        AccessibilityRolePolicy.normalizedRole(" ax web area "),
        "axwebarea",
        "accessibility role policy normalizes whitespace and case"
    )
    try expectNil(
        AccessibilityRolePolicy.normalizedRole("   "),
        "accessibility role policy rejects blank role"
    )
    try expect(
        AccessibilityRolePolicy.isWebAreaRole("AXWebArea"),
        true,
        "accessibility role policy detects AXWebArea"
    )
    try expect(
        AccessibilityRolePolicy.containsWebAreaRole(["AXStaticText", "AXGroup", "AXWebArea"]),
        true,
        "accessibility role policy detects AXWebArea ancestry"
    )
    try expect(
        AccessibilityRolePolicy.containsWebAreaRole(["AXStaticText", "AXGroup", "AXWindow"]),
        false,
        "accessibility role policy rejects static ancestry without AXWebArea"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityMailReplacement.fullWordReplacementSelector,
        "applyMailBehaviourForFullWords:withEvent:withCharsToSelect:withForceWordEndingCharPresent:",
        "accessibility role policy pins observed Punto Switcher Mail full-word helper selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityMailReplacement.partialWordReplacementSelector,
        "applyMailBehaviourForPartialWords:",
        "accessibility role policy pins observed Punto Switcher Mail partial-word helper selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityMailReplacement.deletionCounterKey,
        "numberOfDeletionsInMail",
        "accessibility role policy pins observed Punto Switcher Mail deletion counter"
    )
    try expect(
        AccessibilityRolePolicy.observedMailApplicationToken,
        "Mail",
        "accessibility role policy pins observed Punto Switcher Mail app token"
    )
    try expect(
        AccessibilityRolePolicy.observedParallelsBundleID,
        "com.parallels.desktop",
        "accessibility role policy pins observed Punto Switcher Parallels bundle id"
    )
    try expect(
        AccessibilityRolePolicy.observedScrollAreaRole,
        "AXScrollArea",
        "accessibility role policy pins observed Punto Switcher scroll-area role"
    )
    try expect(
        AccessibilityRolePolicy.isObservedClipboardReplaceableContentRole("AXScrollArea"),
        true,
        "accessibility role policy mirrors observed Punto Switcher AXScrollArea content surface"
    )
    try expect(
        AccessibilityRolePolicy.containsObservedClipboardReplaceableContentRole(["AXStaticText", "AXScrollArea"]),
        true,
        "accessibility role policy detects observed clipboard-replaceable content ancestry"
    )
    try expect(
        AccessibilityRolePolicy.containsObservedClipboardReplaceableContentRole(["AXStaticText", "AXGroup"]),
        false,
        "accessibility role policy rejects generic content ancestry for active clipboard replacement"
    )
    for role in ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"] {
        try expect(
            AccessibilityRolePolicy.isEditableTextRole(role),
            true,
            "accessibility role policy treats \(role) as editable text"
        )
    }
    for role in ["AXStaticText", "AXList", "AXTable", "AXButton", "AXWindow", "AXScrollArea"] {
        try expect(
            AccessibilityRolePolicy.isNonEditableContentRole(role),
            true,
            "accessibility role policy treats \(role) as non-editable content"
        )
    }
    try expect(
        AccessibilityRolePolicy.isEditableTextRole("AXStaticText"),
        false,
        "accessibility role policy does not treat static text as editable"
    )
    try expect(
        AccessibilityRolePolicy.isNonEditableContentRole("AXTextArea"),
        false,
        "accessibility role policy does not treat text area as non-editable content"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXTextArea",
            axEditable: true,
            selectedTextSettable: false
        ),
        true,
        "accessibility role policy accepts editable text area replacement"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXComboBox",
            axEditable: false,
            selectedTextSettable: true
        ),
        true,
        "accessibility role policy accepts settable editable-role replacement"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: nil,
            axEditable: nil,
            selectedTextSettable: true
        ),
        true,
        "accessibility role policy preserves settable replacement for unknown roles"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXStaticText",
            axEditable: true,
            selectedTextSettable: true
        ),
        false,
        "accessibility role policy blocks direct replacement for static content role"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXList",
            axEditable: false,
            selectedTextSettable: true
        ),
        false,
        "accessibility role policy blocks direct replacement for navigation/list role"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXScrollArea",
            axEditable: true,
            selectedTextSettable: true
        ),
        false,
        "accessibility role policy blocks direct replacement for observed AXScrollArea content"
    )
    let editableTextAreaCapability = AccessibilityReplacementCapability(
        role: "AXTextArea",
        axEditable: true,
        selectedTextSettable: false,
        selectedTextSettableErrorCode: -25205
    )
    try expect(
        editableTextAreaCapability.supportsDirectSelectedTextReplacement,
        true,
        "accessibility replacement capability accepts editable text area evidence"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(editableTextAreaCapability),
        true,
        "accessibility role policy accepts typed replacement capability evidence"
    )
    try expect(
        editableTextAreaCapability.logDescription,
        "role=AXTextArea axEditable=true selectedTextSettable=false settableError=-25205",
        "accessibility replacement capability preserves AX evidence for diagnostics"
    )
    let staticContentCapability = AccessibilityReplacementCapability(
        role: "AXStaticText",
        axEditable: true,
        selectedTextSettable: true,
        selectedTextSettableErrorCode: 0
    )
    try expect(
        staticContentCapability.supportsDirectSelectedTextReplacement,
        false,
        "accessibility replacement capability blocks static content despite optimistic AX flags"
    )
    let unknownSettableCapability = AccessibilityReplacementCapability(
        role: nil,
        axEditable: nil,
        selectedTextSettable: true,
        selectedTextSettableErrorCode: 0
    )
    try expect(
        unknownSettableCapability.supportsDirectSelectedTextReplacement,
        true,
        "accessibility replacement capability preserves settable unknown-role support"
    )
    try expect(
        AccessibilityRolePolicy.isObservedSearchExceptionRole(
            role: "AXTextField",
            bundleID: nil,
            context: .searchbar
        ),
        true,
        "accessibility role policy mirrors global searchbar editable-role exception"
    )
    try expect(
        AccessibilityRolePolicy.isObservedSearchExceptionRole(
            role: "AXApplication",
            bundleID: nil,
            context: .searchbar
        ),
        true,
        "accessibility role policy mirrors AXApplication searchbar-only exception"
    )
    try expect(
        AccessibilityRolePolicy.isObservedSearchExceptionRole(
            role: "AXApplication",
            bundleID: nil,
            context: .click
        ),
        false,
        "accessibility role policy keeps AXApplication out of click exceptions"
    )
    try expect(
        AccessibilityRolePolicy.isObservedSearchExceptionRole(
            role: "AXGroup",
            bundleID: "com.apple.finder",
            context: .click
        ),
        true,
        "accessibility role policy mirrors Finder click group exception"
    )
    try expect(
        AccessibilityRolePolicy.isObservedSearchExceptionRole(
            role: "AXGroup",
            bundleID: "com.apple.finder",
            context: .searchbar
        ),
        false,
        "accessibility role policy keeps Finder group click-only exception scoped"
    )
    try expect(
        AccessibilityRolePolicy.isObservedSearchExceptionRole(
            role: "AXMenuItem",
            bundleID: "ORG.MOZILLA.FIREFOX",
            context: .click
        ),
        true,
        "accessibility role policy normalizes app-specific search exception bundle ids"
    )
    try expect(
        AccessibilityRolePolicy.isObservedSearchExceptionRole(
            role: "AXGroup",
            bundleID: "com.example.Editor",
            context: .click
        ),
        false,
        "accessibility role policy rejects app-specific roles outside observed apps"
    )
    try expect(
        Set(AccessibilityRolePolicy.observedSearchbarExceptionRoles.keys),
        [
            "*",
            "com.adobe.acc.AdobeCreativeCloud",
            "com.apple.ActivityMonitor",
            "com.apple.Aperture",
            "com.apple.DiskImageMounter",
            "com.apple.FinalCut",
            "com.apple.Notes",
            "com.apple.Photos",
            "com.apple.Preview",
            "com.apple.RemoteDesktop",
            "com.apple.ScreenSharing",
            "com.apple.SystemProfiler",
            "com.apple.dock",
            "com.apple.dt.Xcode",
            "com.apple.finder",
            "com.apple.garageband10",
            "com.apple.iCal",
            "com.apple.iTunes",
            "com.apple.iWork.Keynote",
            "com.apple.iWork.Numbers",
            "com.apple.iWork.Pages",
            "com.apple.logic10",
            "com.apple.loginwindow",
            "com.apple.mail",
            "com.apple.reminders",
            "com.apple.storeuid",
            "com.apple.talagent",
            "com.aspyr",
            "com.bittorrent.uTorrent",
            "com.blizzard",
            "com.bohemiancoding.sketch3",
            "com.google.chrome",
            "com.microsoft",
            "com.mojang",
            "com.parallels.desktop",
            "com.teamviewer.TeamViewer",
            "com.wunderkinder.wunderlistdesktop",
            "it.bloop.airmail",
            "it.bloop.airmail2",
            "org.chromium.chromium",
            "org.mozilla.firefox",
            "org.telegram.desktop",
            "ru.keepcoder.Telegram",
            "ru.yandex.desktop.yandex-browser"
        ],
        "accessibility role policy preserves full observed searchbar exception key set"
    )
    try expect(
        Set(AccessibilityRolePolicy.observedClickExceptionRoles.keys),
        [
            "*",
            "com.adobe.acc.AdobeCreativeCloud",
            "com.apple.ActivityMonitor",
            "com.apple.Aperture",
            "com.apple.DiskImageMounter",
            "com.apple.DiskUtility",
            "com.apple.FinalCut",
            "com.apple.Notes",
            "com.apple.Photos",
            "com.apple.Preview",
            "com.apple.RemoteDesktop",
            "com.apple.ScreenSharing",
            "com.apple.SystemProfiler",
            "com.apple.dock",
            "com.apple.dt.Xcode",
            "com.apple.finder",
            "com.apple.garageband10",
            "com.apple.iCal",
            "com.apple.iTunes",
            "com.apple.iWork.Keynote",
            "com.apple.iWork.Numbers",
            "com.apple.iWork.Pages",
            "com.apple.logic10",
            "com.apple.loginwindow",
            "com.apple.mail",
            "com.apple.reminders",
            "com.apple.storeuid",
            "com.apple.talagent",
            "com.bittorrent.uTorrent",
            "com.bohemiancoding.sketch3",
            "com.google.chrome",
            "com.microsoft",
            "com.parallels.desktop",
            "com.teamviewer.TeamViewer",
            "com.wunderkinder.wunderlistdesktop",
            "it.bloop.airmail",
            "it.bloop.airmail2",
            "org.chromium.chromium",
            "org.mozilla.firefox",
            "org.telegram.desktop",
            "ru.keepcoder.Telegram",
            "ru.yandex.desktop.yandex-browser"
        ],
        "accessibility role policy preserves full observed click exception key set"
    )
    try expect(
        AccessibilityRolePolicy.observedSearchbarExceptionRoles["*"],
        ["AXTextField", "AXTextArea", "AXComboBox", "AXWindow", "AXUnknown", "AXStaticText", "AXPopUpButton", "AXApplication"],
        "accessibility role policy preserves observed global searchbar roles"
    )
    try expect(
        AccessibilityRolePolicy.observedClickExceptionRoles["*"],
        ["AXTextField", "AXTextArea", "AXComboBox", "AXWindow", "AXUnknown", "AXStaticText", "AXPopUpButton"],
        "accessibility role policy preserves observed global click roles"
    )
    try expect(
        AccessibilityRolePolicy.observedSearchbarExceptionRoles["com.apple.finder"],
        ["AXList", "AXOutline", "AXGrid", "AXImage"],
        "accessibility role policy preserves Finder searchbar exception roles"
    )
    try expect(
        AccessibilityRolePolicy.observedClickExceptionRoles["com.apple.finder"],
        ["AXList", "AXOutline", "AXGrid", "AXImage", "AXGroup"],
        "accessibility role policy preserves Finder click exception roles"
    )
    try expect(
        AccessibilityRolePolicy.observedSearchbarExceptionRoles["com.apple.Preview"],
        [],
        "accessibility role policy preserves explicit empty observed app searchbar exception"
    )
    try expect(
        AccessibilityRolePolicy.observedClickExceptionRoles["com.apple.DiskUtility"],
        [],
        "accessibility role policy preserves explicit empty observed app click exception"
    )
}

private func runAccessibilityTraversalPolicyTests() throws {
    try expect(
        AccessibilityTraversalPolicy.maxDescendantSearchDepth,
        5,
        "accessibility traversal policy keeps recursive descendant search bounded"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 0),
        true,
        "accessibility traversal policy inspects root depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 4),
        true,
        "accessibility traversal policy inspects final descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 5),
        false,
        "accessibility traversal policy stops after max descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: -1),
        false,
        "accessibility traversal policy rejects negative descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.maxAncestorRoleDepth,
        5,
        "accessibility traversal policy keeps ancestor role collection bounded"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldCollectAncestorRole(atDepth: 5),
        true,
        "accessibility traversal policy includes final ancestor role depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldCollectAncestorRole(atDepth: 6),
        false,
        "accessibility traversal policy stops ancestor role collection after max depth"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .empty),
        true,
        "accessibility selection search continues after empty wrapper selection"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .failed),
        true,
        "accessibility selection search continues after failed wrapper selection"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .text),
        false,
        "accessibility selection search stops after text is found"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .noFocus),
        false,
        "accessibility selection search stops when no focused element exists"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(false, after: .empty),
        true,
        "accessibility selection search records empty selection probes"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(true, after: .failed),
        true,
        "accessibility selection search preserves previous empty probes through failures"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(false, after: .failed),
        false,
        "accessibility selection search does not invent empty state from unsupported AX probes"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.finalOutcomeAfterSearch(sawEmptySelection: true),
        .empty,
        "accessibility selection search preserves empty selection after alternatives are exhausted"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.finalOutcomeAfterSearch(sawEmptySelection: false),
        .failed,
        "accessibility selection search falls back to failed when no AX source answered"
    )
}

private func runKeyboardReplacementPolicyTests() throws {
    try expect(
        KeyboardEventKeyCodePolicy.pasteKeyCode,
        9,
        "keyboard event key code policy uses V key for paste"
    )
    try expect(
        KeyboardEventKeyCodePolicy.backspaceKeyCode,
        51,
        "keyboard event key code policy uses Backspace for exact tail deletion"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftArrowKeyCode,
        123,
        "keyboard event key code policy uses Left Arrow for reselection"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftCommandKeyCode,
        55,
        "keyboard event key code policy exposes left Command for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightCommandKeyCode,
        54,
        "keyboard event key code policy exposes right Command for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftShiftKeyCode,
        56,
        "keyboard event key code policy exposes left Shift for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightShiftKeyCode,
        60,
        "keyboard event key code policy exposes right Shift for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftOptionKeyCode,
        58,
        "keyboard event key code policy exposes left Option for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightOptionKeyCode,
        61,
        "keyboard event key code policy exposes right Option for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftControlKeyCode,
        59,
        "keyboard event key code policy exposes left Control for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightControlKeyCode,
        62,
        "keyboard event key code policy exposes right Control for modifier cleanup"
    )
    try expect(
        KeyDownEventPolicy.copyKeyCode,
        KeyboardEventKeyCodePolicy.copyKeyCode,
        "key down policy shares copy key code policy"
    )
    try expect(
        KeyDownEventPolicy.pasteKeyCode,
        KeyboardEventKeyCodePolicy.pasteKeyCode,
        "key down policy shares paste key code policy"
    )
    try expect(
        KeyDownEventPolicy.deleteKeyCode,
        KeyboardEventKeyCodePolicy.backspaceKeyCode,
        "key down policy shares backspace key code policy"
    )
    try expect(
        WordTrackingPolicy.deleteKeyCode,
        KeyboardEventKeyCodePolicy.backspaceKeyCode,
        "word tracking policy shares backspace key code policy"
    )
    try expect(
        KeyboardEventTimingPolicy.selectionSettleDelay,
        0.02,
        "keyboard event timing policy keeps selection settle delay"
    )
    try expect(
        KeyboardEventTimingPolicy.commandKeyUpDelay,
        0.02,
        "keyboard event timing policy keeps command key-up delay"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldSelectAfterPaste(true, replacementText: "hello"),
        true,
        "selected-text clipboard replacement reselects non-empty pasted text when requested"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldSelectAfterPaste(false, replacementText: "hello"),
        false,
        "selected-text clipboard replacement skips reselection when not requested"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldSelectAfterPaste(true, replacementText: ""),
        false,
        "selected-text clipboard replacement skips reselection for empty text"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 7, replacementChangeCount: 7),
        true,
        "selected-text clipboard replacement restores unchanged replacement clipboard"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 8, replacementChangeCount: 7),
        false,
        "selected-text clipboard replacement preserves externally changed clipboard"
    )
    try expect(
        ClipboardReplacementPolicy.shouldRestoreClipboardAfterReplacementPaste(
            currentChangeCount: 11,
            replacementChangeCount: 11
        ),
        true,
        "shared clipboard replacement policy restores only while replacement paste remains current"
    )
    try expect(
        ClipboardReplacementPolicy.shouldRestoreClipboardAfterReplacementPaste(
            currentChangeCount: 12,
            replacementChangeCount: 11
        ),
        false,
        "shared clipboard replacement policy preserves externally changed clipboard"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.postPasteDelay,
        0.03,
        "selected-text clipboard replacement preserves post-paste delay"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.selectAfterPasteDelay,
        0.02,
        "selected-text clipboard replacement preserves selection delay"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.clipboardRestoreDelay,
        ClipboardReplacementPolicy.clipboardRestoreDelay,
        "selected-text clipboard replacement shares clipboard restore delay"
    )
    try expect(
        KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: 1),
        true,
        "keyboard replacement attempts positive delete length"
    )
    try expect(
        KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: 0),
        false,
        "keyboard replacement rejects zero delete length before events"
    )
    try expect(
        KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: -1),
        false,
        "keyboard replacement rejects negative delete length before events"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: 6, sentCount: 6),
        true,
        "keyboard replacement proceeds after complete backspace sequence"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: 6, sentCount: 5),
        false,
        "keyboard replacement aborts after partial backspace sequence"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: 0, sentCount: 0),
        false,
        "keyboard replacement rejects zero-length delete before paste"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: -1, sentCount: -1),
        false,
        "keyboard replacement rejects invalid negative counts"
    )
    try expect(
        KeyboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 42, replacementChangeCount: 42),
        true,
        "keyboard replacement restores clipboard when replacement remains current"
    )
    try expect(
        KeyboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 43, replacementChangeCount: 42),
        false,
        "keyboard replacement keeps clipboard when another app changed it after paste"
    )
    try expect(
        KeyboardReplacementPolicy.modifierReleaseSettleDelay,
        0.05,
        "keyboard replacement preserves modifier release settle delay"
    )
    try expect(
        KeyboardReplacementPolicy.modifierReleaseMaxWait,
        0.35,
        "keyboard replacement waits briefly for real HID modifier release before destructive keys"
    )
    try expect(
        KeyboardReplacementPolicy.modifierReleasePollInterval,
        0.01,
        "keyboard replacement polls modifier release at short intervals"
    )
    try expect(
        KeyboardReplacementPolicy.shouldStartKeyboardEventsAfterModifierWait(modifiersArePressed: false),
        true,
        "keyboard replacement starts destructive events when modifiers are released"
    )
    try expect(
        KeyboardReplacementPolicy.shouldStartKeyboardEventsAfterModifierWait(modifiersArePressed: true),
        false,
        "keyboard replacement refuses destructive events while modifiers remain pressed"
    )
    try expect(
        KeyboardModifierCleanupPolicy.shouldPostCleanup(
            for: ModifierFlagsSnapshot(command: false, option: false, shift: false, control: false)
        ),
        false,
        "keyboard modifier cleanup skips empty modifier state"
    )
    try expect(
        KeyboardModifierCleanupPolicy.keyUpCodes(
            for: ModifierFlagsSnapshot(command: true, option: false, shift: false, control: false)
        ),
        [
            KeyboardEventKeyCodePolicy.leftCommandKeyCode,
            KeyboardEventKeyCodePolicy.rightCommandKeyCode
        ],
        "keyboard modifier cleanup releases both Command keys for a latched Command flag"
    )
    try expect(
        KeyboardModifierCleanupPolicy.keyUpCodes(
            for: ModifierFlagsSnapshot(command: false, option: true, shift: true, control: true)
        ),
        [
            KeyboardEventKeyCodePolicy.leftOptionKeyCode,
            KeyboardEventKeyCodePolicy.rightOptionKeyCode,
            KeyboardEventKeyCodePolicy.leftShiftKeyCode,
            KeyboardEventKeyCodePolicy.rightShiftKeyCode,
            KeyboardEventKeyCodePolicy.leftControlKeyCode,
            KeyboardEventKeyCodePolicy.rightControlKeyCode
        ],
        "keyboard modifier cleanup releases all latched non-command modifier sides in stable order"
    )
    try expect(
        KeyboardReplacementPolicy.backspaceInterval,
        0.02,
        "keyboard replacement preserves backspace interval"
    )
    try expect(
        KeyboardReplacementPolicy.prePasteDelay,
        0.02,
        "keyboard replacement preserves pre-paste delay"
    )
    try expect(
        KeyboardReplacementPolicy.postPasteDelay,
        0.03,
        "keyboard replacement preserves post-paste delay"
    )
    try expect(
        KeyboardReplacementPolicy.clipboardRestoreDelay,
        ClipboardReplacementPolicy.clipboardRestoreDelay,
        "keyboard replacement shares async clipboard restore delay"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "TextEdit",
                role: "AXTextArea",
                isEnabled: true,
                isFocused: true
            )
        ),
        true,
        "keyboard focus policy accepts typed enabled focused target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "Ghostty",
                role: "AXTextArea",
                isEnabled: true,
                isFocused: false
            )
        ),
        true,
        "keyboard focus policy allows typed enabled target with unreliable focused flag"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "TextEdit",
                role: "AXTextArea",
                isEnabled: false,
                isFocused: true
            )
        ),
        false,
        "keyboard focus policy rejects typed disabled target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "Finder",
                role: "AXButton",
                isEnabled: true,
                isFocused: true
            )
        ),
        false,
        "keyboard focus policy rejects typed non-editable focused role"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "UnknownApp",
                role: nil,
                isEnabled: true,
                isFocused: true
            )
        ),
        true,
        "keyboard focus policy keeps unknown roles eligible"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .noFocusedElement(appName: "TextEdit", errorCode: -25205)
        ),
        false,
        "keyboard focus policy rejects typed missing focused element"
    )
    try expect(
        KeyboardFocusEvidence.focusedElement(
            appName: "TextEdit",
            role: "AXTextArea",
            isEnabled: true,
            isFocused: false
        ).logDescription,
        "app='TextEdit' role='AXTextArea' enabled=true focused=false",
        "keyboard focus evidence preserves legacy log shape"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' role='AXTextArea' enabled=true focused=true"
        ),
        true,
        "keyboard focus policy accepts enabled focused target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='Ghostty' role='AXTextArea' enabled=true focused=false"
        ),
        true,
        "keyboard focus policy allows enabled target with unreliable focused flag"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' role='AXTextArea' enabled=false focused=true"
        ),
        false,
        "keyboard focus policy rejects disabled target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='Finder' role='AXButton' enabled=true focused=true"
        ),
        false,
        "keyboard focus policy rejects non-editable focused role"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='UnknownApp' role='?' enabled=true focused=true"
        ),
        true,
        "keyboard focus policy preserves unknown string role eligibility"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' NO_FOCUSED_ELEMENT (error=-25205)"
        ),
        false,
        "keyboard focus policy rejects missing focused element"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(focusDescription: "  "),
        false,
        "keyboard focus policy rejects empty focus evidence"
    )
}

private func runTextReplacementPolicyTests() throws {
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .keyboardBackspacePaste),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "failed keyboard replacement",
            clearConversionSessionReason: "failed keyboard replacement"
        ),
        "replacement failure action clears tracked text and undo after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "failed keyboard replacement",
            clearConversionSessionReason: "failed keyboard replacement"
        ),
        "replacement failure action clears tracked text and undo after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .accessibilitySelection),
        ReplacementFailureAction(clearTrackedText: false, clearConversionSession: false),
        "replacement failure action preserves state after failed AX replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .blocked),
        ReplacementFailureAction(clearTrackedText: false, clearConversionSession: false),
        "replacement failure action ignores blocked plans"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardBackspacePaste),
        true,
        "replacement failure policy clears tracked text after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        true,
        "replacement failure policy clears tracked text after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .accessibilitySelection),
        false,
        "replacement failure policy keeps tracked text after failed AX selection replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .blocked),
        false,
        "replacement failure policy ignores blocked replacement plans"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .keyboardBackspacePaste),
        true,
        "replacement failure policy clears undo session after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        true,
        "replacement failure policy clears undo session after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .accessibilitySelection),
        false,
        "replacement failure policy keeps undo session after failed AX selection replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .blocked),
        false,
        "replacement failure policy keeps undo session for blocked plans"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            replacement: "привет",
            keepSelection: true
        ),
        .accessibilitySelection(text: "привет", keepSelection: true),
        "replacement policy keeps AX selection replacement as AX plan"
    )
    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "browser selection",
                replacementMethod: .accessibilitySelection,
                source: "active clipboard fallback",
                selectedTextReplacementTransport: .clipboard
            ),
            replacement: "браузер",
            keepSelection: true
        ),
        .clipboardSelection(text: "браузер", selectAfterPaste: true),
        "replacement policy routes clipboard selected-text capture directly to clipboard plan"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "hello",
                replacementMethod: .keyboardBackspacePaste,
                source: "passive clipboard tail selection"
            ),
            replacement: "привет",
            keepSelection: true
        ),
        .keyboardBackspacePaste(deleteLength: 5, text: "привет"),
        "replacement policy uses captured length for keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "",
                replacementMethod: .keyboardBackspacePaste,
                source: "empty keyboard capture"
            ),
            replacement: "привет",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks empty keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "commit",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "AX non-settable command-tail selection"
            ),
            replacement: "COMMIT",
            keepSelection: false
        ),
        .keyboardBackspacePaste(deleteLength: 10, text: "git COMMIT"),
        "replacement policy rewrites full terminal tail before keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "missing",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "stale tail"
            ),
            replacement: "MISSING",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks unrewritable terminal tail"
    )
    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "mit",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "stale tail"
            ),
            replacement: "ьше",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks partial-word terminal tail replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(text: "", replacementMethod: .blocked, source: "blocked"),
            replacement: "ignored",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks unsafe capture"
    )
}

private func runAccessibilityReplacementPolicyTests() throws {
    try expect(
        AccessibilityReplacementPolicy.selectedTextVerificationDelay,
        0.05,
        "AX replacement policy keeps selected text verification delay"
    )
    try expect(
        AccessibilityReplacementPolicy.focusedApplicationRetryAttempts,
        3,
        "AX replacement policy keeps focused application retry attempts"
    )
    try expect(
        AccessibilityReplacementPolicy.focusedApplicationRetryDelay,
        0.05,
        "AX replacement policy keeps focused application retry delay"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: false,
            originalSelectedText: "hello",
            observedSelectedText: "руддщ",
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects failed set call"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "hello",
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects silent no-op"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "руддщ",
            replacement: "руддщ"
        ),
        true,
        "AX replacement policy accepts observed replacement"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: nil,
            replacement: "руддщ"
        ),
        true,
        "AX replacement policy accepts deselected changed state"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: nil,
            observedSelectedText: nil,
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects success without before or after text evidence"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "hello",
            replacement: "hello"
        ),
        true,
        "AX replacement policy accepts idempotent replacement"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 1),
        true,
        "AX replacement policy retries before final focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 2),
        true,
        "AX replacement policy retries on penultimate focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 3),
        false,
        "AX replacement policy does not sleep after final focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldReadOriginalSelectionRange(keepSelection: true),
        true,
        "AX replacement policy reads original selection range only when selection should be retained"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldReadOriginalSelectionRange(keepSelection: false),
        false,
        "AX replacement policy skips original selection range when selection retention is not needed"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: 5),
        4,
        "AX replacement policy accepts valid original selection range location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: 0),
        4,
        "AX replacement policy accepts collapsed valid selection range location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: -1, length: 5),
        nil,
        "AX replacement policy rejects negative original selection location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: -1),
        nil,
        "AX replacement policy rejects negative original selection length"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "руддщ",
            keepSelection: true
        ),
        AccessibilityReplacementPolicy.SelectionRange(location: 4, length: 5),
        "AX replacement policy reselects replacement at original selection location"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "a😀",
            keepSelection: true
        ),
        AccessibilityReplacementPolicy.SelectionRange(location: 4, length: 3),
        "AX replacement policy uses UTF-16 length for AX selection range"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: nil,
            replacement: "руддщ",
            keepSelection: true
        ),
        nil,
        "AX replacement policy does not guess a selection location when AX range is unavailable"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "руддщ",
            keepSelection: false
        ),
        nil,
        "AX replacement policy skips reselection when selection retention is disabled"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: -1,
            replacement: "руддщ",
            keepSelection: true
        ),
        nil,
        "AX replacement policy rejects invalid negative selection locations"
    )
}

private func runHotkeyPolicyTests() throws {
    try expect(Hotkey.defaultConvertLayout.isModifierOnly, true, "default convert hotkey is modifier-only")
    try expect(Hotkey.defaultConvertLayout.displayString, "\u{2325}\u{21E7}\u{2318}", "default convert hotkey display")
    try expect(Hotkey.defaultToggleCase.displayString, "\u{2325}\u{2318}Z", "default toggle-case hotkey display")
    try expect(Hotkey.defaultToggleAutoCorrection.displayString, "\u{2325}\u{2318}A", "default toggle-auto-correction hotkey display")
    try expect(Hotkey.defaultCancelLayoutChange.displayString, "\u{2325}\u{2318}Delete", "default cancel-layout-change hotkey display")
    try expect(Hotkey.defaultFindInYandex.displayString, "Not Set", "default find-in-Yandex hotkey is unassigned")
    try expect(Hotkey.defaultFindInSlovari.displayString, "Not Set", "default find-in-Slovari hotkey is unassigned")
    try expect(KeyCodeNames.name(for: 49), "Space", "key code name lookup")
    try expectNil(KeyCodeNames.name(for: UInt16.max), "modifier-only key has no key name")

    let encoded = try JSONEncoder().encode(Hotkey.defaultConvertLayout)
    let decoded = try JSONDecoder().decode(Hotkey.self, from: encoded)
    try expect(decoded, Hotkey.defaultConvertLayout, "hotkey codable round-trip")
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey.defaultConvertLayout),
        true,
        "hotkey validation accepts default modifier-only convert hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey.defaultToggleCase),
        true,
        "hotkey validation accepts default key-based toggle hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey.defaultToggleAutoCorrection),
        true,
        "hotkey validation accepts default key-based auto-correction toggle hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey.defaultCancelLayoutChange),
        true,
        "hotkey validation accepts default key-based cancel-layout-change hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedCharacterKeycode(0),
        true,
        "hotkey validation allows ordinary character keycodes"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedCharacterKeycode(55),
        false,
        "hotkey validation rejects modifier keycodes as raw characters"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedShortcutCharacterKeycode(0),
        true,
        "hotkey validation allows ordinary character shortcut keycodes"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedShortcutCharacterKeycode(51),
        true,
        "hotkey validation allows Delete as a shortcut keycode for cancel-layout-change"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedShortcutCharacterKeycode(55),
        false,
        "hotkey validation rejects modifier keycodes as shortcut characters"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedShortcutCharacterKeycode(57),
        false,
        "hotkey validation rejects Caps Lock as a shortcut character"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedShortcutCharacterKeycode(53),
        false,
        "hotkey validation rejects Escape because it cancels shortcut editing"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey(
            keyCode: 55,
            command: true,
            option: false,
            shift: false,
            control: false
        )),
        false,
        "hotkey validation rejects Command key as a key-based shortcut character"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey.disabled),
        true,
        "hotkey validation accepts explicitly disabled shortcuts"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey(
            keyCode: Hotkey.modifierOnlyKeyCode,
            command: true,
            option: false,
            shift: false,
            control: false
        )),
        false,
        "hotkey validation rejects single-modifier modifier-only hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey(
            keyCode: 0,
            command: false,
            option: false,
            shift: true,
            control: false
        )),
        false,
        "hotkey validation rejects shift-only key hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey(
            keyCode: 0,
            command: false,
            option: true,
            shift: false,
            control: false
        )),
        true,
        "hotkey validation accepts option-key shortcut"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey(
            keyCode: UInt16.max - 2,
            command: true,
            option: false,
            shift: false,
            control: false
        )),
        false,
        "hotkey validation rejects unknown key code"
    )
    try expect(
        HotkeyValidationPolicy.normalized(
            Hotkey(keyCode: 0, command: false, option: false, shift: false, control: false),
            fallback: Hotkey.defaultToggleCase
        ),
        Hotkey.defaultToggleCase,
        "hotkey validation falls back for plain key shortcut"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            "charKeycode": 6,
            "isCommandUsed": true,
            "isAltUsed": NSNumber(value: true),
            "isShiftUsed": false,
            "isControlUsed": false
        ]),
        Hotkey.defaultToggleCase,
        "legacy hotkey policy reads Punto Switcher shortcut dictionaries"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            "charKeycode": " 6 ",
            "isCommandUsed": "yes",
            "isAltUsed": "0",
            "isShiftUsed": "true",
            "isControlUsed": "off"
        ]),
        Hotkey(keyCode: 6, command: true, option: false, shift: true, control: false),
        "legacy hotkey policy reads string-backed shortcut dictionaries"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            "charKeycode": 666,
            "isCommandUsed": true,
            "isAltUsed": true,
            "isShiftUsed": true,
            "isControlUsed": false
        ]),
        Hotkey.defaultConvertLayout,
        "legacy hotkey policy maps Punto Switcher no-key shortcut to modifier-only hotkey"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            "charKeycode": 666,
            "isCommandUsed": false,
            "isAltUsed": false,
            "isShiftUsed": false,
            "isControlUsed": false
        ]),
        Hotkey.disabled,
        "legacy hotkey policy maps Punto Switcher no-key/no-modifier shortcut to disabled"
    )
    try expect(
        LegacyHotkeyPolicy.normalized([
            "charKeycode": 666,
            "isCommandUsed": true,
            "isAltUsed": false,
            "isShiftUsed": false,
            "isControlUsed": false
        ], fallback: Hotkey.defaultToggleCase),
        Hotkey.defaultToggleCase,
        "legacy hotkey policy normalizes invalid single-modifier shortcuts"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutChangeLayoutKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutChangeLayoutKey,
        "legacy hotkey policy keeps change-layout import key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutChangeCaseKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutChangeCaseKey,
        "legacy hotkey policy keeps change-case import key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutSwitchAutocorrectionKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutSwitchAutocorrectionKey,
        "legacy hotkey policy keeps switch-autocorrection import key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutCancelLayoutChangeKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutCancelLayoutChangeKey,
        "legacy hotkey policy keeps cancel-layout-change import key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutFindInYandexKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutFindInYandexKey,
        "legacy hotkey policy keeps find-in-Yandex import key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutFindInSlovariKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutFindInSlovariKey,
        "legacy hotkey policy keeps find-in-Slovari import key aligned with reverse-audit anchor"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutSelector,
        "setShortcut:",
        "legacy hotkey policy preserves observed generic shortcut setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.shortcutWithDictionarySelector,
        "shortcutWithDictionary:",
        "legacy hotkey policy preserves observed dictionary importer selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.resetShortcutsToDefaultsSelector,
        "resetShortcutsToDefaults:",
        "legacy hotkey policy preserves observed reset-shortcuts selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutChangeLayoutSelector,
        "setShortcutChangeLayout:",
        "legacy hotkey policy preserves observed change-layout setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutChangeCaseSelector,
        "setShortcutChangeCase:",
        "legacy hotkey policy preserves observed change-case setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutSwitchAutocorrectionSelector,
        "setShortcutSwitchAutocorrection:",
        "legacy hotkey policy preserves observed switch-autocorrection setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutCancelLayoutChangeSelector,
        "setShortcutCancelLayoutChange:",
        "legacy hotkey policy preserves observed cancel-layout-change setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutFindInYandexSelector,
        "setShortcutFindInYandex:",
        "legacy hotkey policy preserves observed find-in-Yandex setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutFindInSlovariSelector,
        "setShortcutFindInSlovari:",
        "legacy hotkey policy preserves observed find-in-Slovari setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.shortcutsPreferencesControllerKey,
        "shortcutsPreferencesController",
        "legacy hotkey policy preserves observed shortcuts preferences controller key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutsPreferencesControllerSelector,
        "setShortcutsPreferencesController:",
        "legacy hotkey policy preserves observed shortcuts preferences controller setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.switchAutocorrectionSelector,
        "switchAutocorrection:",
        "legacy hotkey policy preserves observed switch-autocorrection action selector"
    )
    try expect(
        LegacyHotkeyPolicy.legacyCancelLayoutChangeShortcutKey,
        PuntoSwitcherObservedSurface.Hotkeys.cancelLayoutChangeShortcutKey,
        "legacy hotkey policy keeps cancel-layout-change shortcut field key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacySwitchAutocorrectionShortcutKey,
        PuntoSwitcherObservedSurface.Hotkeys.switchAutocorrectionShortcutKey,
        "legacy hotkey policy keeps switch-autocorrection shortcut field key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyChangeCaseShortcutKey,
        PuntoSwitcherObservedSurface.Hotkeys.changeCaseShortcutKey,
        "legacy hotkey policy keeps change-case shortcut field key aligned with reverse-audit anchor"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setChangeCaseShortcutSelector,
        "setChangeCaseShortcut:",
        "legacy hotkey policy preserves observed change-case shortcut-field setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.shortcutFieldClassName,
        "ShortcutField",
        "legacy hotkey policy preserves observed shortcut-field class boundary"
    )

    try expect(
        PuntoSwitcherObservedSurface.HotkeyCollision.doesCollideSelector,
        "doesCollideWithExistingShortcuts",
        "hotkey collision policy preserves observed collision selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.HotkeyCollision.canAllowShortcutSelector,
        "shortcutField:canAllowShortcut:",
        "hotkey collision policy preserves observed shortcut-field selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.HotkeyCollision.emptyShortcutSelector,
        "emptyShortcut",
        "hotkey collision policy preserves observed empty-shortcut selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.HotkeyCollision.allowedCharacterKeycodeSelector,
        "isAllowedCharacterKeycode:",
        "hotkey collision policy preserves observed raw allowed-keycode selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.HotkeyCollision.allowedShortcutCharacterKeycodeSelector,
        "isAllowedShortcutCharacterKeycode:",
        "hotkey collision policy preserves observed shortcut allowed-keycode selector"
    )

    let assignments = [
        HotkeyAssignment(slot: .convertLayout, hotkey: Hotkey.defaultConvertLayout),
        HotkeyAssignment(slot: .toggleCase, hotkey: Hotkey.defaultToggleCase),
        HotkeyAssignment(slot: .toggleAutoCorrection, hotkey: Hotkey.defaultToggleAutoCorrection),
        HotkeyAssignment(slot: .cancelLayoutChange, hotkey: Hotkey.defaultCancelLayoutChange),
        HotkeyAssignment(slot: .findInYandex, hotkey: Hotkey.defaultFindInYandex),
        HotkeyAssignment(slot: .findInSlovari, hotkey: Hotkey.defaultFindInSlovari)
    ]
    try expect(
        HotkeyCollisionPolicy.collidingSlot(
            for: Hotkey.defaultToggleCase,
            in: assignments,
            excluding: .findInYandex
        ),
        .toggleCase,
        "hotkey collision policy reports the existing shortcut owner"
    )
    try expect(
        HotkeyCollisionPolicy.doesCollideWithExistingShortcuts(
            Hotkey.defaultToggleCase,
            in: assignments,
            excluding: .toggleCase
        ),
        false,
        "hotkey collision policy ignores the slot being edited"
    )
    try expect(
        HotkeyCollisionPolicy.canAllowShortcut(
            Hotkey(keyCode: 31, command: true, option: true, shift: false, control: false),
            in: assignments,
            excluding: .findInYandex
        ),
        true,
        "hotkey collision policy allows unique shortcuts"
    )
    try expect(
        HotkeyCollisionPolicy.canAllowShortcut(
            Hotkey.disabled,
            in: assignments,
            excluding: .findInYandex
        ),
        true,
        "hotkey collision policy allows multiple empty shortcuts"
    )
    try expect(
        HotkeyCollisionPolicy.canAllowShortcut(
            Hotkey.defaultConvertLayout,
            in: assignments,
            excluding: .findInSlovari
        ),
        false,
        "hotkey collision policy rejects duplicate modifier-only shortcuts"
    )

    let machine = ModifierOnlyHotkeyStateMachine(debounceInterval: 0.5)
    try expect(
        ModifierOnlyHotkeyStateMachine.actionDelay,
        0.15,
        "modifier-only hotkey action is delayed until real HID modifiers settle"
    )
    let hotkey = Hotkey.defaultConvertLayout
    let pressed = ModifierFlagsSnapshot(command: true, option: true, shift: true, control: false)
    let released = ModifierFlagsSnapshot(command: false, option: false, shift: false, control: false)
    let partial = ModifierFlagsSnapshot(command: true, option: true, shift: false, control: false)
    let extra = ModifierFlagsSnapshot(command: true, option: true, shift: true, control: true)
    let now = Date(timeIntervalSince1970: 100)

    try expect(machine.handleFlagsChanged(flags: pressed, hotkey: hotkey, now: now), false, "modifier-only press arms but does not trigger")
    try expect(machine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(0.1)), true, "modifier-only release triggers")

    try expect(machine.handleFlagsChanged(flags: pressed, hotkey: hotkey, now: now.addingTimeInterval(0.2)), false, "modifier-only second press arms")
    try expect(machine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(0.3)), false, "modifier-only debounce suppresses repeated release")

    try expect(machine.handleFlagsChanged(flags: pressed, hotkey: hotkey, now: now.addingTimeInterval(1.0)), false, "modifier-only press after debounce arms")
    try expect(machine.handleFlagsChanged(flags: partial, hotkey: hotkey, now: now.addingTimeInterval(1.1)), false, "partial release does not trigger")
    try expect(machine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(1.2)), true, "full release after partial release triggers")

    try expect(machine.handleFlagsChanged(flags: pressed, hotkey: hotkey, now: now.addingTimeInterval(2.0)), false, "modifier-only arms before keyDown cancel")
    machine.cancelPendingModifierOnlyChord()
    try expect(machine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(2.1)), false, "keyDown cancel prevents modifier-only trigger")

    try expect(machine.handleFlagsChanged(flags: extra, hotkey: hotkey, now: now.addingTimeInterval(3.0)), false, "extra modifier does not arm modifier-only hotkey")
    try expect(machine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(3.1)), false, "extra modifier release does not trigger")

    let exactThenExtraMachine = ModifierOnlyHotkeyStateMachine(debounceInterval: 0.5)
    try expect(exactThenExtraMachine.handleFlagsChanged(flags: pressed, hotkey: hotkey, now: now.addingTimeInterval(4.0)), false, "modifier-only arms before extra modifier")
    try expect(exactThenExtraMachine.handleFlagsChanged(flags: extra, hotkey: hotkey, now: now.addingTimeInterval(4.1)), false, "extra modifier cancels armed modifier-only chord")
    try expect(exactThenExtraMachine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(4.2)), false, "release after extra modifier does not trigger")

    try expect(
        ModifierOnlyHotkeyStateMachine().handleFlagsChanged(
            flags: pressed,
            hotkey: Hotkey.defaultToggleCase,
            now: now
        ),
        false,
        "key-based hotkey is ignored by modifier-only machine"
    )
}

private func runKeyDownEventPolicyTests() throws {
    let none = ModifierFlagsSnapshot(command: false, option: false, shift: false, control: false)
    let shift = ModifierFlagsSnapshot(command: false, option: false, shift: true, control: false)
    let command = ModifierFlagsSnapshot(command: true, option: false, shift: false, control: false)
    let commandOption = ModifierFlagsSnapshot(command: true, option: true, shift: false, control: false)
    let commandOptionShift = ModifierFlagsSnapshot(command: true, option: true, shift: true, control: false)
    let commandControl = ModifierFlagsSnapshot(command: true, option: false, shift: false, control: true)
    let optionOnly = ModifierFlagsSnapshot(command: false, option: true, shift: false, control: false)
    let controlOnly = ModifierFlagsSnapshot(command: false, option: false, shift: false, control: true)
    let findInYandexHotkey = Hotkey(keyCode: 3, command: true, option: true, shift: false, control: false)
    let findInSlovariHotkey = Hotkey(keyCode: 3, command: true, option: true, shift: true, control: false)

    try expect(
        KeyDownEventPolicy.keyBasedHotkeyActionDelay,
        0.15,
        "keyDown policy delays key-based hotkey actions until modifiers are released"
    )
    try expect(
        KeyDownEventPolicy.action(
            keyCode: 6,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .toggleCaseHotkey,
        "keyDown policy detects toggle-case hotkey"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 0,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase,
            toggleAutoCorrectionHotkey: Hotkey.defaultToggleAutoCorrection
        ),
        .toggleAutoCorrectionHotkey,
        "keyDown policy detects toggle-auto-correction hotkey"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 51,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase,
            toggleAutoCorrectionHotkey: Hotkey.defaultToggleAutoCorrection,
            cancelLayoutChangeHotkey: Hotkey.defaultCancelLayoutChange
        ),
        .cancelLayoutChangeHotkey,
        "keyDown policy detects cancel-layout-change hotkey before modified deletion"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 3,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase,
            toggleAutoCorrectionHotkey: Hotkey.defaultToggleAutoCorrection,
            cancelLayoutChangeHotkey: Hotkey.defaultCancelLayoutChange,
            findInYandexHotkey: findInYandexHotkey,
            findInSlovariHotkey: findInSlovariHotkey
        ),
        .findInYandexHotkey,
        "keyDown policy detects find-in-Yandex hotkey before modified shortcut clearing"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 3,
            flags: commandOptionShift,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase,
            toggleAutoCorrectionHotkey: Hotkey.defaultToggleAutoCorrection,
            cancelLayoutChangeHotkey: Hotkey.defaultCancelLayoutChange,
            findInYandexHotkey: findInYandexHotkey,
            findInSlovariHotkey: findInSlovariHotkey
        ),
        .findInSlovariHotkey,
        "keyDown policy detects find-in-Slovari hotkey before modified shortcut clearing"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 3,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase,
            findInYandexHotkey: Hotkey.disabled,
            findInSlovariHotkey: Hotkey.disabled
        ),
        .clearTrackedText(reason: "modified shortcut"),
        "keyDown policy treats disabled search shortcut as ordinary modified shortcut"
    )

    let keyBasedConvert = Hotkey(keyCode: 49, command: true, option: true, shift: false, control: false)
    try expect(
        KeyDownEventPolicy.action(
            keyCode: 49,
            flags: commandOption,
            convertHotkey: keyBasedConvert,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .convertLayoutHotkey,
        "keyDown policy detects key-based convert hotkey"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 6,
            flags: commandOptionShift,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "modified shortcut"),
        "keyDown policy clears tracker for non-exact modified hotkey chord"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 9,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "paste"),
        "keyDown policy clears tracker for Cmd+V"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 8,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "copy"),
        "keyDown policy clears tracker for Cmd+C"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 6,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "undo"),
        "keyDown policy clears tracker for Cmd+Z"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 9,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "modified shortcut"),
        "keyDown policy clears tracker for Cmd+Opt+V as modified shortcut"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 7,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "cut"),
        "keyDown policy clears tracker for Cmd+X"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 0,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "selection"),
        "keyDown policy clears tracker for Cmd+A"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 51,
            flags: optionOnly,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "modified deletion"),
        "keyDown policy clears tracker for Option+Delete"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 123,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "modified navigation"),
        "keyDown policy clears tracker for Cmd+Left"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 0,
            flags: none,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .trackKeyPress,
        "keyDown policy tracks plain key press"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 0,
            flags: shift,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .trackKeyPress,
        "keyDown policy tracks shifted key press"
    )

    for (flags, label) in [(command, "command"), (optionOnly, "option"), (controlOnly, "control"), (commandControl, "command-control")] {
        try expect(
            KeyDownEventPolicy.action(
                keyCode: 11,
                flags: flags,
                convertHotkey: Hotkey.defaultConvertLayout,
                toggleCaseHotkey: Hotkey.defaultToggleCase
            ),
            .clearTrackedText(reason: "modified shortcut"),
            "keyDown policy clears tracker for \(label)-modified shortcut"
        )
    }
}

private func runSearchShortcutPolicyTests() throws {
    try expectNil(
        SearchShortcutPolicy.normalizedQuery(" \n\t "),
        "search shortcut policy rejects empty normalized query"
    )
    try expect(
        SearchShortcutPolicy.normalizedQuery("  привет мир  "),
        "привет мир",
        "search shortcut policy trims query"
    )

    try expect(
        SearchShortcutPolicy.url(for: "привет мир", destination: .yandexSearch)?.absoluteString,
        "http://yandex.ru/yandsearch?text=%D0%BF%D1%80%D0%B8%D0%B2%D0%B5%D1%82%20%D0%BC%D0%B8%D1%80&clid=141986&yasoft=puntomac",
        "search shortcut policy builds Punto Switcher-style Yandex search URL"
    )
    try expect(
        SearchShortcutPolicy.url(for: "привет мир", destination: .yandexSearch)?.absoluteString.contains("yasoft=puntomac") == true,
        true,
        "search shortcut policy preserves yasoft marker"
    )

    try expect(
        SearchShortcutPolicy.url(for: "hello", destination: .yandexTranslate)?.absoluteString,
        "http://translate.yandex.ru/?text=hello&clid=141986",
        "search shortcut policy builds Yandex translate URL"
    )
}

private func runSelectedTextSearchPolicyTests() throws {
    let editableCapture = CapturedText(
        text: " привет мир ",
        replacementMethod: .accessibilitySelection,
        source: "AX editable selection"
    )
    try expect(
        SelectedTextSearchPolicy.plan(capturedText: editableCapture, destination: .yandexSearch),
        .open(URL(string: "http://yandex.ru/yandsearch?text=%D0%BF%D1%80%D0%B8%D0%B2%D0%B5%D1%82%20%D0%BC%D0%B8%D1%80&clid=141986&yasoft=puntomac")!),
        "selected-text search policy opens normalized Yandex search URL"
    )

    let terminalTailCapture = CapturedText(
        text: "hello",
        replacementMethod: .keyboardRewriteTail(originalTail: "echo hello"),
        source: "terminal command-tail selection"
    )
    try expect(
        SelectedTextSearchPolicy.plan(capturedText: terminalTailCapture, destination: .yandexTranslate),
        .open(URL(string: "http://translate.yandex.ru/?text=hello&clid=141986")!),
        "selected-text search policy allows safe terminal-tail selected text"
    )

    let blockedCapture = CapturedText(
        text: "stale",
        replacementMethod: .blocked,
        source: "unsafe stale clipboard fallback"
    )
    try expect(
        SelectedTextSearchPolicy.plan(capturedText: blockedCapture, destination: .yandexSearch),
        .blockedCapture(blockedCapture),
        "selected-text search policy blocks unsafe capture"
    )

    try expect(
        SelectedTextSearchPolicy.plan(capturedText: nil, destination: .yandexSearch),
        .noText,
        "selected-text search policy reports nil capture as no text"
    )
    try expect(
        SelectedTextSearchPolicy.plan(
            capturedText: CapturedText(text: "", replacementMethod: .accessibilitySelection, source: "empty"),
            destination: .yandexSearch
        ),
        .noText,
        "selected-text search policy reports empty selected text as no text"
    )
    try expect(
        SelectedTextSearchPolicy.plan(
            capturedText: CapturedText(text: " \n\t ", replacementMethod: .accessibilitySelection, source: "blank"),
            destination: .yandexSearch
        ),
        .skipped(reason: "empty normalized query"),
        "selected-text search policy skips blank normalized query"
    )

    let searchURL = URL(string: "http://yandex.ru/yandsearch?text=%D0%BF%D1%80%D0%B8%D0%B2%D0%B5%D1%82%20%D0%BC%D0%B8%D1%80&clid=141986&yasoft=puntomac")!
    try expect(
        SelectedTextSearchPolicy.runtimePlan(from: .open(searchURL)),
        .open(
            url: searchURL,
            logMessage: "Opening selected text search URL: \(searchURL.absoluteString)",
            shouldFlashIcon: true
        ),
        "selected-text search runtime policy owns URL opening log and icon flash"
    )

    try expect(
        SelectedTextSearchPolicy.runtimePlan(from: .blockedCapture(blockedCapture)),
        .blockedCapture(
            capturedText: blockedCapture,
            logMessage: "Selected text search blocked unsafe selection fallback: unsafe stale clipboard fallback"
        ),
        "selected-text search runtime policy owns blocked-capture cleanup log"
    )

    try expect(
        SelectedTextSearchPolicy.runtimePlan(from: .skipped(reason: "empty normalized query")),
        .skipped(logMessage: "Selected text search skipped: empty normalized query"),
        "selected-text search runtime policy owns skipped log"
    )

    try expect(
        SelectedTextSearchPolicy.runtimePlan(from: .noText),
        .noText(logMessage: "Selected text search skipped: no selected text"),
        "selected-text search runtime policy owns no-text log"
    )
}

private func runSearchClickPolicyTests() throws {
    try expect(
        PuntoSwitcherObservedSurface.SearchClick.canDoSearchClickSelector,
        "canDoSearchClick",
        "search click policy pins observed Punto Switcher click capability selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.SearchClick.showSearchWindowAutomaticallySelector,
        "showSearchWindowAutomatically",
        "search click policy pins observed Punto Switcher automatic search window selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.SearchClick.showSearchWindowSelectedTextSelector,
        "showSearchWindowSelectedText",
        "search click policy pins observed Punto Switcher selected-text search window selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.SearchClick.setIsClickSearchSelector,
        "setIsClickSearch:",
        "search click policy pins observed Punto Switcher click-search state setter"
    )
    try expect(
        SearchClickPolicy.canDoSearchClick(role: "AXWebArea", bundleID: "com.example.browser"),
        true,
        "search click policy allows click search outside observed click exception roles"
    )
    try expect(
        SearchClickPolicy.canDoSearchClick(role: "AXTextField", bundleID: "com.example.editor"),
        false,
        "search click policy rejects observed global editable click exception role"
    )
    try expect(
        SearchClickPolicy.canDoSearchClick(role: "AXGroup", bundleID: "com.apple.finder"),
        false,
        "search click policy rejects observed app-specific click exception role"
    )
    try expect(
        SearchClickPolicy.canDoSearchClick(role: nil, bundleID: "com.example.editor"),
        false,
        "search click policy rejects missing focused role"
    )
    try expect(
        SearchClickPolicy.shouldSearchSelectedTextAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 2,
            shouldSearchByDoubleClick: true,
            canDoSearchClick: true
        ),
        true,
        "search click policy allows selected-text search after eligible double click"
    )
    try expect(
        SearchClickPolicy.shouldSearchSelectedTextAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 1,
            shouldSearchByDoubleClick: true,
            canDoSearchClick: true
        ),
        false,
        "search click policy rejects single click"
    )
    try expect(
        SearchClickPolicy.shouldSearchSelectedTextAfterClick(
            eventTypeRawValue: PointerEventPolicy.rightMouseDownRawValue,
            clickCount: 2,
            shouldSearchByDoubleClick: true,
            canDoSearchClick: true
        ),
        false,
        "search click policy rejects right double click"
    )
    try expect(
        SearchClickPolicy.shouldSearchSelectedTextAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 2,
            shouldSearchByDoubleClick: false,
            canDoSearchClick: true
        ),
        false,
        "search click policy rejects double click when setting is disabled"
    )
    try expect(
        SearchClickPolicy.shouldSearchSelectedTextAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 2,
            shouldSearchByDoubleClick: true,
            canDoSearchClick: false
        ),
        false,
        "search click policy rejects double click without live click-search capability"
    )
}

private func runSearchbarSettingsPolicyTests() throws {
    try expect(
        SearchbarSettingsPolicy.defaultSnapshot,
        SearchbarSettingsSnapshot(
            activationShortcut: Hotkey.disabled,
            shouldOfferSearchbarAutoactivation: true,
            autoactivationExceptions: [],
            alertShownIn: SearchbarSettingsPolicy.legacyInitialDate,
            shouldSearchByDoubleClick: false,
            sitesearchPromptCounter: 3
        ),
        "searchbar settings policy mirrors Punto Switcher default-conf search bar/click offers and observed unset fields"
    )

    try expect(
        SearchbarSettingsPolicy.snapshot(from: nil),
        nil,
        "searchbar settings policy rejects missing dictionary"
    )

    try expect(
        SearchbarSettingsPolicy.snapshot(from: [
            SearchbarSettingsPolicy.activationShortcutKey: [
                LegacyHotkeyPolicy.keyCodeKey: NSNumber(value: 6),
                LegacyHotkeyPolicy.commandKey: NSNumber(value: true),
                LegacyHotkeyPolicy.optionKey: NSNumber(value: false),
                LegacyHotkeyPolicy.shiftKey: NSNumber(value: true),
                LegacyHotkeyPolicy.controlKey: NSNumber(value: false)
            ],
            SearchbarSettingsPolicy.autoactivationKey: NSNumber(value: false),
            SearchbarSettingsPolicy.autoactivationExceptionsKey: [
                " COM.Example.App ",
                "",
                "com.example.app",
                "org.example.Editor"
            ],
            SearchbarSettingsPolicy.alertShownInKey: NSNumber(value: 1_230_757_260),
            SearchbarSettingsPolicy.shouldSearchByDoubleClickKey: NSNumber(value: true),
            SearchbarSettingsPolicy.sitesearchPromptCounterKey: NSNumber(value: 7)
        ]),
        SearchbarSettingsSnapshot(
            activationShortcut: Hotkey(keyCode: 6, command: true, option: false, shift: true, control: false),
            shouldOfferSearchbarAutoactivation: false,
            autoactivationExceptions: ["com.example.app", "org.example.editor"],
            alertShownIn: Date(timeIntervalSince1970: 1_230_757_260),
            shouldSearchByDoubleClick: true,
            sitesearchPromptCounter: 7
        ),
        "searchbar settings policy parses NSNumber-backed legacy plist values and normalizes exception apps"
    )

    try expect(
        SearchbarSettingsPolicy.snapshot(from: [
            SearchbarSettingsPolicy.activationShortcutKey: [
                LegacyHotkeyPolicy.keyCodeKey: LegacyHotkeyPolicy.noKeyCode,
                LegacyHotkeyPolicy.commandKey: true,
                LegacyHotkeyPolicy.optionKey: true,
                LegacyHotkeyPolicy.shiftKey: false,
                LegacyHotkeyPolicy.controlKey: false
            ],
            SearchbarSettingsPolicy.autoactivationKey: "yes",
            SearchbarSettingsPolicy.alertShownInKey: "2009-01-01 00:00:00 +0300",
            SearchbarSettingsPolicy.shouldSearchByDoubleClickKey: "0",
            SearchbarSettingsPolicy.sitesearchPromptCounterKey: " 4 "
        ]),
        SearchbarSettingsSnapshot(
            activationShortcut: Hotkey(
                keyCode: Hotkey.modifierOnlyKeyCode,
                command: true,
                option: true,
                shift: false,
                control: false
            ),
            shouldOfferSearchbarAutoactivation: true,
            alertShownIn: SearchbarSettingsPolicy.legacyInitialDate,
            shouldSearchByDoubleClick: false,
            sitesearchPromptCounter: 4
        ),
        "searchbar settings policy parses string-backed imported values and observed alert date"
    )

    try expect(
        SearchbarSettingsPolicy.snapshot(from: [
            SearchbarSettingsPolicy.sitesearchPromptCounterKey: -2
        ]),
        SearchbarSettingsSnapshot(
            activationShortcut: Hotkey.disabled,
            shouldOfferSearchbarAutoactivation: true,
            autoactivationExceptions: [],
            alertShownIn: SearchbarSettingsPolicy.legacyInitialDate,
            shouldSearchByDoubleClick: false,
            sitesearchPromptCounter: 0
        ),
        "searchbar settings policy clamps negative prompt counters"
    )

    try expect(
        SearchbarSettingsPolicy.effectiveShouldSearchByDoubleClick(
            hasNativeValue: true,
            nativeValue: false,
            legacySnapshot: SearchbarSettingsSnapshot(
                shouldOfferSearchbarAutoactivation: true,
                shouldSearchByDoubleClick: true,
                sitesearchPromptCounter: 3
            )
        ),
        false,
        "searchbar settings policy lets native double-click search setting override imported PSSearchbarSettings"
    )
    try expect(
        SearchbarSettingsPolicy.effectiveShouldSearchByDoubleClick(
            hasNativeValue: false,
            nativeValue: nil,
            legacySnapshot: SearchbarSettingsSnapshot(
                shouldOfferSearchbarAutoactivation: true,
                shouldSearchByDoubleClick: true,
                sitesearchPromptCounter: 3
            )
        ),
        true,
        "searchbar settings policy imports legacy ShouldSearchByDoubleClick when native setting is absent"
    )
    try expect(
        SearchbarSettingsPolicy.effectiveShouldSearchByDoubleClick(
            hasNativeValue: false,
            nativeValue: nil,
            legacySnapshot: nil
        ),
        false,
        "searchbar settings policy defaults double-click search off without native or legacy settings"
    )
}

private func runCaseConverterTests() throws {
    try expect(CaseConverter.toggleCase("hello"), "HELLO", "case converter lower to upper")
    try expect(CaseConverter.toggleCase("HELLO"), "hello", "case converter upper to lower")
    try expect(CaseConverter.toggleCase("Hello"), "hELLO", "case converter inverts title case")
    try expect(CaseConverter.toggleCase("hELLO"), "Hello", "case converter restores inverted title case")
    try expect(CaseConverter.toggleCase("HeLLo WoRLd"), "hEllO wOrlD", "case converter inverts mixed latin text")

    try expect(CaseConverter.toggleCase("привет"), "ПРИВЕТ", "case converter russian lower to upper")
    try expect(CaseConverter.toggleCase("ПРИВЕТ"), "привет", "case converter russian upper to lower")
    try expect(CaseConverter.toggleCase("ПрИвЕт"), "пРиВеТ", "case converter inverts mixed russian text")
    try expect(CaseConverter.toggleCase("Ё"), "ё", "case converter toggles russian yo")

    try expect(CaseConverter.toggleCase("hello123"), "HELLO123", "case converter preserves numbers")
    try expect(CaseConverter.toggleCase(";'[].,"), ";'[].,", "case converter preserves punctuation")
    try expect(CaseConverter.toggleCase(""), "", "case converter empty string")
    try expect(CaseConverter.toggleCase(" "), " ", "case converter whitespace")

    for sample in ["Hello", "WORLD", "привет", "ПРИВЕТ", "MiXeD CaSe", "ПрИвЕт МиР"] {
        try expect(CaseConverter.toggleCase(CaseConverter.toggleCase(sample)), sample, "case converter round-trip \(sample)")
    }
}

private func runToggleCasePolicyTests() throws {
    try expect(
        ToggleCasePolicy.replacement(
            for: CapturedText(
                text: "Hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            )
        ),
        ToggleCaseReplacement(
            originalText: "Hello",
            toggledText: "hELLO",
            undoMethod: .accessibilitySelection,
            trackedTailAfterReplacement: nil
        ),
        "toggle-case policy records AX replacement for undo"
    )

    try expect(
        ToggleCasePolicy.replacement(
            for: CapturedText(
                text: "commit",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "AX non-settable command-tail selection"
            )
        ),
        ToggleCaseReplacement(
            originalText: "commit",
            toggledText: "COMMIT",
            undoMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
            trackedTailAfterReplacement: "git COMMIT"
        ),
        "toggle-case policy records terminal tail replacement for undo"
    )

    try expectNil(
        ToggleCasePolicy.replacement(
            for: CapturedText(text: "", replacementMethod: .accessibilitySelection, source: "empty")
        ),
        "toggle-case policy rejects empty capture"
    )

    try expectNil(
        ToggleCasePolicy.replacement(
            for: CapturedText(text: "Hello", replacementMethod: .blocked, source: "blocked")
        ),
        "toggle-case policy rejects blocked capture"
    )
}

private func runToggleCaseConversionPolicyTests() throws {
    let axCapture = CapturedText(
        text: "Hello",
        replacementMethod: .accessibilitySelection,
        source: "AX editable selection"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: axCapture),
        .capturedText(
            capture: axCapture,
            replacement: ToggleCaseReplacement(
                originalText: "Hello",
                toggledText: "hELLO",
                undoMethod: .accessibilitySelection,
                trackedTailAfterReplacement: nil
            )
        ),
        "toggle-case conversion policy plans editable selected text"
    )

    let tailCapture = CapturedText(
        text: "commit",
        replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
        source: "AX non-settable command-tail selection"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: tailCapture),
        .capturedText(
            capture: tailCapture,
            replacement: ToggleCaseReplacement(
                originalText: "commit",
                toggledText: "COMMIT",
                undoMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
                trackedTailAfterReplacement: "git COMMIT"
            )
        ),
        "toggle-case conversion policy plans terminal-tail selected text"
    )

    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: CapturedText(
            text: "Hello",
            replacementMethod: .blocked,
            source: "unsafe stale clipboard fallback"
        )),
        .blockedCapture(CapturedText(
            text: "Hello",
            replacementMethod: .blocked,
            source: "unsafe stale clipboard fallback"
        )),
        "toggle-case conversion policy blocks unsafe capture"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: CapturedText(
            text: "",
            replacementMethod: .accessibilitySelection,
            source: "empty selection"
        )),
        .noText,
        "toggle-case conversion policy reports empty capture as no text"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: nil),
        .noText,
        "toggle-case conversion policy reports nil capture as no text"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(
            from: ToggleCaseConversionPolicy.plan(capturedText: axCapture)
        ),
        .replace(ToggleCaseReplacementRuntimePlan(
            capturedText: axCapture,
            replacement: ToggleCaseReplacement(
                originalText: "Hello",
                toggledText: "hELLO",
                undoMethod: .accessibilitySelection,
                trackedTailAfterReplacement: nil
            ),
            logMessage: "Toggling case for captured text: 'Hello'",
            keepSelection: true,
            failedReplacementLogMessage: "Toggle case replacement aborted",
            failedReplacementMethod: .accessibilitySelection,
            commitPlan: TextReplacementCommitPlan(
                trackedTailCommit: nil,
                layoutSwitchCommit: nil,
                soundFeedbackEvent: .toggleCase,
                productStatisticsEvent: nil,
                conversionRecordCommit: ConversionRecordCommit(
                    originalText: "Hello",
                    convertedText: "hELLO",
                    replacementMethod: .accessibilitySelection,
                    origin: .toggleCase
                )
            )
        )),
        "toggle-case runtime policy plans editable replacement execution and commit"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(
            from: ToggleCaseConversionPolicy.plan(capturedText: tailCapture)
        ),
        .replace(ToggleCaseReplacementRuntimePlan(
            capturedText: tailCapture,
            replacement: ToggleCaseReplacement(
                originalText: "commit",
                toggledText: "COMMIT",
                undoMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
                trackedTailAfterReplacement: "git COMMIT"
            ),
            logMessage: "Toggling case for captured text: 'commit'",
            keepSelection: false,
            failedReplacementLogMessage: "Toggle case replacement aborted",
            failedReplacementMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
            commitPlan: TextReplacementCommitPlan(
                trackedTailCommit: TrackedTailCommit(text: "git COMMIT", reason: "toggle-case completed"),
                layoutSwitchCommit: nil,
                soundFeedbackEvent: .toggleCase,
                productStatisticsEvent: nil,
                conversionRecordCommit: ConversionRecordCommit(
                    originalText: "commit",
                    convertedText: "COMMIT",
                    replacementMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
                    origin: .toggleCase
                )
            )
        )),
        "toggle-case runtime policy plans terminal-tail replay and undo record"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(from: .blockedCapture(CapturedText(
            text: "Hello",
            replacementMethod: .blocked,
            source: "unsafe stale clipboard fallback"
        ))),
        .blockedCapture(
            capturedText: CapturedText(
                text: "Hello",
                replacementMethod: .blocked,
                source: "unsafe stale clipboard fallback"
            ),
            logMessage: "Toggle case blocked unsafe selection fallback: unsafe stale clipboard fallback"
        ),
        "toggle-case runtime policy preserves blocked-capture cleanup log"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(from: .skipped(reason: "replacement unavailable")),
        .skipped(logMessage: "Toggle case aborted: replacement plan could not be derived"),
        "toggle-case runtime policy owns skipped log"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(from: .noText),
        .noText(logMessage: "Toggle case: no selected text"),
        "toggle-case runtime policy owns no-text log"
    )
}

private func runAutoCorrectionEngineTests() throws {
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

private func runAutoCorrectionPreflightPolicyTests() throws {
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "auto-correction preflight allows eligible completed token"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: "\n",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction on Enter/Tab disabled"),
        "auto-correction preflight consumes Return token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: "\t",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction on Enter/Tab disabled"),
        "auto-correction preflight consumes Tab token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: " ",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "auto-correction preflight still allows Space token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: " ",
            isCompletedTokenAutoCorrectionSuppressed: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "completed token auto-correction cancelled"),
        "auto-correction preflight consumes edited-token cancellation"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "Punto disabled"),
        "auto-correction preflight consumes token when Punto is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction disabled"),
        "auto-correction preflight consumes token when auto-correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "conversion in progress"),
        "auto-correction preflight consumes token during conversion window"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: true,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "current app disabled"),
        "auto-correction preflight consumes token for disabled app"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "no completed token"),
        "auto-correction preflight skips without token"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: true,
            isPasswordField: false
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction preflight clears state for secure input"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "auto-correction preflight clears state for password field"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction preflight prioritizes secure input"
    )
    try expect(
        AutoCorrectionPreflightPolicy.logMessage(for: .blockAndClear(reason: "password field")),
        "Auto-correction blocked for secure input",
        "auto-correction preflight preserves secure block log"
    )
}

private func runAutoCorrectionReplacementPolicyTests() throws {
    let rule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let replacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "ghbdtn", separator: " "),
        trackedTailBeforeCorrection: "say ghbdtn "
    )

    try expect(
        replacement,
        AutoCorrectionReplacement(
            originalText: "ghbdtn ",
            replacementText: "привет ",
            replacementLength: 7,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: "say привет "
        ),
        "auto-correction replacement preserves separator and tracked tail"
    )

    let newlineReplacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "teh", replacement: "the", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "teh", separator: "\n"),
        trackedTailBeforeCorrection: "teh\n"
    )

    try expect(
        newlineReplacement?.trackedTailAfterReplacement,
        "the\n",
        "auto-correction replacement preserves newline boundary"
    )

    let dashReplacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "ghbdtn", separator: "-"),
        trackedTailBeforeCorrection: "echo ghbdtn-"
    )

    try expect(
        dashReplacement,
        AutoCorrectionReplacement(
            originalText: "ghbdtn-",
            replacementText: "привет-",
            replacementLength: 7,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: "echo привет-"
        ),
        "auto-correction replacement preserves dash suffix boundary"
    )

    let staleTailReplacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "teh", replacement: "the", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "teh", separator: " "),
        trackedTailBeforeCorrection: "other text "
    )

    try expect(
        staleTailReplacement?.trackedTailAfterReplacement,
        "the ",
        "auto-correction replacement falls back to replacement text for stale tail"
    )

    try expectNil(
        AutoCorrectionReplacementPolicy.replacement(
            for: AutoCorrectionDecision(original: "other", replacement: "the", rule: rule),
            completedToken: WordTracker.CompletedToken(word: "teh", separator: " "),
            trackedTailBeforeCorrection: "teh "
        ),
        "auto-correction replacement rejects mismatched token and decision"
    )

    try expectNil(
        AutoCorrectionReplacementPolicy.replacement(
            for: AutoCorrectionDecision(original: "teh", replacement: "the", rule: rule),
            completedToken: WordTracker.CompletedToken(word: "teh", separator: ""),
            trackedTailBeforeCorrection: "teh"
        ),
        "auto-correction replacement rejects missing boundary separator"
    )

    try expect(
        AutoCorrectionReplacementPolicy.shouldClearConversionSessionAfterPlanFailure(),
        true,
        "auto-correction clears stale undo session after replacement plan failure"
    )
}

private func runAutoCorrectionRuntimePolicyTests() throws {
    let token = WordTracker.CompletedToken(word: "ghbdtn", separator: " ")
    let suppressedToken = WordTracker.CompletedToken(
        word: "ghbdtn",
        separator: " ",
        isAutoCorrectionSuppressed: true
    )

    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: token
        ),
        .proceed,
        "auto-correction runtime route proceeds for enabled completed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: token
        ),
        .consumeTokenAndSkip(reason: "Punto disabled"),
        "auto-correction runtime route consumes token when Punto is disabled"
    )
    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: suppressedToken
        ),
        .consumeTokenAndSkip(reason: "completed token auto-correction cancelled"),
        "auto-correction runtime route consumes suppressed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.securityPreflightAction(
            token: token,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "auto-correction runtime security blocks password fields"
    )
    try expect(
        AutoCorrectionRuntimePolicy.securityPreflightAction(
            token: token,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction runtime security prioritizes secure input"
    )

    let rule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let engine = AutoCorrectionEngine(rules: [rule])
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: token,
            trackedTailBeforeCorrection: "say ghbdtn ",
            engine: engine
        ),
        .replacement(
            decision: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule),
            replacement: AutoCorrectionReplacement(
                originalText: "ghbdtn ",
                replacementText: "привет ",
                replacementLength: 7,
                undoMethod: .keyboardBackspacePaste,
                trackedTailAfterReplacement: "say привет "
            )
        ),
        "auto-correction runtime derives executable replacement plan"
    )
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: WordTracker.CompletedToken(word: "unknown", separator: " "),
            trackedTailBeforeCorrection: "unknown ",
            engine: engine
        ),
        .noCorrection,
        "auto-correction runtime reports no correction without a matching rule"
    )
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: WordTracker.CompletedToken(word: "ghbdtn", separator: ""),
            trackedTailBeforeCorrection: "ghbdtn",
            engine: engine
        ),
        .planFailure(decision: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule)),
        "auto-correction runtime reports plan failure for invalid completed token boundary"
    )

    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed(completedTokenStatisticsEvent: .completedWord, token: token),
        "auto-correction runtime gate proceeds after route and security checks"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: token,
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "say ghbdtn ",
            engine: engine
        ),
        .replacement(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correcting completed word 'ghbdtn' -> 'привет'",
            replacement: AutoCorrectionReplacement(
                originalText: "ghbdtn ",
                replacementText: "привет ",
                replacementLength: 7,
                undoMethod: .keyboardBackspacePaste,
                trackedTailAfterReplacement: "say привет "
            ),
            commitPlan: TextReplacementCommitPlan(
                trackedTailCommit: TrackedTailCommit(text: "say привет ", reason: "auto-correction completed"),
                layoutSwitchCommit: nil,
                soundFeedbackEvent: .autoCorrection,
                productStatisticsEvent: .automaticSwitch,
                conversionRecordCommit: ConversionRecordCommit(
                    originalText: "ghbdtn ",
                    convertedText: "привет ",
                    replacementMethod: .keyboardBackspacePaste,
                    origin: .autoCorrection(rule: rule)
                )
            )
        ),
        "auto-correction runtime attempt includes statistics, log, replacement, and commit plan"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: nil,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipped(completedTokenStatisticsEvent: nil, logMessage: nil),
        "auto-correction runtime gate skips cleanly without completed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipped(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correction skipped: Punto disabled"
        ),
        "auto-correction runtime gate consumes completed-token stats when route skips"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(
            completedTokenStatisticsEvent: .completedWord,
            reason: "password field",
            logMessage: "Auto-correction blocked for secure input"
        ),
        "auto-correction runtime gate blocks and clears secure/password input before tail lookup"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: WordTracker.CompletedToken(word: "unknown", separator: " "),
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "unknown ",
            engine: engine
        ),
        .noCorrection(completedTokenStatisticsEvent: .completedWord),
        "auto-correction runtime attempt preserves completed-token stats for no-op rule lookup"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: WordTracker.CompletedToken(word: "ghbdtn", separator: ""),
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "ghbdtn",
            engine: engine
        ),
        .planFailure(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correction aborted: replacement plan could not be derived",
            conversionSessionClearReason: "auto-correction plan derivation failed"
        ),
        "auto-correction runtime attempt owns plan-failure cleanup reason"
    )
}

private func runAutoCorrectionUndoLearningPolicyTests() throws {
    let undoneRule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let rules = [
        undoneRule,
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "gjrf", replacement: "пока")
    ]
    let record = ConversionRecord(
        originalText: "ghbdtn ",
        convertedText: "привет ",
        timestamp: Date(timeIntervalSince1970: 100),
        replacementMethod: .keyboardBackspacePaste,
        origin: .autoCorrection(rule: undoneRule)
    )

    let learnedRules = try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: record,
            isUndoLearningEnabled: true
        ),
        [
            AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
            AutoCorrectionRule(trigger: "gjrf", replacement: "пока")
        ],
        "auto-correction undo learning removes undone rule"
    )
    guard let learnedRules else {
        throw TestFailure(description: "auto-correction undo learning removes undone rule: expected updated rules")
    }
    let engine = AutoCorrectionEngine(rules: learnedRules)
    try expectNil(engine.correction(for: "ghbdtn"), "auto-correction undo learning suppresses repeated correction")
    try expect(engine.correction(for: "Teh")?.replacement, "The", "auto-correction undo learning keeps unrelated rules")
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: record,
            isUndoLearningEnabled: false
        ),
        "auto-correction undo learning setting can disable learned rule removal"
    )

    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: ConversionRecord(
                originalText: "hello",
                convertedText: "руддщ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .layoutConversion
            )
        ),
        "auto-correction undo learning ignores manual layout conversion undo"
    )
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [AutoCorrectionRule(trigger: "other", replacement: "другое")],
            record: record
        ),
        "auto-correction undo learning ignores already removed rule"
    )

    let preserveCaseVariant = AutoCorrectionRule(
        trigger: "teh",
        replacement: "the",
        matchMode: .caseInsensitive,
        preserveCase: false
    )
    let caseSensitiveRules = [
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive, preserveCase: true),
        preserveCaseVariant
    ]
    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: caseSensitiveRules,
            record: ConversionRecord(
                originalText: "teh ",
                convertedText: "the ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(
                    trigger: "teh",
                    replacement: "the",
                    matchMode: .caseInsensitive,
                    preserveCase: true
                ))
            )
        ),
        [preserveCaseVariant],
        "auto-correction undo learning preserves same trigger rule with different case behavior"
    )
    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [
                AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
                AutoCorrectionRule(trigger: "other", replacement: "другое")
            ],
            record: ConversionRecord(
                originalText: "TEH ",
                convertedText: "THE ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(
                    trigger: "TEH",
                    replacement: "the",
                    matchMode: .caseInsensitive
                ))
            )
        ),
        [AutoCorrectionRule(trigger: "other", replacement: "другое")],
        "auto-correction undo learning matches case-insensitive trigger case-insensitively"
    )
    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [
                AutoCorrectionRule(trigger: "Teh", replacement: "The"),
                AutoCorrectionRule(trigger: "teh", replacement: "the")
            ],
            record: ConversionRecord(
                originalText: "Teh ",
                convertedText: "The ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(trigger: "Teh", replacement: "The"))
            )
        ),
        [AutoCorrectionRule(trigger: "teh", replacement: "the")],
        "auto-correction undo learning keeps exact trigger case-sensitive"
    )

    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [
                AutoCorrectionRule(trigger: " ghbdtn ", replacement: " привет\n"),
                AutoCorrectionRule(trigger: "gjrf", replacement: "пока")
            ],
            record: ConversionRecord(
                originalText: "ghbdtn ",
                convertedText: "привет ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"))
            )
        ),
        [AutoCorrectionRule(trigger: "gjrf", replacement: "пока")],
        "auto-correction undo learning matches normalized rule fields"
    )

    try expect(
        AutoCorrectionUndoLearningPolicy.originAfterUndo(record: record),
        .autoCorrectionRedo(rule: undoneRule),
        "auto-correction undo learning preserves auto-correction redo origin"
    )
    try expect(
        AutoCorrectionUndoLearningPolicy.originAfterUndo(record: ConversionRecord(
            originalText: "hello",
            convertedText: "руддщ",
            timestamp: Date(timeIntervalSince1970: 100),
            replacementMethod: .keyboardBackspacePaste,
            origin: .layoutConversion
        )),
        .manualRedo,
        "auto-correction undo learning delegates manual redo origin"
    )
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: ConversionRecord(
                originalText: "привет ",
                convertedText: "ghbdtn ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .manualRedo
            )
        ),
        "auto-correction undo learning ignores manual redo record"
    )
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: ConversionRecord(
                originalText: "привет ",
                convertedText: "ghbdtn ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrectionRedo(rule: undoneRule)
            )
        ),
        "auto-correction undo learning ignores auto-correction redo record"
    )
}

private func runAutoCorrectionRuleStoreTests() throws {
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

    let legacyRules = LegacyUserRulePolicy.rules(from: [
        [
            "rule_string": " ghbdtn ",
            "rule": " привет ",
            "is_active": NSNumber(value: true),
            "is_regexp": NSNumber(value: false),
            "do_replace": NSNumber(value: true)
        ],
        [
            "string": "teh",
            "rule": "the",
            "isRuleActive": "yes",
            "isRegExp": "no",
            "shouldSwitchLayout": "true"
        ],
        [
            "rule_string": "inactive",
            "rule": "ignored",
            "is_active": NSNumber(value: false)
        ],
        [
            "rule_string": "regexp",
            "rule": "ignored",
            "is_regexp": NSNumber(value: true)
        ],
        [
            "rule_string": "switchOnly",
            "rule": "ignored",
            "do_replace": NSNumber(value: false)
        ]
    ])
    try expect(
        legacyRules,
        [
            AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"),
            AutoCorrectionRule(trigger: "teh", replacement: "the")
        ],
        "legacy user rule policy imports active non-regexp Punto Switcher replacement rules"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.createUserRuleSelector,
        "createUserRule",
        "observed surface preserves user-rule create selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.modifyUserRuleSelector,
        "modifyUserRule",
        "observed surface preserves user-rule modify selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.removeUserRuleWithIndexSelector,
        "removeUserRuleWithIndex:",
        "observed surface preserves user-rule remove selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.addUserRuleSelector,
        "addUserRuleWithString:rule:shouldSwitchLayout:isRuleActive:isRegExp:",
        "observed surface preserves user-rule add selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.modifyUserRuleWithIndexSelector,
        "modifyUserRuleWithIndex:string:rule:shouldSwitchLayout:isRuleActive:isRegExp:",
        "observed surface preserves user-rule indexed modify selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.showWordAddedTooltipSelector,
        "showWordAddedTooltip:",
        "observed surface preserves user-rule word-added tooltip selector"
    )
    try expect(
        LegacyUserRulePolicy.rules(from: []),
        [],
        "legacy user rule policy preserves observed empty userRulesDictionary as empty"
    )
    try expectNil(
        LegacyUserRulePolicy.rules(from: ["not": "array"]),
        "legacy user rule policy ignores unexpected userRulesDictionary shape"
    )

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

private func runAutoCorrectionRuleSourcePolicyTests() throws {
    let starterRules = [
        AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    ]
    let persistedRules = [
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive)
    ]

    try expect(
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesDefaultConfPath,
        "switcher.use_old_rules",
        "observed surface pins Punto Switcher default-conf old-rules path"
    )
    try expect(
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesAccessor,
        "switcherUseOldRules",
        "observed surface pins Punto Switcher old-rules accessor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.useOldRulesDefaultConfPath,
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesDefaultConfPath,
        "rule source policy keeps default-conf old-rules path aligned with reverse-audit anchor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.useOldRulesAccessor,
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesAccessor,
        "rule source policy keeps old-rules accessor aligned with reverse-audit anchor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules
        ),
        [
            AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"),
            AutoCorrectionRule(trigger: "custom", replacement: "замена")
        ],
        "rule source policy adds Punto Switcher userRulesDictionary rules to starter catalog"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [],
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy keeps starter catalog when Punto Switcher userRulesDictionary is empty"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [],
            starterRules: starterRules,
            useStarterRules: false
        ),
        [],
        "rule source policy disables starter catalog when switcher.use_old_rules is false"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules,
            useStarterRules: false
        ),
        [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
        "rule source policy keeps user rules when old starter rules are disabled"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: persistedRules,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules
        ),
        persistedRules,
        "rule source policy prefers native saved rules over Punto Switcher userRulesDictionary"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy uses starter catalog before rules are saved"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: persistedRules,
            starterRules: starterRules
        ),
        persistedRules,
        "rule source policy uses persisted user rules"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: [],
            starterRules: starterRules
        ),
        [],
        "rule source policy preserves intentionally empty persisted rules"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: nil,
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy falls back to starter catalog for unreadable persisted rules"
    )
}

private func runAutoCorrectionStarterCatalogTests() throws {
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

private func runApplicationReturnKeyPolicyTests() throws {
    try expect(
        ApplicationReturnKeyPolicy.legacyResetOnReturnKey,
        "switcher.reset_on_return",
        "return policy owns observed reset-on-return import key"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "org.telegram.desktop",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        true,
        "return policy resets text state on Telegram Return"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "ru.keepcoder.Telegram",
            keyCode: ApplicationReturnKeyPolicy.enterKeyCode
        ),
        true,
        "return policy resets text state on Telegram Enter"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.telegram.client",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        true,
        "return policy resets text state for telegram bundle component"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.apple.TextEdit",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        false,
        "return policy keeps ordinary editors eligible for return auto-correction"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.slack.client",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: [" slack "]
        ),
        true,
        "return policy supports configured reset_on_return bundle components"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.slackclient",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: ["slack"]
        ),
        false,
        "return policy rejects glued configured reset_on_return component"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.slack.client",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: [" "]
        ),
        false,
        "return policy ignores blank configured reset_on_return components"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.nottelegram",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        false,
        "return policy rejects glued telegram suffix"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "org.telegram.desktop",
            keyCode: 49
        ),
        false,
        "return policy ignores non-return keys"
    )
}

private func runAccessibilityApplicationPolicyTests() throws {
    try expect(
        AccessibilityApplicationPolicy.observedBrowserInjectionBundleIDs,
        [
            "com.apple.safari",
            "com.google.chrome",
            "org.chromium.chromium",
            "ru.yandex.desktop.yandex-browser",
            "com.operasoftware.Opera",
            "org.mozilla.firefox"
        ],
        "accessibility app policy preserves observed default-conf injection order"
    )
    try expect(
        AccessibilityApplicationPolicy.observedEnhancedUserInterfaceBundleIDs,
        [
            "com.google.chrome",
            "com.operasoftware.Opera",
            "org.chromium.chromium",
            "org.mozilla.firefox",
            "ru.yandex.desktop.yandex-browser"
        ],
        "accessibility app policy preserves observed default-conf eui order"
    )

    for bundleID in [
        "com.apple.Safari",
        "com.google.chrome",
        "com.operasoftware.Opera",
        "org.chromium.chromium",
        "org.mozilla.firefox",
        "ru.yandex.desktop.yandex-browser"
    ] {
        try expect(
            AccessibilityApplicationPolicy.isObservedBrowserInjectionBundleID(bundleID),
            true,
            "accessibility app policy detects observed browser injection bundle \(bundleID)"
        )
    }

    for bundleID in [
        "com.google.chrome",
        "com.operasoftware.Opera",
        "org.chromium.chromium",
        "org.mozilla.firefox",
        "ru.yandex.desktop.yandex-browser"
    ] {
        try expect(
            AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: bundleID),
            true,
            "accessibility app policy enables enhanced UI for observed eui bundle \(bundleID)"
        )
    }

    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: "com.apple.Safari"),
        false,
        "accessibility app policy keeps Safari out of AXEnhancedUserInterface to match observed eui list"
    )
    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: " com.google.Chrome "),
        true,
        "accessibility app policy normalizes browser bundle id"
    )
    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: "com.google.chrome.helper"),
        false,
        "accessibility app policy rejects glued browser bundle suffix"
    )
    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: nil),
        false,
        "accessibility app policy rejects missing bundle id"
    )
}

private func runSoundFeedbackPolicyTests() throws {
    try expect(
        SoundFeedbackPolicy.requiredResourceNames,
        ["replace", "reverse", "misprint", "switch", "en", "ru", "typeeng", "typerus"],
        "sound feedback declares every bundled Punto-style sound resource"
    )
    try expect(
        SoundFeedbackPolicy.defaultEnabledResourceNames,
        SoundFeedbackPolicy.requiredResourceNames,
        "sound feedback enables every resource by default"
    )
    try expect(
        Set(SoundFeedbackPolicy.legacyPerResourceToggleKeys),
        [
            "useSoundLayoutSwitchToRussian",
            "useSoundLayoutSwitchToEnglish",
            "useSoundConvertation",
            "useSoundMisprint",
            "useSoundAutocorrection",
            "useSoundUndo",
            "useSoundKeystrokes"
        ],
        "sound feedback declares observed Punto Switcher per-resource sound toggles"
    )
    try expect(
        PuntoSwitcherObservedSurface.SoundFeedback.skipNextLanguageChangeSoundSelector,
        "shouldSkipNextLanguageChangeSound",
        "sound feedback pins observed Punto Switcher skip-next-language-change-sound selector"
    )
    try expect(
        SoundFeedbackPolicy.legacyIsSoundOnKey,
        "isSoundOn",
        "sound feedback pins observed Punto Switcher global sound key"
    )
    try expect(
        PuntoSwitcherObservedSurface.SoundFeedback.setSoundStateSelector,
        "setSoundState:isSoundOn:",
        "sound feedback pins observed Punto Switcher sound-state setter"
    )
    try expect(
        SoundFeedbackPolicy.legacyEnabledSoundsKey,
        "enabledSounds",
        "sound feedback pins observed Punto Switcher enabled-sounds bitmask key"
    )
    try expect(
        SoundFeedbackPolicy.normalizedEnabledResourceNames(["replace", "unknown", "ru"]),
        ["replace", "ru"],
        "sound feedback drops unknown per-resource settings"
    )
    try expect(
        SoundFeedbackPolicy.enabledResourceNames(fromLegacyBitmask: 502),
        ["reverse", "misprint", "en", "ru", "typeeng", "typerus"],
        "sound feedback reads observed Punto Switcher enabledSounds bitmask"
    )
    try expectNil(
        SoundFeedbackPolicy.enabledResourceNames(fromLegacyBitmask: nil),
        "sound feedback ignores missing legacy enabledSounds bitmask"
    )
    try expect(
        SoundFeedbackPolicy.enabledResourceNames(fromLegacyToggles: [
            "useSoundLayoutSwitchToRussian": false,
            "useSoundLayoutSwitchToEnglish": true,
            "useSoundConvertation": false,
            "useSoundKeystrokes": false,
            "unknown": false
        ]),
        ["reverse", "misprint", "switch", "en"],
        "sound feedback reads Punto Switcher useSound flags as resource toggles"
    )
    try expect(
        SoundFeedbackPolicy.enabledResourceNames(fromLegacyToggles: [
            "useSoundMisprint": false,
            "useSoundAutocorrection": true
        ]),
        ["replace", "reverse", "switch", "en", "ru", "typeeng", "typerus"],
        "sound feedback lets disabled legacy aliases win when two aliases share native misprint feedback"
    )
    try expectNil(
        SoundFeedbackPolicy.enabledResourceNames(fromLegacyToggles: ["unknown": false]),
        "sound feedback ignores unknown legacy toggle names"
    )
    try expect(
        SoundFeedbackPolicy.eventAfterTextInput(characters: "a", detectedLayout: .english),
        .typedText(layout: .english),
        "sound feedback emits typed English event for English input"
    )
    try expect(
        SoundFeedbackPolicy.eventAfterTextInput(characters: "ф", detectedLayout: .russian),
        .typedText(layout: .russian),
        "sound feedback emits typed Russian event for Russian input"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterTextInput(characters: "", detectedLayout: .english),
        "sound feedback skips empty text input"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterTextInput(characters: nil, detectedLayout: .english),
        "sound feedback skips nil text input"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterTextInput(characters: "1", detectedLayout: .unknown),
        "sound feedback skips unknown text input"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterTextInput(characters: "aф", detectedLayout: .mixed),
        "sound feedback skips mixed text input"
    )
    try expect(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(targetLayout: .english, didSwitch: true),
        .inputSourceSwitch(to: .english),
        "sound feedback emits English switch event after standalone English input-source switch"
    )
    try expect(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(targetLayout: .russian, didSwitch: true),
        .inputSourceSwitch(to: .russian),
        "sound feedback emits Russian switch event after standalone Russian input-source switch"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(
            targetLayout: .english,
            didSwitch: true,
            context: .textReplacement
        ),
        "sound feedback skips input-source switch sound after text replacement"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(
            targetLayout: .russian,
            didSwitch: true,
            context: .textReplacement
        ),
        "sound feedback skips Russian input-source switch sound after text replacement"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(
            targetLayout: .english,
            didSwitch: true,
            context: .rememberedApplicationRestore
        ),
        "sound feedback skips English input-source switch sound after remembered application layout restore"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(
            targetLayout: .russian,
            didSwitch: true,
            context: .rememberedApplicationRestore
        ),
        "sound feedback skips Russian input-source switch sound after remembered application layout restore"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(targetLayout: .english, didSwitch: false),
        "sound feedback skips failed input-source switch"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(targetLayout: .mixed, didSwitch: true),
        "sound feedback skips non-switchable mixed input-source target"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(targetLayout: .unknown, didSwitch: true),
        "sound feedback skips non-switchable unknown input-source target"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .layoutConversion, soundEffectsEnabled: true),
        "replace",
        "sound feedback uses replace sound for layout conversion"
    )
    try expectNil(
        SoundFeedbackPolicy.resourceName(
            for: .layoutConversion,
            soundEffectsEnabled: true,
            enabledResourceNames: ["reverse", "misprint"]
        ),
        "sound feedback skips disabled replace resource"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(
            for: .undo,
            soundEffectsEnabled: true,
            enabledResourceNames: ["reverse"]
        ),
        "reverse",
        "sound feedback still plays enabled reverse resource"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .undo, soundEffectsEnabled: true),
        "reverse",
        "sound feedback uses reverse sound for undo"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .toggleCase, soundEffectsEnabled: true),
        "replace",
        "sound feedback uses replace sound for toggle case"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .autoCorrection, soundEffectsEnabled: true),
        "misprint",
        "sound feedback uses misprint sound for auto-correction"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .inputSourceSwitch(to: .english), soundEffectsEnabled: true),
        "en",
        "sound feedback uses en sound for English input source switch"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .inputSourceSwitch(to: .russian), soundEffectsEnabled: true),
        "ru",
        "sound feedback uses ru sound for Russian input source switch"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .inputSourceSwitch(to: .unknown), soundEffectsEnabled: true),
        "switch",
        "sound feedback uses generic switch sound for unknown input source switch"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .typedText(layout: .english), soundEffectsEnabled: true),
        "typeeng",
        "sound feedback uses typeeng sound for typed English input"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .typedText(layout: .russian), soundEffectsEnabled: true),
        "typerus",
        "sound feedback uses typerus sound for typed Russian input"
    )
    try expectNil(
        SoundFeedbackPolicy.resourceName(for: .typedText(layout: .unknown), soundEffectsEnabled: true),
        "sound feedback skips typed unknown resource"
    )
    try expectNil(
        SoundFeedbackPolicy.resourceName(for: .layoutConversion, soundEffectsEnabled: false),
        "sound feedback is disabled globally"
    )
}

private func runLogRetentionPolicyTests() throws {
    try expect(
        LogRetentionPolicy.shouldRotateActiveLog(size: LogRetentionPolicy.maxActiveLogSize),
        false,
        "log retention keeps active log at max size"
    )
    try expect(
        LogRetentionPolicy.shouldRotateActiveLog(size: LogRetentionPolicy.maxActiveLogSize + 1),
        true,
        "log retention rotates active log above max size"
    )

    let archivePath = LogRetentionPolicy.archivePath(
        for: Date(timeIntervalSince1970: 1_230_757_200),
        directory: "/tmp"
    )
    try expect(
        archivePath,
        "/tmp/punto.log.2008-12-31-21-00-00-000.log",
        "log retention writes deterministic Punto-style archive names"
    )
    try expect(
        LogRetentionPolicy.archivePath(
            for: Date(timeIntervalSince1970: 1_230_757_200),
            directory: "/tmp",
            collisionIndex: 2
        ),
        "/tmp/punto.log.2008-12-31-21-00-00-000-002.log",
        "log retention writes deterministic collision archive names"
    )
    try expect(
        LogRetentionPolicy.uniqueArchivePath(
            for: Date(timeIntervalSince1970: 1_230_757_200),
            directory: "/tmp",
            existingPaths: [
                "/tmp/punto.log.2008-12-31-21-00-00-000.log",
                "/tmp/punto.log.2008-12-31-21-00-00-000-001.log"
            ]
        ),
        "/tmp/punto.log.2008-12-31-21-00-00-000-002.log",
        "log retention chooses the first non-colliding archive path"
    )
    try expect(
        LogRetentionPolicy.shouldArchiveActiveLogAtStartup(size: 0),
        false,
        "log retention keeps empty startup log unarchived"
    )
    try expect(
        LogRetentionPolicy.shouldArchiveActiveLogAtStartup(size: 1),
        true,
        "log retention archives non-empty startup log before clearing active file"
    )

    let base = Date(timeIntervalSince1970: 1_000)
    let files = [
        ArchivedLogFile(path: "/tmp/punto.log.old.log", size: 10, modifiedAt: base),
        ArchivedLogFile(path: "/tmp/punto.log.mid.log", size: 10, modifiedAt: base.addingTimeInterval(1)),
        ArchivedLogFile(path: "/tmp/punto.log.new.log", size: 10, modifiedAt: base.addingTimeInterval(2))
    ]
    try expect(
        LogRetentionPolicy.archivedLogFilesToDelete(files, maximumNumberOfFiles: 2, diskQuota: 100),
        ["/tmp/punto.log.old.log"],
        "log retention deletes oldest files beyond maximum count"
    )
    try expect(
        LogRetentionPolicy.archivedLogFilesToDelete(files, maximumNumberOfFiles: 5, diskQuota: 15),
        ["/tmp/punto.log.mid.log", "/tmp/punto.log.old.log"],
        "log retention preserves newest files within disk quota"
    )
    try expect(
        LogRetentionPolicy.archivedLogFilesToDelete(files, maximumNumberOfFiles: 0, diskQuota: 100),
        files.map(\.path).sorted(),
        "log retention zero max count deletes all archived logs"
    )
}

do {
    print("PuntoCoreTest starting")
    try runWordBoundaryPolicyTests()
    try runWordTrackingPolicyTests()
    try runLayoutConverterTests()
    try runLayoutDetectionPolicyTests()
    try runWordTrackerTests()
    try runTextCapturePolicyTests()
    try runLayoutConversionReplacementPolicyTests()
    try runManualLayoutConversionPolicyTests()
    try runManualLayoutConversionRuntimePolicyTests()
    try runConversionSessionTests()
    try runUndoReplacementPolicyTests()
    try runUndoRuntimePolicyTests()
    try runTextReplacementCommitPolicyTests()
    try runConversionOriginPolicyTests()
    try runApplicationLayoutMemoryTests()
    try runApplicationBundleIDPolicyTests()
    try runApplicationLayoutPolicyTests()
    try runSettingsPersistencePolicyTests()
    try runLegacyValuePolicyTests()
    try runUndoLearningSettingsPolicyTests()
    try runProductStatisticsPolicyTests()
    try runApplicationUpdateSettingsPolicyTests()
    try runStartupPresentationPolicyTests()
    try runLayoutSwitchPolicyTests()
    try runApplicationDisablePolicyTests()
    try runAutoCorrectionTogglePolicyTests()
    try runStatusIconPolicyTests()
    try runAccessibilityPreferencesPolicyTests()
    try runInputSourceChangePolicyTests()
    try runInputSourceSwitchVerificationPolicyTests()
    try runConversionProtectionPolicyTests()
    try runInputSourceLanguagePolicyTests()
    try runApplicationContextPolicyTests()
    try runHotkeyRoutingPolicyTests()
    try runKeyTrackingRuntimePolicyTests()
    try runTextActionPreflightPolicyTests()
    try runTextActionRuntimePreflightPolicyTests()
    try runPointerEventPolicyTests()
    try runEventTapLifecyclePolicyTests()
    try runAccessibilityNotificationPolicyTests()
    try runTextTrackingSecurityPolicyTests()
    try runAccessibilityRolePolicyTests()
    try runAccessibilityTraversalPolicyTests()
    try runKeyboardReplacementPolicyTests()
    try runTextReplacementPolicyTests()
    try runAccessibilityReplacementPolicyTests()
    try runHotkeyPolicyTests()
    try runKeyDownEventPolicyTests()
    try runSearchShortcutPolicyTests()
    try runSelectedTextSearchPolicyTests()
    try runSearchClickPolicyTests()
    try runSearchbarSettingsPolicyTests()
    try runCaseConverterTests()
    try runToggleCasePolicyTests()
    try runToggleCaseConversionPolicyTests()
    try runAutoCorrectionEngineTests()
    try runAutoCorrectionPreflightPolicyTests()
    try runAutoCorrectionReplacementPolicyTests()
    try runAutoCorrectionRuntimePolicyTests()
    try runAutoCorrectionUndoLearningPolicyTests()
    try runAutoCorrectionRuleStoreTests()
    try runAutoCorrectionRuleSourcePolicyTests()
    try runAutoCorrectionStarterCatalogTests()
    try runApplicationReturnKeyPolicyTests()
    try runAccessibilityApplicationPolicyTests()
    try runSoundFeedbackPolicyTests()
    try runLogRetentionPolicyTests()
    print("PuntoCoreTest passed")
} catch {
    fputs("PuntoCoreTest failed: \(error)\n", stderr)
    exit(1)
}
