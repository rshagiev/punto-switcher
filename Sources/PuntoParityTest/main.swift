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
    return value
}

private func expectNil<T>(_ actual: @autoclosure () -> T?, _ message: String) throws {
    let value = actual()
    guard value == nil else {
        throw TestFailure(description: "\(message): expected nil, got \(String(describing: value))")
    }
}

private struct ConversionCase {
    let input: String
    let expected: String
    let description: String
}

private func runConversionCorpus() throws {
    let converter = LayoutConverter()

    let cases: [ConversionCase] = [
        ConversionCase(input: "ghbdtn", expected: "привет", description: "standard wrong-layout RU word"),
        ConversionCase(input: "hello", expected: "руддщ", description: "standard wrong-layout EN word"),
        ConversionCase(input: "world", expected: "цщкдв", description: "second common EN word"),
        ConversionCase(input: "q", expected: "й", description: "single lowercase letter"),
        ConversionCase(input: "GHBDTN", expected: "ПРИВЕТ", description: "all-caps word"),
        ConversionCase(input: "Ghbdtn", expected: "Привет", description: "capitalized word"),
        ConversionCase(input: "test", expected: "еуые", description: "common lowercase word"),
        ConversionCase(input: "привет", expected: "ghbdtn", description: "standard wrong-layout EN reverse word"),
        ConversionCase(input: "руддщ", expected: "hello", description: "reverse hello"),
        ConversionCase(input: "мир", expected: "vbh", description: "reverse short RU word"),
        ConversionCase(input: "й", expected: "q", description: "single lowercase reverse letter"),
        ConversionCase(input: "ПРИВЕТ", expected: "GHBDTN", description: "all-caps reverse word"),
        ConversionCase(input: "Привет", expected: "Ghbdtn", description: "capitalized reverse word"),
        ConversionCase(input: "123", expected: "123", description: "numbers stay unchanged"),
        ConversionCase(input: "hello 123", expected: "руддщ 123", description: "text plus digits"),
        ConversionCase(input: "test123test", expected: "еуые123еуые", description: "digits inside text"),
        ConversionCase(input: "   ", expected: "   ", description: "spaces stay unchanged"),
        ConversionCase(input: "hello world", expected: "руддщ цщкдв", description: "two words"),
        ConversionCase(input: "HeLLo", expected: "РуДДщ", description: "mixed case is preserved"),
        ConversionCase(input: "Hello World", expected: "Руддщ Цщкдв", description: "title case is preserved"),
        ConversionCase(input: "hELLO", expected: "рУДДЩ", description: "inverted case is preserved")
    ]

    for testCase in cases {
        try expect(converter.convert(testCase.input), testCase.expected, "conversion corpus \(testCase.description)")
    }

    let windowsSymbols: [ConversionCase] = [
        ConversionCase(input: "[", expected: "х", description: "open bracket"),
        ConversionCase(input: "]", expected: "ъ", description: "close bracket"),
        ConversionCase(input: "{", expected: "Х", description: "open brace"),
        ConversionCase(input: "}", expected: "Ъ", description: "close brace"),
        ConversionCase(input: ";", expected: "ж", description: "semicolon"),
        ConversionCase(input: "'", expected: "э", description: "apostrophe"),
        ConversionCase(input: ":", expected: "Ж", description: "colon"),
        ConversionCase(input: "\"", expected: "Э", description: "double quote"),
        ConversionCase(input: ",", expected: "б", description: "comma"),
        ConversionCase(input: ".", expected: "ю", description: "period"),
        ConversionCase(input: "/", expected: ".", description: "slash"),
        ConversionCase(input: "?", expected: ",", description: "question mark"),
        ConversionCase(input: "<", expected: "Б", description: "less than"),
        ConversionCase(input: ">", expected: "Ю", description: "greater than"),
        ConversionCase(input: "`", expected: "ё", description: "backtick"),
        ConversionCase(input: "~", expected: "Ё", description: "tilde")
    ]

    for testCase in windowsSymbols {
        try expect(converter.convert(testCase.input), testCase.expected, "windows symbol conversion \(testCase.description)")
        if !["/", "?"].contains(testCase.input) {
            try expect(converter.convert(testCase.expected), testCase.input, "windows symbol round-trip \(testCase.description)")
        }
    }

    let macSymbols: [ConversionCase] = [
        ConversionCase(input: "\\", expected: "ё", description: "Mac backslash key"),
        ConversionCase(input: "|", expected: "Ё", description: "Mac shifted backslash key"),
        ConversionCase(input: "`", expected: "]", description: "Mac backtick key"),
        ConversionCase(input: "~", expected: "[", description: "Mac shifted backtick key")
    ]

    for testCase in macSymbols {
        try expect(
            converter.convert(testCase.input, russianLayoutType: .mac),
            testCase.expected,
            "mac symbol conversion \(testCase.description)"
        )
        if !["`", "~"].contains(testCase.input) {
            try expect(
                converter.convert(testCase.expected, russianLayoutType: .mac),
                testCase.input,
                "mac symbol round-trip \(testCase.description)"
            )
        }
    }
}

private func runRoundTripCorpus() throws {
    let converter = LayoutConverter()
    let samples = [
        "hello",
        "привет",
        "HELLO",
        "ПРИВЕТ",
        "Hello World",
        "123abc",
        "test!",
        "data[0]",
        "test'case",
        "[test]",
        ";',./",
        "path/to/file.txt"
    ]

    for sample in samples {
        try expect(converter.convert(converter.convert(sample)), sample, "round-trip corpus \(sample.debugDescription)")
    }

    let emojiPreservingCases = [
        ("👋 hello", "👋 руддщ"),
        ("hello 👋", "руддщ 👋"),
        ("hel👋lo", "руд👋дщ")
    ]
    for (input, expected) in emojiPreservingCases {
        let result = converter.convertWithResult(input)
        try expect(result.text, expected, "emoji-adjacent EN/RU text converts around emoji \(input.debugDescription)")
        try expect(result.shouldApply, true, "emoji-adjacent EN/RU text is applicable \(input.debugDescription)")
    }

    for sample in ["👋", "カタカナ", "مرحبا"] {
        let result = converter.convertWithResult(sample)
        try expect(result.text, sample, "non EN/RU corpus passes through \(sample.debugDescription)")
        try expect(result.shouldApply, false, "non EN/RU corpus is non-applicable \(sample.debugDescription)")
    }
}

private func runRepeatedConversionCorpus() throws {
    let converter = LayoutConverter()

    let simpleRoundTrips = [
        "hello",
        "ghbdtn",
        "привет",
        "HELLO",
        "GHBDTN",
        "Hello World",
        "test123"
    ]
    for sample in simpleRoundTrips {
        try expect(
            converter.convert(converter.convert(sample)),
            sample,
            "repeated conversion simple round-trip \(sample.debugDescription)"
        )
    }

    for sample in ["hello", "привет", "Test"] {
        var text = sample
        for _ in 1...3 {
            text = converter.convert(text)
        }
        let after3 = text
        text = converter.convert(text)
        let after4 = text
        text = converter.convert(text)
        let after5 = text

        try expect(after4, sample, "repeated conversion even symmetry \(sample.debugDescription)")
        try expect(after5, after3, "repeated conversion odd symmetry \(sample.debugDescription)")
        try expect(after5 != sample, true, "repeated conversion odd state differs from original \(sample.debugDescription)")
    }

    for sample in ["keyboard", "клавиатура", "MixedCase", "123abc456"] {
        var text = sample
        for index in 1...20 {
            text = converter.convert(text)
            if index.isMultiple(of: 2) {
                try expect(text, sample, "repeated conversion 10 round-trips \(sample.debugDescription) at step \(index)")
            }
        }
    }

    try expect(converter.convert("ghbdtn"), "привет", "repeated conversion user scenario EN keys to RU word")
    try expect(converter.convert("привет"), "ghbdtn", "repeated conversion user scenario back to original EN keys")
    try expect(converter.convert("руддщ"), "hello", "repeated conversion reverse user scenario RU keys to EN word")
    try expect(converter.convert("hello"), "руддщ", "repeated conversion reverse user scenario back to original RU keys")

    let specialRoundTrips = [";", "'", "[", "]", "`", ",", "."]
    for sample in specialRoundTrips {
        try expect(
            converter.convert(converter.convert(sample)),
            sample,
            "repeated conversion special-key round-trip \(sample.debugDescription)"
        )
    }

    for sample in ["hello;world", "test'case", "data[0]", "path/to/file"] {
        try expect(
            converter.convert(converter.convert(sample)),
            sample,
            "repeated conversion punctuation text round-trip \(sample.debugDescription)"
        )
    }

    try expect(converter.convert("12345"), "12345", "repeated conversion leaves numbers unchanged")
    try expect(converter.convert(converter.convert("12345")), "12345", "repeated conversion numbers stay unchanged twice")

    let caseSamples: [(String, String)] = [
        ("HeLLo", "РуДДщ"),
        ("WORLD", "ЦЩКДВ"),
        ("MiXeD", "ЬшЧуВ")
    ]
    for (input, expectedConverted) in caseSamples {
        let once = converter.convert(input)
        let twice = converter.convert(once)
        let thrice = converter.convert(twice)
        let fourth = converter.convert(thrice)
        try expect(once, expectedConverted, "repeated conversion preserves first-pass case \(input)")
        try expect(twice, input, "repeated conversion preserves second-pass case \(input)")
        try expect(thrice, expectedConverted, "repeated conversion preserves third-pass case \(input)")
        try expect(fourth, input, "repeated conversion preserves fourth-pass case \(input)")
    }

    for sample in ["hello", "привет", "Test123"] {
        var text = sample
        for index in 1...100 {
            text = converter.convert(text)
            if index.isMultiple(of: 2) {
                try expect(text, sample, "repeated conversion 50 round-trips \(sample.debugDescription) at step \(index)")
            }
        }
    }
}

private func runRapidConversionCorpus() throws {
    let converter = LayoutConverter()

    try expect(converter.convert("ghb"), "при", "rapid conversion incremental partial word")
    try expect(converter.convert("ghbdtn"), "привет", "rapid conversion incremental full word")

    let rapidWords: [(String, String)] = [
        ("hello", "руддщ"),
        ("world", "цщкдв"),
        ("test", "еуые"),
        ("swift", "ыцшае"),
        ("code", "сщву")
    ]
    for (input, expected) in rapidWords {
        let converted = converter.convert(input)
        try expect(converted, expected, "rapid conversion word \(input)")
        try expect(converter.convert(converted), input, "rapid conversion word round-trip \(input)")
    }

    let fixed = converter.convert("руддщ")
    let undone = converter.convert(fixed)
    try expect(fixed, "hello", "rapid conversion mistake scenario fixes text")
    try expect(undone, "руддщ", "rapid conversion mistake scenario converts back")

    for sample in ["ghbdtn vbh", "hello world"] {
        try expect(
            converter.convert(converter.convert(sample)),
            sample,
            "rapid conversion multi-word round-trip \(sample.debugDescription)"
        )
    }

    let stressWords = [
        "apple", "banana", "cherry", "date", "elderberry",
        "fig", "grape", "honeydew", "kiwi", "lemon",
        "mango", "nectarine", "orange", "papaya", "quince",
        "raspberry", "strawberry", "tangerine", "watermelon", "zucchini",
        "ant", "bee", "cat", "dog", "elephant",
        "fox", "goat", "horse", "iguana", "jaguar",
        "koala", "lion", "mouse", "newt", "owl",
        "penguin", "quail", "rabbit", "snake", "tiger",
        "urchin", "viper", "whale", "xerus", "yak",
        "zebra", "aardvark", "badger", "coyote", "dolphin"
    ]
    for word in stressWords {
        let converted = converter.convert(word)
        try expect(converter.convert(converted), word, "rapid conversion stress word \(word)")
    }
}

private func runSelectedTextCorpus() throws {
    let converter = LayoutConverter()

    let singleWordCases: [(String, String)] = [
        ("ghbdtn", "привет"),
        ("привет", "ghbdtn"),
        ("GHBDTN", "ПРИВЕТ"),
        ("Ghbdtn", "Привет")
    ]
    for (input, expected) in singleWordCases {
        try expect(converter.convert(input), expected, "selected text single-word conversion \(input)")
    }

    let paragraph = "Ghbdtn? Rfr ltkf? Z gbie yf Hecctrv!"
    try expect(
        converter.convert(converter.convert(paragraph)),
        paragraph,
        "selected text paragraph round-trip"
    )

    let partialCases: [(String, String)] = [
        ("hel", "руд"),
        ("при", "ghb"),
        ("HEL", "РУД")
    ]
    for (input, expected) in partialCases {
        try expect(converter.convert(input), expected, "selected text partial-word conversion \(input)")
    }

    for sample in [
        "Line one\nLine two\nLine three",
        "hello\tworld",
        "hello  world",
        "hello\nworld",
        "  hello  "
    ] {
        try expect(
            converter.convert(converter.convert(sample)),
            sample,
            "selected text whitespace/multiline round-trip \(sample.debugDescription)"
        )
    }
}

private func runLayoutDecisionCorpus() throws {
    let converter = LayoutConverter()
    let cases: [(String, LayoutConverter.DetectedLayout, String)] = [
        ("abcdefgh", .english, "all English"),
        ("абвгдежз", .russian, "all Russian"),
        ("abcd абвг", .mixed, "half English half Russian"),
        ("12345", .unknown, "digits only"),
        ("abcdefghij абв", .mixed, "below English threshold"),
        ("abcdefghijk абв", .mixed, "still below English threshold"),
        ("abcdefghijkl абв", .mixed, "exact English threshold remains mixed"),
        ("abcdefghijklm абв", .english, "above English threshold")
    ]

    for (input, expected, description) in cases {
        try expect(converter.detectLayout(input), expected, "layout decision corpus \(description)")
    }
}

private func runWordTrackerCorpus() throws {
    func tracker(after characters: String, russianLayoutType: KeyboardLayoutType = .windows) -> WordTracker {
        let tracker = WordTracker(maxSize: 50, maxTailSize: 80)
        for character in characters {
            tracker.trackKeyPress(keyCode: 0, characters: String(character), russianLayoutType: russianLayoutType)
        }
        return tracker
    }

    try expect(tracker(after: "hello").getLastWord(), "hello", "word tracker basic word")
    try expectNil(tracker(after: "hello ").getLastWord(), "word tracker clears last word after space")
    try expect(tracker(after: "hello.").getLastWord(), "hello.", "word tracker keeps mapped period")
    try expect(tracker(after: "hello,").getLastWord(), "hello,", "word tracker keeps mapped comma")
    try expect(tracker(after: "hello:").getLastWord(), "hello:", "word tracker keeps mapped colon")
    try expect(tracker(after: "hello;").getLastWord(), "hello;", "word tracker keeps mapped semicolon")
    try expect(tracker(after: "hello'").getLastWord(), "hello'", "word tracker keeps mapped apostrophe")
    try expect(tracker(after: "hello[").getLastWord(), "hello[", "word tracker keeps mapped bracket")
    try expect(tracker(after: "hello`").getLastWord(), "hello`", "word tracker keeps mapped backtick")
    try expect(tracker(after: "hello/").getLastWord(), "hello/", "word tracker keeps slash because it maps to period")
    try expect(tracker(after: "hello?").getLastWord(), "hello?", "word tracker keeps question mark because it maps to comma")
    try expectNil(tracker(after: "hello!").getLastWord(), "word tracker clears after hard sentence boundary")
    try expectNil(tracker(after: "hello(").getLastWord(), "word tracker clears after grouping boundary")
    try expect(tracker(after: "hello world").getLastWord(), "world", "word tracker keeps only last word after space")
    try expect(tracker(after: "git commit").getTypedTail(), "git commit", "word tracker keeps terminal command tail")

    let backspaceTracker = tracker(after: "hello")
    backspaceTracker.trackKeyPress(keyCode: KeyboardEventKeyCodePolicy.backspaceKeyCode, characters: nil)
    try expect(backspaceTracker.getLastWord(), "hell", "word tracker handles backspace")

    let navigationTracker = tracker(after: "hello")
    navigationTracker.trackKeyPress(keyCode: KeyboardEventKeyCodePolicy.leftArrowKeyCode, characters: nil)
    try expectNil(navigationTracker.getLastWord(), "word tracker clears after navigation")

    try expect(tracker(after: "\\|", russianLayoutType: .mac).getLastWord(), "\\|", "word tracker keeps Mac Russian physical punctuation")
    try expectNil(tracker(after: "\\|", russianLayoutType: .windows).getLastWord(), "word tracker treats Windows slash-like physical punctuation as boundary")
}

private func runCaptureAndReplacementCorpus() throws {
    try expect(
        TextCapturePolicy.terminalTailRewrite(
            selectedText: "user@host % git commit\n",
            lastTrackedTail: "git commit"
        ),
        TextCapturePolicy.TailRewrite(selectedText: "git commit", originalTail: "git commit"),
        "terminal capture accepts prompt-prefixed current command"
    )
    try expectNil(
        TextCapturePolicy.terminalTailRewrite(
            selectedText: "old scrollback git commit",
            lastTrackedTail: "git commit"
        ),
        "terminal capture rejects promptless scrollback"
    )
    try expect(
        TextReplacementPolicy.rewriteTail("git commit ghbdtn", replacing: "ghbdtn", with: "привет"),
        "git commit привет",
        "terminal replacement rewrites only current suffix"
    )
    try expectNil(
        TextReplacementPolicy.rewriteTail("otherghbdtn", replacing: "ghbdtn", with: "привет"),
        "terminal replacement rejects glued stale suffix"
    )
}

private let suites: [(String, () throws -> Void)] = [
    ("conversion corpus", runConversionCorpus),
    ("round-trip corpus", runRoundTripCorpus),
    ("repeated conversion corpus", runRepeatedConversionCorpus),
    ("rapid conversion corpus", runRapidConversionCorpus),
    ("selected text corpus", runSelectedTextCorpus),
    ("layout decisions", runLayoutDecisionCorpus),
    ("word tracker corpus", runWordTrackerCorpus),
    ("capture and replacement corpus", runCaptureAndReplacementCorpus)
]

do {
    for (name, suite) in suites {
        try suite()
        print("PASS \(name)")
    }
    print("PuntoParityTest passed")
} catch let failure as TestFailure {
    fputs("FAIL \(failure.description)\n", stderr)
    exit(1)
} catch {
    fputs("FAIL \(error)\n", stderr)
    exit(1)
}
