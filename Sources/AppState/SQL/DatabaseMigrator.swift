//
//  DatabaseMigrator.swift
//  AppState
//
//  Created by Jules on 2024-07-25.
//

import Foundation
import GRDB

/// Manages database schema migrations.
///
/// `DatabaseMigrator` is responsible for registering and applying database migrations.
/// It uses GRDB's `DatabaseMigrator` to perform the actual migration tasks.
///
/// ### Example
///
/// ```swift
/// extension Application {
///     var databaseMigrator: Dependency<DatabaseMigrator> {
///         dependency {
///             var migrator = DatabaseMigrator()
///
///             // Register a migration to create the 'user' table
///             migrator.registerMigration("v1.0.0 - createUserTable") { db in
///                 try db.create(table: "user") { t in
///                     t.autoIncrementedPrimaryKey("id")
///                     t.column("name", .text).notNull()
///                     t.column("email", .text).notNull().unique()
///                 }
///             }
///
///             // Register another migration to add an 'age' column to 'user'
///             migrator.registerMigration("v1.0.1 - addUserAge") { db in
///                 try db.alter(table: "user") { t in
///                     t.add(column: "age", .integer)
///                 }
///             }
///
///             return migrator
///         }
///     }
/// }
/// ```
public struct DatabaseMigrator {
    private var grdbMigrator = GRDB.DatabaseMigrator()

    /// Creates a new `DatabaseMigrator`.
    public init() { }

    /// Registers a migration with a given identifier and a closure that defines the migration.
    ///
    /// - Parameters:
    ///   - identifier: A unique string identifying the migration (e.g., "v1.0.0-createUserTable").
    ///                 This identifier is permanently stored in the database.
    ///   - migrate: A closure that takes a `GRDB.Database` connection and performs the migration.
    ///
    /// - Important: Migrations are registered in the order they should be applied.
    ///              Once a migration is applied, it is never executed again.
    public mutating func registerMigration(
        _ identifier: String,
        migrate: @escaping (GRDB.Database) throws -> Void
    ) {
        grdbMigrator.registerMigration(identifier, migrate: migrate)
    }

    /// Applies all pending migrations to the database.
    ///
    /// - Parameter dbQueue: The `DatabaseQueue` to apply migrations to.
    /// - Throws: An error if any migration fails.
    internal func migrate(_ dbQueue: GRDB.DatabaseQueue) throws {
        try grdbMigrator.migrate(dbQueue)
    }
}
