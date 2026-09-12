// Opt-in: sends synthetic examples through the authenticated Codex CLI.
// swiftc Sources/PuntoNative/LunaClient.swift Scripts/check-luna-prompt.swift -o /tmp/punto-prompt-check
import Foundation
@main struct PromptCheck {
    static func main() {
        let samples = [
            "Нужно сделать экспорт в CSV. Нет, в JSON. Только последние 42 записи. Не удаляй данные. Сначала покажи план, потом код. Интерфейс потом, сейчас не трогать.",
            "Напиши короткий промпт для проверки README. Ссылку https://example.com/docs сохрани. Файл docs/README.md. Срок пока не знаю. Может таблица, может список - ещё решим."
        ]
        for (index,text) in samples.enumerated() {
            let client = LunaClient(); var done = false
            client.correct(text,mode:.prompt) { result in
                guard case .success(let output) = result else { fatalError("Model request failed: \(result)") }
                print("Sample \(index+1):\n\(output)\n")
                precondition(!output.contains("—") && !output.contains("–"))
                if index == 0 {
                    precondition(output.contains("JSON") && output.contains("42"))
                    precondition(!output.contains("CSV"))
                    precondition(output.lowercased().contains("не удал") || output.lowercased().contains("без удал"))
                } else {
                    precondition(output.contains("https://example.com/docs") && output.contains("docs/README.md"))
                    precondition(output.lowercased().contains("срок"),"Dropped explicit unknown deadline")
                }
                done = true
            }
            while !done { RunLoop.current.run(until:Date().addingTimeInterval(0.1)) }
        }
        print("PASS: prompt mode, self-correction, constraints, names, paths and ASCII dashes (two live samples)")
    }
}
