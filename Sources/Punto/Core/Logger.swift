import Foundation

/// Simple file-based logger for debugging
enum PuntoLog {
    private static let logFile = "/tmp/punto.log"
    private static let backupLogFile = "/tmp/punto.log.1"
    private static let maxLogSize = 1_000_000  // 1 MB

    /// Unique session ID to distinguish app restarts in logs
    static let sessionId = String(UUID().uuidString.prefix(8))

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    static func clear() {
        try? "".write(toFile: logFile, atomically: true, encoding: .utf8)
    }

    /// Rotate log file if it exceeds maxLogSize
    private static func rotateIfNeeded() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: logFile),
              let size = attrs[.size] as? Int,
              size > maxLogSize else {
            return
        }

        // Remove old backup and rename current to backup
        try? FileManager.default.removeItem(atPath: backupLogFile)
        try? FileManager.default.moveItem(atPath: logFile, toPath: backupLogFile)
    }

    static func log(_ message: String, file: String = #file, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let threadId = Thread.isMainThread ? "main" : "bg"
        let entry = "[\(timestamp)] [\(sessionId)] [\(threadId)] [\(fileName):\(line)] \(message)\n"

        // Also print to stdout
        print(entry, terminator: "")
        fflush(stdout)

        // Rotate if needed
        rotateIfNeeded()

        // Write to file
        if let handle = FileHandle(forWritingAtPath: logFile) {
            handle.seekToEndOfFile()
            if let data = entry.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } else {
            // Create file if doesn't exist
            try? entry.write(toFile: logFile, atomically: true, encoding: .utf8)
        }
    }

    static func info(_ message: String, file: String = #file, line: Int = #line) {
        log("INFO: \(message)", file: file, line: line)
    }

    static func error(_ message: String, file: String = #file, line: Int = #line) {
        log("ERROR: \(message)", file: file, line: line)
    }

    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log("DEBUG: \(message)", file: file, line: line)
    }
}
