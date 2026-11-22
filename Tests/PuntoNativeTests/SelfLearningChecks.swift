import AppKit
import PuntoCore

@main
struct SelfLearningChecks {
    let folder: URL
    let resources: URL

    static func main() {
        _ = NSApplication.shared
        let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let resources = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        let checks = SelfLearningChecks(folder: folder, resources: resources)
        do {
            try checks.testModifierChordFiresOnlyOnFinalRelease()
            try checks.testEnabledLearningPersistsCountAndPreventsConversionAfterSecondCancellation()
            try checks.testLearningPromptDeliversOnceAndAcceptingItCreatesAnException()
            try checks.testDecliningResetsCountAndSuppressionStopsFuturePrompts()
            print("PASS: modifier chord, self-learning persistence, exception application, prompt delivery, acceptance and decline")
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            exit(EXIT_FAILURE)
        }
    }

    private let word = "ghbdtn"

    func testModifierChordFiresOnlyOnFinalRelease() throws {
        let engine = try makeEngine(learning: false, showPrompt: false)
        let modifiers = Shortcut.command | Shortcut.option | Shortcut.shift
        // Observe command dispatch through a setting in the fixture instead of editing a real field.
        engine.settings.value.shortcuts[1] = Shortcut()
        engine.settings.value.shortcuts[0] = Shortcut(modifiers: modifiers)
        guard let events = ConversionChord.events(source: nil), let release = events.last else {
            throw CheckFailure(line: #line)
        }

        for event in events.dropLast() {
            _ = engine.handle(event.type, event)
            try check(engine.settings.value.automatic)
        }
        _ = engine.handle(release.type, release)
        try check(!engine.settings.value.automatic)
        _ = engine.handle(release.type, release)
        try check(!engine.settings.value.automatic)
    }

    func testEnabledLearningPersistsCountAndPreventsConversionAfterSecondCancellation() throws {
        let engine = try makeEngine(learning: true, showPrompt: true)
        try check(engine.shouldAutomaticallyConvert("ghb", completed: false))
        try check(engine.shouldAutomaticallyConvert(word, completed: true))

        engine.registerCancellation(word)
        try check(engine.settings.value.learningCounts[word] == 1)
        try check(engine.settings.value.rules.isEmpty)
        engine.settings.flush()

        let resumed = reload(engine)
        try check(resumed.settings.value.learningCounts[word] == 1)
        resumed.registerCancellation(word)
        try check(resumed.pendingLearningPrompt == nil)
        try check(resumed.settings.value.learningCounts[word] == nil)
        resumed.settings.flush()

        let learned = reload(resumed)
        guard let rule = learned.settings.value.rules.first else {
            throw CheckFailure(line: #line)
        }
        try check(learned.settings.value.rules.count == 1)
        try check(rule.text == word)
        try check(rule.mode == .exact)
        try check(rule.enabled)
        try check(rule.caseSensitive)
        try check(!rule.switches)
        try check(!learned.shouldAutomaticallyConvert("ghb", completed: false))
        try check(!learned.shouldAutomaticallyConvert(word, completed: true))
        try check(learned.shouldAutomaticallyConvert("rfr", completed: true))
    }

    func testLearningPromptDeliversOnceAndAcceptingItCreatesAnException() throws {
        let engine = try makeEngine(learning: false, showPrompt: true)
        var offeredWords: [String] = []
        engine.onLearning = { word in
            offeredWords.append(word)
        }

        engine.registerCancellation(word)
        try check(engine.pendingLearningPrompt == nil)
        engine.registerCancellation(word)
        try check(engine.pendingLearningPrompt == word)
        try check(engine.settings.value.rules.isEmpty)
        engine.drainInput()
        engine.drainInput()
        let delivered = DispatchSemaphore(value: 0)
        DispatchQueue.main.async { delivered.signal() }
        let deadline = Date().addingTimeInterval(2)
        while delivered.wait(timeout: .now()) != .success {
            try check(Date() < deadline)
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        try check(offeredWords == [word])

        engine.resolveLearningPrompt(for: word, accepted: true, suppressFuturePrompts: false)
        try check(engine.settings.value.learning)
        try check(engine.settings.value.learningCounts[word] == nil)
        try check(!engine.shouldAutomaticallyConvert(word, completed: true))
    }

    func testDecliningResetsCountAndSuppressionStopsFuturePrompts() throws {
        let engine = try makeEngine(learning: false, showPrompt: true)
        engine.registerCancellation(word)
        engine.registerCancellation(word)
        try check(engine.pendingLearningPrompt == word)
        engine.drainInput()

        engine.resolveLearningPrompt(for: word, accepted: false, suppressFuturePrompts: false)
        try check(engine.settings.value.learningCounts[word] == nil)
        try check(engine.settings.value.showLearningPrompt)
        engine.registerCancellation(word)
        try check(engine.pendingLearningPrompt == nil)
        engine.registerCancellation(word)
        try check(engine.pendingLearningPrompt == word)
        engine.drainInput()

        engine.resolveLearningPrompt(for: word, accepted: false, suppressFuturePrompts: true)
        engine.registerCancellation(word)
        engine.registerCancellation(word)
        try check(engine.pendingLearningPrompt == nil)
        try check(!engine.settings.value.learning)
        try check(!engine.settings.value.showLearningPrompt)
        try check(engine.settings.value.rules.isEmpty)
        try check(engine.shouldAutomaticallyConvert(word, completed: true))
    }

    private func makeEngine(learning: Bool, showPrompt: Bool) throws -> KeyboardEngine {
        let folder = self.folder.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)

        var preferences = Preferences()
        preferences.automatic = true
        preferences.learning = learning
        preferences.showLearningPrompt = showPrompt
        try JSONEncoder().encode(preferences).write(to: folder.appendingPathComponent("settings.json"))
        return makeEngine(folder: folder)
    }

    private func reload(_ engine: KeyboardEngine) -> KeyboardEngine {
        makeEngine(folder: engine.settings.folder)
    }

    private func makeEngine(folder: URL) -> KeyboardEngine {
        let engine = KeyboardEngine(settings: Settings(folder: folder), resources: resources)
        engine.ownerSource = engine.settings.value.english
        return engine
    }
}

private struct CheckFailure: Error, CustomStringConvertible {
    let line: UInt
    var description: String { "Self-learning check failed at SelfLearningChecks.swift:\(line)" }
}

private func check(_ condition: @autoclosure () -> Bool, line: UInt = #line) throws {
    guard condition() else { throw CheckFailure(line: line) }
}
