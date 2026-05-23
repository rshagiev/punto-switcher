import Foundation

public enum CaseConverter {
    public static func toggleCase(_ text: String) -> String {
        String(text.map(toggleCase))
    }

    private static func toggleCase(_ character: Character) -> Character {
        if character.isUppercase {
            return Character(character.lowercased())
        }

        if character.isLowercase {
            return Character(character.uppercased())
        }

        return character
    }
}
