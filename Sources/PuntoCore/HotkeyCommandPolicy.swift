import Foundation

public struct HotkeyCommandMetadata: Equatable {
    public let slot: HotkeySlot
    public let title: String
    public let systemName: String
    public let resetTag: Int
    public let defaultHotkey: Hotkey
    public let routingKind: HotkeyRoutingKind
    public let keyDownAction: KeyDownAction

    public init(
        slot: HotkeySlot,
        title: String,
        systemName: String,
        resetTag: Int,
        defaultHotkey: Hotkey,
        routingKind: HotkeyRoutingKind,
        keyDownAction: KeyDownAction
    ) {
        self.slot = slot
        self.title = title
        self.systemName = systemName
        self.resetTag = resetTag
        self.defaultHotkey = defaultHotkey
        self.routingKind = routingKind
        self.keyDownAction = keyDownAction
    }
}

public enum HotkeyCommandPolicy {
    public static let displayOrder: [HotkeyCommandMetadata] = [
        HotkeyCommandMetadata(
            slot: .convertLayout,
            title: "Convert Layout",
            systemName: "textformat.abc",
            resetTag: 0,
            defaultHotkey: .defaultConvertLayout,
            routingKind: .convertLayout,
            keyDownAction: .convertLayoutHotkey
        ),
        HotkeyCommandMetadata(
            slot: .toggleCase,
            title: "Toggle Case",
            systemName: "textformat",
            resetTag: 1,
            defaultHotkey: .defaultToggleCase,
            routingKind: .toggleCase,
            keyDownAction: .toggleCaseHotkey
        ),
        HotkeyCommandMetadata(
            slot: .toggleAutoCorrection,
            title: "Toggle Auto-correction",
            systemName: "wand.and.stars",
            resetTag: 2,
            defaultHotkey: .defaultToggleAutoCorrection,
            routingKind: .toggleAutoCorrection,
            keyDownAction: .toggleAutoCorrectionHotkey
        ),
        HotkeyCommandMetadata(
            slot: .cancelLayoutChange,
            title: "Cancel Last Conversion",
            systemName: "arrow.uturn.backward",
            resetTag: 3,
            defaultHotkey: .defaultCancelLayoutChange,
            routingKind: .cancelLayoutChange,
            keyDownAction: .cancelLayoutChangeHotkey
        ),
        HotkeyCommandMetadata(
            slot: .findInYandex,
            title: "Find in Yandex",
            systemName: "magnifyingglass",
            resetTag: 4,
            defaultHotkey: .defaultFindInYandex,
            routingKind: .findInYandex,
            keyDownAction: .findInYandexHotkey
        ),
        HotkeyCommandMetadata(
            slot: .findInSlovari,
            title: "Find in Translate",
            systemName: "character.book.closed",
            resetTag: 5,
            defaultHotkey: .defaultFindInSlovari,
            routingKind: .findInSlovari,
            keyDownAction: .findInSlovariHotkey
        )
    ]

    public static func metadata(for slot: HotkeySlot) -> HotkeyCommandMetadata? {
        displayOrder.first { $0.slot == slot }
    }

    public static func slot(forResetTag resetTag: Int) -> HotkeySlot? {
        displayOrder.first { $0.resetTag == resetTag }?.slot
    }

    public static func defaultHotkey(for slot: HotkeySlot) -> Hotkey {
        metadata(for: slot)?.defaultHotkey ?? .disabled
    }
}
