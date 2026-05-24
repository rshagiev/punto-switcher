import Foundation
import PuntoCore

func runKeyboardInputSourceSettingsPolicyTests() throws {
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
        InputSourceSelectionPolicy.legacyUndefinedSourceID,
        "UNDEFINED",
        "settings persistence owns observed undefined input-source id sentinel as a legacy alias"
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
}
