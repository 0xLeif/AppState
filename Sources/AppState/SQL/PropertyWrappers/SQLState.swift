//
//  SQLState.swift
//  AppState
//
//  Created by Jules on 2024-07-25.
//

import SwiftUI
import Combine
import GRDB

/// A property wrapper that subscribes to a database query for a single record
/// and updates a SwiftUI view when the record changes, is created, or is deleted.
///
/// `@SQLState` is designed for observing a single instance of an `SQLModel`.
///
/// ### Usage
///
/// 1. **Define the query for the single record, often using its ID, as an extension on `Application`**:
///
///    ```swift
///    import AppState
///    import GRDB
///
///    extension Application {
///        func user(id: Int64) -> SQLQuery<User?> { // Note: SQLQuery<User?> is used by SQLState
///            Application.sqlQuery(User.filter(key: id))
///        }
///    }
///    ```
///    Alternatively, you can define a specific helper for `SQLState` if needed, though
///    reusing `SQLQuery<Value?>` is often sufficient.
///
/// 2. **Use `@SQLState` in your SwiftUI view**:
///
///    ```swift
///    struct UserDetailView: View {
///        private var userId: Int64
///        @SQLState(Application.user(id: userId)) private var user // user will be User?
///
///        init(userId: Int64) {
///            self.userId = userId
///            // Initialize SQLState with the dynamic query.
///            // Note: This pattern requires SQLState to be initialized carefully if the ID changes.
///            // A common approach is to key the view itself on the ID, e.g., UserDetailView(userId: id).id(id)
///            // Or, ensure the query provided to SQLState is updated if `userId` can change
///            // while the view is alive (less common for detail views).
///
///            // For the @SQLState to use the `userId` from the struct's property,
///            // the query definition needs to be passed at initialization.
///            // One way to do this:
///            self._user = SQLState(request: User.filter(key: userId), initialValue: nil)
///            // Or if using the Application extension style:
///            // self._user = SQLState(Application.user(id: userId)) // Ensure this is how you want to capture `userId`
///        }
///
///        var body: some View {
///            if let user = user {
///                Text("Name: \(user.name)")
///                Text("Email: \(user.email)")
///            } else {
///                Text("User not found or loading...")
///            }
///        }
///    }
///    ```
///
/// ### How It Works
///
/// `@SQLState` leverages the same underlying mechanism as `@SQLQuery` (`QueryObserver` and
/// `ValueObservation`) but is typically configured to fetch a single optional record (`Value?`).
/// When the specific record identified by the query is inserted, updated, or deleted,
/// the `wrappedValue` (e.g., `User?`) is updated, triggering a view refresh.
///
@propertyWrapper
public struct SQLState<Value>: DynamicProperty { // Value is typically an Optional<SQLModel>, e.g., User?
    @ObservedObject private var observer: QueryObserver<Value>
    @AppDependency(\.sqlDatabaseManager) private var dbManager

    /// The current value of the observed record (often an optional).
    /// This property is updated automatically when the database changes.
    public var wrappedValue: Value {
        observer.value
    }

    /// Initializes the property wrapper with a key path to an `SQLQuery<Value>`
    /// that is expected to return a single optional record.
    ///
    /// - Parameter queryPath: A key path to an `SQLQuery<Value>` on `Application`
    ///                        (e.g., `SQLQuery<MyModel?>`).
    public init(_ queryPath: KeyPath<Application, SQLQuery<Value>>) {
        let queryInstance = Application.query(queryPath)
        self.observer = queryInstance.observer
    }

    /// Initializes the property wrapper with a direct `SQLRequest` for a single optional record.
    ///
    /// - Parameter request: An `SQLRequest<Value>` (e.g., `SQLRequest<MyModel?>`)
    ///                      that defines how to fetch the single record.
    /// - Parameter initialValue: The initial value to use before the first fetch completes.
    public init<Request: SQLRequestable>(request: Request, initialValue: Value) where Request.Value == Value {
         self.observer = QueryObserver(
            dbManager: Application.dependency(\.sqlDatabaseManager),
            request: request,
            initialValue: initialValue
        )
    }

    /// Internal initializer for Application.sqlState to pass a pre-configured observer
    internal init(observer: QueryObserver<Value>) {
        self.observer = observer
    }

    public func update() {
        // observer.updateDatabaseManagerIfNeeded(dbManager) // Handled by QueryObserver if needed
    }
}

// Extension on Application to provide helper for creating SQLState instances more directly
public extension Application {
    /// A helper function to create an `SQLState` instance for observing a single `SQLModel` record.
    ///
    /// This function configures an `SQLQuery` that fetches an optional record, suitable for use with `@SQLState`.
    ///
    /// - Parameters:
    ///   - grdbRequest: A GRDB `QueryInterfaceRequest` that is expected to return at most one record
    ///                  (e.g., `User.filter(key: someId)`).
    /// - Returns: An `SQLQuery<Record?>` instance, which can be used to initialize `@SQLState`.
    ///
    /// ### Example for `@SQLState`
    /// ```swift
    /// struct UserView: View {
    ///     @SQLState(Application.sqlState(User.filter(key: 1))) var user: User?
    ///
    ///     var body: some View {
    ///         // ...
    ///     }
    /// }
    /// ```
    static func sqlState<Record: FetchableRecord & SQLModel>(
        _ grdbRequest: QueryInterfaceRequest<Record>
    ) -> SQLQuery<Record?> { // Returns SQLQuery<Record?>, used by SQLState
        let request = SQLRequest(grdbRequest) // This SQLRequest init defaults to fetchOne for Record?
        let observer = QueryObserver(
            dbManager: Application.dependency(\.sqlDatabaseManager),
            request: request,
            initialValue: nil // Default to nil for an optional record
        )
        return SQLQuery<Record?>(observer: observer)
    }
    // The `sqlState(expected:)` function that previously had a fatalError has been removed.
    // Users should use `SQLState<Record?>` and handle optionality in their views,
    // or use `Application.sqlQuery(expected:)` if they need a non-optional SQLQuery<Record>
    // and handle potential errors from the request itself.
}

// Make SQLState itself usable with an SQLQuery<Value>
public extension SQLState {
    /// Initializes SQLState with an existing `SQLQuery` instance.
    /// This is particularly useful when the `SQLQuery` is constructed with specific parameters.
    ///
    /// - Parameter query: An `SQLQuery<Value>` instance, typically configured to fetch
    ///                    a single optional record (e.g., `SQLQuery<MyModel?>`).
    init(_ query: SQLQuery<Value>) {
        self.observer = query.observer
    }
}
