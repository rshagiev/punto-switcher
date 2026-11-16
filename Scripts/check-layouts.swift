// Local integration check; requires U.S. and Russian – QWERTY enabled in macOS.
// swiftc Sources/PuntoNative/Layouts.swift Sources/PuntoCore/Conversion.swift Scripts/check-layouts.swift -o /tmp/punto-layouts-check
import Foundation
import Carbon

@main struct LayoutsCheck {
    static func main() {
        let en = "com.apple.keylayout.US", ru = "com.apple.keylayout.Russian-Phonetic"
        let ids = Set(Layouts.all.compactMap { Layouts.property($0,kTISPropertyInputSourceID) })
        precondition(ids.contains(en) && ids.contains(ru),"Enable U.S. and Russian – QWERTY before running this check")
        for (before,after) in [("privet","привет"),("Privet","Привет"),("PRIVET","ПРИВЕТ"),("Privet 123\n🙂","Привет 123\n🙂")] {
            precondition(Layouts.convert(before,from:en,to:ru) == after)
            precondition(Layouts.convert(after,from:ru,to:en) == before)
        }
        let selected = LayoutConversion.selection("  Privet\tпривет\n🙂  ") { word, toRussian in
            Layouts.convert(word,from:toRussian ? en : ru,to:toRussian ? ru : en)
        }
        precondition(selected == "  Привет\tprivet\n🙂  ")
        precondition(Layouts.convert("privet",from:"missing-layout",to:ru) == "privet")
        precondition(Layouts.convert("privet",from:en,to:"missing-layout") == "privet")
        // Continued typing must map back into the original layout for undo.
        precondition("pri" + Layouts.convert("вет",from:ru,to:en) == "privet")
        precondition(Layouts.convert("privet",from:en,to:ru) != "зкшмуе")
        print("PASS: system phonetic layout, both directions, case, selection, whitespace, emoji, undo mapping and unavailable layouts")
    }
}
