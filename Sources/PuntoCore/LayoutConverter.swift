import Foundation

/// Converts text between Russian and English keyboard layouts
public final class LayoutConverter {
    public init() {}

    // MARK: - Conversion

    /// Converts text between layouts, auto-detecting the source layout.
    /// Mixed English/Russian text is left unchanged; punctuation-only text can
    /// still use the physical-key majority fallback.
    public func convert(_ text: String) -> String {
        convertWithResult(text).text
    }

    public func convert(_ text: String, russianLayoutType: KeyboardLayoutType) -> String {
        convertWithResult(text, russianLayoutType: russianLayoutType).text
    }

    public func convert(
        _ text: String,
        englishLayoutVariant: KeyboardLayoutVariant,
        russianLayoutType: KeyboardLayoutType
    ) -> String {
        convertWithResult(
            text,
            englishLayoutVariant: englishLayoutVariant,
            russianLayoutType: russianLayoutType
        ).text
    }

    /// Converts English text to Russian layout
    public func convertToRussian(_ text: String) -> String {
        convertToRussian(text, russianLayoutType: .windows)
    }

    public func convertToRussian(_ text: String, russianLayoutType: KeyboardLayoutType) -> String {
        convertToRussian(text, englishLayoutVariant: .qwerty, russianLayoutType: russianLayoutType)
    }

    public func convertToRussian(
        _ text: String,
        englishLayoutVariant: KeyboardLayoutVariant,
        russianLayoutType: KeyboardLayoutType
    ) -> String {
        let maps = KeyboardLayoutMappingPolicy.characterMaps(
            for: englishLayoutVariant,
            russianLayoutType: russianLayoutType
        )
        return String(text.map { maps.enToRu[$0] ?? $0 })
    }

    /// Converts Russian text to English layout
    public func convertToEnglish(_ text: String) -> String {
        convertToEnglish(text, russianLayoutType: .windows)
    }

    public func convertToEnglish(_ text: String, russianLayoutType: KeyboardLayoutType) -> String {
        convertToEnglish(text, englishLayoutVariant: .qwerty, russianLayoutType: russianLayoutType)
    }

    public func convertToEnglish(
        _ text: String,
        englishLayoutVariant: KeyboardLayoutVariant,
        russianLayoutType: KeyboardLayoutType
    ) -> String {
        let maps = KeyboardLayoutMappingPolicy.characterMaps(
            for: englishLayoutVariant,
            russianLayoutType: russianLayoutType
        )
        return String(text.map { maps.ruToEn[$0] ?? $0 })
    }

    // MARK: - Layout Detection

    public enum DetectedLayout {
        case english
        case russian
        case mixed
        case unknown
    }

    /// Результат конвертации с информацией о направлении
    public struct ConversionResult {
        public let text: String
        public let targetLayout: DetectedLayout

        public var shouldApply: Bool {
            targetLayout != .unknown
        }
    }

    /// Конвертирует текст и возвращает результат с направлением
    public func convertWithResult(_ text: String) -> ConversionResult {
        convertWithResult(text, russianLayoutType: .windows)
    }

    public func convertWithResult(
        _ text: String,
        russianLayoutType: KeyboardLayoutType
    ) -> ConversionResult {
        convertWithResult(text, englishLayoutVariant: .qwerty, russianLayoutType: russianLayoutType)
    }

    public func convertWithResult(
        _ text: String,
        englishLayoutVariant: KeyboardLayoutVariant,
        russianLayoutType: KeyboardLayoutType
    ) -> ConversionResult {
        let sourceLayout = detectLayout(text)

        switch sourceLayout {
        case .english:
            return ConversionResult(
                text: convertToRussian(
                    text,
                    englishLayoutVariant: englishLayoutVariant,
                    russianLayoutType: russianLayoutType
                ),
                targetLayout: .russian
            )
        case .russian:
            return ConversionResult(
                text: convertToEnglish(
                    text,
                    englishLayoutVariant: englishLayoutVariant,
                    russianLayoutType: russianLayoutType
                ),
                targetLayout: .english
            )
        case .mixed:
            return ConversionResult(text: text, targetLayout: .unknown)
        case .unknown:
            let maps = KeyboardLayoutMappingPolicy.characterMaps(
                for: englishLayoutVariant,
                russianLayoutType: russianLayoutType
            )
            let direction = majorityConversionDirection(for: text, maps: maps)
            switch direction {
            case .toRussian:
                return ConversionResult(
                    text: convertToRussian(
                        text,
                        englishLayoutVariant: englishLayoutVariant,
                        russianLayoutType: russianLayoutType
                    ),
                    targetLayout: .russian
                )
            case .toEnglish:
                return ConversionResult(
                    text: convertToEnglish(
                        text,
                        englishLayoutVariant: englishLayoutVariant,
                        russianLayoutType: russianLayoutType
                    ),
                    targetLayout: .english
                )
            case .none:
                return ConversionResult(text: text, targetLayout: .unknown)
            }
        }
    }

    /// Detects the keyboard layout of the given text
    public func detectLayout(_ text: String) -> DetectedLayout {
        var englishCount = 0
        var russianCount = 0

        for char in text {
            if isEnglishLetter(char) {
                englishCount += 1
            } else if isRussianLetter(char) {
                russianCount += 1
            }
        }

        return LayoutDetectionPolicy.detectedLayout(
            englishCount: englishCount,
            russianCount: russianCount
        )
    }

    private func isEnglishLetter(_ char: Character) -> Bool {
        LayoutDetectionPolicy.isEnglishLetter(char)
    }

    private func isRussianLetter(_ char: Character) -> Bool {
        LayoutDetectionPolicy.isRussianLetter(char)
    }

    private enum ConversionDirection {
        case toRussian
        case toEnglish
        case none
    }

    private func majorityConversionDirection(
        for text: String,
        maps: KeyboardLayoutCharacterMaps
    ) -> ConversionDirection {
        var enToRuCount = 0
        var ruToEnCount = 0

        for char in text {
            if let converted = maps.enToRu[char], converted != char {
                enToRuCount += 1
            }
            if let converted = maps.ruToEn[char], converted != char {
                ruToEnCount += 1
            }
        }

        guard enToRuCount > 0 || ruToEnCount > 0 else {
            return .none
        }

        if enToRuCount >= ruToEnCount {
            return .toRussian
        } else {
            return .toEnglish
        }
    }

}
