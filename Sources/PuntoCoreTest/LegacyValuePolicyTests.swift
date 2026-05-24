import Foundation
import PuntoCore

func runLegacyValuePolicyTests() throws {
    let legacyDate = Date(timeIntervalSince1970: 1_230_757_200)

    try expect(
        LegacyValuePolicy.bool(" on "),
        true,
        "legacy value policy parses on-style true strings"
    )
    try expect(
        LegacyValuePolicy.bool("OFF"),
        false,
        "legacy value policy parses off-style false strings"
    )
    try expectNil(
        LegacyValuePolicy.bool("maybe"),
        "legacy value policy rejects unknown boolean strings"
    )
    try expect(
        LegacyValuePolicy.bool("maybe", defaultValue: true),
        true,
        "legacy value policy falls back for unknown boolean strings"
    )
    try expect(
        LegacyValuePolicy.int(" 42 "),
        42,
        "legacy value policy parses string-backed integers"
    )
    try expectNil(
        LegacyValuePolicy.int("4.2"),
        "legacy value policy rejects non-integer numeric strings"
    )
    try expect(
        LegacyValuePolicy.nonNegativeInt("-3", defaultValue: 7),
        0,
        "legacy value policy clamps negative integers"
    )
    try expect(
        LegacyValuePolicy.nonNegativeInt("bad", defaultValue: 7),
        7,
        "legacy value policy falls back for unreadable integers"
    )
    try expect(
        LegacyValuePolicy.date("2009-01-01 00:00:00 +0300"),
        legacyDate,
        "legacy value policy parses Punto Switcher date strings"
    )
    try expectNil(
        LegacyValuePolicy.date("1230757200"),
        "legacy value policy does not parse numeric date strings unless requested"
    )
    try expect(
        LegacyValuePolicy.date("1230757200", allowNumericString: true),
        legacyDate,
        "legacy value policy parses numeric date strings for policies that already accepted them"
    )
    try expect(
        LegacyValuePolicy.normalizedStringArray([" COM.Example.App ", "", "com.example.app", "org.example.Editor"]),
        ["com.example.app", "org.example.editor"],
        "legacy value policy normalizes bundle-id arrays"
    )
}
