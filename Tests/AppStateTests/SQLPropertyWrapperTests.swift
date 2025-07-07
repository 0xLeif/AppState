//
//  SQLPropertyWrapperTests.swift
//  AppStateTests
//
//  Created by Jules on 2024-07-25.
//

import XCTest
@testable import AppState
import GRDB
import Combine

// Using TestUser from SQLDatabaseManagerTests.swift, ensure it's accessible or redefine.
// For simplicity, assuming TestUser is available here. If not, it should be moved to a shared location or redefined.

@MainActor
class SQLPropertyWrapperTests: XCTestCase {

    var dbManager: SQLDatabaseManager!
    var cancellables: Set<AnyCancellable>!

    // Mock Application queries
    static func setupTestApplicationExtensions() {
        Application.resetAllDependencies() // Start clean

        // Must define these on the static type Application for KeyPath access
        // This is a bit tricky for tests if they need to be dynamic per test method.
        // For now, we define them once.
        // If different tests need different DB managers for these queries, it gets complex.
        // The @AppDependency within SQLQuery/State should pick up the overridden dbManager.

        Application.extensible(\.allTestUsers) {
            Application.sqlQuery(TestUser.order(Column("name")))
        }
        Application.extensible(\.testUserById) { (id: Int64) -> SQLQuery<TestUser?> in
            Application.sqlQuery(TestUser.filter(key: id))
        }
    }

    override class func setUp() {
        super.setUp()
        // This is called once before all tests in the class
        setupTestApplicationExtensions()
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        cancellables = []
        Application.resetAllDependencies() // Reset for each test method

        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1-createTestUser") { db in
            try db.create(table: TestUser.databaseTableName) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("email", .text)
            }
        }

        // Each test gets its own in-memory database and manager
        let currentDbManager = try SQLDatabaseManager(inMemoryIdentifier: UUID().uuidString, migrator: migrator)
        self.dbManager = currentDbManager

        Application.override(dependency: \.databaseMigrator, value: migrator) // Not strictly needed if dbManager is already migrated
        Application.override(dependency: \.sqlDatabaseManager, value: currentDbManager)
    }

    override func tearDownWithError() throws {
        dbManager = nil
        cancellables = nil
        Application.resetAllDependencies()
        try super.tearDownWithError()
    }

    // Test @SQLQuery
    func testSQLQueryReactivity() async throws {
        // The keypath based SQLQuery initialization
        let query = SQLQuery(\.allTestUsers)
        // To directly test the observer's published value
        let observer = query.observer as! QueryObserver<[TestUser]> // Force cast for test access

        let expectation = XCTestExpectation(description: "SQLQuery updates value")
        expectation.expectedFulfillmentCount = 3 // Initial empty, after add, after second add

        var receivedValues: [[TestUser]] = []

        observer.$value
            .sink { users in
                AppLogger.info("testSQLQueryReactivity received users: \(users.map(\.name))")
                receivedValues.append(users)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Wait for initial value (usually empty or from previous state if DB wasn't cleared, but here it's fresh)
        // The QueryObserver starts its observation upon init.
        // Fulfill #1 (initial value)

        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds to allow observation to publish initial value

        var user1 = TestUser(name: "Charlie")
        try await dbManager.dbQueue.write { db in try user1.save(db) }
        AppLogger.info("Added Charlie")
        // Fulfill #2 (after adding Charlie)

        try await Task.sleep(nanoseconds: 100_000_000) // Allow time for update

        var user2 = TestUser(name: "Alice") // Alice comes before Charlie due to ordering
        try await dbManager.dbQueue.write { db in try user2.save(db) }
        AppLogger.info("Added Alice")
        // Fulfill #3 (after adding Alice)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedValues.count, 3, "Should have received 3 updates.")

        XCTAssertTrue(receivedValues[0].isEmpty, "Initial value should be empty.")

        XCTAssertEqual(receivedValues[1].count, 1, "Should have 1 user after first add.")
        XCTAssertEqual(receivedValues[1].first?.name, "Charlie", "First user should be Charlie.")

        XCTAssertEqual(receivedValues[2].count, 2, "Should have 2 users after second add.")
        XCTAssertEqual(receivedValues[2].first?.name, "Alice", "Users should be sorted by name (Alice then Charlie).")
        XCTAssertEqual(receivedValues[2].last?.name, "Charlie")

        // Test wrappedValue
        XCTAssertEqual(query.wrappedValue.count, 2)
        XCTAssertEqual(query.wrappedValue.first?.name, "Alice")
    }

    // Test @SQLState
    func testSQLStateReactivity() async throws {
        var userToObserve = TestUser(name: "Bob", email: "bob@example.com")
        try await dbManager.dbQueue.write { db in try userToObserve.save(db) }
        let userId = try XCTUnwrap(userToObserve.id)

        // Initialize SQLState using the Application extension that returns SQLQuery<TestUser?>
        // This requires Application.testUserById to be defined.
        let stateWrapper = SQLState(Application.testUserById(id: userId))
        let observer = stateWrapper.observer as! QueryObserver<TestUser?>

        let expectation = XCTestExpectation(description: "SQLState updates value")
        expectation.expectedFulfillmentCount = 4 // Initial, update, delete, (re-add for fun)

        var receivedValues: [TestUser?] = []
        observer.$value
            .sink { user in
                AppLogger.info("testSQLStateReactivity received user: \(String(describing: user?.name))")
                receivedValues.append(user)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000) // Allow initial fetch
        // Fulfill #1 (initial Bob)

        userToObserve.name = "Robert"
        try await dbManager.dbQueue.write { db in try userToObserve.save(db) }
        AppLogger.info("Updated Bob to Robert")
        // Fulfill #2 (Robert)

        try await Task.sleep(nanoseconds: 100_000_000)

        try await dbManager.dbQueue.write { db in _ = try TestUser.deleteOne(db, key: userId) }
        AppLogger.info("Deleted Robert")
        // Fulfill #3 (nil)

        try await Task.sleep(nanoseconds: 100_000_000)

        var newUserSameIdSlot = TestUser(id: userId, name: "Bobby") // This won't reuse ID if autoincrement.
                                                                  // Let's insert a new user with a new ID, then change query.
                                                                  // No, let's re-insert a user with the same data, GRDB might give it a new ID.
                                                                  // The observation is on the ID. So if it's deleted, it's nil.
                                                                  // If a new item with the same ID appears (not typical with autoinc), it would show.

        // Let's re-add Bob (will get a new ID, original observation remains nil)
        var newBob = TestUser(name: "Bob reincarnated")
        try await dbManager.dbQueue.write { db in try newBob.save(db) }
        // This should not trigger the existing SQLState for `userId` unless we re-insert with the same `userId` (which is bad practice).
        // So, expectation count of 3 (initial, update, delete) is more realistic for a stable ID.

        // Let's adjust expectation for a more realistic scenario:
        // Initial fetch, update, delete.
        expectation.expectedFulfillmentCount = 3
        // Remove the 4th fulfill from sink if not testing re-creation with same ID.
        // For now, let's assume the sink fires 4 times but the 4th might be `nil` again or unchanged.
        // The test will pass if it fulfills at least 3 times.
        // Let's be precise:
        // 1. Initial fetch (Bob)
        // 2. Update (Robert)
        // 3. Delete (nil)
        // If we re-insert a user *with the same ID* (manually, not via save on a new instance):
        var manualUserSameId = TestUser(id: userId, name: "Bob Returns")
        try await dbManager.dbQueue.write { db in try manualUserSameId.insert(db, onConflict: .replace) } // replace to ensure it uses the ID
        AppLogger.info("Re-inserted Bob with same ID")
        // Fulfill #4 (Bob Returns)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(receivedValues.count, 4, "Should have received 4 updates for SQLState.")

        XCTAssertNotNil(receivedValues[0], "Initial value should be Bob.")
        XCTAssertEqual(receivedValues[0]??.name, "Bob")

        XCTAssertNotNil(receivedValues[1], "After update, value should be Robert.")
        XCTAssertEqual(receivedValues[1]??.name, "Robert")

        XCTAssertNil(receivedValues[2], "After delete, value should be nil.")

        XCTAssertNotNil(receivedValues[3], "After re-insert with same ID, value should be Bob Returns.")
        XCTAssertEqual(receivedValues[3]??.name, "Bob Returns")

        XCTAssertEqual(stateWrapper.wrappedValue?.name, "Bob Returns")
    }

    func testSQLStateWithDirectRequest() async throws {
        var userToObserve = TestUser(name: "DirectDave", email: "dave@example.com")
        try await dbManager.dbQueue.write { db in try userToObserve.save(db) }
        let userId = try XCTUnwrap(userToObserve.id)

        let request = SQLRequest(TestUser.filter(key: userId)) // Request for TestUser?
        let stateWrapper = SQLState(request: request, initialValue: nil) // Explicit initialValue

        let observer = stateWrapper.observer as! QueryObserver<TestUser?>

        let expectation = XCTestExpectation(description: "SQLState direct request updates value")
        expectation.expectedFulfillmentCount = 1 // Just initial fetch after setup

        var receivedValue: TestUser?? = .some(nil) // To check it's set

        observer.$value
            .sink { user in
                receivedValue = user
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)

        XCTAssertNotNil(receivedValue, "Should have received a value.")
        XCTAssertNotNil(receivedValue!, "The optional TestUser should not be nil.")
        XCTAssertEqual(receivedValue?!.name, "DirectDave")
        XCTAssertEqual(stateWrapper.wrappedValue?.name, "DirectDave")
    }
}

// Define Application extensions for test queries
// These need to be accessible by the KeyPaths used in SQLQuery/SQLState initializers.
fileprivate extension Application {
    var allTestUsers: SQLQuery<[TestUser]> {
        // This will be dynamically replaced or set up by `setupTestApplicationExtensions`
        // The actual implementation is Application.sqlQuery(...)
        // This definition here is just for satisfying the KeyPath.
        // The real one is registered via `Application.extensible`.
        // It's a bit of a dance for testing.
        fatalError("This should be overridden by test setup using Application.extensible")
    }

    // Need a way to make this work with parameters for KeyPath based init,
    // or use the direct request init for SQLState in tests more often.
    // The `SQLState(Application.user(id: userId))` pattern from docs is harder to test without global query state.
    // The `SQLState(request: ...)` is cleaner for tests.
    // The provided example for SQLState init in docs: `@SQLState(Application.user(id: userId))`
    // This means `Application.user(id:)` returns an `SQLQuery<User?>` instance.
    // Let's make the test helper match that.
    static func testUserById(id: Int64) -> SQLQuery<TestUser?> {
         // This will be dynamically replaced or set up by `setupTestApplicationExtensions`
        fatalError("This should be overridden by test setup using Application.extensible")
    }
}
