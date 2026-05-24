import Foundation
import PuntoCore

func runKeyboardLayoutInputSourcePolicyTests() throws {
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
        KeyboardLayoutVariantPolicy.englishLayoutVariant(for: " COM.APPLE.KEYLAYOUT.DVORAK "),
        .dvorak,
        "keyboard layout variant policy resolves Dvorak English variant"
    )
    try expect(
        KeyboardLayoutVariantPolicy.englishLayoutVariant(for: " com.apple.keylayout.ABC "),
        .qwerty,
        "keyboard layout variant policy resolves default English variant"
    )
    try expect(
        KeyboardLayoutVariantPolicy.effectiveEnglishLayoutVariant(
            currentSourceID: "com.apple.keylayout.Dvorak",
            selectedEnglishSourceID: "com.apple.keylayout.ABC",
            preferredEnglishSourceID: nil
        ),
        .dvorak,
        "keyboard layout variant policy lets active Dvorak source override selected default English"
    )
    try expect(
        KeyboardLayoutVariantPolicy.effectiveEnglishLayoutVariant(
            currentSourceID: "com.apple.keylayout.Russian",
            selectedEnglishSourceID: "com.apple.keylayout.Dvorak",
            preferredEnglishSourceID: "com.apple.keylayout.ABC"
        ),
        .dvorak,
        "keyboard layout variant policy falls back to selected English source when current source is Russian"
    )
    try expect(
        KeyboardLayoutVariantPolicy.effectiveEnglishLayoutVariant(
            currentSourceID: "com.apple.keylayout.Russian",
            selectedEnglishSourceID: nil,
            preferredEnglishSourceID: "com.apple.keylayout.Dvorak"
        ),
        .dvorak,
        "keyboard layout variant policy falls back to preferred English source before defaulting"
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
}
