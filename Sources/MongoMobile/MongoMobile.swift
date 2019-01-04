import Foundation
import MongoSwift
import mongo_embedded
import mongoc_embedded

/// Settings for constructing a `MongoClient`
public struct MongoClientSettings {
    /// the database path to use
    public let dbPath: String

    /// public member-wise initializer
    public init(dbPath: String) {
        self.dbPath = dbPath
    }
}

public enum MongoMobileError: LocalizedError {
    case invalidClient()
    case invalidInstance(message: String)
    case invalidLibrary()
    case instanceDropError(message: String)
    case cleanupError(message: String)

    /// a string to be printed out when the error is thrown
    public var errorDescription: String? {
        switch self {
        case let .invalidInstance(message),
            let .instanceDropError(message),
            let .cleanupError(message):
            return message
        default:
            return nil
        }
    }
}

public struct MongoEmbeddedV1Error: LocalizedError {
    private let statusMessage: String
    private let error: mongo_embedded_v1_error

    public var errorDescription: String? {
        return "\(error): \(statusMessage)"
    }

    init(_ error: mongo_embedded_v1_error,
         statusMessage: String) {
        self.statusMessage = statusMessage
        self.error = error
    }
}

/// Prints a log statement in the format `[component] message`.
private func mongo_mobile_log_callback(userDataPtr: UnsafeMutableRawPointer?,
                                       messagePtr: UnsafePointer<Int8>?,
                                       componentPtr: UnsafePointer<Int8>?,
                                       contextPtr: UnsafePointer<Int8>?,
                                       severityPtr: Int32) {
    let message = messagePtr != nil ? String(cString: messagePtr!) : ""
    let component = componentPtr != nil ? String(cString: componentPtr!) : ""
    print("[\(component)] \(message)")
}

private struct WeakRef<T> where T: AnyObject {
    weak var reference: T?

    init(_ reference: T) {
        self.reference = reference
    }
}

/// Given an `OpaquePointer` to a `mongo_embedded_v1_status`, get the status's explanation.
private func getStatusExplanation(_ status: OpaquePointer?) -> String {
    return String(cString: mongo_embedded_v1_status_get_explanation(status))
}

/// A class containing static methods for working with MongoMobile.
public class MongoMobile {
    /// Shared singleton
    public static let shared = MongoMobile()

    /// Single embedded instance
    private var libraryInstance: OpaquePointer?
    /// Cache embedded instances for cleanup
    private var embeddedInstances = [String: OpaquePointer]()
    /// Cache embedded clients for cleanup
    private var embeddedClients = [WeakRef<MongoClient>]()

    private init() {
        #if os(Linux)
        let observer = CFRunLoopObserverCreateWithHandler(
            nil, CFRunLoopActivity.exit.rawValue, true, 0, { (observer, activity) in
            try? MongoMobile.shared.destroy()
            MongoSwift.cleanup()
        })
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, CFRunLoopMode.defaultMode)
        #else
        #if swift(>=4.2)
        // observe when application will terminate
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cleanup),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        #else
        // observe when application will terminate
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cleanup),
            name: NSNotification.Name.UIApplicationWillTerminate,
            object: nil
        )
        #endif
        #endif
        MongoSwift.initialize()
        reinitialize()
    }

    #if !os(Linux)
    /// Cleanup the library. Finalize.
    @objc internal func cleanup() {
        try? MongoMobile.shared.destroy()
        MongoSwift.cleanup()
    }
    #endif

    /**
     Perform required operations to reinitialize the embedded server.
     This will reinitialize the library so that other dbPaths can be used.
     */
    public func reinitialize() {
        let status = mongo_embedded_v1_status_create()
        var initParams = mongo_embedded_v1_init_params()
        initParams.log_callback = mongo_mobile_log_callback
        initParams.log_flags = UInt64(MONGO_EMBEDDED_V1_LOG_CALLBACK.rawValue)

        guard let instance = mongo_embedded_v1_lib_init(&initParams, status) else {
            fatalError(getStatusExplanation(status))
        }

        libraryInstance = instance
    }

    /**
      Perform required operations to clean up the embedded library instance.
     */
    public func destroy() throws {
        self.embeddedClients.forEach { ref in
            ref.reference?.close()
        }

        let status = mongo_embedded_v1_status_create()
        for (_, instance) in embeddedInstances {
            let result = mongo_embedded_v1_error(mongo_embedded_v1_instance_destroy(instance, status))
            if result != MONGO_EMBEDDED_V1_SUCCESS {
                throw MongoEmbeddedV1Error(result,
                                           statusMessage: getStatusExplanation(status))
            }
        }

        let result = mongo_embedded_v1_error(mongo_embedded_v1_lib_fini(libraryInstance, status))
        if result != MONGO_EMBEDDED_V1_SUCCESS {
            throw MongoEmbeddedV1Error(result,
                                       statusMessage: getStatusExplanation(status))
        }

        self.embeddedClients.removeAll()
        self.embeddedInstances.removeAll()
    }

    /**
     * Create a new `MongoClient` for the database indicated by `dbPath` in
     * the passed in settings.
     * NOTE: Only one dbPath can be used at a time.
     * - Parameters:
     *   - settings: required settings for client creation
     *
     * - Returns: a new `MongoClient`
     */
    public func create(_ settings: MongoClientSettings) throws -> MongoClient {
        let status = mongo_embedded_v1_status_create()
        var instance: OpaquePointer?
        if let cachedInstance = embeddedInstances[settings.dbPath] {
            instance = cachedInstance
        } else {
            // get the configuration as a JSON string
            let configuration = [
                "storage": [
                    "dbPath": settings.dbPath
                ]
            ]
            let configurationData = try JSONSerialization.data(withJSONObject: configuration)
            let configurationString = String(data: configurationData, encoding: .utf8)

            guard let library = libraryInstance else {
                throw MongoMobileError.invalidLibrary()
            }

            guard let capiInstance = mongo_embedded_v1_instance_create(library, configurationString, status) else {
                throw MongoMobileError.invalidInstance(message: getStatusExplanation(status))
            }

            instance = capiInstance
            embeddedInstances[settings.dbPath] = instance
        }

        guard let capiClient = mongoc_embedded_v1_client_create(instance) else {
            throw MongoMobileError.invalidClient()
        }

        let client = MongoClient(fromPointer: capiClient)
        self.embeddedClients.append(WeakRef(client))
        return client
    }
}
