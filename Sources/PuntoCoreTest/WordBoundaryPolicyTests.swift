import Foundation
import PuntoCore

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
