import Foundation
import PuntoCore

func runWordBoundaryPolicyTests() throws {
    for character in [";", "'", ":", "\"", ",", ".", "/", "?", "[", "]", "{", "}", "<", ">", "`", "~", "@", "#", "$", "^", "&"] as [Character] {
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

    for character in ["!", "(", ")", "\\", "|", "%", "*", "+", "=", "-", "_"] as [Character] {
        try expect(
            WordBoundaryPolicy.isTypedWordBoundary(character, keyCode: 0),
            true,
            "word boundary policy treats \(character) as typed-word boundary"
        )
    }

    try expect(
        KeyboardLayoutMappingPolicy.isLayoutMappedPunctuation("@", russianLayoutType: .windows),
        true,
        "keyboard layout mapping policy exposes Windows shifted-number punctuation"
    )
    try expect(
        KeyboardLayoutMappingPolicy.isLayoutMappedPunctuation("%", russianLayoutType: .windows),
        false,
        "keyboard layout mapping policy does not treat unchanged Windows percent as mapped punctuation"
    )
    try expect(
        KeyboardLayoutMappingPolicy.isLayoutMappedPunctuation("/", russianLayoutType: .mac),
        false,
        "keyboard layout mapping policy keeps unchanged Mac slash out of mapped punctuation"
    )
    try expect(
        KeyboardLayoutMappingPolicy.isLayoutMappedPunctuation(
            "-",
            englishLayoutVariant: .dvorak,
            russianLayoutType: .windows
        ),
        true,
        "keyboard layout mapping policy exposes Dvorak punctuation as physical-key text"
    )
    try expect(
        WordBoundaryPolicy.isTypedWordBoundary(
            "-",
            keyCode: 0,
            englishLayoutVariant: .dvorak,
            russianLayoutType: .windows
        ),
        false,
        "word boundary policy keeps Dvorak apostrophe-key output inside wrong-layout word"
    )

    let qwertyWindowsMaps = KeyboardLayoutMappingPolicy.characterMaps(
        for: .qwerty,
        russianLayoutType: .windows
    )
    try expect(
        qwertyWindowsMaps.enToRu[";"],
        "ж",
        "keyboard layout character maps expose QWERTY Windows forward punctuation"
    )
    try expect(
        qwertyWindowsMaps.ruToEn["?"],
        "&",
        "keyboard layout character maps expose QWERTY Windows reverse ambiguity fix"
    )

    let qwertyMacMaps = KeyboardLayoutMappingPolicy.characterMaps(
        for: .qwerty,
        russianLayoutType: .mac
    )
    try expect(
        qwertyMacMaps.enToRu["\\"],
        "ё",
        "keyboard layout character maps expose QWERTY Mac forward Apple punctuation"
    )
    try expect(
        qwertyMacMaps.ruToEn["%"],
        "$",
        "keyboard layout character maps expose QWERTY Mac reverse ambiguity fix"
    )

    let dvorakWindowsMaps = KeyboardLayoutMappingPolicy.characterMaps(
        for: .dvorak,
        russianLayoutType: .windows
    )
    try expect(
        dvorakWindowsMaps.enToRu["-"],
        "э",
        "keyboard layout character maps expose Dvorak Windows physical-key remap"
    )
    try expect(
        dvorakWindowsMaps.ruToEn["э"],
        "-",
        "keyboard layout character maps expose Dvorak Windows reverse remap"
    )

    let dvorakMacMaps = KeyboardLayoutMappingPolicy.characterMaps(
        for: .dvorak,
        russianLayoutType: .mac
    )
    try expect(
        dvorakMacMaps.enToRu["="],
        "ъ",
        "keyboard layout character maps expose Dvorak Mac shifted bracket remap"
    )
    try expect(
        dvorakMacMaps.ruToEn["%"],
        "$",
        "keyboard layout character maps expose Dvorak Mac reverse ambiguity fix"
    )

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

func runLayoutConverterTests() throws {
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
    try expect(
        converter.convert(
            "idxeyb",
            englishLayoutVariant: .dvorak,
            russianLayoutType: .windows
        ),
        "привет",
        "Dvorak English layout converts wrong-layout Russian word"
    )
    try expect(
        converter.convert(
            "руддщ",
            englishLayoutVariant: .dvorak,
            russianLayoutType: .windows
        ),
        "d.nnr",
        "Dvorak English layout reverses Russian word to Dvorak output"
    )
    try expect(
        converter.convertToRussian(
            "-",
            englishLayoutVariant: .dvorak,
            russianLayoutType: .windows
        ),
        "э",
        "Dvorak English layout maps apostrophe physical key output to Russian e"
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

func runLayoutDetectionPolicyTests() throws {
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

func runWordTrackerTests() throws {
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
        tracker.trackKeyPress(keyCode: 0, characters: "ghbdtn@#$^&", russianLayoutType: .windows)
        try expect(
            tracker.getLastWord(),
            "ghbdtn@#$^&",
            "word tracker keeps Windows shifted-number mapped punctuation in last word"
        )
    }

    do {
        let tracker = WordTracker()
        tracker.trackKeyPress(
            keyCode: 0,
            characters: "idxeyb-",
            englishLayoutVariant: .dvorak,
            russianLayoutType: .windows
        )
        try expect(
            tracker.getLastWord(),
            "idxeyb-",
            "word tracker keeps Dvorak punctuation mapped to Russian letters in last word"
        )
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
        tracker.replaceTrackedTail(
            with: "idxeyb-",
            reason: "Dvorak tail replacement test",
            englishLayoutVariant: .dvorak,
            russianLayoutType: .windows
        )
        try expect(
            tracker.getLastWord(),
            "idxeyb-",
            "replaceTrackedTail keeps Dvorak punctuation mapped to Russian letters in last word"
        )
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

