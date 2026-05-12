import Foundation
import os.log

// MARK: - Logger
enum Logger {

    // MARK: - Private Properties

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.naplet.app"

    private static let categories: [LogLevel: OSLog] = [
        .debug: OSLog(subsystem: subsystem, category: "Debug"),
        .info: OSLog(subsystem: subsystem, category: "Info"),
        .warning: OSLog(subsystem: subsystem, category: "Warning"),
        .error: OSLog(subsystem: subsystem, category: "Error")
    ]

    // MARK: - Log Method

    /// Logs a message with the specified level
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The log level (default: .debug)
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    static func log(
        _ message: String,
        level: LogLevel = .debug,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Check if we should log based on current environment's log level
        guard level >= AppEnvironment.current.logLevel else { return }

        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) → \(message)"

        // Log to OSLog
        let osLog = categories[level] ?? .default
        let osLogType: OSLogType = {
            switch level {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }()

        os_log("%{public}@", log: osLog, type: osLogType, logMessage)

        // Also print to console in debug builds
        #if DEBUG
        print("\(level.prefix) \(logMessage)")
        #endif
    }

    // MARK: - Convenience Methods

    /// Log a debug message
    static func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    /// Log an info message
    static func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    /// Log a warning message
    static func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    /// Log an error message
    static func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    /// Log an error with the Error object
    static func error(
        _ error: Error,
        context: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let message: String
        if let context = context {
            message = "\(context): \(error.localizedDescription)"
        } else {
            message = error.localizedDescription
        }
        log(message, level: .error, file: file, function: function, line: line)
    }
}

// MARK: - Performance Logging
extension Logger {

    /// Measures and logs the execution time of a block
    static func measure<T>(
        _ label: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        block: () throws -> T
    ) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let end = CFAbsoluteTimeGetCurrent()
        let duration = (end - start) * 1000 // Convert to milliseconds

        log("⏱ \(label): \(String(format: "%.2f", duration))ms", level: .debug, file: file, function: function, line: line)

        return result
    }

    /// Measures and logs the execution time of an async block
    static func measureAsync<T>(
        _ label: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        block: () async throws -> T
    ) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let end = CFAbsoluteTimeGetCurrent()
        let duration = (end - start) * 1000

        log("⏱ \(label): \(String(format: "%.2f", duration))ms", level: .debug, file: file, function: function, line: line)

        return result
    }
}
