import AppKit
import Combine

final class CodexConnection:ObservableObject {
    enum Status { case checking, connected, signedOut, missing, unavailable }
    @Published private(set) var status:Status = .checking
    @Published private(set) var account = ""
    @Published private(set) var checkedAt:Date?
    private var process:Process?
    private var generation = UUID()
    var title:String {
        switch status {
        case .checking: return "Проверяю Codex…"
        case .connected: return "Codex подключён"
        case .signedOut: return "Войдите в Codex"
        case .missing: return "Codex не установлен"
        case .unavailable: return "Не удалось проверить Codex"
        }
    }
    var detail:String {
        switch status {
        case .checking: return "Проверка установки и входа"
        case .connected: return "\(account) · GPT-5.6 Luna"
        case .signedOut: return "Для корректуры нужен вход в ваш аккаунт."
        case .missing: return "Установите Codex CLI, затем войдите в аккаунт."
        case .unavailable: return "Повторите проверку или проверьте Codex в Терминале."
        }
    }
    func refresh() {
        guard process == nil else { return }
        guard let url = LunaClient.executable else { status = .missing; checkedAt = Date(); return }
        status = .checking
        let id = UUID(); generation = id
        let child = Process(), output = Pipe()
        child.executableURL = url; child.arguments = ["login","status"]
        child.standardOutput = output; child.standardError = output; child.standardInput = FileHandle.nullDevice
        child.terminationHandler = { [weak self] process in
            let message = String(data:output.fileHandleForReading.readDataToEndOfFile(),encoding:.utf8) ?? ""
            DispatchQueue.main.async {
                guard let self, self.generation == id else { return }
                self.process = nil; self.checkedAt = Date()
                if process.terminationStatus == 0 && message.contains("Logged in") {
                    self.account = message.contains("ChatGPT") ? "Вход через ChatGPT" : "Вход выполнен"
                    self.status = .connected
                } else if message.lowercased().contains("not logged in") { self.status = .signedOut }
                else { self.status = .unavailable }
            }
        }
        do { try child.run(); process = child }
        catch { status = .unavailable; checkedAt = Date(); return }
        DispatchQueue.main.asyncAfter(deadline:.now()+5) { [weak self] in
            guard let self, self.generation == id, child.isRunning else { return }
            self.generation = UUID(); child.terminate(); self.process = nil
            self.status = .unavailable; self.checkedAt = Date()
            DispatchQueue.global().asyncAfter(deadline:.now()+1) { if child.isRunning { kill(child.processIdentifier,SIGKILL) } }
        }
    }
}
