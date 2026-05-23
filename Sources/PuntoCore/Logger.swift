import Foundation

/// Simple file-based logger for debugging
public enum PuntoLog {
    private static let logFile = LogRetentionPolicy.activeLogPath

    /// Unique session ID to distinguish app restarts in logs
    public static let sessionId = String(UUID().uuidString.prefix(8))

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    public static func clear() {
        try? "".write(toFile: logFile, atomically: true, encoding: .utf8)
    }

    /// Rotate log files using the same bounded file-log shape Punto Switcher exposes through CocoaLumberjack.
    private static func rotateIfNeeded() {
        let fileManager = FileManager.default
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: logFile),
              let size = attrs[.size] as? Int,
              LogRetentionPolicy.shouldRotateActiveLog(size: size) else {
            return
        }

        let archivePath = LogRetentionPolicy.archivePath(for: Date())
        try? fileManager.moveItem(atPath: logFile, toPath: archivePath)
        pruneArchivedLogs(fileManager: fileManager)
    }

    private static func pruneArchivedLogs(fileManager: FileManager) {
        let directory = (logFile as NSString).deletingLastPathComponent
        guard let filenames = try? fileManager.contentsOfDirectory(atPath: directory) else {
            return
        }

        let files = filenames.compactMap { filename -> ArchivedLogFile? in
            guard filename.hasPrefix(LogRetentionPolicy.archivePrefix),
                  filename.hasSuffix(".\(LogRetentionPolicy.archiveExtension)") else {
                return nil
            }

            let path = "\(directory)/\(filename)"
            guard let attrs = try? fileManager.attributesOfItem(atPath: path) else {
                return nil
            }

            return ArchivedLogFile(
                path: path,
                size: attrs[.size] as? Int ?? 0,
                modifiedAt: attrs[.modificationDate] as? Date ?? .distantPast
            )
        }

        for path in LogRetentionPolicy.archivedLogFilesToDelete(files) {
            try? fileManager.removeItem(atPath: path)
        }
    }

    public static func log(_ message: String, file: String = #file, line: Int = #line) {
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

    public static func info(_ message: String, file: String = #file, line: Int = #line) {
        log("INFO: \(message)", file: file, line: line)
    }

    public static func error(_ message: String, file: String = #file, line: Int = #line) {
        log("ERROR: \(message)", file: file, line: line)
    }

    public static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log("DEBUG: \(message)", file: file, line: line)
    }
}
