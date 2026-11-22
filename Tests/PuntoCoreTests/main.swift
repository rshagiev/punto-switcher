import Foundation
import PuntoCore
final class CoreTests {
    func testRussianKeyboardAndPunctuation() {
        XCTAssertEqual(LayoutConversion.english.count,LayoutConversion.russian.count)
        XCTAssertEqual(LayoutConversion.english.count,LayoutConversion.russianPC.count)
        for (input,output) in [("ghbdtn","привет"),("Ghbdtn","Привет"),("djj,ot","вообще"),("[etdj","хуево"),("ghbdtn;","приветж")] {
            XCTAssertEqual(LayoutConversion.convert(input,toRussian:true),output)
            XCTAssertEqual(LayoutConversion.convert(output,toRussian:false),input)
        }
    }
    func testSelectionKeepsWhitespaceAndEmoji() {
        XCTAssertEqual(LayoutConversion.selection("ghbdtn\tруддщ\n🙂"),"привет\thello\n🙂")
        XCTAssertEqual(LayoutConversion.selection("  Ghbdtn  "),"  Привет  ")
        XCTAssertEqual(LayoutConversion.selection(""),"")
    }
    func testCaseToggle() {
        XCTAssertEqual(LayoutConversion.changeCase("Привет Hello"),"ПРИВЕТ HELLO")
        XCTAssertEqual(LayoutConversion.changeCase("ПРИВЕТ HELLO"),"привет hello")
    }
    func testSelectionUsesSelectedLayoutConverter() {
        var directions: [Bool] = []
        let result = LayoutConversion.selection("  privet\tпривет\n🙂  ") { word, toRussian in
            directions.append(toRussian)
            if word == "privet" { return "привет" }
            if word == "привет" { return "privet" }
            return word
        }
        XCTAssertEqual(result,"  привет\tprivet\n🙂  ")
        XCTAssertEqual(directions,[true,false,true])
    }
    func testChordAfterOrdinaryTyping() {
        var c = ChordTracker(); c.keyPressed()
        XCTAssertNil(c.changed(Shortcut.command))
        XCTAssertNil(c.changed(Shortcut.command|Shortcut.option|Shortcut.shift))
        XCTAssertNil(c.changed(Shortcut.shift))
        XCTAssertEqual(c.changed(0),Shortcut.command|Shortcut.option|Shortcut.shift)
        XCTAssertNil(c.changed(0))
    }
    func testChordDoesNotFireAfterModifiedKey() {
        var c = ChordTracker(); _ = c.changed(Shortcut.command|Shortcut.option|Shortcut.shift); c.keyPressed()
        XCTAssertNil(c.changed(0))
    }
    func testCommandPeriodRecording() {
        // Left and right Command have different device bits, but the same mask.
        for command in [Shortcut.command | 0x08, Shortcut.command | 0x10] {
            for keyFlags in [UInt64(0), command] {
                var recorder = ShortcutRecorder()
                XCTAssertNil(recorder.changed(command))
                let shortcut = recorder.keyPressed(47,flags:keyFlags)
                XCTAssertEqual(shortcut,Shortcut(key:47,modifiers:Shortcut.command))
                XCTAssertNil(recorder.changed(0))
                let data = try! JSONEncoder().encode(shortcut)
                let restored = try! JSONDecoder().decode(Shortcut.self,from:data)
                XCTAssertEqual(restored,shortcut)
                // Same predicate used by KeyboardEngine for a key shortcut.
                XCTAssertTrue(restored.key == 47 && restored.modifiers == (command & Shortcut.mask) && restored.enabled)
            }
        }
        // Command may already be held when the recording button is clicked.
        var recorder = ShortcutRecorder()
        XCTAssertEqual(recorder.keyPressed(47,flags:Shortcut.command),Shortcut(key:47,modifiers:Shortcut.command))
        XCTAssertEqual(recorder.keyPressed(47,flags:0),Shortcut(key:47))
    }
    func testRecordingUsesHeldModifiersAndResets() {
        var recorder = ShortcutRecorder()
        XCTAssertNil(recorder.changed(Shortcut.command | Shortcut.shift))
        XCTAssertNil(recorder.changed(Shortcut.command))
        XCTAssertEqual(recorder.keyPressed(47,flags:0),Shortcut(key:47,modifiers:Shortcut.command))
        XCTAssertNil(recorder.changed(0))
        XCTAssertNil(recorder.changed(Shortcut.command))
        XCTAssertEqual(recorder.changed(0),Shortcut(modifiers:Shortcut.command))
        XCTAssertNil(recorder.changed(0))
        XCTAssertNil(recorder.changed(Shortcut.option))
        recorder.reset() // Escape, explicit cancellation, or a focus change.
        XCTAssertEqual(recorder.keyPressed(47,flags:0),Shortcut(key:47))
    }
    func testBackspaceResumesWordAfterSingleSpace() {
        var b = TypingBuffer(); b.append("ghbdtn"); b.boundary(" ")
        XCTAssertEqual(b.convertible,"ghbdtn"); XCTAssertEqual(b.suffix," ")
        b.backspace(cancelAuto:false); XCTAssertEqual(b.convertible,"ghbdtn"); b.reset()
        b.append("abc"); b.backspace(cancelAuto:true); XCTAssertEqual(b.text,"ab"); XCTAssertTrue(b.cancelled)
        b.reset(); XCTAssertFalse(b.cancelled); XCTAssertEqual(b.convertible,"")
    }
    func testRuleConditionsAndRegexValidation() {
        XCTAssertTrue(UserRule(text:"foo",mode:.exact).matches("FOO"))
        XCTAssertFalse(UserRule(text:"foo",mode:.exact,caseSensitive:true).matches("FOO"))
        XCTAssertTrue(UserRule(text:"foo",mode:.prefix).matches("foobar"))
        XCTAssertTrue(UserRule(text:"oo",mode:.contains).matches("foobar"))
        XCTAssertTrue(UserRule(text:"^foo[0-9]+$",mode:.regex).matches("foo12"))
        XCTAssertFalse(UserRule(text:"[",mode:.regex).valid)
    }
    func testUserRulesDuringPartialTyping() {
        let rules = AutoRules(triggers:"ghbdtn")
        XCTAssertFalse(rules.shouldConvert("ghbdtn",completed:false,userRules:[UserRule(text:"ghbdtn")]))
        XCTAssertTrue(rules.shouldConvert("ghbdtn",completed:false,userRules:[UserRule(text:"bd",mode:.contains)]))
        XCTAssertFalse(rules.shouldConvert("ghbdtn",completed:false,userRules:[UserRule(text:"ghb",mode:.prefix)]))
        XCTAssertFalse(rules.shouldConvert("ghbdtn",completed:false,userRules:[UserRule(text:"^ghb.*",mode:.regex)]))
        XCTAssertTrue(rules.shouldConvert("abc",completed:false,userRules:[UserRule(text:"abc",mode:.prefix,switches:true)]))
    }
    func testOriginalRuleFlags() {
        let prefix = OriginalRule(line:"_B ghb")!
        XCTAssertTrue(prefix.matches("GHBDTN")); XCTAssertFalse(prefix.matches("xghb"))
        let exact = OriginalRule(line:"_PC GHBDTN")!
        XCTAssertTrue(exact.matches("GHBDTN")); XCTAssertFalse(exact.matches("ghbdtn")); XCTAssertEqual(exact.flags,12)
        let rule = OriginalRule(line:"_PE hello")!
        XCTAssertEqual(rule.flags,20)
    }
    func testRuleOrderAndUserOverride() {
        let rules = AutoRules(dictionary:"_PE hello\n_B ghb\n_PD a",triggers:"ghbd\n")
        XCTAssertFalse(rules.shouldConvert("hello",completed:true,userRules:[]))
        XCTAssertTrue(rules.shouldConvert("ghbdtn",completed:true,userRules:[]))
        XCTAssertFalse(rules.shouldConvert("ghbdtn",completed:true,userRules:[UserRule(text:"ghbdtn")]))
        XCTAssertTrue(rules.shouldConvert("ghbd",completed:false,userRules:[]))
        XCTAssertFalse(rules.shouldConvert("a",completed:true,userRules:[]))
    }
}

var checks = 0
func XCTAssertTrue(_ value: @autoclosure () -> Bool, file: StaticString = #filePath, line: UInt = #line) { precondition(value(), "Expected true at \(file):\(line)"); checks += 1 }
func XCTAssertFalse(_ value: @autoclosure () -> Bool, file: StaticString = #filePath, line: UInt = #line) { XCTAssertTrue(!value(), file:file, line:line) }
func XCTAssertEqual<T: Equatable>(_ a: T, _ b: T, file: StaticString = #filePath, line: UInt = #line) { precondition(a == b, "\(a) != \(b) at \(file):\(line)"); checks += 1 }
func XCTAssertNil<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) { precondition(value == nil, "Expected nil at \(file):\(line)"); checks += 1 }
let tests = CoreTests()
tests.testRussianKeyboardAndPunctuation()
tests.testSelectionKeepsWhitespaceAndEmoji()
tests.testSelectionUsesSelectedLayoutConverter()
tests.testCaseToggle()
tests.testChordAfterOrdinaryTyping()
tests.testChordDoesNotFireAfterModifiedKey()
tests.testCommandPeriodRecording()
tests.testRecordingUsesHeldModifiersAndResets()
tests.testBackspaceResumesWordAfterSingleSpace()
tests.testRuleConditionsAndRegexValidation()
tests.testOriginalRuleFlags()
tests.testUserRulesDuringPartialTyping()
tests.testRuleOrderAndUserOverride()
print("PASS: \(checks) assertions")
let root = URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
if let dictionary = try? String(contentsOf:root.appendingPathComponent("Resources/ps.dat.txt"),encoding:.utf8), let triggers = try? String(contentsOf:root.appendingPathComponent("Resources/triggers.dat.txt"),encoding:.utf8) {
    let actual = AutoRules(dictionary:dictionary,triggers:triggers)
    for word in ["ghbdtn","rfr","руддщ"] { XCTAssertTrue(actual.shouldConvert(word,completed:true,userRules:[])) }
    for word in ["hello","привет","git","swift","a","я"] { XCTAssertFalse(actual.shouldConvert(word,completed:true,userRules:[])) }
    let words = ["hello","привет","git","swift","ghbdtn","rfr","руддщ"]
    let start = Date()
    for _ in 0..<100 { for word in words { _ = actual.shouldConvert(word,completed:true,userRules:[]) } }
    print("Rules: \(actual.count), average completed-word check: \(Date().timeIntervalSince(start)/700*1000) ms")
}
if let dictionary = try? String(contentsOf:root.appendingPathComponent("Resources/ps.dat.txt"),encoding:.utf8) {
    let parsed = dictionary.components(separatedBy:.newlines).compactMap(OriginalRule.init)
    let ordered = parsed.filter { $0.flags & 32 != 0 } + parsed.filter { $0.flags & 16 != 0 } + parsed.filter { $0.flags & 48 == 0 }
    let index = AutoRules(dictionary:dictionary)
    var samples = ["", "swift", "привет", "ghbdtn", "hello", "РУДДЩ", "test@example.com"]
    for (i,r) in parsed.enumerated() where i % 149 == 0 { samples += [r.text, "x"+r.text, r.text+"x", r.text.uppercased()] }
    for word in samples {
        var expected = false
        for r in ordered where r.matches(word) {
            if r.flags & 16 != 0 { expected = false; break }
            if r.flags & 128 == 0 { expected = true; break }
        }
        XCTAssertEqual(index.shouldConvert(word,completed:true,userRules:[]),expected)
    }
    print("PASS: indexed rules agree with sequential reference on \(samples.count) strings; \(checks) total assertions")
}

for global in [false,true] {
    for mode in AppMode.allCases {
        XCTAssertEqual(mode.automaticEnabled(global:global),mode == .automatic || (mode == .global && global))
        XCTAssertEqual(mode.manualEnabled,mode != .disabled)
    }
}
print("PASS: all 16 application-profile policy cases")

// Proofreading ranges must preserve original UTF-16 offsets, including emoji.
func fragments(_ text:String,_ ranges:[NSRange]) -> [String] { ranges.map { (text as NSString).substring(with:$0) } }
let typo = ProofreadingDiff(original:"Я замеря 🙂",corrected:"Я замеряю 🙂")
XCTAssertEqual(fragments("Я замеря 🙂",typo.removed),["замеря"])
XCTAssertEqual(fragments("Я замеряю 🙂",typo.inserted),["замеряю"])
let comma = ProofreadingDiff(original:"🙂 да но нет",corrected:"🙂 да, но нет")
XCTAssertEqual(comma.removed,[])
XCTAssertEqual(fragments("🙂 да, но нет",comma.inserted),[","])
let identical = ProofreadingDiff(original:"норм - 👩🏽‍💻\n42",corrected:"норм - 👩🏽‍💻\n42")
XCTAssertEqual(identical.removed,[])
XCTAssertEqual(identical.inserted,[])
let deletion = ProofreadingDiff(original:"очень очень хорошо",corrected:"очень хорошо")
XCTAssertEqual(fragments("очень очень хорошо",deletion.removed),["очень "])
XCTAssertEqual(deletion.inserted,[])
let hyphen = ProofreadingDiff(original:"где то",corrected:"где-то")
XCTAssertEqual(fragments("где то",hyphen.removed),[" "])
XCTAssertEqual(fragments("где-то",hyphen.inserted),["-"])
let empty = ProofreadingDiff(original:"",corrected:"текст")
XCTAssertEqual(empty.removed,[])
XCTAssertEqual(fragments("текст",empty.inserted),["текст"])
print("PASS: proofreading ranges, punctuation, whitespace, repetition and Unicode")

let choices = ProofreadingDiff(original:"Я хочю где то.",corrected:"Я хочу где-то!")
XCTAssertEqual(choices.edits.count,3)
XCTAssertEqual(choices.result(rejecting:[]),"Я хочу где-то!")
XCTAssertEqual(choices.result(rejecting:[0]),"Я хочю где-то!")
XCTAssertEqual(choices.result(rejecting:[1]),"Я хочу где то!")
XCTAssertEqual(choices.result(rejecting:[0,2]),"Я хочю где-то.")
XCTAssertEqual(choices.result(rejecting:Set(choices.edits.map(\.id))),choices.original)
let variants = ["", "а", "а а", "а, б", "🙂 б", "где-то", "где то", " а\nб ", "👩🏽‍💻 42", "б а а!"]
for before in variants {
    for after in variants {
        let diff = ProofreadingDiff(original:before,corrected:after)
        XCTAssertEqual(diff.result(rejecting:[]),after)
        XCTAssertEqual(diff.result(rejecting:Set(diff.edits.map(\.id))),before)
    }
}
print("PASS: independent proofreading choices and 100 round-trip pairs")
for before in variants {
    for after in variants {
        let diff = ProofreadingDiff(original:before,corrected:after,phrases:true)
        XCTAssertEqual(diff.result(rejecting:[]),after)
        XCTAssertEqual(diff.result(rejecting:Set(diff.edits.map(\.id))),before)
    }
}
print("PASS: phrase-level selection preserves both variants on 100 pairs")

let sentences = ProofreadingDiff(original:"Первое криво. Второе криво.",corrected:"Первое исправлено. Второе исправлено.",phrases:true)
XCTAssertEqual(sentences.edits.count,2)
XCTAssertEqual(sentences.result(rejecting:[0]),"Первое криво. Второе исправлено.")
XCTAssertEqual(ProcessingDepth.suggestsStructure("Типа написал ющер и наделал опечаток и где то тупил. Мы не будем прям за него все переписывать но очевиднок говно пофиксим."),false)
XCTAssertEqual(ProcessingDepth.suggestsStructure("Давай в четверг нет лучше в пятницу после обеда тут две вещи первое проверить 42 файла второе наверное написать Саше но обещать пока не буду"),true)
XCTAssertEqual(ProcessingDepth.suggestsStructure(String(repeating:"Сегодня мы обсуждаем разные важные вопросы. ",count:10)),false)
XCTAssertEqual(ProcessingDepth.suggestsStructure("Первое - проверить файлы.\nВторое - написать Саше.\nТретье - уточнить время. Нет, лучше пока ничего не обещать, нужно сначала всё проверить."),false)
XCTAssertEqual(ProcessingDepth.suggestsStructure("Нет лучше завтра"),false)
XCTAssertEqual(ProcessingDepth.suggestsStructure("Я очень очень рад и очень очень доволен тем как прошла встреча сегодня вечером мы обсудили планы на неделю."),false)
print("PASS: depth routing distinguishes rough dictation from typos, clean prose and lists")

var history = ActivityHistory()
var counts = ActivityCounts()
counts.symbols = 4
history.record(counts, day: 20261122, interval: 7)
counts.symbols = 5
counts.automatic = 1
history.record(counts, day: 20261123, interval: 0)
history.record(counts, day: 20261123, interval: 0)
let reopenedHistory = try JSONDecoder().decode(ActivityHistory.self, from: JSONEncoder().encode(history))
XCTAssertNil(reopenedHistory.day(20261121))
XCTAssertEqual(reopenedHistory.day(20261122)?.totals.symbols, 4)
XCTAssertEqual(reopenedHistory.day(20261123)?[0].symbols, 10)
XCTAssertEqual(reopenedHistory.day(20261123)?.totals.automatic, 2)
XCTAssertEqual(reopenedHistory.day(20261124)?.totals.symbols, 0)
print("PASS: local activity separates midnight, unavailable history and known zero")

let date = Date(timeIntervalSince1970: 1_795_300_000)
var invitation = SupportInvitation()
XCTAssertNil(invitation.available(at: date))
invitation.qualify()
let firstInvite = invitation.available(at: date)
XCTAssertTrue(firstInvite != nil)
XCTAssertEqual(invitation.registerShow(at: date), firstInvite)
XCTAssertNil(invitation.registerShow(at: date))
XCTAssertEqual(invitation.available(at: date), firstInvite)
invitation.snooze(at: date)
XCTAssertNil(invitation.available(at: date.addingTimeInterval(3 * 86400 - 1)))
var restartedInvitation = try JSONDecoder().decode(SupportInvitation.self, from: JSONEncoder().encode(invitation))
let nextInvite = restartedInvitation.registerShow(at: date.addingTimeInterval(3 * 86400))
XCTAssertTrue(nextInvite != nil && nextInvite != firstInvite)
restartedInvitation.dismiss()
restartedInvitation.qualify()
XCTAssertNil(restartedInvitation.available(at: date.addingTimeInterval(4 * 86400)))
print("PASS: support invitation is shared, survives restart and snoozes exactly three days")

let installationID = UUID()
let requestID = UUID()
let day = UsageCapture.day(at: date)
let active = UsageEnvelope(day: day, version: "2.0.6", os: "14.8.0", event: .activeDay(first: true))
let readiness = UsageEnvelope(day: day, version: "2.0.6", os: "14.8.0", event: .keyboardReady)
let request = try UsageCapture.request(token: "phc_fixture_capture_only", installation: installationID,
    events: [active, readiness], version: "2.0.6", requestID: requestID, attempt: 1, created: date, now: date)
XCTAssertEqual(request.url, UsageCapture.endpoint)
XCTAssertEqual(request.httpMethod, "POST")
XCTAssertEqual(request.value(forHTTPHeaderField: "PostHog-Request-Id"), requestID.uuidString)
let payload = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
let sent = payload["batch"] as! [[String: Any]]
let event = sent[0]
let properties = event["properties"] as! [String: Any]
let options = event["options"] as! [String: Any]
XCTAssertEqual(event["timestamp"] as? String, day + "T00:00:00.000Z")
XCTAssertEqual(event["distinct_id"] as? String, installationID.uuidString)
XCTAssertEqual(event["uuid"] as? String, active.id.uuidString.lowercased())
XCTAssertEqual(Set(properties.keys), ["schema_version", "app_version", "macos_version", "$geoip_disable", "first_active_day"])
XCTAssertEqual(options["process_person_profile"] as? Bool, false)
XCTAssertEqual(options["disable_skew_correction"] as? Bool, true)
let serverResponse = try JSONSerialization.data(withJSONObject: ["results": [
    active.id.uuidString.lowercased(): ["result": "ok"],
    readiness.id.uuidString.lowercased(): ["result": "retry"]
]])
XCTAssertEqual(UsageCapture.awaitingRetry(status: 200, body: serverResponse, in: [active, readiness]), [readiness])
XCTAssertEqual(UsageCapture.awaitingRetry(status: 503, body: Data(), in: [active, readiness]), [active, readiness])
XCTAssertEqual(UsageCapture.awaitingRetry(status: 401, body: Data(), in: [active, readiness]), [])
XCTAssertEqual(UsageCapture.validToken("phx_private_key"), false)
print("PASS: PostHog packet allowlist, UTC timestamp, stable IDs and partial retries")
