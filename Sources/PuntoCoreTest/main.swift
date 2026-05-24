import Foundation
import PuntoCore

let suites = [
    TestSuite(name: "layout", aliases: ["word", "words", "converter"]) {
        try runWordBoundaryPolicyTests()
        try runWordTrackingPolicyTests()
        try runLayoutConverterTests()
        try runLayoutDetectionPolicyTests()
        try runWordTrackerTests()
    },
    TestSuite(name: "text", aliases: ["capture", "replacement", "undo"]) {
        try runClipboardCapturePolicyTests()
        try runTerminalTailCapturePolicyTests()
        try runNonSettableContentCapturePolicyTests()
        try runTextTailReplacementPolicyTests()
        try runTextCaptureDecisionPolicyTests()
        try runClipboardContentCapturePolicyTests()
        try runTextCaptureFallbackPolicyTests()
        try runLayoutConversionReplacementPolicyTests()
        try runManualLayoutConversionPolicyTests()
        try runManualLayoutConversionRuntimePolicyTests()
        try runConversionSessionTests()
        try runUndoReplacementPolicyTests()
        try runUndoRuntimePolicyTests()
        try runTextReplacementCommitPolicyTests()
        try runConversionOriginPolicyTests()
    },
    TestSuite(name: "settings", aliases: ["application", "app", "persistence"]) {
        try runApplicationLayoutMemoryTests()
        try runApplicationBundleIDPolicyTests()
        try runApplicationLayoutPolicyTests()
        try runSettingsDefaultsPolicyTests()
        try runLayoutAndManualSettingsPolicyTests()
        try runApplicationSettingsPolicyTests()
        try runAutoCorrectionSettingsPolicyTests()
        try runSoundClipboardStatisticsSettingsPolicyTests()
        try runBooleanSettingsPersistencePolicyTests()
        try runKeyboardInputSourceSettingsPolicyTests()
        try runReturnKeySettingsPersistencePolicyTests()
        try runLegacyValuePolicyTests()
        try runUndoLearningSettingsPolicyTests()
        try runProductStatisticsPolicyTests()
        try runApplicationUpdateSettingsPolicyTests()
        try runStartupPresentationPolicyTests()
        try runLayoutSwitchPolicyTests()
        try runApplicationDisablePolicyTests()
        try runAutoCorrectionTogglePolicyTests()
        try runStatusIconPolicyTests()
        try runAccessibilityPreferencesPolicyTests()
    },
    TestSuite(name: "runtime", aliases: ["routing", "accessibility", "security"]) {
        try runInputSourceChangePolicyTests()
        try runInputSourceSwitchVerificationPolicyTests()
        try runConversionProtectionPolicyTests()
        try runInputSourceLanguagePolicyTests()
        try runApplicationContextPolicyTests()
        try runHotkeyRoutingPolicyTests()
        try runKeyTrackingRuntimePolicyTests()
        try runTextActionPreflightPolicyTests()
        try runTextActionRuntimePreflightPolicyTests()
        try runPointerEventPolicyTests()
        try runEventTapLifecyclePolicyTests()
        try runAccessibilityNotificationPolicyTests()
        try runTextTrackingSecurityPolicyTests()
        try runAccessibilityRolePolicyTests()
        try runAccessibilityTraversalPolicyTests()
        try runKeyboardReplacementPolicyTests()
        try runTextReplacementPolicyTests()
        try runAccessibilityReplacementPolicyTests()
    },
    TestSuite(name: "hotkeys", aliases: ["search", "case", "autocorrect", "auto-correction"]) {
        try runHotkeyPolicyTests()
        try runKeyDownEventPolicyTests()
        try runSearchShortcutPolicyTests()
        try runSelectedTextSearchPolicyTests()
        try runSearchClickPolicyTests()
        try runSearchbarSettingsPolicyTests()
        try runCaseConverterTests()
        try runToggleCasePolicyTests()
        try runToggleCaseConversionPolicyTests()
        try runAutoCorrectionEngineTests()
        try runAutoCorrectionPreflightPolicyTests()
        try runAutoCorrectionReplacementPolicyTests()
        try runAutoCorrectionRuntimePolicyTests()
        try runAutoCorrectionUndoLearningPolicyTests()
        try runAutoCorrectionRuleStoreTests()
        try runLegacyUserRulePolicyTests()
        try runAutoCorrectionRuleSourcePolicyTests()
        try runAutoCorrectionStarterCatalogTests()
        try runApplicationReturnKeyPolicyTests()
        try runAccessibilityApplicationPolicyTests()
    },
    TestSuite(name: "sound", aliases: ["log", "logging"]) {
        try runSoundFeedbackPolicyTests()
        try runLogRetentionPolicyTests()
    }
]

let requestedSuites = Array(CommandLine.arguments.dropFirst())

if requestedSuites.contains("list") || requestedSuites.contains("--list") {
    print("PuntoCoreTest suites: all \(suites.map(\.name).joined(separator: " "))")
    exit(0)
}

let suitesToRun: [TestSuite]
if requestedSuites.isEmpty || requestedSuites.contains("all") {
    suitesToRun = suites
} else {
    var selectedSuites: [TestSuite] = []
    var selectedSuiteNames = Set<String>()
    var unknownSuites: [String] = []
    for requestedSuite in requestedSuites {
        if let suite = suites.first(where: { $0.matches(requestedSuite) }) {
            if selectedSuiteNames.insert(suite.name).inserted {
                selectedSuites.append(suite)
            }
        } else {
            unknownSuites.append(requestedSuite)
        }
    }
    if !unknownSuites.isEmpty {
        fputs(
            "PuntoCoreTest unknown suite(s): \(unknownSuites.joined(separator: ", ")). Available: all \(suites.map(\.name).joined(separator: " "))\n",
            stderr
        )
        exit(2)
    }
    suitesToRun = selectedSuites
}

do {
    print("PuntoCoreTest starting: \(suitesToRun.map(\.name).joined(separator: ", "))")
    for suite in suitesToRun {
        print("PuntoCoreTest suite: \(suite.name)")
        try suite.run()
    }
    print("PuntoCoreTest passed")
} catch {
    fputs("PuntoCoreTest failed: \(error)\n", stderr)
    exit(1)
}
