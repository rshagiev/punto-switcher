import Foundation
import PuntoCore

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

@discardableResult
func expect<T: Equatable>(_ actual: @autoclosure () -> T, _ expected: T, _ message: String) throws -> T {
    let value = actual()
    guard value == expected else {
        throw TestFailure(description: "\(message): expected \(expected), got \(value)")
    }
    print("PASS \(message)")
    return value
}

func expectNil<T>(_ actual: @autoclosure () -> T?, _ message: String) throws {
    let value = actual()
    guard value == nil else {
        throw TestFailure(description: "\(message): expected nil, got \(String(describing: value))")
    }
    print("PASS \(message)")
}

func type(_ text: String, into tracker: WordTracker) {
    for char in text {
        let keyCode: UInt16 = char == " " ? 49 : 0
        tracker.trackKeyPress(keyCode: keyCode, characters: String(char))
    }
}

struct TestSuite {
    let name: String
    let aliases: Set<String>
    let run: () throws -> Void

    func matches(_ requestedName: String) -> Bool {
        let normalizedName = requestedName.lowercased()
        return name == normalizedName || aliases.contains(normalizedName)
    }
}
