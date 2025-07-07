//
//  SQLDatabaseManagerTests.swift
//  AppStateTests
//
//  Created by Jules on 2024-07-25.
//

import XCTest
@testable import AppState
import GRDB

// Sample SQLModel for testing
struct TestUser: SQLModel, Equatable {
    var id: Int64?
    var name: String
    var email: String? // Making email optional for testing various scenarios

    static let databaseTableName = "testUser"

    // To conform to Equatable for easy comparison in tests
    static func == (lhs: TestUser, rhs: TestUser) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.email == rhs.email
    }
}

class SQLDatabaseManagerTests: XCTestCase {

    var dbManager: SQLDatabaseManager!
    var migrator: DatabaseMigrator!

    @MainActor override func setUpWithError() throws {
        try super.setUpWithError()
        Application.resetAllDependencies() // Reset dependencies for each test

        // Configure a migrator for tests
        migrator = DatabaseMigrator()
        migrator.registerMigration("v1-createUserTable") { db in
            try db.create(table: TestUser.databaseTableName) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("email", .text) // Optional email
            }
        }
        migrator.registerMigration("v2-addTimestamp") { db in
            try db.alter(table: TestUser.databaseTableName) { t in
                t.add(column: "createdAt", .datetime)
            }
        }

        // Override Application dependencies for testing
        Application.override(dependency: \.databaseMigrator, value: migrator)

        // Use an in-memory database for tests
        dbManager = try SQLDatabaseManager(inMemoryIdentifier: UUID().uuidString, migrator: migrator) // Unique ID for isolation
        Application.override(dependency: \.sqlDatabaseManager, value: dbManager)
    }

    override func tearDownWithError() throws {
        dbManager = nil
        migrator = nil
        Application.resetAllDependencies()
        try super.tearDownWithError()
    }

    @MainActor func testMigrationsAreApplied() throws {
        // Check if table exists
        try dbManager.dbQueue.read { db in
            XCTAssertTrue(try db.tableExists(TestUser.databaseTableName), "TestUser table should exist after migration.")

            // Check if columns from all migrations exist
            let columns = try db.columns(in: TestUser.databaseTableName)
            XCTAssertTrue(columns.contains { $0.name == "id" }, "Column 'id' should exist.")
            XCTAssertTrue(columns.contains { $0.name == "name" }, "Column 'name' should exist.")
            XCTAssertTrue(columns.contains { $0.name == "email" }, "Column 'email' should exist.")
            XCTAssertTrue(columns.contains { $0.name == "createdAt" }, "Column 'createdAt' from v2 migration should exist.")
        }
    }

    @MainActor func testCRUDOperations() async throws {
        // 1. Create
        var alice = TestUser(name: "Alice", email: "alice@example.com")
        try await dbManager.dbQueue.write { db in
            try alice.save(db)
        }
        XCTAssertNotNil(alice.id, "Alice's ID should be set after saving.")
        let aliceId = try XCTUnwrap(alice.id)

        // 2. Read
        var fetchedAlice: TestUser? = nil
        try await dbManager.dbQueue.read { db in
            fetchedAlice = try TestUser.fetchOne(db, key: aliceId)
        }
        XCTAssertEqual(fetchedAlice, alice, "Fetched Alice should match original Alice.")

        // 3. Update
        var updatedAlice = alice
        updatedAlice.name = "Alice Wonderland"
        updatedAlice.email = "alice.wonderland@example.com"
        try await dbManager.dbQueue.write { db in
            try updatedAlice.save(db) // save() handles insert or update
        }

        var fetchedUpdatedAlice: TestUser? = nil
        try await dbManager.dbQueue.read { db in
            fetchedUpdatedAlice = try TestUser.fetchOne(db, key: aliceId)
        }
        XCTAssertEqual(fetchedUpdatedAlice?.name, "Alice Wonderland", "Alice's name should be updated.")
        XCTAssertEqual(fetchedUpdatedAlice?.email, "alice.wonderland@example.com", "Alice's email should be updated.")
        XCTAssertEqual(fetchedUpdatedAlice, updatedAlice, "Fetched updated Alice should match the updated Alice.")


        // 4. Delete
        var deleted: Bool = false
        try await dbManager.dbQueue.write { db in
            deleted = try TestUser.deleteOne(db, key: aliceId)
        }
        XCTAssertTrue(deleted, "Alice should be deleted successfully.")

        var fetchedAfterDelete: TestUser? = nil
        try await dbManager.dbQueue.read { db in
            fetchedAfterDelete = try TestUser.fetchOne(db, key: aliceId)
        }
        XCTAssertNil(fetchedAfterDelete, "Alice should not be found after deletion.")

        // Test inserting multiple records
        let bob = TestUser(name: "Bob")
        let charlie = TestUser(name: "Charlie", email: "charlie@example.com")

        try await dbManager.dbQueue.write { db in
            try bob.insert(db) // Using insert explicitly
            try charlie.insert(db)
        }

        var allUsers: [TestUser] = []
        try await dbManager.dbQueue.read { db in
            allUsers = try TestUser.fetchAll(db)
        }
        XCTAssertEqual(allUsers.count, 2, "Should be 2 users (Bob and Charlie) after Alice was deleted.")
    }

    @MainActor func testDatabaseManagerIsDependency() throws {
        // Ensure the dbManager set up in setUpWithError is the one resolved by Application
        let resolvedManager = Application.dependency(\.sqlDatabaseManager)
        XCTAssertTrue(resolvedManager === dbManager, "The resolved SQLDatabaseManager should be the same instance used in tests.")
    }
}
