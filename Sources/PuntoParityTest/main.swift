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
