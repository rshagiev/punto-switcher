// Read the built-in layout tables without enabling or switching input sources.
// swiftc Sources/PuntoNative/Layouts.swift Sources/PuntoCore/Conversion.swift Scripts/check-layouts.swift -o /tmp/punto-layouts-check
import Foundation
import Carbon

@main struct LayoutsCheck {
    static func main() {
        let ru = Layouts.russianPhonetic
        for en in ["com.apple.keylayout.ABC", "com.apple.keylayout.US"] {
            for (before,after) in [("privet","привет"),("Privet","Привет"),("PRIVET","ПРИВЕТ"),("Privet 123\n🙂","Привет 123\n🙂"),("[]-=\\`","южьъэщ"),("{}_+|~","ЮЖЬЪЭЩ"),("®™©€","®™©€")] {
                precondition(Layouts.convertPhonetic(before,from:en,to:ru) == after, before)
                precondition(Layouts.convertPhonetic(after,from:ru,to:en) == before, after)
            }
            let selected = LayoutConversion.selection("  [Privet]\t«привет»\n🙂  ") { word, toRussian in
                Layouts.convertPhonetic(word,from:toRussian ? en : ru,to:toRussian ? ru : en,preservingPunctuation:true)
            }
            precondition(selected == "  [Привет]\t«privet»\n🙂  ")
            precondition(Layouts.convertPhonetic("[—] €",from:en,to:ru,preservingPunctuation:true) == "[—] €")
            precondition(Layouts.convertPhonetic("privet",from:en,to:"missing-layout") == "privet")
            // Continued typing maps back into the original layout for undo.
            precondition("pri" + Layouts.convertPhonetic("вет",from:ru,to:en) == "privet")
        }
        precondition(Layouts.convertPhonetic("privet",from:"missing-layout",to:ru) == "privet")
        print("PASS: ABC and U.S. ↔ Russian – QWERTY, case, punctuation, selection, emoji, undo and unavailable layouts")
    }
}
