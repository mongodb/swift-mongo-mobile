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
    /// Thrown when MongoMobile fails to initialize properly.
    case initError(message: String)

    /// Thrown when MongoMobile fails to clean up properly when closing.
    case deinitError(message: String)

    /// Thrown when creating a new embedded mongo instance fails.
    case instanceCreationError(message: String)

    /// Thrown when destroying an embedded mongo instance fails.
    case instanceDestructionError(message: String)

    /// Thrown when getting a client for an embedded mongo instance fails.
    case clientCreationError

    /// Thrown when MongoMobile is incorrectly used.
    case logicError(message: String)

    /// a string to be printed out when the error is thrown
    public var errorDescription: String? {
        switch self {
        case let .initError(message),
             let .deinitError(message),
             let .instanceCreationError(message),
             let .instanceDestructionError(message),
             let .logicError(message):
            return message
        default:
            return nil
        }
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
     *  - `MongoMobileError.logicError` if `MongoMobile` has already been initialized.
     *  - `MongoMobileError.initError` if there is any error initializing the embedded server.
     */
    public static func initialize(options: MongoMobileOptions? = nil) throws {
        guard self.libraryInstance == nil else {
            throw MongoMobileError.logicError(message: "MongoMobile already initialized")
        }

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
            throw MongoMobileError.initError(message: getStatusExplanation(status))
        }

        self.logger = options?.logger
        self.libraryInstance = instance
    }

    /**
     * Perform required operations to clean up the embedded server.
     *
     * - Throws:
     *   - `MongoMobileError.deinitError` if an error occurs while de-initializing the embedded server.
     */
    public static func close() throws {
        self.embeddedClients.forEach { ref in ref.reference?.close() }
        self.embeddedClients.removeAll()

        for (_, instance) in self.embeddedInstances { try destroyInstance(instance) }
        self.embeddedInstances.removeAll()

        let status = mongo_embedded_v1_status_create()
        let result = mongo_embedded_v1_error(mongo_embedded_v1_lib_fini(self.libraryInstance, status))
        guard result == MONGO_EMBEDDED_V1_SUCCESS else {
            throw MongoMobileError.deinitError(message: getStatusExplanation(status))
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
     *
     * - Throws:
     *   - `MongoMobileError.logicError` if `MongoMobile.initialize` has not been called yet.
     *   - `MongoMobileError.instanceCreationError` if an instance corresponding to `dbPath` isn't cached and an error
     *     occurs while creating it.
     *   - `MongoMobileError.clientCreationError` if an error occurs while creating the client.
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
                throw MongoMobileError.logicError(message: "MongoMobile must be initialized before calling create()")
            }

            guard let capiInstance = mongo_embedded_v1_instance_create(library, configurationString, status) else {
                throw MongoMobileError.instanceCreationError(message: getStatusExplanation(status))
            }

            instance = capiInstance
            self.embeddedInstances[settings.dbPath] = instance
        }

        guard let capiClient = mongoc_embedded_v1_client_create(instance) else {
            throw MongoMobileError.clientCreationError
        }

        let client = MongoClient(fromPointer: capiClient)
        self.embeddedClients.append(WeakRef(client))
        return client
    }

    private static func destroyInstance(_ instance: OpaquePointer) throws {
        let status = mongo_embedded_v1_status_create()
        let result = mongo_embedded_v1_error(mongo_embedded_v1_instance_destroy(instance, status))
        guard result == MONGO_EMBEDDED_V1_SUCCESS else {
            throw MongoMobileError.instanceDestructionError(message: getStatusExplanation(status))
        }
    }
}
