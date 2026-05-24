import Foundation
import PuntoCore

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
        converter.convertToRussian(
            "_+",
            englishLayoutVariant: .dvorak,
            russianLayoutType: .mac
        ),
        "ЭЪ",
        "Dvorak Mac layout converts shifted physical punctuation through Apple Russian mapping"
    )
    try expect(
        converter.convertToEnglish(
            "ЭЪ",
            englishLayoutVariant: .dvorak,
            russianLayoutType: .mac
        ),
        "_+",
        "Dvorak Mac layout reverses shifted physical punctuation through Apple Russian mapping"
    )
    try expect(
        converter.convert(
            "_+",
            englishLayoutVariant: .dvorak,
            russianLayoutType: .mac
        ),
        "ЭЪ",
        "Dvorak Mac layout auto-converts punctuation-only wrong-layout text"
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
