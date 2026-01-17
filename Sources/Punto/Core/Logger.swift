import Foundation

/// Simple file-based logger for debugging
enum PuntoLog {
    private static let logFile = "/tmp/punto.log"
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    static func clear() {
        try? "".write(toFile: logFile, atomically: true, encoding: .utf8)
    }

    static func log(_ message: String, file: String = #file, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let entry = "[\(timestamp)] [\(fileName):\(line)] \(message)\n"

        // Also print to stdout
        print(entry, terminator: "")
        fflush(stdout)

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
