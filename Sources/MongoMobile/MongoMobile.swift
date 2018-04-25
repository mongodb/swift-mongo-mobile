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
    print(message);
}

public class MongoMobile {
  private static var databases = [String: OpaquePointer]()

  /**
   * Perform required operations to initialize the embedded server.
   */
  public static func initialize() {
    // NOTE: remove once MongoSwift is handling this
    mongoc_init()

    var initParams = libmongodbcapi_init_params()
    initParams.log_callback = mongo_mobile_log_callback
    initParams.log_flags = 4 // LIBMONGODB_CAPI_LOG_CALLBACK
    libmongodbcapi_init(&initParams)
  }

  /**
   * Perform required operations to cleanup the embedded server.
   */
  public static func close() {
    for (_, database) in databases {
        libmongodbcapi_db_destroy(database)
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
    var database: OpaquePointer
    if let _database = databases[settings.dbPath] {
        database = _database
    } else {
        let databasePath = NSHomeDirectory()
        let configuration = [
            "storage": [
                "dbPath": databasePath
            ]
        ]

        let configurationData = try JSONSerialization.data(withJSONObject: configuration)
        let configurationString = String(data: configurationData, encoding: .utf8)
        guard let _db = libmongodbcapi_db_new(configurationString) else {
            throw MongoMobileError.invalidDatabase()
        }

        database = _db
        databases[settings.dbPath] = database
    }

    guard let client_t = embedded_mongoc_client_new(database) else {
        throw MongoMobileError.invalidClient()
    }

    return MongoClient(fromPointer: client_t)
  }
}
