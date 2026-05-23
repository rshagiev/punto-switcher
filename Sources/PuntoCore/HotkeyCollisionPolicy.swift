import Foundation

public enum HotkeySlot: String, CaseIterable, Equatable {
    case convertLayout
    case toggleCase
    case toggleAutoCorrection
    case cancelLayoutChange
    case findInYandex
    case findInSlovari
}

public struct HotkeyAssignment: Equatable {
    public let slot: HotkeySlot
    public let hotkey: Hotkey

    public init(slot: HotkeySlot, hotkey: Hotkey) {
        self.slot = slot
        self.hotkey = hotkey
    }
}

public enum HotkeyCollisionPolicy {
    public static func collidingSlot(
        for candidate: Hotkey,
        in assignments: [HotkeyAssignment],
        excluding excludedSlot: HotkeySlot
    ) -> HotkeySlot? {
        guard !candidate.isDisabled else {
            return nil
        }

        return assignments.first { assignment in
            assignment.slot != excludedSlot
                && !assignment.hotkey.isDisabled
                && assignment.hotkey == candidate
        }?.slot
    }

    public static func doesCollideWithExistingShortcuts(
        _ candidate: Hotkey,
        in assignments: [HotkeyAssignment],
        excluding excludedSlot: HotkeySlot
    ) -> Bool {
        collidingSlot(for: candidate, in: assignments, excluding: excludedSlot) != nil
    }

    public static func canAllowShortcut(
        _ candidate: Hotkey,
        in assignments: [HotkeyAssignment],
        excluding excludedSlot: HotkeySlot
    ) -> Bool {
        !doesCollideWithExistingShortcuts(candidate, in: assignments, excluding: excludedSlot)
    }
}
