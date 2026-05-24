import Foundation
import PuntoCore

func runSoundFeedbackPolicyTests() throws {
    try expect(
        SoundFeedbackPolicy.requiredResourceNames,
        ["replace", "reverse", "misprint", "switch", "en", "ru", "typeeng", "typerus"],
        "sound feedback declares every bundled Punto-style sound resource"
    )
    try expect(
        SoundFeedbackPolicy.defaultEnabledResourceNames,
        SoundFeedbackPolicy.requiredResourceNames,
        "sound feedback enables every resource by default"
    )
    try expect(
        SoundFeedbackPolicy.displayRows,
        [
            [
                SoundResourceDisplayItem(title: "Replace", resourceName: "replace"),
                SoundResourceDisplayItem(title: "Reverse", resourceName: "reverse")
            ],
            [
                SoundResourceDisplayItem(title: "Misprint", resourceName: "misprint"),
                SoundResourceDisplayItem(title: "Switch", resourceName: "switch")
            ],
            [
                SoundResourceDisplayItem(title: "English", resourceName: "en"),
                SoundResourceDisplayItem(title: "Russian", resourceName: "ru")
            ],
            [
                SoundResourceDisplayItem(title: "Typed EN", resourceName: "typeeng"),
                SoundResourceDisplayItem(title: "Typed RU", resourceName: "typerus")
            ]
        ],
        "sound feedback owns settings UI display rows for bundled resources"
    )
    try expect(
        Set(SoundFeedbackPolicy.displayOrder.map(\.resourceName)),
        SoundFeedbackPolicy.requiredResourceNames,
        "sound feedback settings display covers every bundled resource"
    )
    try expect(
        SoundFeedbackPolicy.displayOrder.count,
        SoundFeedbackPolicy.requiredResourceNames.count,
        "sound feedback settings display lists every bundled resource exactly once"
    )
    try expect(
        Set(SoundFeedbackPolicy.legacyPerResourceToggleKeys),
        [
            "useSoundLayoutSwitchToRussian",
            "useSoundLayoutSwitchToEnglish",
            "useSoundConvertation",
            "useSoundMisprint",
            "useSoundAutocorrection",
            "useSoundUndo",
            "useSoundKeystrokes"
        ],
        "sound feedback declares observed Punto Switcher per-resource sound toggles"
    )
    try expect(
        PuntoSwitcherObservedSurface.SoundFeedback.skipNextLanguageChangeSoundSelector,
        "shouldSkipNextLanguageChangeSound",
        "sound feedback pins observed Punto Switcher skip-next-language-change-sound selector"
    )
    try expect(
        SoundFeedbackPolicy.legacyIsSoundOnKey,
        "isSoundOn",
        "sound feedback pins observed Punto Switcher global sound key"
    )
    try expect(
        PuntoSwitcherObservedSurface.SoundFeedback.setSoundStateSelector,
        "setSoundState:isSoundOn:",
        "sound feedback pins observed Punto Switcher sound-state setter"
    )
    try expect(
        SoundFeedbackPolicy.legacyEnabledSoundsKey,
        "enabledSounds",
        "sound feedback pins observed Punto Switcher enabled-sounds bitmask key"
    )
    try expect(
        SoundFeedbackPolicy.normalizedEnabledResourceNames(["replace", "unknown", "ru"]),
        ["replace", "ru"],
        "sound feedback drops unknown per-resource settings"
    )
    try expect(
        SoundFeedbackPolicy.enabledResourceNames(fromLegacyBitmask: 502),
        ["reverse", "misprint", "en", "ru", "typeeng", "typerus"],
        "sound feedback reads observed Punto Switcher enabledSounds bitmask"
    )
    try expectNil(
        SoundFeedbackPolicy.enabledResourceNames(fromLegacyBitmask: nil),
        "sound feedback ignores missing legacy enabledSounds bitmask"
    )
    try expect(
        SoundFeedbackPolicy.enabledResourceNames(fromLegacyToggles: [
            "useSoundLayoutSwitchToRussian": false,
            "useSoundLayoutSwitchToEnglish": true,
            "useSoundConvertation": false,
            "useSoundKeystrokes": false,
            "unknown": false
        ]),
        ["reverse", "misprint", "switch", "en"],
        "sound feedback reads Punto Switcher useSound flags as resource toggles"
    )
    try expect(
        SoundFeedbackPolicy.enabledResourceNames(fromLegacyToggles: [
            "useSoundMisprint": false,
            "useSoundAutocorrection": true
        ]),
        ["replace", "reverse", "switch", "en", "ru", "typeeng", "typerus"],
        "sound feedback lets disabled legacy aliases win when two aliases share native misprint feedback"
    )
    try expectNil(
        SoundFeedbackPolicy.enabledResourceNames(fromLegacyToggles: ["unknown": false]),
        "sound feedback ignores unknown legacy toggle names"
    )
    try expect(
        SoundFeedbackPolicy.eventAfterTextInput(characters: "a", detectedLayout: .english),
        .typedText(layout: .english),
        "sound feedback emits typed English event for English input"
    )
    try expect(
        SoundFeedbackPolicy.eventAfterTextInput(characters: "ф", detectedLayout: .russian),
        .typedText(layout: .russian),
        "sound feedback emits typed Russian event for Russian input"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterTextInput(characters: "", detectedLayout: .english),
        "sound feedback skips empty text input"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterTextInput(characters: nil, detectedLayout: .english),
        "sound feedback skips nil text input"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterTextInput(characters: "1", detectedLayout: .unknown),
        "sound feedback skips unknown text input"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterTextInput(characters: "aф", detectedLayout: .mixed),
        "sound feedback skips mixed text input"
    )
    try expect(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(targetLayout: .english, didSwitch: true),
        .inputSourceSwitch(to: .english),
        "sound feedback emits English switch event after standalone English input-source switch"
    )
    try expect(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(targetLayout: .russian, didSwitch: true),
        .inputSourceSwitch(to: .russian),
        "sound feedback emits Russian switch event after standalone Russian input-source switch"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(
            targetLayout: .english,
            didSwitch: true,
            context: .textReplacement
        ),
        "sound feedback skips input-source switch sound after text replacement"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(
            targetLayout: .russian,
            didSwitch: true,
            context: .textReplacement
        ),
        "sound feedback skips Russian input-source switch sound after text replacement"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(
            targetLayout: .english,
            didSwitch: true,
            context: .rememberedApplicationRestore
        ),
        "sound feedback skips English input-source switch sound after remembered application layout restore"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(
            targetLayout: .russian,
            didSwitch: true,
            context: .rememberedApplicationRestore
        ),
        "sound feedback skips Russian input-source switch sound after remembered application layout restore"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(targetLayout: .english, didSwitch: false),
        "sound feedback skips failed input-source switch"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(targetLayout: .mixed, didSwitch: true),
        "sound feedback skips non-switchable mixed input-source target"
    )
    try expectNil(
        SoundFeedbackPolicy.eventAfterInputSourceSwitch(targetLayout: .unknown, didSwitch: true),
        "sound feedback skips non-switchable unknown input-source target"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .layoutConversion, soundEffectsEnabled: true),
        "replace",
        "sound feedback uses replace sound for layout conversion"
    )
    try expectNil(
        SoundFeedbackPolicy.resourceName(
            for: .layoutConversion,
            soundEffectsEnabled: true,
            enabledResourceNames: ["reverse", "misprint"]
        ),
        "sound feedback skips disabled replace resource"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(
            for: .undo,
            soundEffectsEnabled: true,
            enabledResourceNames: ["reverse"]
        ),
        "reverse",
        "sound feedback still plays enabled reverse resource"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .undo, soundEffectsEnabled: true),
        "reverse",
        "sound feedback uses reverse sound for undo"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .toggleCase, soundEffectsEnabled: true),
        "replace",
        "sound feedback uses replace sound for toggle case"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .autoCorrection, soundEffectsEnabled: true),
        "misprint",
        "sound feedback uses misprint sound for auto-correction"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .inputSourceSwitch(to: .english), soundEffectsEnabled: true),
        "en",
        "sound feedback uses en sound for English input source switch"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .inputSourceSwitch(to: .russian), soundEffectsEnabled: true),
        "ru",
        "sound feedback uses ru sound for Russian input source switch"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .inputSourceSwitch(to: .unknown), soundEffectsEnabled: true),
        "switch",
        "sound feedback uses generic switch sound for unknown input source switch"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .typedText(layout: .english), soundEffectsEnabled: true),
        "typeeng",
        "sound feedback uses typeeng sound for typed English input"
    )
    try expect(
        SoundFeedbackPolicy.resourceName(for: .typedText(layout: .russian), soundEffectsEnabled: true),
        "typerus",
        "sound feedback uses typerus sound for typed Russian input"
    )
    try expectNil(
        SoundFeedbackPolicy.resourceName(for: .typedText(layout: .unknown), soundEffectsEnabled: true),
        "sound feedback skips typed unknown resource"
    )
    try expectNil(
        SoundFeedbackPolicy.resourceName(for: .layoutConversion, soundEffectsEnabled: false),
        "sound feedback is disabled globally"
    )
}

func runLogRetentionPolicyTests() throws {
    try expect(
        LogRetentionPolicy.shouldRotateActiveLog(size: LogRetentionPolicy.maxActiveLogSize),
        false,
        "log retention keeps active log at max size"
    )
    try expect(
        LogRetentionPolicy.shouldRotateActiveLog(size: LogRetentionPolicy.maxActiveLogSize + 1),
        true,
        "log retention rotates active log above max size"
    )

    let archivePath = LogRetentionPolicy.archivePath(
        for: Date(timeIntervalSince1970: 1_230_757_200),
        directory: "/tmp"
    )
    try expect(
        archivePath,
        "/tmp/punto.log.2008-12-31-21-00-00-000.log",
        "log retention writes deterministic Punto-style archive names"
    )
    try expect(
        LogRetentionPolicy.archivePath(
            for: Date(timeIntervalSince1970: 1_230_757_200),
            directory: "/tmp",
            collisionIndex: 2
        ),
        "/tmp/punto.log.2008-12-31-21-00-00-000-002.log",
        "log retention writes deterministic collision archive names"
    )
    try expect(
        LogRetentionPolicy.uniqueArchivePath(
            for: Date(timeIntervalSince1970: 1_230_757_200),
            directory: "/tmp",
            existingPaths: [
                "/tmp/punto.log.2008-12-31-21-00-00-000.log",
                "/tmp/punto.log.2008-12-31-21-00-00-000-001.log"
            ]
        ),
        "/tmp/punto.log.2008-12-31-21-00-00-000-002.log",
        "log retention chooses the first non-colliding archive path"
    )
    try expect(
        LogRetentionPolicy.shouldArchiveActiveLogAtStartup(size: 0),
        false,
        "log retention keeps empty startup log unarchived"
    )
    try expect(
        LogRetentionPolicy.shouldArchiveActiveLogAtStartup(size: 1),
        true,
        "log retention archives non-empty startup log before clearing active file"
    )

    let base = Date(timeIntervalSince1970: 1_000)
    let files = [
        ArchivedLogFile(path: "/tmp/punto.log.old.log", size: 10, modifiedAt: base),
        ArchivedLogFile(path: "/tmp/punto.log.mid.log", size: 10, modifiedAt: base.addingTimeInterval(1)),
        ArchivedLogFile(path: "/tmp/punto.log.new.log", size: 10, modifiedAt: base.addingTimeInterval(2))
    ]
    try expect(
        LogRetentionPolicy.archivedLogFilesToDelete(files, maximumNumberOfFiles: 2, diskQuota: 100),
        ["/tmp/punto.log.old.log"],
        "log retention deletes oldest files beyond maximum count"
    )
    try expect(
        LogRetentionPolicy.archivedLogFilesToDelete(files, maximumNumberOfFiles: 5, diskQuota: 15),
        ["/tmp/punto.log.mid.log", "/tmp/punto.log.old.log"],
        "log retention preserves newest files within disk quota"
    )
    try expect(
        LogRetentionPolicy.archivedLogFilesToDelete(files, maximumNumberOfFiles: 0, diskQuota: 100),
        files.map(\.path).sorted(),
        "log retention zero max count deletes all archived logs"
    )
}
