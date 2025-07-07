# AppState SQL Persistence Guide

Welcome to the guide for using SQL persistence features in AppState! This document will walk you through setting up your database, defining data models, performing migrations, querying data reactively in SwiftUI, and executing Create, Read, Update, Delete (CRUD) operations.

AppState's SQL layer is built on top of [GRDB.swift](https://github.com/groue/GRDB.swift), a powerful and flexible SQLite toolkit for Swift.

## Table of Contents

1.  [Setup and Configuration](#1-setup-and-configuration)
    *   [Adding Dependencies](#adding-dependencies)
    *   [Initializing the Database](#initializing-the-database)
2.  [Schema Migrations](#2-schema-migrations)
    *   [Defining Migrations](#defining-migrations)
    *   [Applying Migrations](#applying-migrations)
3.  [Defining Data Models](#3-defining-data-models)
    *   [Conforming to `SQLModel`](#conforming-to-sqlmodel)
    *   [Table Name and Coding Keys](#table-name-and-coding-keys)
4.  [Reading Data (Queries)](#4-reading-data-queries)
    *   [Observing Collections with `@SQLQuery`](#observing-collections-with-sqlquery)
    *   [Observing Single Records with `@SQLState`](#observing-single-records-with-sqlstate)
    *   [Defining Reusable Queries](#defining-reusable-queries)
    *   [Dynamic Filtering and Advanced Queries](#dynamic-filtering-and-advanced-queries)
5.  [Writing Data (CRUD Operations)](#5-writing-data-crud-operations)
    *   [Accessing the Database Queue](#accessing-the-database-queue)
    *   [Create, Update, Delete Examples](#create-update-delete-examples)
6.  [Advanced Topics](#6-advanced-topics)
    *   [Using In-Memory Databases (e.g., for Previews or Tests)](#using-in-memory-databases)
    *   [Error Handling](#error-handling)
    *   [Transactions](#transactions)
7.  [Full Example](#7-full-example)

---

## 1. Setup and Configuration

### Adding Dependencies

Ensure GRDB.swift is added to your `Package.swift` if it's not already managed by AppState's own dependencies. AppState includes GRDB, so you typically don't need to add it separately if you're using the AppState library.

### Initializing the Database

The core of the SQL system is the `SQLDatabaseManager`. You need to define how it's created, usually by specifying a path to your SQLite file and providing a `DatabaseMigrator`. This is done by overriding the `sqlDatabaseManager` dependency in an extension of `Application`.

**Example (`Application` extension):**

```swift
import AppState
import GRDB // You might need this for GRDB-specific types like `Column`

fileprivate extension Application {
    // First, define your migrator (see next section)
    var databaseMigrator: Dependency<DatabaseMigrator> {
        dependency {
            var migrator = DatabaseMigrator()
            // Register all your migrations here
            migrator.registerMigration("v1.0.0 - initialSchema") { db in
                // Example: Create 'user' table
                try db.create(table: "user") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("name", .text).notNull()
                    t.column("email", .text).notNull().unique()
                }
                // Add more table creations or alterations
            }
            // migrator.registerMigration("v1.0.1 - addAgeToUser") { ... }
            return migrator
        }
    }

    // Then, define the SQLDatabaseManager
    var sqlDatabaseManager: Dependency<SQLDatabaseManager> {
        dependency {
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true // Creates the directory if it doesn't exist
            )
            // It's good practice to put your database in a subdirectory
            let dbDirectoryURL = appSupportURL.appendingPathComponent("MyAppNameDB")
            try fileManager.createDirectory(at: dbDirectoryURL, withIntermediateDirectories: true, attributes: nil)

            let dbURL = dbDirectoryURL.appendingPathComponent("database.sqlite")
            AppLogger.info("Database path: \(dbURL.path)")

            let migrator = Application.dependency(\.databaseMigrator)

            return try SQLDatabaseManager(path: dbURL.path, migrator: migrator)
        }
    }
}
```

**Loading the Database on App Launch:**

To ensure migrations run before your UI attempts to access the database, preload the `sqlDatabaseManager` dependency in your app's `init()`.

```swift
import AppState
import SwiftUI

@main
struct MyApp: App {
    init() {
        // Preload the database manager on app launch.
        // This ensures migrations run before the UI is shown.
        Application.load(dependency: \.sqlDatabaseManager)
        AppLogger.info("SQLDatabaseManager loaded and migrations applied (if any).")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## 2. Schema Migrations

Migrations allow you to evolve your database schema over time in a structured way. Each migration is identified by a unique string and contains code to modify the schema.

### Defining Migrations

You register migrations using the `DatabaseMigrator` instance, which you typically define as an `Application` dependency.

```swift
// Inside your Application extension for `databaseMigrator`:
var migrator = DatabaseMigrator()

// Migration 1: Create the 'user' table
migrator.registerMigration("v1.0.0 - createUserTable") { db in
    try db.create(table: "user") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("name", .text).notNull()
        t.column("email", .text).notNull().unique()
        t.column("createdAt", .datetime).defaults(to: Date()) // Example default value
    }
}

// Migration 2: Add an 'age' column to the 'user' table
migrator.registerMigration("v1.0.1 - addUserAge") { db in
    try db.alter(table: "user") { t in
        t.add(column: "age", .integer)
    }
}

// Migration 3: Create an 'article' table
migrator.registerMigration("v1.1.0 - createArticleTable") { db in
    try db.create(table: "article") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("userId", .integer).notNull().indexed().references("user", onDelete: .cascade)
        t.column("title", .text).notNull()
        t.column("content", .text)
        t.column("publishedDate", .date)
    }
}
// return migrator
```

**Important Notes on Migrations:**
*   **Order Matters:** Migrations are applied in the order they are registered.
*   **Identifiers are Permanent:** The string identifier for each migration (e.g., `"v1.0.0 - createUserTable"`) is stored in the database. It should not be changed once a migration has been applied.
*   **Idempotency:** Migrations are run only once. If a migration has already been applied, it will be skipped.
*   Use descriptive identifiers for your migrations.

### Applying Migrations

Migrations are automatically applied by the `SQLDatabaseManager` during its initialization. By preloading the manager as shown in the setup, you ensure this happens at app launch.

---

## 3. Defining Data Models

Your data models are Swift structs or classes that conform to the `SQLModel` protocol. This protocol combines several GRDB protocols (`Codable`, `FetchableRecord`, `PersistableRecord`, `Identifiable`) to make your types database-friendly.

### Conforming to `SQLModel`

```swift
import AppState // Or import GRDB if you only need SQLModel's components
import GRDB // For Column, etc.

public struct User: SQLModel {
    // `Identifiable` conformance (GRDB uses `id` for primary key by default if Int64)
    public var id: Int64? // Optional for new records before they are saved

    // Properties of your model
    public var name: String
    public var email: String
    public var age: Int?
    public var createdAt: Date?

    // `SQLModel` conformance: Define the database table name
    public static let databaseTableName = "user"

    // Optional: Define CodingKeys if your property names don't match column names
    // or if you want to exclude properties from database persistence.
    // By default, all properties are mapped.
    enum CodingKeys: String, CodingKey, ColumnExpression {
        case id
        case name
        case email
        case age
        case createdAt // Ensure this matches the column name in your migration
    }

    // Initializer
    public init(id: Int64? = nil, name: String, email: String, age: Int? = nil, createdAt: Date? = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.age = age
        self.createdAt = createdAt
    }
}

public struct Article: SQLModel {
    public var id: Int64?
    public var userId: Int64
    public var title: String
    public var content: String?
    public var publishedDate: Date?

    public static let databaseTableName = "article"

    // Example of a relationship (not directly part of SQLModel, but common with GRDB)
    // This would require custom fetching logic or using GRDB's associations.
    // For AppState's property wrappers, you typically fetch related models separately if needed.
}
```

### Table Name and Coding Keys
*   `static var databaseTableName`: This must match the table name used in your migrations.
*   `CodingKeys`: If your Swift property names differ from your database column names, or if you want to customize which properties are persisted, define an `enum CodingKeys: String, CodingKey`. For GRDB, also conforming `CodingKeys` to `ColumnExpression` can be handy for type-safe query building (e.g., `User.Columns.name`).

---

## 4. Reading Data (Queries)

AppState provides two property wrappers for declaratively reading data from the database and keeping your SwiftUI views updated: `@SQLQuery` for collections and `@SQLState` for single records.

### Defining Reusable Queries

It's highly recommended to define your database queries as computed properties or methods on an `Application` extension. This promotes reusability and centralizes your data access logic.

```swift
import AppState
import GRDB // For GRDB requests like User.all(), Column("name"), etc.

extension Application {
    // Query for all users, sorted by name
    var allUsersSortedByName: SQLQuery<[User]> {
        Application.sqlQuery(User.order(User.Columns.name))
    }

    // Query for a specific user by ID (returns an optional User)
    static func user(id: Int64) -> SQLQuery<User?> {
        Application.sqlQuery(User.filter(key: id))
    }

    // Query for articles by a specific user, sorted by published date
    static func articles(forUser userId: Int64) -> SQLQuery<[Article]> {
        Application.sqlQuery(
            Article.filter(Column("userId") == userId)
                   .order(Column("publishedDate").desc)
        )
    }

    // Example of a query for a count
    var totalUserCount: SQLQuery<Int> {
        // Uses the new helper for GRDB.SQLRequest<Value>
        Application.sqlQuery(User.all().fetchCount(), defaultValue: 0)
    }

    // Example for an optional primitive value, e.g., max age
    var maxUserAge: SQLQuery<Int?> {
        Application.sqlQuery(User.select(max(Column("age"))).asRequest(of: Int.self))
        // Or if you have a direct GRDB.SQLRequest<Int>:
        // Application.sqlQuery(GRDB.SQLRequest<Int>(sql: "SELECT MAX(age) FROM user"))
    }
}
```

### Observing Collections with `@SQLQuery`

Use `@SQLQuery` in your SwiftUI views to observe an array of records. The view will automatically update when the underlying data changes.

```swift
import SwiftUI
import AppState

struct UserListView: View {
    // Using a query defined on Application
    @SQLQuery(\.allUsersSortedByName) private var users // users is [User]

    // Example for a query that takes parameters
    // @State private var selectedUserId: Int64 = 1
    // @SQLQuery(Application.articles(forUser: selectedUserId)) private var userArticles
    // Note: If selectedUserId changes, the view needs to be re-evaluated for the query to update.
    // Often, you'd make the view take selectedUserId as an init param and key the view.

    var body: some View {
        List(users) { user in // User must be Identifiable
            VStack(alignment: .leading) {
                Text(user.name).font(.headline)
                Text(user.email).font(.subheadline)
            }
        }
        .navigationTitle("All Users")
    }
}
```

### Observing Single Records with `@SQLState`

Use `@SQLState` to observe a single record, typically an optional (e.g., `User?`). The view updates if the record is created, modified, or deleted.

```swift
import SwiftUI
import AppState

struct UserDetailView: View {
    let userId: Int64

    // Use the static factory method on Application that returns SQLQuery<User?>
    // and pass its result to SQLState.
    @SQLState(Application.user(id: userId)) private var user // user is User?

    init(userId: Int64) {
        self.userId = userId
        // The @SQLState property wrapper will use the `userId` from the init parameter
        // when it initializes the query.
    }

    var body: some View {
        if let user = user {
            VStack {
                Text("Name: \(user.name)").font(.title)
                Text("Email: \(user.email)")
                Text("Age: \(user.age != nil ? String(user.age!) : "N/A")")
                Text("Member since: \(user.createdAt?.formatted() ?? "N/A")")
            }
            .navigationTitle(user.name)
        } else {
            Text("Loading user or user not found...")
                .navigationTitle("User Details")
        }
    }
}
```

### Dynamic Filtering and Advanced Queries

For complex scenarios, like search queries that depend on live user input, the `@SQLQuery` or `@SQLState` wrappers might re-initialize too often if their input parameters change rapidly. In such cases, consider these patterns:

1.  **Dedicated `ObservableObject` Service:** Create a service that holds the search criteria and publishes the results. This service can manage its own `ValueObservation` from GRDB more finely.

    ```swift
    @MainActor
    class UserSearchService: ObservableObject {
        @AppDependency(\.sqlDatabaseManager) private var dbManager
        @Published var searchText: String = "" {
            didSet { if oldValue != searchText { observeSearchResults() } }
        }
        @Published var searchResults: [User] = []

        private var observationCancellable: AnyCancellable?

        init() {
            observeSearchResults() // Initial observation
        }

        private func observeSearchResults() {
            observationCancellable?.cancel() // Cancel previous observation

            let pattern = "%\(searchText)%"
            let request = User.filter(Column("name").like(pattern) || Column("email").like(pattern))
                              .order(Column("name"))

            let observation = ValueObservation.tracking { db in
                try request.fetchAll(db)
            }

            observationCancellable = observation
                .publisher(in: dbManager.dbQueue)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            AppLogger.error("UserSearchService observation error: \(error)")
                        }
                    },
                    receiveValue: { [weak self] users in
                        self?.searchResults = users
                    }
                )
        }
    }

    // In your SwiftUI View:
    // @StateObject private var searchService = UserSearchService()
    // ...
    // TextField("Search users", text: $searchService.searchText)
    // List(searchService.searchResults) { ... }
    ```

2.  **Using `@SQLQuery` with Debouncing (via `initialValue` and task modifiers):**
    If you construct `@SQLQuery` with `init(request:initialValue:)`, you can update the `request` parameter less frequently, for example, by using `.task(id: debouncedSearchText)` in SwiftUI to trigger a query update. This is a more advanced pattern.

---

## 5. Writing Data (CRUD Operations)

Create, Read (covered above), Update, and Delete operations are performed by interacting directly with the `SQLDatabaseManager`'s `dbQueue`. This queue provides access to GRDB's database connection.

### Accessing the Database Queue

Inject `SQLDatabaseManager` into your services or views where you need to perform write operations:

```swift
import AppState

class MyDataService {
    @AppDependency(\.sqlDatabaseManager) private var dbManager: SQLDatabaseManager

    // ... methods to perform CUD operations ...
}

// Or directly in a SwiftUI view (less common for complex logic, better in a service/viewmodel)
struct MyView: View {
    @AppDependency(\.sqlDatabaseManager) private var dbManager: SQLDatabaseManager
    // ...
}
```

### Create, Update, Delete Examples

GRDB's `PersistableRecord` protocol (which `SQLModel` conforms to) provides methods like `save()`, `insert()`, `update()`, and `delete()`.

```swift
// In a function within your service or view
@AppDependency(\.sqlDatabaseManager) var dbManager // Can be local if needed

// CREATE a new user
func addUser(name: String, email: String) async {
    var newUser = User(name: name, email: email) // id is nil initially
    do {
        try await dbManager.dbQueue.write { db in
            try newUser.save(db) // save() inserts if id is nil, then sets the id
        }
        AppLogger.info("Added user: \(newUser.name) with ID \(newUser.id!)")
    } catch {
        AppLogger.error("Failed to add user: \(error)")
    }
}

// UPDATE an existing user
func updateUserEmail(userId: Int64, newEmail: String) async {
    do {
        try await dbManager.dbQueue.write { db in
            if var user = try User.fetchOne(db, key: userId) {
                user.email = newEmail
                try user.update(db) // Explicitly update
                // OR: try user.save(db) // save() also updates if id is not nil
                AppLogger.info("Updated user ID \(userId) email to \(newEmail)")
            } else {
                AppLogger.warning("User ID \(userId) not found for update.")
            }
        }
    } catch {
        AppLogger.error("Failed to update user: \(error)")
    }
}

// DELETE a user
func deleteUser(userId: Int64) async {
    do {
        let success = try await dbManager.dbQueue.write { db in
            try User.deleteOne(db, key: userId)
        }
        if success {
            AppLogger.info("Deleted user ID \(userId)")
        } else {
            AppLogger.warning("User ID \(userId) not found for deletion, or delete failed.")
        }
    } catch {
        AppLogger.error("Failed to delete user: \(error)")
    }
}

// BATCH Operations (example: delete multiple users)
func deleteUsers(ids: [Int64]) async {
    do {
        try await dbManager.dbQueue.write { db in
            _ = try User.deleteAll(db, keys: ids)
            AppLogger.info("Attempted to delete users with IDs: \(ids)")
        }
    } catch {
        AppLogger.error("Failed to delete multiple users: \(error)")
    }
}
```

**Key GRDB `PersistableRecord` methods:**
*   `save(db)`: Inserts or updates the record. Sets the `id` property on insert if it's an auto-incremented primary key.
*   `insert(db)`: Inserts the record. Throws an error if it already exists (based on primary key).
*   `update(db)`: Updates the record. Throws an error if it doesn't exist.
*   `delete(db)`: Deletes the record.
*   Static methods like `User.deleteOne(db, key:)`, `User.deleteAll(db, keys:)` are also available.

---

## 6. Advanced Topics

### Using In-Memory Databases

For SwiftUI Previews or unit testing, you might want to use an in-memory database. Configure `SQLDatabaseManager` like this:

```swift
// For SwiftUI Previews or specific test setups
extension Application {
    static var inMemorySqlDatabaseManager: Dependency<SQLDatabaseManager> {
        dependency {
            // Ensure you have a migrator, even if it's simple for previews
            var migrator = DatabaseMigrator()
            migrator.registerMigration("v1-previewSchema") { db in /* ... define schema ... */ }

            // Use a unique identifier if you might have multiple in-memory DBs
            return try! SQLDatabaseManager(inMemoryIdentifier: "previewDB-\(UUID().uuidString)", migrator: migrator)
        }
    }
}

// In your PreviewProvider:
// struct MyView_Previews: PreviewProvider {
//     static var previews: some View {
//         MyView()
//             .appDependency(\.sqlDatabaseManager, Application.dependency(\.inMemorySqlDatabaseManager))
//     }
// }
```
The default `SQLDatabaseManager` if not overridden by the user is an in-memory database named "defaultAppStateDB".

### Error Handling

Database operations can throw errors (e.g., connection issues, constraint violations, migration failures).
*   **Initialization/Migration Errors:** Errors during `SQLDatabaseManager` init (often migration failures) will be thrown. Your app should handle this, perhaps by displaying an error to the user or logging critical failure.
*   **CRUD Errors:** Read/write operations performed inside `dbQueue.read/write` closures can throw. Use `do-catch` blocks to handle these errors appropriately.
*   **`@SQLQuery`/`@SQLState` Errors:** The underlying `ValueObservation` can also encounter errors. These are logged by `AppLogger`. For more robust UI feedback, you might need to customize the `QueryObserver` or use Combine's error handling operators on its publisher.

### Transactions

For operations that require multiple database changes to succeed or fail as a single unit, use transactions:

```swift
func transferFunds(fromUser: User, toUser: User, amount: Double) async throws {
    try await dbManager.dbQueue.inTransaction { db in
        // 1. Decrement balance for fromUser
        // 2. Increment balance for toUser
        // If any step fails, the transaction is rolled back.
        // Example (assuming User has a 'balance' property):
        // var sender = fromUser
        // var receiver = toUser
        // sender.balance -= amount
        // receiver.balance += amount
        // try sender.update(db)
        // try receiver.update(db)
        return .commit // Or .rollback if a condition isn't met
    }
}
```

---

## 7. Full Example (Conceptual)

This section would tie everything together with a small, runnable example app structure, including:
*   App struct with `SQLDatabaseManager` preloading.
*   `Application` extension for `databaseMigrator` and `sqlDatabaseManager`.
*   `User` model definition.
*   `UserListView` using `@SQLQuery`.
*   `UserDetailView` using `@SQLState`.
*   Example functions for adding/deleting users.

*(This full example is omitted for brevity here but is a good goal for sample code accompanying the library.)*

---

This guide provides a comprehensive overview of AppState's SQL persistence features. For more detailed information on specific GRDB functionalities (like advanced query building, associations, custom SQL, etc.), please refer to the official [GRDB.swift documentation](https://github.com/groue/GRDB.swift/blob/master/README.md).
```
