import Foundation
import PuntoCore

func runConversionSessionTests() throws {
    let session = ConversionSession(undoTimeout: 3)
    let now = Date(timeIntervalSince1970: 100)

    try expectNil(session.undoCandidate(now: now), "empty session has no undo")

    session.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor",
        origin: .autoCorrection(rule: AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"))
    )

    try expect(session.undoCandidate(now: now.addingTimeInterval(2), contextID: "com.example.editor")?.originalText, "ghbdtn", "undo available inside timeout")
    try expect(
        session.undoCandidate(now: now.addingTimeInterval(2), contextID: " COM.EXAMPLE.Editor ")?.originalText,
        "ghbdtn",
        "undo matches normalized app context id"
    )
    try expect(
        session.lastConversion?.contextID,
        "com.example.editor",
        "undo session stores normalized context id"
    )
    try expect(
        session.undoCandidate(now: now.addingTimeInterval(2), contextID: "com.example.editor")?.origin,
        .autoCorrection(rule: AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")),
        "undo preserves conversion origin"
    )
    try expectNil(session.undoCandidate(now: now.addingTimeInterval(2), contextID: "com.example.chat"), "undo rejected in different app context")
    try expect(session.lastConversion?.originalText, "ghbdtn", "context mismatch keeps undo session for original app")

    let futureSession = ConversionSession(undoTimeout: 3)
    futureSession.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(futureSession.undoCandidate(now: now.addingTimeInterval(-0.1), contextID: "com.example.editor"), "undo rejects future-dated conversion record")
    try expectNil(futureSession.lastConversion, "undo clears future-dated conversion record")

    let timeoutBoundarySession = ConversionSession(undoTimeout: 3)
    timeoutBoundarySession.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(timeoutBoundarySession.undoCandidate(now: now.addingTimeInterval(3), contextID: "com.example.editor"), "undo expires at exact timeout boundary")
    try expectNil(timeoutBoundarySession.lastConversion, "undo clears record at exact timeout boundary")

    let expiredSession = ConversionSession(undoTimeout: 3)
    expiredSession.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(expiredSession.undoCandidate(now: now.addingTimeInterval(3.1), contextID: "com.example.editor"), "undo expires after timeout")
    try expectNil(expiredSession.lastConversion, "undo clears expired conversion record")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: " "
    )
    try expectNil(session.lastConversion?.contextID, "undo session normalizes blank context id to nil")
    try expect(
        session.undoCandidate(now: now.addingTimeInterval(1), contextID: nil)?.originalText,
        "hello",
        "undo matches nil context after blank normalization"
    )

    session.clear(reason: "test")
    try expectNil(session.undoCandidate(now: now), "clear removes undo")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "same",
        convertedText: "same",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects no-op conversion records")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects empty original records")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "hello",
        convertedText: "",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects empty converted records")

    session.record(
        originalText: "hello",
        convertedText: "руддщ",
        replacementMethod: .keyboardBackspacePaste,
        now: now,
        contextID: "com.example.editor"
    )
    session.record(
        originalText: "unsafe",
        convertedText: "blocked",
        replacementMethod: .blocked,
        now: now,
        contextID: "com.example.editor"
    )
    try expectNil(session.undoCandidate(now: now, contextID: "com.example.editor"), "undo session rejects blocked replacement records")

    let commitSession = ConversionSession(undoTimeout: 3)
    commitSession.record(
        ConversionRecordCommit(
            originalText: "hello",
            convertedText: "руддщ",
            replacementMethod: .keyboardBackspacePaste,
            origin: .layoutConversion
        ),
        now: now,
        contextID: "com.example.editor"
    )
    try expect(
        commitSession.undoCandidate(now: now.addingTimeInterval(1), contextID: "com.example.editor")?.convertedText,
        "руддщ",
        "undo session records conversion commit payloads"
    )
    try expect(
        commitSession.undoCandidate(now: now.addingTimeInterval(1), contextID: "com.example.editor")?.origin,
        .layoutConversion,
        "undo session preserves commit payload origin"
    )
}
