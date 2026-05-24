import Foundation
import PuntoCore

func runReturnKeySettingsPersistencePolicyTests() throws {
    try expect(
        ApplicationReturnKeyPolicy.normalizedResetBundleComponents([
            " Telegram ",
            "",
            "SLACK"
        ]),
        ["telegram", "slack"],
        "settings persistence normalizes reset-on-return components"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: false,
            persistedComponents: nil
        ),
        ApplicationReturnKeyPolicy.defaultResetBundleComponents,
        "settings persistence uses default reset-on-return components before user config"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: false,
            persistedComponents: nil,
            hasLegacyComponents: true,
            legacyComponents: [" Telegram ", "", "SLACK"]
        ),
        ["telegram", "slack"],
        "settings persistence reads Punto Switcher switcher.reset_on_return alias"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: true,
            persistedComponents: [],
            hasLegacyComponents: true,
            legacyComponents: ["telegram"]
        ),
        [],
        "settings persistence prefers intentionally empty native reset-on-return override"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: true,
            persistedComponents: nil,
            hasLegacyComponents: true,
            legacyComponents: ["telegram"]
        ),
        ApplicationReturnKeyPolicy.defaultResetBundleComponents,
        "settings persistence falls back to default for unreadable reset-on-return config"
    )
}
