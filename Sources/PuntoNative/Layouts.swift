import AppKit
import Carbon

final class Layouts {
    static let russianPhonetic = "com.apple.keylayout.Russian-Phonetic"
    static func property(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }
    static var all: [TISInputSource] { keyboardLayouts() }
    private static func keyboardLayouts(includeDisabled: Bool = false) -> [TISInputSource] {
        (TISCreateInputSourceList([kTISPropertyInputSourceType!: kTISTypeKeyboardLayout!] as CFDictionary, includeDisabled).takeRetainedValue() as NSArray).compactMap { $0 as! TISInputSource? }
    }
    static var currentID: String { property(TISCopyCurrentKeyboardInputSource().takeRetainedValue(), kTISPropertyInputSourceID) ?? "" }
    static func select(_ id: String) -> Bool {
        guard let source = all.first(where: { property($0,kTISPropertyInputSourceID) == id }) else { return false }
        return TISSelectInputSource(source) == noErr
    }
    static func translate(_ key: UInt16, flags: CGEventFlags, source: TISInputSource) -> String {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return "" }
        let data = Unmanaged<CFData>.fromOpaque(ptr).takeUnretainedValue()
        let layout = UnsafeRawPointer(CFDataGetBytePtr(data)).assumingMemoryBound(to: UCKeyboardLayout.self)
        var dead: UInt32 = 0, length = 0
        var chars = [UniChar](repeating: 0, count: 8)
        var mods: UInt32 = 0
        if flags.contains(.maskShift) { mods |= UInt32(shiftKey) }
        if flags.contains(.maskAlphaShift) { mods |= UInt32(alphaLock) }
        if flags.contains(.maskAlternate) { mods |= UInt32(optionKey) }
        let status = UCKeyTranslate(layout, key, UInt16(kUCKeyActionDown), mods >> 8, UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit), &dead, chars.count, &length, &chars)
        return status == noErr ? String(utf16CodeUnits: chars, count: length) : ""
    }
    struct Stroke { let key: UInt16; let flags: CGEventFlags; let text: String }
    private static var keyMaps: [String: [String: Stroke]] = [:]
    static func strokes(_ text: String, sourceID: String) -> [Stroke] {
        if keyMaps[sourceID] == nil, let source = all.first(where: { property($0,kTISPropertyInputSourceID) == sourceID }) {
            var map: [String: Stroke] = [:]
            // Prefer ordinary keys over Option dead-key combinations and keypad keys.
            for flags: CGEventFlags in [[], .maskShift, .maskAlternate, [.maskShift,.maskAlternate]] {
                for key: UInt16 in 0..<51 {
                    let value = translate(key, flags:flags, source:source)
                    if value.count == 1, map[value] == nil { map[value] = Stroke(key:key,flags:flags,text:value) }
                }
            }
            keyMaps[sourceID] = map
        }
        return text.map { character in
            let value = String(character)
            return keyMaps[sourceID]?[value] ?? Stroke(key:0,flags:[],text:value)
        }
    }
    private static var phoneticMaps: [[String]: [Character: Character]] = [:]
    static func convertPhonetic(_ text: String, from sourceID: String, to targetID: String, preservingPunctuation: Bool = false) -> String {
        guard sourceID != targetID, [sourceID,targetID].contains(russianPhonetic) else { return text }
        let pair = [sourceID,targetID]
        if phoneticMaps[pair] == nil {
            let sources = keyboardLayouts(includeDisabled:true)
            guard let source = sources.first(where: { property($0,kTISPropertyInputSourceID) == sourceID }),
                  let target = sources.first(where: { property($0,kTISPropertyInputSourceID) == targetID }) else { return text }
            phoneticMaps[pair] = phoneticMap(from:source,to:target)
        }
        let map = phoneticMaps[pair] ?? [:]
        return String(text.map { character in
            if preservingPunctuation, !character.isLetter { return character }
            return map[character] ?? character
        })
    }
    private static func phoneticMap(from source: TISInputSource, to target: TISInputSource) -> [Character: Character] {
        func russianLetter(_ value: String) -> Bool {
            guard let scalar = value.unicodeScalars.first, value.unicodeScalars.count == 1 else { return false }
            return (0x410...0x44F).contains(scalar.value) || scalar.value == 0x401 || scalar.value == 0x451
        }
        // Use plain and Shift keys to avoid interpreting Option symbols as letters.
        // Some phonetic letters share a physical key with Latin punctuation.
        var pairs: [(Character, Character)] = []
        for flags: CGEventFlags in [[], .maskShift] {
            for key: UInt16 in 0..<51 {
                let before = translate(key,flags:flags,source:source)
                let after = translate(key,flags:flags,source:target)
                guard before.count == 1, after.count == 1, let input = before.first, let output = after.first,
                      russianLetter(before) != russianLetter(after) else { continue }
                let latinSide = russianLetter(before) ? after : before
                guard latinSide.utf8.count == 1, let byte = latinSide.utf8.first, (33...126).contains(byte) else { continue }
                pairs.append((input,output))
            }
        }
        let reverse = Dictionary(grouping:pairs) { $0.1 }
        let forward = Dictionary(grouping:pairs) { $0.0 }
        return forward.compactMapValues { candidates in
            guard let candidate = candidates.first, candidates.count == 1, reverse[candidate.1]?.count == 1 else { return nil }
            return candidate.1
        }
    }
    static func text(_ key: UInt16, flags: CGEventFlags) -> String {
        translate(key, flags: flags, source: TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue())
    }
    static func keyName(_ key: UInt16) -> String {
        let source = all.first { property($0,kTISPropertyInputSourceID) == "com.apple.keylayout.ABC" } ?? TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
        let s = translate(key, flags: [], source: source)
        return s.isEmpty ? "Код \(key)" : s.uppercased()
    }
}
