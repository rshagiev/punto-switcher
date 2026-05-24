import Foundation

public struct ArchivedLogFile: Equatable {
    public let path: String
    public let size: Int
    public let modifiedAt: Date

    public init(path: String, size: Int, modifiedAt: Date) {
        self.path = path
        self.size = max(0, size)
        self.modifiedAt = modifiedAt
    }
}

public enum LogRetentionPolicy {
    public static let activeLogPath = "/tmp/punto.log"
    public static let archivePrefix = "punto.log."
    public static let archiveExtension = "log"
    public static let maxActiveLogSize = 1_000_000
    public static let maximumNumberOfArchivedLogFiles = 5
    public static let logFilesDiskQuota = 5_000_000

    public static func archivePath(for date: Date, directory: String = "/tmp") -> String {
        archivePath(for: date, directory: directory, collisionIndex: 0)
    }

    public static func archivePath(for date: Date, directory: String = "/tmp", collisionIndex: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
        let suffix = collisionIndex > 0 ? String(format: "-%03d", collisionIndex) : ""
        return "\(directory)/\(archivePrefix)\(formatter.string(from: date))\(suffix).\(archiveExtension)"
    }

    public static func uniqueArchivePath(
        for date: Date,
        directory: String = "/tmp",
        existingPaths: Set<String>
    ) -> String {
        var collisionIndex = 0
        while true {
            let path = archivePath(for: date, directory: directory, collisionIndex: collisionIndex)
            if !existingPaths.contains(path) {
                return path
            }
            collisionIndex += 1
        }
    }

    public static func shouldArchiveActiveLogAtStartup(size: Int) -> Bool {
        size > 0
    }

    public static func shouldRotateActiveLog(size: Int, maxActiveLogSize: Int = Self.maxActiveLogSize) -> Bool {
        size > max(0, maxActiveLogSize)
    }

    public static func archivedLogFilesToDelete(
        _ files: [ArchivedLogFile],
        maximumNumberOfFiles: Int = Self.maximumNumberOfArchivedLogFiles,
        diskQuota: Int = Self.logFilesDiskQuota
    ) -> [String] {
        let normalizedMaxFiles = max(0, maximumNumberOfFiles)
        let normalizedQuota = max(0, diskQuota)
        let newestFirst = files.sorted {
            if $0.modifiedAt == $1.modifiedAt {
                return $0.path > $1.path
            }
            return $0.modifiedAt > $1.modifiedAt
        }

        var kept: [ArchivedLogFile] = []
        var totalSize = 0
        var deletePaths: [String] = []

        for file in newestFirst {
            let wouldExceedCount = kept.count >= normalizedMaxFiles
            let wouldExceedQuota = totalSize + file.size > normalizedQuota
            if wouldExceedCount || wouldExceedQuota {
                deletePaths.append(file.path)
            } else {
                kept.append(file)
                totalSize += file.size
            }
        }

        return deletePaths.sorted()
    }
}
