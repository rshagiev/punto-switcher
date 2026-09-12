import Foundation

/// Conservative local routing, evaluated only when opening a new review.
public enum ProcessingDepth {
    public static func suggestsStructure(_ text:String) -> Bool {
        guard !text.contains("```"), text.utf16.count <= 12000 else { return false }
        let lower = text.lowercased()
        let wordRegex = try! NSRegularExpression(pattern:#"[\p{L}\p{N}]+"#)
        func words(_ value:String)->[String] {
            let ns = value as NSString
            return wordRegex.matches(in:value,range:NSRange(location:0,length:ns.length)).map { ns.substring(with:$0.range) }
        }
        let tokens = words(lower)
        guard tokens.count >= 18 else { return false }
        var signals = 0
        let corrections = ["нет лучше", "нет давай", "я хотел сказать", "точнее", "вернее", "поправлюсь", "no actually", "i mean", "rather than that"]
        let normalized = " " + tokens.joined(separator:" ") + " "
        if corrections.contains(where:{normalized.contains(" "+$0+" ")}) { signals += 1 }
        let runs = lower.components(separatedBy:CharacterSet(charactersIn:".!?;\n"))
        if runs.map({words($0).count}).max() ?? 0 >= 32 { signals += 1 }
        // A repeated phrase is stronger evidence than emphatic word repetition.
        var seen = Set<String>(), repeated = false
        if tokens.count >= 6 {
            for i in 0...(tokens.count-3) {
                let phrase = tokens[i...i+2].joined(separator:" ")
                if !seen.insert(phrase).inserted { repeated = true }
            }
        }
        if repeated { signals += 1 }
        let enumerators = ["первое", "второе", "третье", "во первых", "во вторых", "first", "second", "third"]
        let enumerationCount = enumerators.filter { normalized.contains(" "+$0+" ") }.count
        if enumerationCount >= 2 && text.filter({$0 == "\n"}).count < 2 { signals += 1 }
        return signals >= 2
    }
}
