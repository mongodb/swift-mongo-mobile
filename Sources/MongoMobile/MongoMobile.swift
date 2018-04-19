import libmongodbcapi

/// Settings for constructing a `MongoClient`
public struct MongoClientSettings {
  /// the database path to use
  public let dbPath: String
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
//    let component = String(cString: componentPtr!)
//    let context = String(cString: contextPtr!)
    print(message);
}

public class MongoMobile {
  private static var databases = [String: OpaquePointer]()

  /**
   * Perform required operations to initialize the embedded server.
   */
  public static func initialize() {
    print("initializing....")
    var initParams = libmongodbcapi_init_params()
    initParams.log_callback = mongo_mobile_log_callback
    initParams.log_flags = 4 // LIBMONGODB_CAPI_LOG_CALLBACK

    let result = libmongodbcapi_init(&initParams);
    if libmongodbcapi_error(result) != LIBMONGODB_CAPI_SUCCESS {
        print("error initializing: \(result)")
    }

    print("initialized with result: \(result)")
  }

  /**
   * Perform required operations to cleanup the embedded server.
   */
  public static func close() {
    for (_, database) in databases {
      libmongodbcapi_db_destroy(database)
    }
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
  public static func create(/* settings: MongoClientSettings */) throws -> MongoClient {
    let settings = MongoClientSettings(dbPath: "test-mongo-mobile")
    var database: OpaquePointer
    if let _database = databases[settings.dbPath] {
      database = _database
    } else {
      // let appSupportDirPath =
      //   String(describing: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
      // print("appSupportDirPath: \(appSupportDirPath)")

      let dataPath = NSHomeDirectory()

      let yamlData = "{ \"storage\": { \"dbpath\": \"\(dataPath)\" } }";
      guard let _db = libmongodbcapi_db_new(yamlData) else {
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
