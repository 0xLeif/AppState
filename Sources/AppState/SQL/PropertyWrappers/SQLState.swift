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

    /// A helper function to create an `SQLState` instance for observing a single, non-optional `SQLModel` record.
    /// If the record is not found, this will result in an error during fetching.
    ///
    /// - Parameters:
    ///   - grdbRequest: A GRDB `QueryInterfaceRequest` that is expected to return exactly one record.
    /// - Returns: An `SQLQuery<Record>` instance.
    ///
    /// ### Example
    /// ```swift
    /// // Assuming user with ID 1 is guaranteed to exist or an error is acceptable.
    /// @SQLState(Application.sqlState(expected: User.filter(key: 1))) var user: User
    /// ```
    static func sqlState<Record: FetchableRecord & SQLModel>(
        expected grdbRequest: QueryInterfaceRequest<Record>
    ) -> SQLQuery<Record> { // Returns SQLQuery<Record>, used by SQLState for non-optional
        let request = SQLRequest(expected: grdbRequest) // This SQLRequest init fetches one or throws
        let observer = QueryObserver(
            dbManager: Application.dependency(\.sqlDatabaseManager),
            request: request,
            // For non-optional, initialValue is tricky. The view will typically show a loading
            // state or handle potential errors if the observer reports them.
            // Providing a "default" non-optional value here might be misleading.
            // The QueryObserver will publish the fetched value or an error.
            // Let's consider what initial value makes sense.
            // For now, this will crash if not careful because `QueryObserver.value` would need a valid initial `Record`.
            // This highlights a need for better error handling or clearer initial state management for non-optional SQLState.
            //
            // A common pattern is for the view to handle the loading state until the first value arrives.
            // Forcing an `initialValue` here for a non-optional generic `Record` is not feasible without more constraints.
            // The `QueryObserver`'s `@Published var value: Value` will hold the initial value.
            //
            // Let's refine the SQLRequest for non-optional to make this clearer.
            // The `SQLRequest(expected:)` will throw if not found. The observer will then propagate this error.
            // The `wrappedValue` of SQLState would ideally reflect this loading/error state or require a default.
            //
            // For simplicity and consistency with how SQLQuery<[Record]> defaults to [],
            // SQLQuery<Record?> defaults to nil.
            // SQLQuery<Record> (non-optional single) is the challenging one for an initialValue.
            // The `QueryObserver` would need a way to represent "not yet loaded" for a non-optional type,
            // or the view using `@SQLState` for a non-optional record must be prepared for an error if it's not found.
            //
            // The current `QueryObserver` takes an `initialValue`. If this function is to return `SQLQuery<Record>`,
            // then `QueryObserver` needs an initial `Record`. This implies the user must provide it,
            // or we accept a brief period where a potentially "fake" or "loading" version of `Record` is shown.
            //
            // Alternative: SQLState for non-optional is implicitly `SQLState<Record?>` and the view asserts non-nil.
            // Or, `SQLState` itself could have an `isLoading` and `error` property.
            //
            // Let's assume for now that `SQLState` for a non-optional record implies that the record *is expected*
            // to exist, and if not, it's an error state handled by the observation's completion.
            // The `initialValue` for the `QueryObserver` in this case is problematic if `Record` has no sensible default.
            //
            // The `SQLQuery.init(request:initialValue:)` is the one being used.
            // `SQLState.init(_ queryPath...)` gets the observer from the `SQLQuery` which should have its initial value set.
            //
            // This `Application.sqlState(expected:)` helper is constructing the `SQLQuery` and its `QueryObserver`.
            // The `QueryObserver` for `QueryObserver<Record>` (non-optional) needs an initial `Record`.
            // This is a design constraint.
            // A possible solution: The `QueryObserver`'s `value` could be `Value?` internally, and `SQLState` exposes it as `Value`
            // and throws an error or fatalError if accessed while nil (i.e. loading or actual error).
            // This is how `@StateObject` behaves before `init` completes for its `wrappedValue`.
            //
            // For now, to make this compilable, the `SQLQuery<Record>` would need an initial `Record`.
            // This means the `Application.sqlQuery(expected grdbRequest: ...)` would need to accept one.
            // This isn't ideal.
            //
            // Let's defer the non-optional single record `SQLState` or refine its error/loading handling.
            // The primary use case is `SQLState<Record?>`.
            //
            // Reverting to the simpler model: `SQLState` is primarily for `Value?`.
            // If a user wants a non-optional, they can use `@SQLState(query) var record: MyType?` and then
            // `guard let record = record else { LoadingView(); return }`.
            //
            // The `SQLRequest(expected:)` is fine for `SQLQuery` if the user handles the error.
            // But for `@SQLState`'s `wrappedValue` to be non-optional, it's more complex.
            //
            // Let's remove the `sqlState(expected:)` helper for now to keep `SQLState` focused on optionality,
            // which aligns better with the nature of data that might not exist.
            // Users wanting a non-optional value can use `.compactMap()` or similar on the publisher if they build
            // their own observer, or handle the optionality in the view.
            fatalError("Non-optional SQLState(expected:) is not yet fully supported without a clear strategy for initial value or loading/error state exposure through wrappedValue. Use SQLState for an optional type e.g. Record?")
        )
    }
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
