import Foundation

public enum LayoutDetectionPolicy {
    public static let englishThreshold = 0.8
    public static let russianThreshold = 0.2

    public static func detectedLayout(englishCount: Int, russianCount: Int) -> LayoutConverter.DetectedLayout {
        let total = englishCount + russianCount
        guard total > 0 else {
            return .unknown
        }

        let englishRatio = Double(englishCount) / Double(total)
        if englishRatio > englishThreshold {
            return .english
        }
        if englishRatio < russianThreshold {
            return .russian
        }
        return .mixed
    }

    public static func isEnglishLetter(_ character: Character) -> Bool {
        guard character.unicodeScalars.count == 1,
              let scalar = character.unicodeScalars.first else {
            return false
        }
        return (scalar.value >= 0x41 && scalar.value <= 0x5A) ||
               (scalar.value >= 0x61 && scalar.value <= 0x7A)
    }

    public static func isRussianLetter(_ character: Character) -> Bool {
        guard character.unicodeScalars.count == 1,
              let scalar = character.unicodeScalars.first else {
            return false
        }
        return (scalar.value >= 0x410 && scalar.value <= 0x44F) ||
               scalar.value == 0x401 ||
               scalar.value == 0x451
    }
}
