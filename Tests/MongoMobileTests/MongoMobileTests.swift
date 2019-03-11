import MongoSwift
import XCTest

@testable import MongoMobile

final class MongoMobileTests: XCTestCase {
    static var allTests: [(String, (MongoMobileTests) -> () throws -> Void)] {
        return [
            ("testMongoMobileBasic", testMongoMobileBasic),
            ("testSequentialAccess", testSequentialAccess),
            ("testLogger", testLogger),
        ]
    }

    static var logger: TestLogger!

    // NOTE: These only works because we have one test suite. These method are called
    //       before/after all tests _per_ test suite. Will not work if another suite
    //       is added.
    override class func setUp() {
        super.setUp()
        self.logger = TestLogger()
        try? MongoMobile.initialize(options: MongoMobileOptions(logger: self.logger))
    }

    override class func tearDown() {
        super.tearDown()
        try? MongoMobile.close()
    }

    func createAndCleanTemporaryPath(at path: String) throws -> URL {
        let supportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let databasePath = supportPath.appendingPathComponent(path)

        try? FileManager.default.removeItem(at: databasePath)
        try? FileManager.default.createDirectory(at: databasePath, withIntermediateDirectories: false)
        return databasePath
    }

    func runBasicInsertFindTest(on client: MongoClient) throws {
        let coll = try client.db("test").collection("foo")
        let insertResult = try coll.insertOne([ "test": 42 ])
        // swiftlint:disable:next force_unwrapping - always returns a value if succeeded
        let findResult = try coll.find([ "_id": insertResult!.insertedId ])
        let docs = Array(findResult)
        XCTAssertEqual(docs[0]["test"] as? Int, 42)
    }

    func testMongoMobileBasic() throws {
        let databasePath = try createAndCleanTemporaryPath(at: "test-mongo-mobile")
        let settings = MongoClientSettings(dbPath: databasePath.path)
        let client = try MongoMobile.create(settings)
        try runBasicInsertFindTest(on: client)
    }

    func testSequentialAccess() throws {
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

    // Some basic validation that we are getting log messages correctly.
    func testLogger() throws {
        MongoMobileTests.logger.storeMessages = true
        defer { MongoMobileTests.logger.storeMessages = false }
        let dbPath = try createAndCleanTemporaryPath(at: "test-logging")
        let client = try MongoMobile.create(MongoClientSettings(dbPath: dbPath.path))
        try runBasicInsertFindTest(on: client)
        let messages = MongoMobileTests.logger.messages

        // There are likely more messages pertaining to setting FCV etc, but these are the
        // only messages that directly pertain to the ops we are performing: create embedded
        // instance, connect with a client, and create a collection on the DB.
        XCTAssert(messages.count >= 3, "should have collected at least 3 log messages")
        XCTAssert(messages.contains { $0.message.starts(with: "MongoDB starting") })
        XCTAssert(messages.contains { $0.message.starts(with: "received client metadata") })
        XCTAssert(messages.contains { $0.message.starts(with: "createCollection: test.foo") })
    }
}

struct LogMessage {
    let message: String
    let component: String
    let context: String
    let severity: LogSeverity
}

class TestLogger: MongoMobileLogger {
    var messages = [LogMessage]()
    var storeMessages = false

    func onMessage(message: @autoclosure () -> String,
                   component: @autoclosure () -> String,
                   context: @autoclosure () -> String,
                   severity: LogSeverity) {
        print("[\(component())] \(message())")
        if self.storeMessages {
            self.messages.append(
                LogMessage(message: message(), component: component(), context: context(), severity: severity))
        }
    }
}
