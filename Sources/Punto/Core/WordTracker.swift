import Foundation

/// Tracks the last typed word using a ring buffer
/// Used when no text is selected to convert the most recently typed word
final class WordTracker {

    // MARK: - Ring Buffer

    private let maxSize: Int
    private var buffer: [Character]
    private var head: Int = 0
    private var count: Int = 0

    // Characters that indicate word boundaries
    // Note: Many punctuation marks map to Russian letters on QWERTY layout:
    //   ; -> ж, ' -> э, [ -> х, ] -> ъ, ` -> ё, , -> б, . -> ю
    // So we only treat actual word separators as boundaries
    private let wordBoundaries: Set<Character> = [
        " ", "\n", "\t", "\r",
        "!", "?",
        "(", ")",
        "/", "\\", "|",
        "@", "#", "$", "%", "^", "&", "*",
        "+", "=", "-", "_"
    ]

    // Key codes for special keys
    private let deleteKeyCode: UInt16 = 51
    private let returnKeyCode: UInt16 = 36
    private let enterKeyCode: UInt16 = 76
    private let tabKeyCode: UInt16 = 48
    private let escapeKeyCode: UInt16 = 53
    private let spaceKeyCode: UInt16 = 49

    // Arrow and navigation keys (should clear the buffer)
    private let navigationKeyCodes: Set<UInt16> = [
        123, 124, 125, 126, // Arrow keys
        115, 119, 116, 121, // Home, End, Page Up, Page Down
        117                  // Forward Delete
    ]

    init(maxSize: Int = 50) {
        self.maxSize = maxSize
        self.buffer = [Character](repeating: " ", count: maxSize)
    }

    // MARK: - Public Interface

    /// Tracks a key press event
    /// - Parameters:
    ///   - keyCode: The virtual key code
    ///   - characters: The characters produced by the key press (nil means "clear buffer" signal)
    func trackKeyPress(keyCode: UInt16, characters: String?) {
        // nil characters is a signal to clear buffer (e.g., from Cmd+V paste or Cmd+Z undo)
        if characters == nil && keyCode != deleteKeyCode {
            clear(reason: "external command (keyCode=\(keyCode))")
            return
        }

        // Handle special keys
        if keyCode == deleteKeyCode {
            removeLastCharacter()
            PuntoLog.info("WordTracker: backspace, buffer now '\(getCurrentBuffer())'")
            return
        }

        // Navigation keys clear the buffer (cursor moved)
        if navigationKeyCodes.contains(keyCode) {
            clear(reason: "navigation key \(keyCode)")
            return
        }

        // Return/Enter acts as word boundary
        if keyCode == returnKeyCode || keyCode == enterKeyCode {
            clear(reason: "return/enter")
            return
        }

        // Tab clears the buffer (word boundary)
        if keyCode == tabKeyCode {
            clear(reason: "tab")
            return
        }

        // Process the character
        guard let chars = characters, let firstChar = chars.first else {
            return
        }

        // Space and other word boundaries clear the buffer
        if keyCode == spaceKeyCode || wordBoundaries.contains(firstChar) {
            clear(reason: "word boundary '\(firstChar)'")
            return
        }

        // Add the character to the buffer
        addCharacter(firstChar)
        PuntoLog.info("WordTracker: added '\(firstChar)' (keyCode=\(keyCode)), buffer now '\(getCurrentBuffer())'")
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
    func getLastWord() -> String? {
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

    /// Checks if text contains characters from multiple keyboard layouts
    private func isMixedLayout(_ text: String) -> Bool {
        var hasEnglish = false
        var hasRussian = false

        for char in text {
            if isEnglishLetter(char) {
                hasEnglish = true
            } else if isRussianLetter(char) {
                hasRussian = true
            }

            // Early exit if both detected
            if hasEnglish && hasRussian {
                return true
            }
        }

        return false
    }

    private func isEnglishLetter(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return (scalar.value >= 0x41 && scalar.value <= 0x5A) || // A-Z
               (scalar.value >= 0x61 && scalar.value <= 0x7A)    // a-z
    }

    private func isRussianLetter(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return (scalar.value >= 0x410 && scalar.value <= 0x44F) || // А-я
               scalar.value == 0x401 || scalar.value == 0x451      // Ё, ё
    }

    /// Clears the buffer
    /// - Parameter reason: Why the buffer is being cleared (for logging)
    func clear(reason: String = "unknown") {
        if count > 0 {
            PuntoLog.debug("WordTracker: clearing buffer '\(getCurrentBuffer())' (reason: \(reason))")
        }
        count = 0
    }

    // MARK: - Private Methods

    private func addCharacter(_ char: Character) {
        buffer[head] = char
        head = (head + 1) % maxSize

        if count < maxSize {
            count += 1
        }
    }

    private func removeLastCharacter() {
        guard count > 0 else { return }

        head = (head - 1 + maxSize) % maxSize
        count -= 1
    }
}
