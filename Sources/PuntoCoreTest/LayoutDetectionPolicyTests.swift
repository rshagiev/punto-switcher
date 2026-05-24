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
