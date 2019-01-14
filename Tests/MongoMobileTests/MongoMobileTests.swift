import MongoSwift
import XCTest

@testable import MongoMobile

public final class MongoMobileTests: XCTestCase {
    public static var allTests: [(String, (MongoMobileTests) -> () throws -> Void)] {
        return [
            ("testMongoMobileBasic", testMongoMobileBasic),
            ("testSequentialAccess", testSequentialAccess)
        ]
    }

    // NOTE: These only works because we have one test suite. These method are called
    //       before/after all tests _per_ test suite. Will not work if another suite
    //       is added.
    override public class func setUp() {
        super.setUp()
        try? MongoMobile.initialize()
    }

    override public class func tearDown() {
        super.tearDown()
        try? MongoMobile.close()
    }

    public func createAndCleanTemporaryPath(at path: String) throws -> URL {
        let supportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let databasePath = supportPath.appendingPathComponent(path)

        try? FileManager.default.removeItem(at: databasePath)
        try? FileManager.default.createDirectory(at: databasePath, withIntermediateDirectories: false)
        return databasePath
    }

    public func runBasicInsertFindTest(on client: MongoClient) throws {
        let coll = try client.db("test").collection("foo")
        let insertResult = try coll.insertOne([ "test": 42 ])
        // swiftlint:disable:next force_unwrapping - always returns a value if succeeded
        let findResult = try coll.find([ "_id": insertResult!.insertedId ])
        let docs = Array(findResult)
        XCTAssertEqual(docs[0]["test"] as? Int, 42)
    }

    public func testMongoMobileBasic() throws {
        let databasePath = try createAndCleanTemporaryPath(at: "test-mongo-mobile")
        let settings = MongoClientSettings(dbPath: databasePath.path)
        let client = try MongoMobile.create(settings)
        try runBasicInsertFindTest(on: client)
    }

    public func testSequentialAccess() throws {
        let databasePathA = try createAndCleanTemporaryPath(at: "embedded-app-a")
        let clientA = try MongoMobile.create(MongoClientSettings(dbPath: databasePathA.path))
        try runBasicInsertFindTest(on: clientA)

        let databasePathB = try createAndCleanTemporaryPath(at: "embedded-app-b")
        let clientB = try MongoMobile.create(MongoClientSettings(dbPath: databasePathB.path))
        try runBasicInsertFindTest(on: clientB)
        // TODO: verify that clientA is closed when SWIFT-323 is completed

        let clientA2 = try MongoMobile.create(MongoClientSettings(dbPath: databasePathA.path))
        try runBasicInsertFindTest(on: clientA2)
    }
}
