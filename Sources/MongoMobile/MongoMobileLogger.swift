/// If the user provided a logger when initializing the library, executes the 
/// `onMessage` callback for that logger.
internal func mongo_mobile_log_callback(userDataPtr: UnsafeMutableRawPointer?,
                                        messagePtr: UnsafePointer<Int8>?,
                                        componentPtr: UnsafePointer<Int8>?,
                                        contextPtr: UnsafePointer<Int8>?,
                                        severity: Int32) {
    guard let logger = MongoMobile.logger else {
        return
    }

    let message = String(from: messagePtr)
    let component = String(from: componentPtr)
    let context = String(from: contextPtr)
    // swiftlint:disable:next force_unwrapping - server should always gives a valid raw value.
    let severity = LogSeverity(rawValue: severity)!
    logger.onMessage(message: message, component: component, context: context, severity: severity)
}

extension String {
    /// Returns a string created from the given pointer, or an empty
    /// string if the pointer is nil.
    fileprivate init(from ptr: UnsafePointer<Int8>?) {
        if let ptr = ptr {
            self = String(cString: ptr)
        } else {
            self = ""
        }
    }
}

/// Defines the requirements for a type that can be used as a logger
/// for the embedded library.
public protocol MongoMobileLogger {
    /**
    * A callback that will be executed when a new message is produced
    * by an embedded server.
    *
    * - Parameters:
    *   - message: The text of the log message.
    *   - component: Functional categorization of the message, e.g. "query" or "network".
    *   - context: Describes the context in which this message occurred, e.g. "initandlisten".
    *   - severity: The severity level associated with this message.
    * 
    * - SeeAlso: https://docs.mongodb.com/manual/reference/log-messages/
    */
    func onMessage(message: String,
                   component: String,
                   context: String,
                   severity: LogSeverity)
}

/// The severity of a log message. `RawRepresentable` as an `Int32`.
public enum LogSeverity: RawRepresentable {
    case fatal,
    error,
    warning,
    info,
    log,
    debug(verbosity: Int32)

    public typealias RawValue = Int32

    public var rawValue: Int32 {
        switch self {
        case .fatal:
            return -4
        case .error:
            return -3
        case .warning:
            return -2
        case .info:
            return -1
        case .log:
            return 0
        case .debug(let v):
            return v
        }
    }

    public init?(rawValue: Int32) {
        switch rawValue {
        case -4:
            self = .fatal
        case -3:
            self = .error
        case -2:
            self = .warning
        case -1:
            self = .info
        case 0:
            self = .log
        case 1...5:
            self = .debug(verbosity: rawValue)
        default:
            return nil
        }
    }
}
