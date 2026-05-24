import Foundation

public enum SettingsToggleSlot: String, CaseIterable, Equatable {
    case launchAtLogin
    case showInMenuBar
    case switchLayoutAfterConversion
    case autoCorrectionEnabled
    case soundEffectsEnabled
    case showAdvancedSettings
    case switchLayoutAfterSelectedTextConversion
    case searchSelectedTextByDoubleClick
    case manualConversionDisabled
    case rememberInputSourceForEachApp
    case autoCorrectOnEnterAndTab
    case autoCorrectionUndoLearningEnabled
    case suppressAutoCorrectionAfterManualConversion
    case completelyDisableInExceptionApplications
}

public struct SettingsToggleMetadata: Equatable {
    public let slot: SettingsToggleSlot
    public let title: String
    public let systemName: String
    public let isAdvanced: Bool

    public init(
        slot: SettingsToggleSlot,
        title: String,
        systemName: String,
        isAdvanced: Bool
    ) {
        self.slot = slot
        self.title = title
        self.systemName = systemName
        self.isAdvanced = isAdvanced
    }
}

public enum SettingsTogglePolicy {
    public static let displayOrder: [SettingsToggleMetadata] = [
        SettingsToggleMetadata(
            slot: .launchAtLogin,
            title: "Launch at login",
            systemName: "power",
            isAdvanced: false
        ),
        SettingsToggleMetadata(
            slot: .showInMenuBar,
            title: "Show in menu bar",
            systemName: "menubar.rectangle",
            isAdvanced: false
        ),
        SettingsToggleMetadata(
            slot: .switchLayoutAfterConversion,
            title: "Switch keyboard after conversion",
            systemName: "arrow.triangle.2.circlepath",
            isAdvanced: false
        ),
        SettingsToggleMetadata(
            slot: .autoCorrectionEnabled,
            title: "Auto-correct typed rules",
            systemName: "wand.and.stars",
            isAdvanced: false
        ),
        SettingsToggleMetadata(
            slot: .soundEffectsEnabled,
            title: "Sound effects",
            systemName: "speaker.wave.2",
            isAdvanced: false
        ),
        SettingsToggleMetadata(
            slot: .showAdvancedSettings,
            title: "Show advanced settings",
            systemName: "gearshape.2",
            isAdvanced: false
        ),
        SettingsToggleMetadata(
            slot: .switchLayoutAfterSelectedTextConversion,
            title: "Switch keyboard for selected text",
            systemName: "selection.pin.in.out",
            isAdvanced: true
        ),
        SettingsToggleMetadata(
            slot: .searchSelectedTextByDoubleClick,
            title: "Search selected text by double-click",
            systemName: "cursorarrow.click.2",
            isAdvanced: true
        ),
        SettingsToggleMetadata(
            slot: .manualConversionDisabled,
            title: "Disable manual conversion",
            systemName: "keyboard.badge.eye",
            isAdvanced: true
        ),
        SettingsToggleMetadata(
            slot: .rememberInputSourceForEachApp,
            title: "Remember layout for each app",
            systemName: "rectangle.stack.person.crop",
            isAdvanced: true
        ),
        SettingsToggleMetadata(
            slot: .autoCorrectOnEnterAndTab,
            title: "Auto-correct on Return and Tab",
            systemName: "return",
            isAdvanced: true
        ),
        SettingsToggleMetadata(
            slot: .autoCorrectionUndoLearningEnabled,
            title: "Learn from undone auto-corrections",
            systemName: "arrow.uturn.backward.circle",
            isAdvanced: true
        ),
        SettingsToggleMetadata(
            slot: .suppressAutoCorrectionAfterManualConversion,
            title: "Skip auto-correct after manual conversion",
            systemName: "arrow.trianglehead.2.clockwise.rotate.90",
            isAdvanced: true
        ),
        SettingsToggleMetadata(
            slot: .completelyDisableInExceptionApplications,
            title: "Fully disable in exception apps",
            systemName: "nosign",
            isAdvanced: true
        )
    ]

    public static var basicDisplayOrder: [SettingsToggleMetadata] {
        displayOrder.filter { !$0.isAdvanced }
    }

    public static var advancedDisplayOrder: [SettingsToggleMetadata] {
        displayOrder.filter(\.isAdvanced)
    }

    public static func metadata(for slot: SettingsToggleSlot) -> SettingsToggleMetadata? {
        displayOrder.first { $0.slot == slot }
    }
}
