@testable import MongoMobile
import XCTest

final class MongoMobileTests: XCTestCase {
    static var allTests: [(String, (MongoMobileTests) -> () throws -> Void)] {
        return [
            ("testMongoMobile", testMongoMobile)
        ]
    }

    func testMongoMobile() throws {
        try MongoMobile.initialize()
        defer {
            try? MongoMobile.close()
        }

        // setup database
        let documentPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let databasePath = documentPath.appendingPathComponent("test-mongo-mobile")

        do {
            try FileManager.default.removeItem(at: databasePath)
        } catch {}

        do {
            try FileManager.default.createDirectory(at: databasePath, withIntermediateDirectories: false)
        } catch {}

        let settings = MongoClientSettings(dbPath: databasePath.path)
        let client = try MongoMobile.create(settings)

        // execute the test
        let coll = try client.db("test").collection("foo")
        let insertResult = try coll.insertOne([ "test": 42 ])
        let findResult = try coll.find([ "_id": insertResult!.insertedId ])
        let docs = Array(findResult)
        XCTAssertEqual(docs[0]["test"] as? Int, 42)
    }
}
