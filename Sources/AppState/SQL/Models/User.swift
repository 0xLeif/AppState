//
//  User.swift
//  AppState
//
//  Created by Jules on 2024-07-25.
//

import Foundation
import GRDB // Ensure GRDB is imported if SQLModel doesn't re-export its types

/// A sample user model conforming to `SQLModel`.
///
/// This struct demonstrates how to define a data model that can be persisted
/// using GRDB and AppState's SQL features.
///
/// ### Example Usage:
/// ```swift
/// // Creating a new user
/// let newUser = User(id: nil, name: "Alice", email: "alice@example.com")
///
/// // Saving the user to the database (assuming `dbManager` is an SQLDatabaseManager instance)
/// try await dbManager.dbQueue.write { db in
///     try newUser.save(db)
/// }
///
/// // Fetching a user
/// let fetchedUser: User? = try await dbManager.dbQueue.read { db in
///     try User.fetchOne(db, key: 1)
/// }
/// ```
public struct User: SQLModel {
    public var id: Int64?
    public var name: String
    public var email: String

    /// The name of the database table for this model.
    public static let databaseTableName = "user"

    /// Coding keys for encoding and decoding.
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
    }

    /// Initializes a new `User`.
    public init(id: Int64? = nil, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

// Note: The actual table creation for 'user' would happen in a migration:
//
// migrator.registerMigration("v1.0.0 - createUserTable") { db in
//     try db.create(table: User.databaseTableName) { t in
//         t.autoIncrementedPrimaryKey(User.CodingKeys.id.stringValue)
//         t.column(User.CodingKeys.name.stringValue, .text).notNull()
//         t.column(User.CodingKeys.email.stringValue, .text).notNull().unique()
//     }
// }
