import Foundation
import OSLog

public struct AppLogger {
    private let logger: Logger

    public init(category: String) {
        logger = Logger(subsystem: "com.matthiaswallnergehri.pirrates-captain", category: category)
    }

    public func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    public func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
