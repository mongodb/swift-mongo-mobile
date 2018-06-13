@testable import MongoMobile
import XCTest

final class MongoMobileTests: XCTestCase {
    static var allTests: [(String, (ClientTests) -> () throws -> Void)] {
        return [
            ("testMongoMobile", testMongoMobile)
        ]
    }

    func testMongoMobile() throws {
        let client = MongoMobile.create(settings: MongoClientSettings(dbPath: "test-path"))
        let coll = try client.db("test").collection("foo")
        let insertResult = try coll.insertOne([ "test": 42 ])
        let findResult = try coll.find([ "_id": insertResult!.insertedId ])
        let docs = Array(findResult)
        XCTAssertEqual(docs[0]["test"] as? Int, 42)
    }
}
