import Foundation
import PuntoCore

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
        LayoutDetectionPolicy.detectedLayout(for: "hello123"),
        .english,
        "layout detection policy detects text layout from characters"
    )
    try expect(
        LayoutDetectionPolicy.detectedLayout(for: "привет123"),
        .russian,
        "layout detection policy detects Russian text layout from characters"
    )
    try expect(
        LayoutDetectionPolicy.detectedLayout(for: "heллo"),
        .mixed,
        "layout detection policy detects mixed text from characters"
    )
    try expect(
        LayoutDetectionPolicy.detectedLayout(for: "123"),
        .unknown,
        "layout detection policy detects unknown text without EN/RU letters"
    )
    try expect(
        LayoutDetectionPolicy.isMixedLayout("heллo"),
        true,
        "layout detection policy exposes mixed-layout predicate"
    )
    try expect(
        LayoutDetectionPolicy.isMixedLayout("hello123"),
        false,
        "layout detection policy does not mark single-layout text as mixed"
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
