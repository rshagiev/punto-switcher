import Foundation
import PuntoCore

func runBooleanSettingsPersistencePolicyTests() throws {
    try expect(
        SettingsPersistencePolicy.effectiveBool(
            hasPersistedValue: false,
            persistedValue: false,
            defaultValue: true
        ),
        true,
        "settings persistence uses boolean default before a value is saved"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBool(
            hasPersistedValue: true,
            persistedValue: false,
            defaultValue: true
        ),
        false,
        "settings persistence preserves explicit false boolean value"
    )
    try expect(
        LegacyValuePolicy.bool(" YES "),
        true,
        "legacy value policy parses string-backed true boolean imports"
    )
    try expect(
        LegacyValuePolicy.bool("0"),
        false,
        "legacy value policy parses string-backed false boolean imports"
    )
    try expectNil(
        LegacyValuePolicy.bool("maybe"),
        "legacy value policy rejects unknown string-backed boolean imports"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: false
        ),
        true,
        "settings persistence reads Punto Switcher-style legacy boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: false,
            legacyValue: true,
            defaultValue: false
        ),
        false,
        "settings persistence ignores legacy boolean payload when the legacy key is absent"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            legacyValue: LegacyValuePolicy.bool("on"),
            defaultValue: false
        ),
        true,
        "settings persistence reads string-backed Punto Switcher-style legacy boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: LegacyValuePolicy.bool("0"),
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: true
        ),
        false,
        "settings persistence prefers string-backed native boolean key over legacy alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: true
        ),
        false,
        "settings persistence prefers native boolean key over legacy alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            invertedLegacyValue: false,
            defaultValue: false
        ),
        true,
        "settings persistence reads inverted Punto Switcher-style boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            invertedLegacyValue: LegacyValuePolicy.bool("false"),
            defaultValue: false
        ),
        true,
        "settings persistence reads string-backed inverted Punto Switcher-style boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            invertedLegacyValue: false,
            defaultValue: true
        ),
        false,
        "settings persistence prefers native boolean key over inverted legacy alias"
    )
}
