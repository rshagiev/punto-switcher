import Foundation

/// Word-level ranges in UTF-16. Whitespace and punctuation remain exact tokens.
public struct ProofreadingDiff {
    public struct Edit {
        public let id:Int
        public let range:NSRange
        public let original:String
        public let replacement:String
    }
    public let original:String
    public let edits:[Edit]
    public func result(rejecting rejected:Set<Int>) -> String {
        let ns = original as NSString
        var output = "", cursor = 0
        for edit in edits {
            output += ns.substring(with:NSRange(location:cursor,length:edit.range.location-cursor))
            output += rejected.contains(edit.id) ? edit.original : edit.replacement
            cursor = NSMaxRange(edit.range)
        }
        return output + ns.substring(from:cursor)
    }
    public let removed: [NSRange]
    public let inserted: [NSRange]
    public init(original: String, corrected: String, phrases:Bool = false) {
        self.original = original
        let pattern = phrases ? #"[^.!?\n]+[.!?]*|[.!?]+|\n"# : #"[\p{L}\p{M}\p{N}_]+|\s+|[^\p{L}\p{M}\p{N}_\s]"#
        let regex = try! NSRegularExpression(pattern: pattern)
        func tokens(_ text: String) -> [(String, NSRange)] {
            let ns = text as NSString
            return regex.matches(in:text,range:NSRange(location:0,length:ns.length)).map { (ns.substring(with:$0.range),$0.range) }
        }
        let before = tokens(original), after = tokens(corrected)
        let changes = after.map(\.0).difference(from:before.map(\.0))
        var old: [NSRange] = [], new: [NSRange] = []
        var oldIndices = Set<Int>(), newIndices = Set<Int>()
        for change in changes {
            switch change {
            case .remove(let offset,_,_): old.append(before[offset].1); oldIndices.insert(offset)
            case .insert(let offset,_,_): new.append(after[offset].1); newIndices.insert(offset)
            }
        }
        var groups:[Edit] = [], i = 0, j = 0
        while i < before.count || j < after.count {
            if oldIndices.contains(i) || newIndices.contains(j) {
                let start = i < before.count ? before[i].1.location : (original as NSString).length
                let firstOld = i, firstNew = j
                while oldIndices.contains(i) { i += 1 }
                while newIndices.contains(j) { j += 1 }
                let end = i > firstOld ? NSMaxRange(before[i-1].1) : start
                if phrases && i-firstOld == j-firstNew && i-firstOld > 1 {
                    for offset in 0..<(i-firstOld) {
                        let old = before[firstOld+offset], new = after[firstNew+offset]
                        groups.append(Edit(id:groups.count,range:old.1,original:old.0,replacement:new.0))
                    }
                } else {
                groups.append(Edit(id:groups.count,range:NSRange(location:start,length:end-start),
                    original:before[firstOld..<i].map(\.0).joined(),replacement:after[firstNew..<j].map(\.0).joined()))
                }
            } else { i += 1; j += 1 }
        }
        edits = groups
        func merged(_ ranges: [NSRange]) -> [NSRange] {
            var result: [NSRange] = []
            for range in ranges.sorted(by: { $0.location < $1.location }) {
                if let last = result.last, NSMaxRange(last) == range.location {
                    result[result.count-1].length += range.length
                } else { result.append(range) }
            }
            return result
        }
        removed = merged(old); inserted = merged(new)
    }
}
