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
    private let wordBoundaries: Set<Character> = [
        " ", "\n", "\t", "\r",
        ".", ",", "!", "?", ";", ":",
        "(", ")", "[", "]", "{", "}",
        "\"", "'", "`",
        "/", "\\", "|",
        "<", ">",
        "@", "#", "$", "%", "^", "&", "*",
        "+", "=", "-", "_",
        "~"
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
    ///   - characters: The characters produced by the key press
    func trackKeyPress(keyCode: UInt16, characters: String?) {
        // Handle special keys
        if keyCode == deleteKeyCode {
            removeLastCharacter()
            return
        }

        // Navigation keys clear the buffer (cursor moved)
        if navigationKeyCodes.contains(keyCode) {
            clear()
            return
        }

        // Return/Enter acts as word boundary
        if keyCode == returnKeyCode || keyCode == enterKeyCode {
            clear()
            return
        }

        // Process the character
        guard let chars = characters, let firstChar = chars.first else {
            return
        }

        // Space and other word boundaries clear the buffer
        if keyCode == spaceKeyCode || wordBoundaries.contains(firstChar) {
            clear()
            return
        }

        // Add the character to the buffer
        addCharacter(firstChar)
    }

    /// Returns the last typed word
    func getLastWord() -> String? {
        guard count > 0 else { return nil }

        var result = [Character]()
        result.reserveCapacity(count)

        // Read from the oldest to newest character
        for i in 0..<count {
            let index = (head - count + i + maxSize) % maxSize
            result.append(buffer[index])
        }

        return String(result)
    }

    /// Clears the buffer
    func clear() {
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
