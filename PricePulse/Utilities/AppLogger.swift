import OSLog

/// Centralized `os.Logger` instances, one per subsystem area, so log output can be
/// filtered by category in Console.app while keeping call sites terse.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.pricepulse.app"

    static let scraping = Logger(subsystem: subsystem, category: "scraping")
    static let background = Logger(subsystem: subsystem, category: "background")
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
}
