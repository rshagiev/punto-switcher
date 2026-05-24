import Foundation
import PuntoCore

func runInputSourceLanguagePolicyTests() throws {
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
}
