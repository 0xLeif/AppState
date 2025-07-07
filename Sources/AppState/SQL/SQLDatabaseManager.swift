//
//  SQLDatabaseManager.swift
//  AppState
//
//  Created by Jules on 2024-07-25.
//

import Foundation
import GRDB

/// Manages the SQLite database connection and operations.
///
/// `SQLDatabaseManager` is responsible for:
/// - Setting up the database connection using GRDB's `DatabaseQueue`.
/// - Applying schema migrations using a `DatabaseMigrator`.
/// - Providing access to the `DatabaseQueue` for database read and write operations.
///
/// ### Example: Defining the Dependency
///
/// ```swift
/// fileprivate extension Application {
///     var sqlDatabaseManager: Dependency<SQLDatabaseManager> {
///         dependency {
///             let fileManager = FileManager.default
///             let appSupportURL = try fileManager.url(
///                 for: .applicationSupportDirectory,
///                 in: .userDomainMask,
///                 appropriateFor: nil,
///                 create: true
///             )
///             let dbURL = appSupportURL.appendingPathComponent("myapp.sqlite")
///
///             // Assuming `databaseMigrator` is already defined
///             let migrator = Application.dependency(\.databaseMigrator)
///
///             return try SQLDatabaseManager(
///                 path: dbURL.path,
///                 migrator: migrator
///             )
///         }
///     }
/// }
/// ```
///
/// ### Example: Using the Manager for Writes
///
/// ```swift
/// struct MyService {
///     @AppDependency(\.sqlDatabaseManager) private var dbManager: SQLDatabaseManager
///
///     func addUser(name: String) async throws {
///         try await dbManager.dbQueue.write { db in
///             let user = User(id: nil, name: name, email: "\(name)@example.com")
///             try user.insert(db)
///         }
///     }
/// }
/// ```
public class SQLDatabaseManager {
    /// The GRDB `DatabaseQueue` for interacting with the database.
    /// Use this queue for all database reads and writes.
    public let dbQueue: DatabaseQueue

    /// Initializes a new `SQLDatabaseManager`.
    ///
    /// - Parameters:
    ///   - path: The file path to the SQLite database. If the database does not exist, it will be created.
    ///   - migrator: A `DatabaseMigrator` instance responsible for applying schema migrations.
    ///               Migrations are applied during initialization.
    /// - Throws: An error if the database connection cannot be established or if migrations fail.
    public init(path: String, migrator: DatabaseMigrator) throws {
        var config = Configuration()
        // config.busyMode = .timeout(5.0) // Example: Set a busy timeout
        // config.trace = { print($0) }    // Example: Trace SQL statements

        self.dbQueue = try DatabaseQueue(path: path, configuration: config)

        // Apply migrations
        try migrator.migrate(self.dbQueue)

        AppLogger.info("SQLDatabaseManager initialized at path: \(path)")
    }

    /// Initializes a new `SQLDatabaseManager` for an in-memory database.
    /// This is primarily useful for testing or for data that doesn't need to persist across app launches.
    ///
    /// - Parameters:
    ///   - migrator: A `DatabaseMigrator` instance responsible for applying schema migrations.
    ///               Migrations are applied during initialization.
    /// - Throws: An error if the database connection cannot be established or if migrations fail.
    public convenience init(inMemoryIdentifier: String? = nil, migrator: DatabaseMigrator) throws {
        let path = inMemoryIdentifier.map { ":memory:\($0)" } ?? ":memory:"
        try self.init(path: path, migrator: migrator)
        AppLogger.info("SQLDatabaseManager initialized for in-memory database.")
    }
}
