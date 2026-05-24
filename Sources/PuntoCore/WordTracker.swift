import Foundation

/// Tracks the last typed word using a ring buffer
/// Used when no text is selected to convert the most recently typed word
public final class WordTracker {
    public struct CompletedToken: Equatable {
        public let word: String
        public let separator: String
        public let isAutoCorrectionSuppressed: Bool

        public init(word: String, separator: String, isAutoCorrectionSuppressed: Bool = false) {
            self.word = word
            self.separator = separator
            self.isAutoCorrectionSuppressed = isAutoCorrectionSuppressed
        }
    }

    // MARK: - Ring Buffer

    private let maxSize: Int
    private let maxTailSize: Int
    private var buffer: [Character]
    private var head: Int = 0
    private var count: Int = 0
    private var tailBuffer: [Character]
    private var tailHead: Int = 0
    private var tailCount: Int = 0
    private var lastCompletedToken: CompletedToken?
    private var isCurrentTokenAutoCorrectionSuppressed = false

    public init(maxSize: Int = 50, maxTailSize: Int? = nil) {
        self.maxSize = maxSize
        self.maxTailSize = max(maxSize, maxTailSize ?? maxSize)
        self.buffer = [Character](repeating: " ", count: maxSize)
        self.tailBuffer = [Character](repeating: " ", count: self.maxTailSize)
    }

    // MARK: - Public Interface

    /// Tracks a key press event
    /// - Parameters:
    ///   - keyCode: The virtual key code
    ///   - characters: The characters produced by the key press (nil means "clear buffer" signal)
    public func trackKeyPress(
        keyCode: UInt16,
        characters: String?,
        autoCorrectionCancellingKeyNames: Set<String> = AutoCorrectionCancellingKeyPolicy.defaultEnabledKeyNames,
        englishLayoutVariant: KeyboardLayoutVariant = .qwerty,
        russianLayoutType: KeyboardLayoutType = .windows
    ) {
        switch WordTrackingPolicy.action(keyCode: keyCode, characters: characters) {
        case .clear(let reason):
            clear(reason: reason)
            return

        case .removeLastCharacter:
            let hadCurrentToken = count > 0
            removeLastCharacter()
            removeLastTailCharacter()
            if hadCurrentToken,
               AutoCorrectionCancellingKeyPolicy.shouldSuppressAutoCorrection(
                   keyCode: keyCode,
                   enabledKeyNames: autoCorrectionCancellingKeyNames
               ) {
                isCurrentTokenAutoCorrectionSuppressed = true
            }
            PuntoLog.info("WordTracker: backspace, buffer now '\(getCurrentBuffer())'")
            return

        case .completeToken(let separator, let reason):
            rememberCompletedToken(separator: separator)
            clearKeepingCompletedToken(reason: reason)
            return

        case .trackProducedCharacters:
            break

        case .ignore:
            return
        }

        for char in characters ?? "" {
            trackProducedCharacter(
                char,
                keyCode: keyCode,
                englishLayoutVariant: englishLayoutVariant,
                russianLayoutType: russianLayoutType
            )
        }
    }

    private func trackProducedCharacter(
        _ char: Character,
        keyCode: UInt16,
        englishLayoutVariant: KeyboardLayoutVariant,
        russianLayoutType: KeyboardLayoutType
    ) {
        // Space and other word boundaries clear the word buffer. The broader
        // typed tail remains available for terminal-like passive selections.
        if WordBoundaryPolicy.isTypedWordBoundary(
            char,
            keyCode: keyCode,
            englishLayoutVariant: englishLayoutVariant,
            russianLayoutType: russianLayoutType
        ) {
            rememberCompletedToken(separator: String(char))
            addTailCharacter(char)
            clearWord(reason: "word boundary '\(char)'")
            return
        }

        // Add the character to the buffer
        addCharacter(char)
        addTailCharacter(char)
        PuntoLog.info("WordTracker: added '\(char)' (keyCode=\(keyCode)), buffer now '\(getCurrentBuffer())'")
    }

    /// Returns current buffer contents for debugging
    private func getCurrentBuffer() -> String {
        guard count > 0 else { return "" }
        var result = [Character]()
        result.reserveCapacity(count)
        for i in 0..<count {
            let index = (head - count + i + maxSize) % maxSize
            result.append(buffer[index])
        }
        return String(result)
    }

    /// Returns the last typed word
    /// Returns nil if buffer contains mixed layouts (corrupted data)
    public func getLastWord() -> String? {
        guard count > 0 else {
            PuntoLog.info("WordTracker.getLastWord: buffer empty")
            return nil
        }

        var result = [Character]()
        result.reserveCapacity(count)

        // Read from the oldest to newest character
        for i in 0..<count {
            let index = (head - count + i + maxSize) % maxSize
            result.append(buffer[index])
        }

        let word = String(result)

        // Validate: reject mixed-layout words (e.g. "жеa" - Russian + English)
        // This happens when layout change notification arrives with delay
        if isMixedLayout(word) {
            clear(reason: "mixed layout in '\(word)'")
            return nil
        }

        PuntoLog.info("WordTracker.getLastWord: returning '\(word)' (\(word.count) chars)")
        return word
    }

    public func consumeCompletedToken() -> CompletedToken? {
        let token = lastCompletedToken
        lastCompletedToken = nil
        return token
    }

    /// Returns the current typed tail since the last hard boundary.
    ///
    /// Unlike `getLastWord()`, this keeps spaces so terminal-like surfaces can
    /// validate passive clipboard selections exactly instead of accepting any
    /// stale clipboard value that merely ends with the last word.
    public func getTypedTail() -> String? {
        guard tailCount > 0 else {
            PuntoLog.info("WordTracker.getTypedTail: tail empty")
            return nil
        }

        let tail = currentTypedTail().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tail.isEmpty else {
            PuntoLog.info("WordTracker.getTypedTail: tail whitespace only")
            return nil
        }

        if isMixedLayout(tail) {
            clear(reason: "mixed layout in typed tail '\(tail)'")
            return nil
        }

        PuntoLog.info("WordTracker.getTypedTail: returning '\(tail)' (\(tail.count) chars)")
        return tail
    }

    public func getTypedTailPreservingBoundaryWhitespace() -> String? {
        guard tailCount > 0 else {
            PuntoLog.info("WordTracker.getTypedTailPreservingBoundaryWhitespace: tail empty")
            return nil
        }

        let tail = currentTypedTail()
        guard !tail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            PuntoLog.info("WordTracker.getTypedTailPreservingBoundaryWhitespace: tail whitespace only")
            return nil
        }

        if isMixedLayout(tail) {
            clear(reason: "mixed layout in typed tail '\(tail)'")
            return nil
        }

        PuntoLog.info("WordTracker.getTypedTailPreservingBoundaryWhitespace: returning '\(tail)' (\(tail.count) chars)")
        return tail
    }

    private func isMixedLayout(_ text: String) -> Bool {
        LayoutDetectionPolicy.isMixedLayout(text)
    }

    /// Clears the buffer
    /// - Parameter reason: Why the buffer is being cleared (for logging)
    public func clear(reason: String = "unknown") {
        if count > 0 {
            PuntoLog.debug("WordTracker: clearing buffer '\(getCurrentBuffer())' (reason: \(reason))")
        }
        if tailCount > 0 {
            PuntoLog.debug("WordTracker: clearing typed tail '\(getCurrentTailBuffer())' (reason: \(reason))")
        }
        count = 0
        tailCount = 0
        lastCompletedToken = nil
        isCurrentTokenAutoCorrectionSuppressed = false
    }

    private func clearKeepingCompletedToken(reason: String) {
        if count > 0 {
            PuntoLog.debug("WordTracker: clearing buffer '\(getCurrentBuffer())' (reason: \(reason))")
        }
        if tailCount > 0 {
            PuntoLog.debug("WordTracker: clearing typed tail '\(getCurrentTailBuffer())' (reason: \(reason))")
        }
        count = 0
        tailCount = 0
        isCurrentTokenAutoCorrectionSuppressed = false
    }

    public func replaceTrackedTail(
        with text: String,
        reason: String = "replacement",
        suppressAutoCorrectionForCurrentToken: Bool = false,
        englishLayoutVariant: KeyboardLayoutVariant = .qwerty,
        russianLayoutType: KeyboardLayoutType = .windows
    ) {
        clear(reason: reason)
        for char in text {
            addTailCharacter(char)
            if WordBoundaryPolicy.isTypedWordBoundary(
                char,
                keyCode: 0,
                englishLayoutVariant: englishLayoutVariant,
                russianLayoutType: russianLayoutType
            ) {
                clearWord(reason: "tail replacement boundary '\(char)'")
            } else {
                addCharacter(char)
            }
        }
        if count > 0, suppressAutoCorrectionForCurrentToken {
            isCurrentTokenAutoCorrectionSuppressed = true
        }
        PuntoLog.debug("WordTracker: replaced tracked tail with '\(text)' (reason: \(reason))")
    }

    private func clearWord(reason: String) {
        if count > 0 {
            PuntoLog.debug("WordTracker: clearing buffer '\(getCurrentBuffer())' (reason: \(reason))")
        }
        count = 0
        isCurrentTokenAutoCorrectionSuppressed = false
    }

    private func rememberCompletedToken(separator: String) {
        guard let word = getLastWord(), !word.isEmpty else { return }
        lastCompletedToken = CompletedToken(
            word: word,
            separator: separator,
            isAutoCorrectionSuppressed: isCurrentTokenAutoCorrectionSuppressed
        )
        PuntoLog.debug("WordTracker: completed token word='\(word)' separator='\(separator)' suppressed=\(isCurrentTokenAutoCorrectionSuppressed)")
    }

    // MARK: - Private Methods

    private func addCharacter(_ char: Character) {
        buffer[head] = char
        head = (head + 1) % maxSize

        if count < maxSize {
            count += 1
        }
    }

    private func addTailCharacter(_ char: Character) {
        tailBuffer[tailHead] = char
        tailHead = (tailHead + 1) % maxTailSize

        if tailCount < maxTailSize {
            tailCount += 1
        }
    }

    private func removeLastCharacter() {
        guard count > 0 else { return }

        head = (head - 1 + maxSize) % maxSize
        count -= 1
    }

    private func removeLastTailCharacter() {
        guard tailCount > 0 else { return }

        tailHead = (tailHead - 1 + maxTailSize) % maxTailSize
        tailCount -= 1
    }

    private func getCurrentTailBuffer() -> String {
        guard tailCount > 0 else { return "" }
        return currentTypedTail()
    }

    private func currentTypedTail() -> String {
        var result = [Character]()
        result.reserveCapacity(tailCount)
        for i in 0..<tailCount {
            let index = (tailHead - tailCount + i + maxTailSize) % maxTailSize
            result.append(tailBuffer[index])
        }
        return String(result)
    }
}
