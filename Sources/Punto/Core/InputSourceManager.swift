import Carbon
import Foundation

/// Язык для переключения раскладки
enum KeyboardLanguage {
    case english
    case russian
}

/// Управление системными раскладками клавиатуры через TIS API
final class InputSourceManager {

    private var englishSource: TISInputSource?
    private var russianSource: TISInputSource?

    init() {
        refreshInputSources()
    }

    /// Обновить список доступных раскладок
    func refreshInputSources() {
        guard let sourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return
        }

        for source in sourceList {
            guard isSelectableKeyboard(source) else { continue }

            let languages = getLanguages(source)
            let sourceId = getSourceId(source)

            if englishSource == nil && (languages.contains("en") || sourceId.contains("US") || sourceId.contains("ABC")) {
                englishSource = source
                PuntoLog.info("Found English input source: \(sourceId)")
            }

            if russianSource == nil && (languages.contains("ru") || sourceId.contains("Russian")) {
                russianSource = source
                PuntoLog.info("Found Russian input source: \(sourceId)")
            }
        }
    }

    /// Переключить раскладку на указанный язык
    @discardableResult
    func switchTo(_ language: KeyboardLanguage) -> Bool {
        let source: TISInputSource? = language == .english ? englishSource : russianSource

        guard let source = source else {
            PuntoLog.info("Input source not found for \(language)")
            return false
        }

        let status = TISSelectInputSource(source)
        if status == noErr {
            PuntoLog.info("Switched keyboard to \(language)")
            return true
        } else {
            PuntoLog.error("Failed to switch input source, error: \(status)")
            return false
        }
    }

    // MARK: - Private Helpers

    private func isSelectableKeyboard(_ source: TISInputSource) -> Bool {
        guard let category = getProperty(source, kTISPropertyInputSourceCategory) as? String,
              category == kTISCategoryKeyboardInputSource as String else {
            return false
        }
        return getProperty(source, kTISPropertyInputSourceIsSelectCapable) as? Bool ?? false
    }

    private func getSourceId(_ source: TISInputSource) -> String {
        return getProperty(source, kTISPropertyInputSourceID) as? String ?? ""
    }

    private func getLanguages(_ source: TISInputSource) -> [String] {
        return getProperty(source, kTISPropertyInputSourceLanguages) as? [String] ?? []
    }

    private func getProperty(_ source: TISInputSource, _ key: CFString) -> Any? {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue()
    }
}
