import XCTest
import MongoSwift

@testable import MongoMobile

final class MongoMobileTests: XCTestCase {
    static var allTests: [(String, (MongoMobileTests) -> () throws -> Void)] {
        return [
            ("testMongoMobileBasic", testMongoMobileBasic),
            ("testSequentialAccess", testSequentialAccess)
        ]
    }

    // NOTE: These only works because we have one test suite. These method are called
    //       before/after all tests _per_ test suite. Will not work if another suite
    //       is added.
    override class func setUp() {
        super.setUp()
        try? MongoMobile.initialize()
    }

    override class func tearDown() {
        super.tearDown()
        try? MongoMobile.close()
    }

    func createAndCleanTemporaryPath(at path: String) throws -> URL {
        let supportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let databasePath = supportPath.appendingPathComponent(path)

        do {
            try FileManager.default.removeItem(at: databasePath)
        } catch {}

        do {
            try FileManager.default.createDirectory(at: databasePath, withIntermediateDirectories: false)
        } catch {}

        return databasePath
    }

    func testMongoMobileBasic() throws {
        let databasePath = try createAndCleanTemporaryPath(at: "test-mongo-mobile")
        let settings = MongoClientSettings(dbPath: databasePath.path)
        let client = try MongoMobile.create(settings)

        // execute the test
        let coll = try client.db("test").collection("foo")
        let insertResult = try coll.insertOne([ "test": 42 ])
        let findResult = try coll.find([ "_id": insertResult!.insertedId ])
        let docs = Array(findResult)
        XCTAssertEqual(docs[0]["test"] as? Int, 42)
    }

    func testSequentialAccess() throws {
        func runTest(on client: MongoClient) throws {
            let coll = try client.db("test").collection("foo")
            let insertResult = try coll.insertOne([ "test": 42 ])
            let findResult = try coll.find([ "_id": insertResult!.insertedId ])
            let docs = Array(findResult)
            XCTAssertEqual(docs[0]["test"] as? Int, 42)
        }

        let databasePathA = try createAndCleanTemporaryPath(at: "embedded-app-a")
        let clientA = try MongoMobile.create(MongoClientSettings(dbPath: databasePathA.path))
        try runTest(on: clientA)

        let databasePathB = try createAndCleanTemporaryPath(at: "embedded-app-b")
        let clientB = try MongoMobile.create(MongoClientSettings(dbPath: databasePathB.path))
        try runTest(on: clientB)
        // TODO: verify that clientA is closed when SWIFT-323 is completed

        let clientA2 = try MongoMobile.create(MongoClientSettings(dbPath: databasePathA.path))
        try runTest(on: clientA2)
    }
}
