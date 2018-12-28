@testable import MongoMobile
import XCTest

final class MongoMobileTests: XCTestCase {
    static var allTests: [(String, (MongoMobileTests) -> () throws -> Void)] {
        return [
            ("testMongoMobile", testMongoMobile)
        ]
    }

    override class func tearDown() {
        MongoMobile.shared.cleanup()
    }

    func testMongoMobile() throws {
        var client = try MongoMobile.shared.create(MongoClientSettings(dbPath: FileManager().currentDirectoryPath))
        var coll = try client.db("test").collection("foo")
        var insertResult = try coll.insertOne([ "test": 42 ])
        var findResult = try coll.find([ "_id": insertResult!.insertedId ])
        var docs = Array(findResult)
        XCTAssertEqual(docs[0]["test"] as? Int, 42)

        try MongoMobile.shared.destroy()
        MongoMobile.shared.reinitialize()

        client = try MongoMobile.shared.create(MongoClientSettings(dbPath: FileManager().currentDirectoryPath))
        coll = try client.db("test").collection("foo")
        insertResult = try coll.insertOne([ "test": 42 ])
        findResult = try coll.find([ "_id": insertResult!.insertedId ])
        docs = Array(findResult)
        XCTAssertEqual(docs[0]["test"] as? Int, 42)
    }
}
