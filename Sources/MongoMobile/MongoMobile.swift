import libmongodbcapi

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
    case invalidDatabase()
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
  private static var libraryInstance: OpaquePointer
  private static var embeddedInstances = [String: OpaquePointer]()

  /**
   * Perform required operations to initialize the embedded server.
   */
  public static func initialize() {
    // NOTE: remove once MongoSwift is handling this
    mongoc_init()

    var initParams = mongo_embedded_v1_init_params()
    initParams.log_callback = mongo_mobile_log_callback
    initParams.log_flags = 4 // LIBMONGODB_CAPI_LOG_CALLBACK
    libraryInstance = mongo_embedded_v1_lib_init(&initParams)
  }

  /**
   * Perform required operations to cleanup the embedded server.
   */
  public static func close() {
    for (_, instance) in embeddedInstances {
        mongo_embedded_v1_instance_destroy(instance)
    }

    mongo_embedded_v1_lib_fini(libraryInstance)

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
    var database: OpaquePointer
    if let cachedInstance = embeddedInstances[settings.dbPath] {
        database = cachedInstance
    } else {
        let configuration = [
            "storage": [
                "dbPath": settings.dbPath
            ]
        ]

        let configurationData = try JSONSerialization.data(withJSONObject: configuration)
        let configurationString = String(data: configurationData, encoding: .utf8)
        guard let capiInstance = mongo_embedded_v1_instance_create(libraryInstance, configurationString) else {
            throw MongoMobileError.invalidDatabase()
        }

        instance = capiInstance
        embeddedInstances[settings.dbPath] = instance
    }

    guard let capiClient = mongo_embedded_v1_mongoc_client_create(database) else {
        throw MongoMobileError.invalidClient()
    }

    return MongoClient(fromPointer: capiClient)
  }
}
