import mongo_embedded

let MONGO_EMBEDDED_V1_ERROR_EXCEPTION = 2;

/// Settings for constructing a `MongoClient`
public struct MongoClientSettings {
  /// the database path to use
  public let dbPath: String

  /// public member-wise initializer
  public init(dbPath: String) {
    self.dbPath = dbPath
  }
}

public enum MongoMobileError: Error {
    case invalidClient()
    case invalidInstance(message: String)
    case invalidLibrary()
    case instanceDropError(message: String)
    case cleanupError(message: String)
}

private func mongo_mobile_log_callback(userDataPtr: UnsafeMutableRawPointer?,
                                       messagePtr: UnsafePointer<Int8>?,
                                       componentPtr: UnsafePointer<Int8>?,
                                       contextPtr: UnsafePointer<Int8>?,
                                       severityPtr: Int32)
{
    let message = String(cString: messagePtr!)
    let component = String(cString: componentPtr!)
    print("[\(component)] \(message)")
}

public class MongoMobile {
  private static var libraryInstance: OpaquePointer?
  private static var embeddedInstances = [String: OpaquePointer]()

  /**
   * Perform required operations to initialize the embedded server.
   */
  public static func initialize() throws {
    // NOTE: remove once MongoSwift is handling this
    mongoc_init()

    let status = mongo_embedded_v1_status_create()
    var initParams = mongo_embedded_v1_init_params()
    initParams.log_callback = mongo_mobile_log_callback
    initParams.log_flags = 4 // LIBMONGODB_CAPI_LOG_CALLBACK

    guard let instance = mongo_embedded_v1_lib_init(&initParams, status) else {
        throw MongoMobileError.invalidInstance(message:
                String(cString: mongo_embedded_v1_status_get_explanation(status)))
    }

    libraryInstance = instance
  }

  /**
   * Perform required operations to cleanup the embedded server.
   */
  public static func close() throws {
    let status = mongo_embedded_v1_status_create()
    for (_, instance) in embeddedInstances {
        let result = mongo_embedded_v1_instance_destroy(instance, status)
        if result == MONGO_EMBEDDED_V1_ERROR_EXCEPTION {
            throw MongoMobileError.instanceDropError(message:
                String(cString: mongo_embedded_v1_status_get_explanation(status)))
        }
    }

    let result = mongo_embedded_v1_lib_fini(libraryInstance, status)
    if result == MONGO_EMBEDDED_V1_ERROR_EXCEPTION {
        throw MongoMobileError.cleanupError(message:
            String(cString: mongo_embedded_v1_status_get_explanation(status)))
    }

    // NOTE: remove once MongoSwift is handling this
    mongoc_cleanup()
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
    var instance: OpaquePointer
    if let cachedInstance = embeddedInstances[settings.dbPath] {
        instance = cachedInstance
    } else {
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
            throw MongoMobileError.invalidInstance(message:
                String(cString: mongo_embedded_v1_status_get_explanation(status)))
        }

        instance = capiInstance
        embeddedInstances[settings.dbPath] = instance
    }

    guard let capiClient = mongo_embedded_v1_mongoc_client_create(instance) else {
        throw MongoMobileError.invalidClient()
    }

    return MongoClient(fromPointer: capiClient)
  }
}
