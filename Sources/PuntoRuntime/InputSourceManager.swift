import Carbon
import Foundation
import PuntoCore

/// Язык для переключения раскладки
public enum KeyboardLanguage {
    case english
    case russian
}

/// Управление системными раскладками клавиатуры через TIS API
public final class InputSourceManager {

    private var englishSource: TISInputSource?
    private var russianSource: TISInputSource?
    private let preferredRussianLayoutType: () -> KeyboardLayoutType
    private let preferredEnglishSourceID: () -> String?
    private let preferredRussianSourceID: () -> String?

    public init(
        preferredRussianLayoutType: @escaping () -> KeyboardLayoutType = { KeyboardLayoutTypePolicy.defaultRussianLayoutType },
        preferredEnglishSourceID: @escaping () -> String? = { nil },
        preferredRussianSourceID: @escaping () -> String? = { nil }
    ) {
        self.preferredRussianLayoutType = preferredRussianLayoutType
        self.preferredEnglishSourceID = preferredEnglishSourceID
        self.preferredRussianSourceID = preferredRussianSourceID
        refreshInputSources()
    }

    /// Обновить список доступных раскладок
    public func refreshInputSources() {
        guard let sourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return
        }

        englishSource = nil
        russianSource = nil

        let candidates = sourceList.map { source in
            InputSourceCandidate(
                sourceID: getSourceId(source),
                languages: getLanguages(source),
                isSelectableKeyboard: isSelectableKeyboard(source),
                isEnabled: isEnabledInputSource(source)
            )
        }
        let selection = InputSourceSelectionPolicy.selection(
            from: candidates,
            preferredRussianLayoutType: preferredRussianLayoutType(),
            preferredEnglishSourceID: preferredEnglishSourceID(),
            preferredRussianSourceID: preferredRussianSourceID()
        )

        if let logMessage = InputSourceSelectionPolicy.handleInputSourcesEnabledLogMessage(
            sourceIDs: selection.sourceIDsToEnable
        ) {
            PuntoLog.info(logMessage)
        }

        for source in sourceList {
            let sourceId = getSourceId(source)
            if englishSource == nil, sourceId == selection.englishSourceID {
                if prepareSelectedInputSource(source, sourceID: sourceId, selection: selection) {
                    englishSource = source
                    PuntoLog.info("Found English input source: \(sourceId)")
                }
            }

            if russianSource == nil, sourceId == selection.russianSourceID {
                if prepareSelectedInputSource(source, sourceID: sourceId, selection: selection) {
                    russianSource = source
                    PuntoLog.info("Found Russian input source: \(sourceId)")
                }
            }
        }

        let activeSelection = InputSourceSelection(
            englishSourceID: englishSource.map(getSourceId),
            russianSourceID: russianSource.map(getSourceId)
        )
        if let message = InputSourceSelectionPolicy.missingRequiredLayoutsLogMessage(selection: activeSelection) {
            PuntoLog.error(message)
        }
    }

    /// Переключить раскладку на указанный язык
    @discardableResult
    public func switchTo(_ language: KeyboardLanguage) -> Bool {
        let source: TISInputSource? = language == .english ? englishSource : russianSource

        guard let source = source else {
            PuntoLog.info("Input source not found for \(language)")
            return false
        }

        let targetLayoutID = getSourceId(source)
        let status = TISSelectInputSource(source)
        let result = InputSourceSwitchVerificationPolicy.result(
            selectStatus: status,
            targetLayoutID: targetLayoutID,
            currentLayoutIDAfterSwitch: currentLayoutID()
        )

        switch result {
        case .switched:
            PuntoLog.info("Switched keyboard to \(language)")
            return true
        case .selectFailed(let status):
            PuntoLog.error("Failed to switch input source, error: \(status)")
            return false
        case .layoutStayedSame(let currentLayoutID):
            PuntoLog.error("Tried to switch to layout '\(targetLayoutID)' for \(language), but layout stayed '\(currentLayoutID ?? "unknown")'")
            return false
        }
    }

    @discardableResult
    public func switchToLayoutID(_ layoutID: String) -> Bool {
        if layoutID == languageLayoutID(.english) {
            return switchTo(.english)
        }
        if layoutID == languageLayoutID(.russian) {
            return switchTo(.russian)
        }

        guard let sourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return false
        }

        for source in sourceList where getSourceId(source) == layoutID && isSelectableKeyboard(source) {
            let targetLayoutID = getSourceId(source)
            let status = TISSelectInputSource(source)
            let result = InputSourceSwitchVerificationPolicy.result(
                selectStatus: status,
                targetLayoutID: targetLayoutID,
                currentLayoutIDAfterSwitch: currentLayoutID()
            )

            switch result {
            case .switched:
                PuntoLog.info("Switched keyboard to remembered layout \(layoutID)")
                return true
            case .selectFailed(let status):
                PuntoLog.error("Failed to switch remembered input source \(layoutID), error: \(status)")
                return false
            case .layoutStayedSame(let currentLayoutID):
                PuntoLog.error("Tried to switch to remembered layout '\(targetLayoutID)', but layout stayed '\(currentLayoutID ?? "unknown")'")
                return false
            }
        }

        PuntoLog.info("Remembered input source not found: \(layoutID)")
        return false
    }

    public func currentLayoutID() -> String? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue() else {
            return nil
        }
        return getSourceId(source)
    }

    public func languageLayoutID(_ language: KeyboardLanguage) -> String? {
        let source = language == .english ? englishSource : russianSource
        guard let source else { return nil }
        return getSourceId(source)
    }

    // MARK: - Private Helpers

    private func isSelectableKeyboard(_ source: TISInputSource) -> Bool {
        guard let category = getProperty(source, kTISPropertyInputSourceCategory) as? String,
              category == kTISCategoryKeyboardInputSource as String else {
            return false
        }
        return getProperty(source, kTISPropertyInputSourceIsSelectCapable) as? Bool ?? false
    }

    private func isEnabledInputSource(_ source: TISInputSource) -> Bool {
        getProperty(source, kTISPropertyInputSourceIsEnabled) as? Bool ?? true
    }

    private func prepareSelectedInputSource(
        _ source: TISInputSource,
        sourceID: String,
        selection: InputSourceSelection
    ) -> Bool {
        guard InputSourceSelectionPolicy.shouldEnableInputSource(sourceID: sourceID, selection: selection) else {
            return true
        }

        let status = TISEnableInputSource(source)
        guard status == noErr else {
            PuntoLog.error(InputSourceSelectionPolicy.failedToEnableLayoutLogMessage(
                sourceID: sourceID,
                status: status
            ))
            return false
        }

        PuntoLog.info(InputSourceSelectionPolicy.inputSourceEnabledLogMessage(sourceID: sourceID))
        return true
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
