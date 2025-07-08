//
//  SQLQuery.swift
//  AppState
//
//  Created by Jules on 2024-07-25.
//

import SwiftUI
import Combine
import GRDB

/// A property wrapper that subscribes to a database query and updates a SwiftUI view
/// when the query's results change.
///
/// `@SQLQuery` is designed to be used in SwiftUI views to declaratively fetch and display
/// collections of data from an SQLite database managed by `SQLDatabaseManager`.
///
/// ### Usage
///
/// 1. **Define the query as an extension on `Application`**:
///    This makes the query reusable and easily accessible.
///
///    ```swift
///    import AppState
///    import GRDB
///
///    extension Application {
///        var allUsersSortedByName: SQLQuery<[User]> {
///            sqlQuery(User.order(Column("name")))
///        }
///
///        // For queries with arguments, you can create factory methods:
///        func users(olderThan age: Int) -> SQLQuery<[User]> {
///            sqlQuery(User.filter(Column("age") > age))
///        }
///    }
///    ```
///
/// 2. **Use `@SQLQuery` in your SwiftUI view**:
///
///    ```swift
///    struct UserListView: View {
///        @SQLQuery(\.allUsersSortedByName) private var users
///        // For dynamic queries based on view state:
///        // @State private var minAge = 30
///        // @SQLQuery(Application.users(olderThan: minAge)) private var users // Requires re-evaluation if minAge changes
///
///        var body: some View {
///            List(users) { user in // Assuming User is Identifiable
///                Text(user.name)
///            }
///        }
///    }
///    ```
///
/// ### How It Works
///
/// `@SQLQuery` uses GRDB's `ValueObservation` to monitor the database for changes that
/// affect the specified query. When a relevant change occurs (e.g., a record is inserted,
/// updated, or deleted), the query is re-evaluated, and the `wrappedValue` is updated,
/// triggering a view refresh.
///
/// - Note: The `Value` type parameter must be a collection of `SQLModel` conforming types
///   (e.g., `[User]`).
@propertyWrapper
public struct SQLQuery<Value>: DynamicProperty {
    @ObservedObject private var observer: QueryObserver<Value>
    @AppDependency(\.sqlDatabaseManager) private var dbManager

    /// The current value of the query results.
    /// This property is updated automatically when the database changes.
    public var wrappedValue: Value {
        observer.value
    }

    /// Initializes the property wrapper with a key path to a query defined on `Application`.
    ///
    /// - Parameter queryPath: A key path to an `SQLQuery<Value>` instance defined as a computed
    ///                        property on `Application`.
    public init(_ queryPath: KeyPath<Application, SQLQuery<Value>>) {
        let queryInstance = Application.query(queryPath)
        self.observer = queryInstance.observer
        // dbManager will be resolved by AppDependency
    }

    /// Initializes the property wrapper with a direct `SQLRequest`.
    /// This is useful for queries that might not be predefined on `Application` or depend on local state.
    ///
    /// - Parameter request: A `SQLRequest` that defines what data to fetch.
    /// - Parameter initialValue: The initial value to use before the first fetch completes.
    public init<Request: SQLRequestable>(request: Request, initialValue: Value) where Request.Value == Value {
        // This internal init is used by the `Application.sqlQuery` helper
        self.observer = QueryObserver(
            dbManager: Application.dependency(\.sqlDatabaseManager), // Resolve it immediately
            request: request,
            initialValue: initialValue
        )
    }

    // Internal initializer for Application.sqlQuery to pass a pre-configured observer
    internal init(observer: QueryObserver<Value>) {
        self.observer = observer
    }

    public func update() {
        // This function is part of DynamicProperty.
        // We need to ensure the observer has the correct dbManager if it wasn't set initially
        // or if the environment changes, though AppDependency should handle this.
        // observer.updateDatabaseManagerIfNeeded(dbManager)
    }
}

/// An internal `ObservableObject` that performs the actual database observation and fetching.
@MainActor
internal class QueryObserver<Value>: ObservableObject {
    @Published var value: Value
    private var observationCancellable: AnyCancellable?
    private var dbManager: SQLDatabaseManager
    private var request: any SQLRequestable

    init<Request: SQLRequestable>(dbManager: SQLDatabaseManager, request: Request, initialValue: Value) where Request.Value == Value {
        self.dbManager = dbManager
        self.request = request
        self.value = initialValue
        // Defer starting observation until dbManager is confirmed to be correct,
        // though AppDependency should handle this. For safety in test environments or complex setups,
        // one might consider a mechanism to restart observation if dbManager changes.
        // However, standard SwiftUI view lifecycle with @AppDependency should be fine.
        startObservation()
    }

    private func startObservation() {
        // The `init` constraint `Request.Value == Value` ensures that `self.request.fetch(_:)`
        // will return the same `Value` type that this QueryObserver is generic over.
        let observation = ValueObservation.tracking { [weak self] db in
            guard let self = self else {
                // This scenario (observer deallocated while observation is running)
                // might lead to unexpected behavior if not handled.
                // GRDB's ValueObservation might handle this gracefully by stopping.
                // However, explicitly returning or throwing might be clearer.
                // For now, assuming GRDB handles deallocation of observer.
                // A common pattern is to throw an error like `CancellationError`.
                throw CancellationError() // Or some other specific error
            }
            return try self.request.fetch(db)
        }

        observationCancellable = observation
            .publisher(in: dbManager.dbQueue)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    AppLogger.error("SQLQuery observation failed: \(error.localizedDescription)")
                    // TODO: Consider how to handle errors more robustly, e.g., expose an error state.
                }
            }, receiveValue: { [weak self] fetchedValue in
                self?.value = fetchedValue
            })
        AppLogger.info("SQLQuery: Observation started for \(String(describing: Value.self))")
    }

    // Call this if dbManager could change, e.g., in unit tests or complex scenarios.
    // For most SwiftUI usage, AppDependency should handle providing the correct manager.
    // func updateDatabaseManagerIfNeeded(_ newDbManager: SQLDatabaseManager) {
    //     if dbManager !== newDbManager {
    //         AppLogger.info("SQLQuery: DatabaseManager instance changed. Restarting observation.")
    //         dbManager = newDbManager
    //         observationCancellable?.cancel()
    //         startObservation()
    //     }
    // }

    deinit {
        AppLogger.info("SQLQuery: Deinitializing QueryObserver for \(String(describing: Value.self)). Cancelling observation.")
        observationCancellable?.cancel()
    }
}

/// A type that can be fetched from the database.
/// This protocol is used by `SQLQuery` to define how to fetch values.
public protocol SQLRequestable {
    associatedtype Value
    func fetch(_ db: GRDB.Database) throws -> Value
}

/// A concrete implementation of `SQLRequestable`.
///
/// It encapsulates a GRDB `Request` (like `QueryInterfaceRequest` or `SQLRequest`)
/// and a transform function to convert the fetched results.
public struct SQLRequest<Value>: SQLRequestable {
    private let _fetch: (GRDB.Database) throws -> Value

    /// Creates a `SQLRequest` from a GRDB `DatabaseRegionConvertible` request (e.g., a table query)
    /// and a transform function.
    ///
    /// - Parameters:
    ///   - request: A GRDB request (e.g., `User.all()`).
    ///   - transform: A closure that transforms the fetched `[Record]` into the desired `Value`.
    public init<Record: FetchableRecord & SQLModel>(
        _ request: QueryInterfaceRequest<Record>,
        transform: @escaping ([Record]) throws -> Value
    ) {
        self._fetch = { db in
            let records = try request.fetchAll(db)
            return try transform(records)
        }
    }

    /// Creates a `SQLRequest` specifically for fetching an array of `SQLModel` objects.
    public init<Record: FetchableRecord & SQLModel>(_ request: QueryInterfaceRequest<Record>) where Value == [Record] {
        self._fetch = { db in
            try request.fetchAll(db)
        }
    }

    /// Creates a `SQLRequest` for fetching an optional single `SQLModel` object.
    public init<Record: FetchableRecord & SQLModel>(_ request: QueryInterfaceRequest<Record>) where Value == Record? {
        self._fetch = { db in
            try request.fetchOne(db)
        }
    }

    /// Creates a `SQLRequest` for fetching a non-optional single `SQLModel` object.
    /// Throws an error if the record is not found.
    public init<Record: FetchableRecord & SQLModel>(expected: QueryInterfaceRequest<Record>) where Value == Record {
        self._fetch = { db in
            guard let record = try expected.fetchOne(db) else {
                throw RecordError.recordNotFound(databaseTableName: Record.databaseTableName, key: nil)
            }
            return record
        }
    }

    /// Creates a `SQLRequest` for fetching a single primitive value, like a count.
    /// It defaults to providing a non-optional `Value`, using a `defaultValue` if the database returns `nil`.
    ///
    /// - Parameters:
    ///   - grdbValueRequest: A `GRDB.SQLRequest` that fetches an optional value (e.g., `GRDB.SQLRequest<Int>`).
    ///   - defaultValue: The value to return if the database fetch results in `nil`.
    public init<T>(_ grdbValueRequest: GRDB.SQLRequest<T>, defaultValue: Value) where Value == T {
        self._fetch = { db in
            try grdbValueRequest.fetchOne(db) ?? defaultValue
        }
    }

    /// Creates a `SQLRequest` for fetching an optional single primitive value.
    ///
    /// - Parameters:
    ///   - grdbValueRequest: A `GRDB.SQLRequest` that fetches an optional value (e.g., `GRDB.SQLRequest<Int>`).
    public init<T>(_ grdbValueRequest: GRDB.SQLRequest<T>) where Value == T? {
        self._fetch = { db in
            try grdbValueRequest.fetchOne(db)
        }
    }

    public func fetch(_ db: GRDB.Database) throws -> Value {
        try _fetch(db)
    }
}

public enum RecordError: Error, LocalizedError {
    case recordNotFound(databaseTableName: String?, key: [String: (any DatabaseValueConvertible)?]?)

    public var errorDescription: String? {
        switch self {
        case .recordNotFound(let tableName, let key):
            var message = "Record not found"
            if let tableName { message += " in table '\(tableName)'" }
            if let key { message += " for key \(key)" }
            return message
        }
    }
}


// Extension on Application to provide helper for creating SQLQuery instances
public extension Application {
    /// A helper function to create an `SQLQuery` instance.
    ///
    /// This function is typically used within computed properties on an `Application` extension
    /// to define reusable queries.
    ///
    /// - Parameters:
    ///   - request: A GRDB `QueryInterfaceRequest` for fetching `SQLModel` conforming records.
    /// - Returns: An `SQLQuery` configured to fetch an array of `Record`s.
    ///
    /// ### Example
    /// ```swift
    /// extension Application {
    ///     var allUsers: SQLQuery<[User]> {
    ///         sqlQuery(User.all())
    ///     }
    /// }
    /// ```
    static func sqlQuery<Record: FetchableRecord & SQLModel>(
        _ grdbRequest: QueryInterfaceRequest<Record>
    ) -> SQLQuery<[Record]> {
        let request = SQLRequest(grdbRequest)
        let observer = QueryObserver(
            dbManager: Application.dependency(\.sqlDatabaseManager),
            request: request,
            initialValue: [] // Default to empty array, will be populated by observation
        )
        return SQLQuery<[Record]>(observer: observer)
    }

    /// A helper function to create an `SQLQuery` instance for an optional single record.
    ///
    /// - Parameters:
    ///   - request: A GRDB `QueryInterfaceRequest` for fetching a `SQLModel` conforming record.
    /// - Returns: An `SQLQuery` configured to fetch an optional `Record`.
    ///
    /// ### Example
    /// ```swift
    /// extension Application {
    ///     func user(id: Int64) -> SQLQuery<User?> {
    ///         Application.sqlQuery(User.filter(key: id))
    ///     }
    /// }
    /// ```
    static func sqlQuery<Record: FetchableRecord & SQLModel>(
        _ grdbRequest: QueryInterfaceRequest<Record>
    ) -> SQLQuery<Record?> {
        let request = SQLRequest(grdbRequest)
        let observer = QueryObserver(
            dbManager: Application.dependency(\.sqlDatabaseManager),
            request: request,
            initialValue: nil // Default to nil, will be populated
        )
        return SQLQuery<Record?>(observer: observer)
    }

    // Potentially add more overloads for different Value types if needed, e.g., for counts or other aggregates.

    /// Internal helper to access the SQLQuery instance itself from a KeyPath.
    /// Used by the `@SQLQuery` property wrapper.
    static func query<Value>(_ keyPath: KeyPath<Application, SQLQuery<Value>>) -> SQLQuery<Value> {
        // This creates a temporary Application instance just to access the query definition.
        // The actual `SQLDatabaseManager` used by the query will be the one resolved by
        // `@AppDependency` within the `SQLQuery` instance itself.
        return Application()[keyPath: keyPath]
    }
}
