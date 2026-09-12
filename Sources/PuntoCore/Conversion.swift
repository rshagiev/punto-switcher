import Foundation

public enum LayoutConversion {
    // Russian Apple keyboard. Punctuation is part of the physical key map.
    public static let english = "§qwertyuiop[]asdfghjkl;'\\`zxcvbnm,./±@#$%^&*QWERTYUIOP{}ASDFGHJKL:\"|~ZXCVBNM<>?"
    public static let russian = ">йцукенгшщзхъфывапролджэё]ячсмитьбю/<\"№%:,.;ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЁ[ЯЧСМИТЬБЮ?"
    public static let russianPC = "ёйцукенгшщзхъфывапролджэ\\]ячсмитьбю.Ё\"№;%:?*ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭ/[ЯЧСМИТЬБЮ,"
    public static func convert(_ text: String, toRussian: Bool, pc: Bool = false) -> String {
        let ru = pc ? russianPC : russian
        let from = Array(toRussian ? english : ru), to = Array(toRussian ? ru : english)
        var map: [Character: Character] = [:]
        for (a,b) in zip(from,to) where map[a] == nil { map[a] = b }
        return String(text.map { map[$0] ?? $0 })
    }
    public static func selection(_ text: String, pc: Bool = false) -> String {
        var result = "", word = ""
        func flush() {
            guard !word.isEmpty else { return }
            let hasRussian = word.unicodeScalars.contains { (0x400...0x4ff).contains($0.value) }
            result += convert(word, toRussian: !hasRussian, pc: pc)
            word = ""
        }
        for c in text {
            if c.isWhitespace { flush(); result.append(c) } else { word.append(c) }
        }
        flush()
        return result
    }
    public static func changeCase(_ text: String) -> String {
        text == text.uppercased() ? text.lowercased() : text.uppercased()
    }
}

public struct UserRule: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var text: String
    public var mode: Mode = .exact
    public var caseSensitive = false
    public var switches = false
    public var enabled = true
    public enum Mode: String, Codable, CaseIterable { case exact, prefix, contains, regex }
    public init(text: String, mode: Mode = .exact, caseSensitive: Bool = false, switches: Bool = false) {
        self.text = text; self.mode = mode; self.caseSensitive = caseSensitive; self.switches = switches
    }
    public var valid: Bool { !text.isEmpty && (mode != .regex || (try? NSRegularExpression(pattern: text)) != nil) }
    public func matches(_ value: String) -> Bool {
        guard enabled, valid else { return false }
        let a = caseSensitive ? value : value.lowercased(), b = caseSensitive ? text : text.lowercased()
        switch mode {
        case .exact: return a == b
        case .prefix: return a.hasPrefix(b)
        case .contains: return a.contains(b)
        case .regex: return value.range(of: text, options: caseSensitive ? [.regularExpression] : [.regularExpression, .caseInsensitive]) != nil
        }
    }
}

public struct OriginalRule: Sendable {
    public let text: String
    public let flags: Int
    public let folded: String
    public init?(line: String) {
        let line = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty, !line.hasPrefix("PSVersion=") else { return nil }
        if line.hasPrefix("_"), let space = line.firstIndex(of: " ") {
            let prefix = line[..<space]
            var f = 0
            for (c, bit) in [("B",2),("P",4),("C",8),("E",16),("A",32),("D",128)] where prefix.contains(c) { f |= bit }
            if f & 6 == 0 { f |= 64 }
            flags = f; text = String(line[line.index(after: space)...])
        } else { flags = 64; text = line }
        folded = text.lowercased()
    }
    public func matches(_ word: String) -> Bool {
        let a = flags & 8 != 0 ? word : word.lowercased()
        let b = flags & 8 != 0 ? text : folded
        if flags & 4 != 0 { return a == b }
        if flags & 2 != 0 { return a.hasPrefix(b) }
        return a.contains(b)
    }
}

public final class AutoRules {
    private var rules: [OriginalRule] = []
    private var triggers: Set<String> = []
    private var sensitive: [String: [(Int,Int)]] = [:]
    private var insensitive: [String: [(Int,Int)]] = [:]
    public init(dictionary: String = "", triggers: String = "") {
        let parsed = dictionary.components(separatedBy: .newlines).compactMap(OriginalRule.init)
        rules = parsed.filter { $0.flags & 32 != 0 } + parsed.filter { $0.flags & 16 != 0 } + parsed.filter { $0.flags & 48 == 0 }
        for (rank,rule) in rules.enumerated() {
            if rule.flags & 8 != 0 { sensitive[rule.text,default:[]].append((rank,rule.flags)) }
            else { insensitive[rule.folded,default:[]].append((rank,rule.flags)) }
        }
        self.triggers = Set(triggers.components(separatedBy: .newlines).filter { !$0.isEmpty }.map { $0.lowercased() })
    }
    public var count: Int { rules.count }
    public func shouldConvert(_ word: String, completed: Bool, userRules: [UserRule]) -> Bool {
        guard !word.isEmpty, word.count < 256 else { return false }
        for rule in userRules where (completed || rule.mode == .prefix || rule.mode == .regex) && rule.matches(word) { return rule.switches }
        if !completed {
            guard triggers.contains(word.lowercased()) else { return false }
            // Before accepting a trigger the original checks whether the typed prefix
            // could still grow into an active literal user rule. Contains rules are
            // evaluated on completion; they must not suppress a trigger mid-word.
            for rule in userRules where rule.enabled && rule.valid && rule.mode != .regex {
                let a = rule.caseSensitive ? rule.text : rule.text.lowercased()
                let b = rule.caseSensitive ? word : word.lowercased()
                if a.hasPrefix(b) { return false }
            }
            return true
        }
        // Select the earliest matching rule, preserving the original's A / E / ordinary ordering.
        var best = Int.max, decision = false
        func scan(_ text: String, index: [String: [(Int,Int)]]) {
            let chars = Array(text)
            for start in chars.indices {
                var token = ""
                for end in start..<chars.count {
                    token.append(chars[end])
                    guard let candidates = index[token] else { continue }
                    for (rank,flags) in candidates where rank < best {
                        if flags & 4 != 0 && (start != 0 || end != chars.count-1) { continue }
                        if flags & 4 == 0 && flags & 2 != 0 && start != 0 { continue }
                        if flags & 4 != 0 && flags & 128 != 0 && flags & 16 == 0 { continue }
                        best = rank; decision = flags & 16 == 0
                    }
                }
            }
        }
        scan(word.lowercased(),index:insensitive)
        scan(word,index:sensitive)
        return decision
    }
}

public struct Shortcut: Codable, Equatable {
    public var key: UInt16?
    public var modifiers: UInt64
    public init(key: UInt16? = nil, modifiers: UInt64 = 0) { self.key = key; self.modifiers = modifiers }
    public var enabled: Bool { key != nil || modifiers != 0 }
    public static let command: UInt64 = 1 << 20, option: UInt64 = 1 << 19, shift: UInt64 = 1 << 17, control: UInt64 = 1 << 18
    public static let mask = command | option | shift | control
}

/// Fires a modifier chord only after release, and never after a character was used with it.
public struct ChordTracker {
    private var peak: UInt64 = 0
    private var interrupted = false
    public init() {}
    public mutating func keyPressed() { if peak != 0 { interrupted = true } }
    public mutating func changed(_ flags: UInt64) -> UInt64? {
        let flags = flags & Shortcut.mask
        if flags == 0 {
            let result = !interrupted && peak != 0 ? peak : nil
            peak = 0; interrupted = false
            return result
        }
        peak |= flags
        return nil
    }
    public mutating func reset() { peak = 0; interrupted = false }
}

public struct TypingBuffer {
    public private(set) var text = ""
    public private(set) var previousWord = ""
    public private(set) var separator = ""
    public private(set) var cancelled = false
    public init() {}
    public mutating func append(_ s: String) {
        if text.isEmpty { previousWord = ""; separator = "" }
        text += s
        if text.count > 256 { reset() }
    }
    public mutating func boundary(_ s: String) { previousWord = text; separator = s; text = ""; cancelled = false }
    public mutating func backspace(cancelAuto: Bool) {
        if !text.isEmpty { text.removeLast() }
        else if separator == " " && !previousWord.isEmpty {
            // Original rawTextBuffer retains the word through one delimiter; erasing
            // that delimiter resumes the same word (observed on Punto 2.1.5).
            text = previousWord; previousWord = ""; separator = ""
        } else { reset() }
        cancelled = cancelled || cancelAuto
    }
    public mutating func cancelAuto() { cancelled = true }
    public mutating func reset() { text = ""; previousWord = ""; separator = ""; cancelled = false }
    public var convertible: String { text.isEmpty ? previousWord : text }
    public var suffix: String { text.isEmpty ? separator : "" }
}
