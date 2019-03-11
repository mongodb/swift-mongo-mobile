import Foundation
import mongo_embedded
import mongoc_embedded
import MongoSwift

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

    internal init(_ error: mongo_embedded_v1_error, statusMessage: String) {
        self.statusMessage = statusMessage
        self.error = error
    }
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

/// Options for initializing the embedded server.
public struct MongoMobileOptions {
    /// An optional `MongoMobileLogger` to use with the embedded server.
    /// This logger will be used across all DBs and clients until the 
    /// embedded server is shut down via `MongoMobile.close()`.
    public var logger: MongoMobileLogger?

    /// Initializes a new `MongoMobileOptions`.
    public init(logger: MongoMobileLogger? = nil) {
        self.logger = logger
    }
}

/// A class containing static methods for working with MongoMobile.
public class MongoMobile {
    private static var libraryInstance: OpaquePointer?
    /// Cache embedded instances for cleanup
    private static var embeddedInstances = [String: OpaquePointer]()
    /// Cache embedded clients for cleanup
    private static var embeddedClients = [WeakRef<MongoClient>]()
    /// Store user-provided logger.
    internal static var logger: MongoMobileLogger?

    /**
     * Perform required operations to initialize the embedded server.
     * 
     * Parameters:
     *  - options: options to set on the embedded server.        
     *
     * Throws:
     *  - `MongoMobileError.invalidInstance` if there is any error initializing 
     *    the embedded server.
     */
    public static func initialize(options: MongoMobileOptions? = nil) throws {
        MongoSwift.initialize()

        let status = mongo_embedded_v1_status_create()
        var initParams = mongo_embedded_v1_init_params()

        if options?.logger != nil {
            initParams.log_flags = UInt64(MONGO_EMBEDDED_V1_LOG_CALLBACK.rawValue)
            initParams.log_callback = mongo_mobile_log_callback
        } else {
            initParams.log_flags = UInt64(MONGO_EMBEDDED_V1_LOG_NONE.rawValue)
        }

        guard let instance = mongo_embedded_v1_lib_init(&initParams, status) else {
            throw MongoMobileError.invalidInstance(message: getStatusExplanation(status))
        }

        self.logger = options?.logger
        self.libraryInstance = instance
    }

    /**
     * Perform required operations to clean up the embedded server.
     */
    public static func close() throws {
        self.embeddedClients.forEach { ref in ref.reference?.close() }
        self.embeddedClients.removeAll()

        for (_, instance) in self.embeddedInstances { try destroyInstance(instance) }
        self.embeddedInstances.removeAll()

        let status = mongo_embedded_v1_status_create()
        let result = mongo_embedded_v1_error(mongo_embedded_v1_lib_fini(self.libraryInstance, status))
        guard result == MONGO_EMBEDDED_V1_SUCCESS else {
            throw MongoEmbeddedV1Error(result,
                                       statusMessage: getStatusExplanation(status))
        }
        self.logger = nil
        self.libraryInstance = nil
        MongoSwift.cleanup()
    }

    /**
     * Create a new `MongoClient` for the database indicated by `dbPath` in
     * the passed in settings.
     *
     * - Parameters:
     *   - settings: required settings for client creation
     *
     * - Returns: a new `MongoClient`
     */
    public static func create(_ settings: MongoClientSettings) throws -> MongoClient {
        let status = mongo_embedded_v1_status_create()
        var instance: OpaquePointer?
        if let cachedInstance = self.embeddedInstances[settings.dbPath] {
            instance = cachedInstance
        } else {
            // NOTE: This hack can be removed once SERVER-38943 is resolved. Also note
            //       that the destroy code is not refactored into a common function because
            //       we should be removing this code in the near future.
            if !self.embeddedInstances.isEmpty {
                self.embeddedClients.forEach { ref in ref.reference?.close() }
                self.embeddedClients.removeAll()

                for (_, instance) in self.embeddedInstances { try destroyInstance(instance) }
                self.embeddedInstances.removeAll()
            }

            // get the configuration as a JSON string
            let configuration = [
                "storage": [
                    "dbPath": settings.dbPath
                ]
            ]
            let configurationData = try JSONSerialization.data(withJSONObject: configuration)
            let configurationString = String(data: configurationData, encoding: .utf8)

            guard let library = self.libraryInstance else {
                throw MongoMobileError.invalidLibrary()
            }

            guard let capiInstance = mongo_embedded_v1_instance_create(library, configurationString, status) else {
                throw MongoMobileError.invalidInstance(message: getStatusExplanation(status))
            }

            instance = capiInstance
            self.embeddedInstances[settings.dbPath] = instance
        }

        guard let capiClient = mongoc_embedded_v1_client_create(instance) else {
            throw MongoMobileError.invalidClient()
        }

        let client = MongoClient(fromPointer: capiClient)
        self.embeddedClients.append(WeakRef(client))
        return client
    }

    private static func destroyInstance(_ instance: OpaquePointer) throws {
        let status = mongo_embedded_v1_status_create()
        let result = mongo_embedded_v1_error(mongo_embedded_v1_instance_destroy(instance, status))
        guard result == MONGO_EMBEDDED_V1_SUCCESS else {
            throw MongoEmbeddedV1Error(result, statusMessage: getStatusExplanation(status))
        }
    }
}
