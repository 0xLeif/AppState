//
//  Application+SQLExtensions.swift
//  AppState
//
//  Created by Jules on 2024-07-25.
//

import Foundation
import GRDB

// Content to be added in a later step
public extension Application {
    /// Provides access to the `DatabaseMigrator`.
    ///
    /// This dependency should be configured with all necessary database migrations for your application.
    ///
    /// ### Example:
    /// ```swift
    /// extension Application {
    ///     var databaseMigrator: Dependency<DatabaseMigrator> {
    ///         dependency {
    ///             var migrator = DatabaseMigrator()
    ///             // Register migrations...
    ///             // migrator.registerMigration("v1") { db in ... }
    ///             return migrator
    ///         }
    ///     }
    /// }
    /// ```
    var databaseMigrator: Dependency<DatabaseMigrator> {
        dependency {
            DatabaseMigrator() // Default empty migrator. User should override this.
        }
    }

    /// Provides access to the `SQLDatabaseManager`.
    ///
    /// This dependency manages the connection to your SQLite database and handles migrations.
    /// It typically relies on the `databaseMigrator` dependency.
    ///
    /// ### Example:
    /// ```swift
    /// extension Application {
    ///     var sqlDatabaseManager: Dependency<SQLDatabaseManager> {
    ///         dependency {
    ///             let dbURL = try FileManager.default
    ///                 .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    ///                 .appendingPathComponent("myapp.sqlite")
    ///             let migrator = Application.dependency(\.databaseMigrator)
    ///             return try SQLDatabaseManager(path: dbURL.path, migrator: migrator)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// To use an in-memory database (e.g., for previews or testing):
    /// ```swift
    /// extension Application {
    ///     var sqlDatabaseManager: Dependency<SQLDatabaseManager> {
    ///         dependency {
    ///             let migrator = Application.dependency(\.databaseMigrator)
    ///             // Using a unique identifier if multiple in-memory DBs might be used
    ///             return try SQLDatabaseManager(inMemoryIdentifier: "mainAppDB", migrator: migrator)
    ///         }
    ///     }
    /// }
    /// ```
    var sqlDatabaseManager: Dependency<SQLDatabaseManager> {
        dependency {
            let migrator = Application.dependency(\.databaseMigrator)
            // Default to an in-memory database for ease of use if not configured by the user.
            // Users are expected to override this for persistent storage.
            AppLogger.warning(
                """
                SQLDatabaseManager is using a default in-memory database.
                Override the `Application.sqlDatabaseManager` dependency for persistent storage.
                """
            )
            return try SQLDatabaseManager(inMemoryIdentifier: "defaultAppStateDB", migrator: migrator)
        }
    }

    /// A helper function to create an `SQLQuery` instance for a single primitive value, like a count.
    ///
    /// - Parameters:
    ///   - grdbValueRequest: A `GRDB.SQLRequest` that fetches an optional value (e.g., `GRDB.SQLRequest<Int>`).
    ///   - defaultValue: The value to use as the initial value and if the database returns `nil`.
    /// - Returns: An `SQLQuery` configured to fetch the value.
    ///
    /// ### Example
    /// ```swift
    /// extension Application {
    ///     var totalUserCount: SQLQuery<Int> {
    ///         Application.sqlQuery(User.all().fetchCount(), defaultValue: 0)
    ///     }
    /// }
    /// ```
    static func sqlQuery<T>(
        _ grdbValueRequest: GRDB.SQLRequest<T>,
        defaultValue: T
    ) -> SQLQuery<T> {
        let request = SQLRequest(grdbValueRequest, defaultValue: defaultValue)
        let observer = QueryObserver(
            dbManager: Application.dependency(\.sqlDatabaseManager),
            request: request,
            initialValue: defaultValue
        )
        return SQLQuery<T>(observer: observer)
    }

    /// A helper function to create an `SQLQuery` instance for an optional single primitive value.
    ///
    /// - Parameters:
    ///   - grdbValueRequest: A `GRDB.SQLRequest` that fetches an optional value (e.g., `GRDB.SQLRequest<Int>`).
    /// - Returns: An `SQLQuery` configured to fetch the optional value.
    ///
    /// ### Example
    /// ```swift
    /// extension Application {
    ///     var maybeSomeValue: SQLQuery<Int?> {
    ///         Application.sqlQuery(GRDB.SQLRequest<Int>(sql: "SELECT MAX(value) FROM items"))
    ///     }
    /// }
    /// ```
    static func sqlQuery<T>(
        _ grdbValueRequest: GRDB.SQLRequest<T>
    ) -> SQLQuery<T?> {
        let request = SQLRequest(grdbValueRequest) // This SQLRequest init is for Value == T?
        let observer = QueryObserver(
            dbManager: Application.dependency(\.sqlDatabaseManager),
            request: request,
            initialValue: nil // Default to nil for an optional value
        )
        return SQLQuery<T?>(observer: observer)
    }
}

// Protocol for SQL Models
public protocol SQLModel: Codable, FetchableRecord, PersistableRecord, Identifiable {
    static var databaseTableName: String { get }
}
