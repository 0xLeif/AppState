import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif

// MARK: Application Functions

public extension Application {
    /// Provides a description of the current application state
    @MainActor
    static var description: String {
       """
       {
       \(cacheDescription)
       }
       """
    }

    /**
     Promotes the shared singleton `Application` instance to a new instance of a custom `Application` subclass.
     This allows for custom behavior, such as overriding `didChangeExternally(notification:)`, while maintaining
     any existing state or dependencies already loaded in the previous shared instance.

     All values from the previous shared application's cache are transferred to the new custom instance.
     The global `Application.shared` is then replaced with this new custom instance.

     - Parameter customApplication: The `Application` subclass to promote to. This must be a class type inheriting from `Application`.
     - Returns: The `Application` subclass type that was promoted to, allowing for chained calls or type inference.

     This function is particularly useful when your `Application` subclass needs to override methods like
     `didChangeExternally(notification:)`. It allows you to extend the functionalities of the `Application`
     class and use your custom `Application` type throughout your application.

     Example:
     ```swift
     class CustomApplication: Application {
         override func didChangeExternally(notification: Notification) {
             super.didChangeExternally(notification: notification)

             // Update UI
             // ...

             // Example updating an ObservableObject that has SyncState inside of it.
             DispatchQueue.main.async {
                 Application.dependency(\.userSettings).objectWillChange.send()
             }

             // Example updating all SyncState in SwiftUI Views.
             DispatchQueue.main.async {
                 self.objectWillChange.send()
             }
         }
     }
     ```

     To use the `promote` function to promote the shared singleton to `CustomApplication`:

     ```swift
     Application.promote(to: CustomApplication.self)
     ```

     In this way, your custom Application subclass becomes the shared singleton instance, which you can then use throughout your application.
     */
    @MainActor
    @discardableResult
    static func promote<CustomApplication: Application>(
        to customApplication: CustomApplication.Type
    ) -> CustomApplication.Type {
        NotificationCenter.default.removeObserver(shared)

        let cache = shared.cache
        shared = customApplication.init()
        customApplication.shared = shared

        for (key, value) in cache.allValues {
            shared.cache.set(value: value, forKey: key)
            cache.remove(key)
        }

        return CustomApplication.self
    }

    /// Enables or disables the default logging mechanism within the `Application`.
    ///
    /// When enabled, `Application` will output debug messages for various operations such as state changes,
    /// dependency retrievals, and other significant events. This can be helpful for debugging application flow
    /// and understanding how state is managed.
    ///
    /// - Parameter isEnabled: A Boolean value indicating whether logging should be enabled (`true`) or disabled (`false`).
    /// - Returns: The `Application.Type`, allowing for chained calls.
    @MainActor
    @discardableResult
    static func logging(isEnabled: Bool) -> Application.Type {
        Application.isLoggingEnabled = isEnabled

        return Application.self
    }
}

// MARK: - Dependency Functions

public extension Application {
    /**
     Ensures that a specific `Dependency` is initialized.

     If the dependency is not already loaded (i.e., its value has not been created and cached yet),
     calling this function will trigger its initialization. If it's already loaded, this function has no effect
     beyond ensuring it's available. This is useful for pre-warming or ensuring critical dependencies are
     ready before they are explicitly accessed elsewhere.

     - Parameter keyPath: The `KeyPath` of the `Dependency` to be loaded (e.g., `\.myServiceDependency`).
     - Returns: The `Application.Type`, allowing for chained calls.
     */
    @MainActor
    @discardableResult
    static func load<Value>(
        dependency keyPath: KeyPath<Application, Dependency<Value>>
    ) -> Application.Type {
        shared.load(dependency: keyPath)

        return Application.self
    }

    /**
     Retrieves the value of a `Dependency` from the shared `Application` instance.

     This provides access to the actual dependency object (e.g., a service client, data manager)
     that was defined via an extension on `Application`. If the dependency has not been initialized yet,
     accessing it through this method will trigger its initialization.

     - Parameter keyPath: The `KeyPath` of the `Dependency` to be fetched (e.g., `\.myServiceDependency`).
     - Parameter fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
     - Parameter function: The name of the declaration in which this function is called. Defaults to `#function`.
     - Parameter line: The line number on which this function is called. Defaults to `#line`.
     - Parameter column: The column number in which this function is called. Defaults to `#column`.
     - Returns: The requested dependency value of type `Value`.
     */
    @MainActor
    static func dependency<Value>(
        _ keyPath: KeyPath<Application, Dependency<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Value {
        if keyPath != \.logger {
            log(
                debug: "🔗 Getting Dependency \(String(describing: keyPath))",
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        }

        return shared.value(keyPath: keyPath).value
    }

    /**
     Overrides a specified `Dependency` with a new value, typically a mock or test-specific implementation.
     This is primarily useful for SwiftUI Previews and Unit Testing, allowing parts of the application
     to function with controlled, predictable dependencies.

     The override remains active for the lifetime of the returned `DependencyOverride` token.
     When this token is deallocated (or its `cancel()` method is explicitly called),
     the original dependency value is restored.

     - Parameters:
        - keyPath: The `KeyPath` of the `Dependency` to be overridden (e.g., `\.myServiceDependency`).
        - value: The new value (e.g., a mock service instance) to replace the current dependency.
        - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
        - function: The name of the declaration in which this function is called. Defaults to `#function`.
        - line: The line number on which this function is called. Defaults to `#line`.
        - column: The column number in which this function is called. Defaults to `#column`.
     - Returns: A `DependencyOverride` object. This token must be retained for the duration the override
                  should be active. Its deallocation automatically cancels the override.
     */
    @MainActor
    static func `override`<Value>(
        _ keyPath: KeyPath<Application, Dependency<Value>>,
        with value: Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> DependencyOverride {
        let dependency = shared.value(keyPath: keyPath)

        log(
            debug: "🔗 Starting Dependency Override \(String(describing: keyPath)) with \(value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        shared.cache.set(
            value: Dependency(value, scope: dependency.scope),
            forKey: dependency.scope.key
        )

        let keyPath = String(describing: keyPath)

        return DependencyOverride {
            await log(
                debug: "🔗 Cancelling Dependency Override \(keyPath) ",
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )

            await MainActor.run {
                shared.cache.set(
                    value: dependency,
                    forKey: dependency.scope.key
                )
            }
        }
    }

    /**
     Permanently promotes (replaces) the specified `Dependency` with a new value.

     Unlike `override`, this change is persistent for the lifetime of the application session
     (or until another promotion or direct modification of the underlying cache occurs).
     This is useful for setting up fundamental services or configurations that should not be
     temporarily overridden.

     Internally, this uses the `override` mechanism but retains the override token within
     the `Application`'s shared state, effectively making the change permanent.

     - Parameters:
        - keyPath: The `KeyPath` of the `Dependency` to be promoted (e.g., `\.myServiceDependency`).
        - value: The new value to permanently replace the current dependency.
        - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
        - function: The name of the declaration in which this function is called. Defaults to `#function`.
        - line: The line number on which this function is called. Defaults to `#line`.
        - column: The column number in which this function is called. Defaults to `#column`.
     - Returns: The `Application.Type`, allowing for chained calls.
     - Warning: This is a permanent change for the application session. If temporary changes are needed,
                use `Application.override(_:with:)` instead.
     */
    @MainActor
    @discardableResult
    static func promote<CustomDependency>(
        _ keyPath: KeyPath<Application, Dependency<CustomDependency>>,
        with value: CustomDependency,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Application.Type {
        let promotionOverride = override(
            keyPath,
            with: value,
            fileID,
            function,
            line,
            column
        )

        var promotions = Application.state(\.dependencyPromotions)
        promotions.value.append(promotionOverride)

        return Application.self
    }

    /**
     Defines and retrieves a `Dependency` associated with a specific feature and identifier.

     If a `Dependency` with the given `feature` and `id` does not already exist in the cache,
     the `object` closure is called to create the initial value, which is then stored.
     Subsequent calls with the same `feature` and `id` will return the cached `Dependency`.
     This ensures that the dependency is instantiated only once.

     - Parameters:
        - object: A closure that creates and returns the dependency's value. This closure is executed only
                  if the dependency is not already cached.
        - feature: A `String` namespacing the dependency, often corresponding to a feature module. Defaults to "App".
        - id: A `String` uniquely identifying the dependency within its feature scope.
     - Returns: The `Dependency<Value>` instance, either newly created or retrieved from the cache.
     */
    func dependency<Value>(
        _ object: () -> Value,
        feature: String = "App",
        id: String
    ) -> Dependency<Value> {
        let scope = Scope(name: feature, id: id)
        let key = scope.key

        guard let dependency = cache.get(key, as: Dependency<Value>.self) else {
            let value = object()
            let dependency = Dependency(
                value,
                scope: scope
            )

            cache.set(value: dependency, forKey: key)

            return dependency
        }

        return dependency
    }

    /// Defines and retrieves a `Dependency` where its identifier is automatically generated from the call site's context.
    ///
    /// This is a convenience overload for `dependency(_:feature:id:)`. The `id` is generated using
    /// the file ID, function name, line, and column number of the call site, ensuring uniqueness
    /// for dependencies defined this way. The `feature` defaults to "App".
    ///
    /// - Parameters:
    ///   - setup: A closure that creates and returns the dependency's value. Executed only if not already cached.
    ///   - fileID: The calling file's identifier. Automatically captured.
    ///   - function: The calling function's name. Automatically captured.
    ///   - line: The line number of the call. Automatically captured.
    ///   - column: The column number of the call. Automatically captured.
    /// - Returns: The `Dependency<Value>` instance.
    func dependency<Value>(
        setup: () -> Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Dependency<Value> {
        dependency(
            setup,
            id: Application.codeID(
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }

    /**
     Defines and retrieves a `Dependency` using an autoclosure for the initial value.

     This version is similar to `dependency(_:feature:id:)` but accepts the `object` parameter
     as an autoclosure. The autoclosure is evaluated only if the dependency is not already cached.

     - Parameters:
        - object: An autoclosure that creates and returns the dependency's value. Evaluated only if not cached.
        - feature: A `String` namespacing the dependency. Defaults to "App".
        - id: A `String` uniquely identifying the dependency within its feature scope.
     - Returns: The `Dependency<Value>` instance.
     */
    func dependency<Value>(
        _ object: @autoclosure () -> Value,
        feature: String = "App",
        id: String
    ) -> Dependency<Value> {
        dependency(object, feature: feature, id: id)
    }

    /// Defines and retrieves a `Dependency` using an autoclosure, with an automatically generated identifier.
    ///
    /// This convenience overload combines autoclosure-based value creation with an automatically
    /// generated ID from the call site's context (file, function, line, column).
    /// The `feature` defaults to "App".
    ///
    /// - Parameters:
    ///   - object: An autoclosure that creates and returns the dependency's value. Evaluated only if not cached.
    ///   - fileID: The calling file's identifier. Automatically captured.
    ///   - function: The calling function's name. Automatically captured.
    ///   - line: The line number of the call. Automatically captured.
    ///   - column: The column number of the call. Automatically captured.
    /// - Returns: The `Dependency<Value>` instance.
    func dependency<Value>(
        _ object: @autoclosure () -> Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Dependency<Value> {
        dependency(
            object(),
            id: Application.codeID(
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }
}

#if !os(Linux) && !os(Windows)
// MARK: - SwiftUI Preview Dependency Functions

public extension Application {
    /**
    Use in SwiftUI previews to inject mock dependencies into the content view.

     - Parameters:
        - dependencyOverrides: An array of `Application.override(_, with:)` outputs that you want to use for the preview.
        - content: A closure that returns the View you want to preview.

     - Returns: A View with the overridden dependencies applied.
     */
    @MainActor
    @ViewBuilder
    static func preview<Content: View>(
        _ dependencyOverrides: DependencyOverride...,
        content: @escaping () -> Content
    ) -> some View {
        ApplicationPreview(
            dependencyOverrides: dependencyOverrides,
            content: content
        )
    }
}
#endif

// MARK: - State Functions

public extension Application {
    /// Resets any `State` instance to its initial value.
    ///
    /// - Parameters:
    ///   - keyPath: The `KeyPath` of the `MutableApplicationState` to reset (e.g., `\.myState`).
    ///   - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
    ///   - function: The name of the declaration in which this function is called. Defaults to `#function`.
    ///   - line: The line number on which this function is called. Defaults to `#line`.
    ///   - column: The column number in which this function is called. Defaults to `#column`.
    @MainActor
    static func reset<ApplicationState: MutableApplicationState>(
        _ keyPath: KeyPath<Application, ApplicationState>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {

        log(
            debug: "\(ApplicationState.emoji) Resetting State \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        var storedState = shared.value(keyPath: keyPath)
        storedState.reset()
    }

    /**
     Retrieves a `State`, `StoredState`, `FileState`, `SyncState`, or `SecureState` instance
     from the shared `Application` using its `KeyPath`.

     This function provides access to the state management object itself (e.g., `State<Int>`),
     allowing further interaction like getting or setting its `value`.

     - Parameter keyPath: The `KeyPath` referencing the desired state property defined on `Application`
                          (e.g., `\.myCounterState`).
     - Parameter fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
     - Parameter function: The name of the declaration in which this function is called. Defaults to `#function`.
     - Parameter line: The line number on which this function is called. Defaults to `#line`.
     - Parameter column: The column number in which this function is called. Defaults to `#column`.
     - Returns: The requested application state instance (e.g., `State<Value>`, `StoredState<Value>`).
     */
    @MainActor
    static func state<Value, ApplicationState: MutableApplicationState>(
        _ keyPath: KeyPath<Application, ApplicationState>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> ApplicationState where ApplicationState.Value == Value {
        let appState = shared.value(keyPath: keyPath)

        log(
            debug: "\(ApplicationState.emoji) Getting State \(String(describing: keyPath)) -> \(appState.value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return appState
    }

    /**
     Defines and retrieves a `State<Value>` instance associated with a specific feature and identifier.

     If a `State` with the given `feature` and `id` does not already exist in the cache,
     the `initial` autoclosure is evaluated to create the initial value, and a new `State` instance
     is created and stored. Subsequent calls with the same `feature` and `id` will return the cached `State` instance.
     This ensures that the state and its initial value are established only once.

     - Parameters:
        - initial: An autoclosure that provides the initial value for the state if it's being created for the first time.
                   The closure is evaluated only once when the state is first accessed and not found in the cache.
        - feature: A `String` namespacing the state, often corresponding to a feature module. Defaults to "App".
        - id: A `String` uniquely identifying the state within its feature scope.
     - Returns: The `State<Value>` instance, either newly created or retrieved from the cache.
     */
    func state<Value>(
        initial: @autoclosure () -> Value,
        feature: String = "App",
        id: String
    ) -> State<Value> {
        State(
            type: .state,
            initial: initial(),
            scope: Scope(name: feature, id: id)
        )
    }

    /// Defines and retrieves a `State<Value>` instance with an automatically generated identifier from the call site's context.
    ///
    /// This is a convenience overload for `state(initial:feature:id:)`. The `id` is generated
    /// using the file ID, function name, line, and column number of the call site.
    /// The `feature` defaults to "App". The `initial` autoclosure is evaluated only if the state
    /// is not already cached.
    ///
    /// - Parameters:
    ///   - initial: An autoclosure providing the initial value. Evaluated only if not cached.
    ///   - fileID: The calling file's identifier. Automatically captured.
    ///   - function: The calling function's name. Automatically captured.
    ///   - line: The line number of the call. Automatically captured.
    ///   - column: The column number of the call. Automatically captured.
    /// - Returns: The `State<Value>` instance.
    func state<Value>(
        initial: @autoclosure () -> Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> State<Value> {
        state(
            initial: initial(),
            id: Application.codeID(
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }
}

// MARK: - StoredState Functions

public extension Application {
    /// Resets a `StoredState` instance to its initial value.
    ///
    /// If the initial value was `nil`, the corresponding key will be removed from `UserDefaults`.
    /// Otherwise, the `StoredState` will be set to its originally defined initial value.
    ///
    /// - Parameters:
    ///   - keyPath: The `KeyPath` of the `StoredState` to reset (e.g., `\.myStoredSetting`).
    ///   - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
    ///   - function: The name of the declaration in which this function is called. Defaults to `#function`.
    ///   - line: The line number on which this function is called. Defaults to `#line`.
    ///   - column: The column number in which this function is called. Defaults to `#column`.
    @MainActor
    static func reset<Value>(
        storedState keyPath: KeyPath<Application, StoredState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        log(
            debug: "💾 Resetting StoredState \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        var storedState = shared.value(keyPath: keyPath)
        storedState.reset()
    }

    /**
     Retrieves a `StoredState<Value>` instance from the shared `Application` using its `KeyPath`.

     This function provides access to the `StoredState` management object itself, which is backed by `UserDefaults`.
     You can use this to get or set its `value`.

     - Parameters:
       - keyPath: The `KeyPath` referencing the desired `StoredState` property (e.g., `\.myStoredSetting`).
       - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
       - function: The name of the declaration in which this function is called. Defaults to `#function`.
       - line: The line number on which this function is called. Defaults to `#line`.
       - column: The column number in which this function is called. Defaults to `#column`.
     - Returns: The requested `StoredState<Value>` instance.
     */
    @MainActor
    static func storedState<Value>(
        _ keyPath: KeyPath<Application, StoredState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> StoredState<Value> {
        let storedState = shared.value(keyPath: keyPath)

        log(
            debug: "💾 Getting StoredState \(String(describing: keyPath)) -> \(storedState.value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return storedState
    }

    /**
     Defines and retrieves a `StoredState<Value>` instance, backed by `UserDefaults`,
     associated with a specific feature and identifier.

     If a `StoredState` with the given `feature` and `id` does not already exist (i.e., no value in `UserDefaults`
     for the derived key and not yet cached in memory), the `initial` autoclosure is evaluated. Its result is
     then set as the initial value for the `StoredState` and persisted to `UserDefaults`.
     Subsequent calls with the same `feature` and `id` will return the existing `StoredState` instance,
     retrieving its value from `UserDefaults` or the in-memory cache.

     - Parameters:
        - initial: An autoclosure providing the initial value. This is evaluated and used only if no value
                   currently exists in `UserDefaults` for this state's key and it's the first time this
                   `StoredState` is being accessed in the app session.
        - feature: A `String` namespacing the state, often corresponding to a feature module. Defaults to "App".
                   This helps in generating a unique key for `UserDefaults`.
        - id: A `String` uniquely identifying the state within its feature scope. This also helps in generating
              a unique key for `UserDefaults`.
     - Returns: The `StoredState<Value>` instance, either newly created or retrieved.
     */
    func storedState<Value>(
        initial: @escaping @autoclosure () -> Value,
        feature: String = "App",
        id: String
    ) -> StoredState<Value> {
        StoredState(
            initial: initial(),
            scope: Scope(name: feature, id: id)
        )
    }

    /**
     Defines and retrieves an optional `StoredState<Value?>` instance, backed by `UserDefaults`,
     associated with a specific feature and identifier, with an initial value of `nil`.

     This is a convenience method for creating an optional `StoredState` that does not have an
     explicit initial value other than `nil`. If no value is found in `UserDefaults` for the
     derived key, the state will represent `nil`.

     - Parameters:
        - feature: A `String` namespacing the state. Defaults to "App".
        - id: A `String` uniquely identifying the state within its feature scope.
     - Returns: The `StoredState<Value?>` instance, representing an optional value.
     */
    func storedState<Value>(
        feature: String = "App",
        id: String
    ) -> StoredState<Value?> {
        storedState(
            initial: nil,
            feature: feature,
            id: id
        )
    }
}

#if !os(Linux) && !os(Windows)
// MARK: - SyncState Functions

@available(watchOS 9.0, *)
public extension Application {
    /// Resets a `SyncState` instance to its initial value, synchronizing this reset across iCloud.
    ///
    /// If the initial value was `nil`, the corresponding key will be removed from the iCloud key-value store.
    /// Otherwise, the `SyncState` will be set to its originally defined initial value.
    /// This change is then propagated via iCloud to other devices.
    ///
    /// - Parameters:
    ///   - keyPath: The `KeyPath` of the `SyncState` to reset (e.g., `\.mySyncedSetting`).
    ///   - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
    ///   - function: The name of the declaration in which this function is called. Defaults to `#function`.
    ///   - line: The line number on which this function is called. Defaults to `#line`.
    ///   - column: The column number in which this function is called. Defaults to `#column`.
    @MainActor
    static func reset<Value>(
        syncState keyPath: KeyPath<Application, SyncState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        log(
            debug: "☁️ Resetting SyncState \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        var syncState = shared.value(keyPath: keyPath)
        syncState.reset()
    }

    /**
     Retrieves a `SyncState<Value>` instance from the shared `Application` using its `KeyPath`.

     This function provides access to the `SyncState` management object itself, which is backed by
     the iCloud key-value store. You can use this to get or set its `value`, and changes
     will be synchronized across devices via iCloud.

     - Parameters:
       - keyPath: The `KeyPath` referencing the desired `SyncState` property (e.g., `\.mySyncedSetting`).
                  The `Value` type must conform to `Codable` and `Sendable`.
       - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
       - function: The name of the declaration in which this function is called. Defaults to `#function`.
       - line: The line number on which this function is called. Defaults to `#line`.
       - column: The column number in which this function is called. Defaults to `#column`.
     - Returns: The requested `SyncState<Value>` instance.
     */
    @MainActor
    static func syncState<Value: Codable & Sendable>(
        _ keyPath: KeyPath<Application, SyncState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> SyncState<Value> {
        let storedState = shared.value(keyPath: keyPath)

        log(
            debug: "☁️ Getting SyncState \(String(describing: keyPath)) -> \(storedState.value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return storedState
    }

    /**
     Defines and retrieves a `SyncState<Value>` instance, backed by the iCloud key-value store,
     associated with a specific feature and identifier. The `Value` type must conform to `Codable` and `Sendable`.

     If a `SyncState` with the given `feature` and `id` does not already exist (i.e., no value in iCloud
     for the derived key and not yet cached), the `initial` autoclosure is evaluated. Its result is
     then set as the initial value for the `SyncState` and persisted to iCloud.
     Subsequent calls with the same `feature` and `id` will return the existing `SyncState` instance.

     - Parameters:
        - initial: An autoclosure providing the initial value if the state is new. Evaluated only once.
        - feature: A `String` namespacing the state. Defaults to "App".
        - id: A `String` uniquely identifying the state within its feature scope.
     - Returns: The `SyncState<Value>` instance.
     */
    func syncState<Value: Codable & Sendable>(
        initial: @escaping @autoclosure () -> Value,
        feature: String = "App",
        id: String
    ) -> SyncState<Value> {
        SyncState(
            initial: initial(),
            scope: Scope(name: feature, id: id)
        )
    }

    /**
     Defines and retrieves an optional `SyncState<Value?>` instance, backed by iCloud,
     with an initial value of `nil`. The `Value` type must conform to `Codable` and `Sendable`.

     This is for creating an optional `SyncState` that defaults to `nil` if no value is in iCloud.

     - Parameters:
        - feature: A `String` namespacing the state. Defaults to "App".
        - id: A `String` uniquely identifying the state.
     - Returns: The `SyncState<Value?>` instance.
     */
    func syncState<Value: Codable & Sendable>(
        feature: String = "App",
        id: String
    ) -> SyncState<Value?> {
        syncState(
            initial: nil,
            feature: feature,
            id: id
        )
    }
}

// MARK: - SecureState Functions

public extension Application {
    /**
     Resets a `SecureState` instance, removing its value from the Keychain.

     After reset, the `SecureState` will effectively contain `nil` or its original default if it was defined with one
     (though `SecureState` typically handles optional strings, so `nil` is the common reset state).

     - Parameters:
        - keyPath: The `KeyPath` of the `SecureState` to reset (e.g., `\.myApiKey`).
        - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
        - function: The name of the declaration in which this function is called. Defaults to `#function`.
        - line: The line number on which this function is called. Defaults to `#line`.
        - column: The column number in which this function is called. Defaults to `#column`.
     */
    @MainActor
    static func reset(
        secureState keyPath: KeyPath<Application, SecureState>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        log(
            debug: "🔑 Resetting SecureState \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        var secureState = shared.value(keyPath: keyPath)
        secureState.reset()
    }

    /**
     Retrieves a `SecureState` instance from the shared `Application` using its `KeyPath`.

     This function provides access to the `SecureState` management object itself, which is backed by
     the Keychain. You can use this to get or set its `value` (a `String?`).

     - Parameters:
        - keyPath: The `KeyPath` referencing the desired `SecureState` property (e.g., `\.myApiKey`).
        - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
        - function: The name of the declaration in which this function is called. Defaults to `#function`.
        - line: The line number on which this function is called. Defaults to `#line`.
        - column: The column number in which this function is called. Defaults to `#column`.
     - Returns: The requested `SecureState` instance.
     */
    @MainActor
    static func secureState(
        _ keyPath: KeyPath<Application, SecureState>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> SecureState {
        let secureState = shared.value(keyPath: keyPath)

        log(
            debug: {
                #if DEBUG
                "🔑 Getting SecureState \(String(describing: keyPath)) -> \(secureState.value ?? "nil")"
                #else
                "🔑 Getting SecureState \(String(describing: keyPath))"
                #endif
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return secureState
    }

    /**
     Defines and retrieves a `SecureState` instance, backed by the Keychain,
     associated with a specific feature and identifier.

     If a `SecureState` with the given `feature` and `id` does not already exist (i.e., no value in Keychain
     for the derived key and not yet cached), the `initial` autoclosure is evaluated. Its result is
     then set as the initial value for the `SecureState` and persisted to the Keychain.
     Subsequent calls with the same `feature` and `id` will return the existing `SecureState` instance.

     - Parameters:
        - initial: An autoclosure providing the initial `String?` value. Evaluated only once if not already in Keychain/cache.
        - feature: A `String` namespacing the state. Defaults to "App".
        - id: A `String` uniquely identifying the state within its feature scope.
     - Returns: The `SecureState` instance.
    */
    func secureState(
        initial: @escaping @autoclosure () -> String?,
        feature: String = "App",
        id: String
    ) -> SecureState {
        SecureState(
            initial: initial(),
            scope: Scope(name: feature, id: id)
        )
    }

    /**
     Defines and retrieves a `SecureState` instance, backed by the Keychain,
     with an initial value of `nil`.

     This is a convenience for creating a `SecureState` that defaults to `nil` if no value is in Keychain.

     - Parameters:
        - feature: A `String` namespacing the state. Defaults to "App".
        - id: A `String` uniquely identifying the state.
     - Returns: The `SecureState` instance.
     */
    func secureState(
        feature: String = "App",
        id: String
    ) -> SecureState {
        secureState(
            initial: nil,
            feature: feature,
            id: id
        )
    }
}
#endif

// MARK: - Slice Functions

extension Application {
    /**
     Creates a read-only `Slice` of an existing `ApplicationState` (like `State`, `StoredState`, etc.).
     A slice provides focused access to a specific property within the value of a larger state object.
     This is useful for exposing only a part of a state's data.

     The underlying state is identified by `stateKeyPath`, and the specific property within that
     state's value is identified by `valueKeyPath`.

     - Parameters:
         - stateKeyPath: A `KeyPath` to an existing `ApplicationState` instance defined on `Application` (e.g., `\.userProfileState`).
                         The `Value` of this state will be the source for the slice.
         - valueKeyPath: A `KeyPath` from the `Value` of the `ApplicationState` to the desired `SliceValue`
                         (e.g., `\UserProfile.name`).
         - fileID: The identifier of the file. Automatically captured.
         - function: The name of the declaration. Automatically captured.
         - line: The line number on which it appears. Automatically captured.
         - column: The column number in which it begins. Automatically captured.
     - Returns: A `Slice` instance providing read-only access to the specified sub-property of the application state.
     - Note: This version is for read-only access because `valueKeyPath` is a `KeyPath` (not `WritableKeyPath`).
     */
    @MainActor
    public static func slice<SlicedState: MutableApplicationState, Value, SliceValue>(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: KeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Slice<SlicedState, Value, SliceValue, KeyPath<Value, SliceValue>> where SlicedState.Value == Value {
        let slice = Slice(
            stateKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let stateKeyPathString = String(describing: stateKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> \(slice.value)"
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }

    /**
     Creates a writable `Slice` of an existing `ApplicationState` (like `State`, `StoredState`, etc.).
     A slice provides focused read and write access to a specific property within the value of a larger state object.
     Modifications to the slice's value will reflect in the original application state and trigger
     appropriate updates.

     The underlying state is identified by `stateKeyPath`, and the specific mutable property within that
     state's value is identified by `valueKeyPath`.

     - Parameters:
         - stateKeyPath: A `KeyPath` to an existing `ApplicationState` instance defined on `Application` (e.g., `\.userProfileState`).
                         The `Value` of this state will be the source for the slice.
         - valueKeyPath: A `WritableKeyPath` from the `Value` of the `ApplicationState` to the desired `SliceValue`
                         (e.g., `\UserProfile.name`). This allows the slice to modify the original state.
         - fileID: The identifier of the file. Automatically captured.
         - function: The name of the declaration. Automatically captured.
         - line: The line number on which it appears. Automatically captured.
         - column: The column number in which it begins. Automatically captured.
     - Returns: A `Slice` instance providing read-write access to the specified sub-property of the application state.
     */
    @MainActor
    public static func slice<SlicedState: MutableApplicationState, Value, SliceValue>(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Slice<SlicedState, Value, SliceValue, WritableKeyPath<Value, SliceValue>> where SlicedState.Value == Value {
        let slice = Slice(
            stateKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let stateKeyPathString = String(describing: stateKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> \(slice.value)"
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }

    /**
     Creates a read-only `OptionalSlice` from an `ApplicationState` whose `Value` is an optional type (e.g., `State<User?>`).
     This slice provides safe access to a property of the wrapped optional value. If the application state's
     value is `nil`, the slice's value will also be `nil`.

     - Parameters:
         - stateKeyPath: A `KeyPath` to an `ApplicationState` whose `Value` is `Optional` (e.g., `\.optionalUserProfileState`).
         - valueKeyPath: A `KeyPath` from the wrapped `Value` (non-optional part) to the desired `SliceValue`
                         (e.g., `\User.address`).
         - fileID: The identifier of the file. Automatically captured.
         - function: The name of the declaration. Automatically captured.
         - line: The line number on which it appears. Automatically captured.
         - column: The column number in which it begins. Automatically captured.
     - Returns: An `OptionalSlice` providing read-only access to a property of an optional application state.
                  The slice's value will be `nil` if the source state's value is `nil`.
     - Note: This version is for read-only access.
     */
    @MainActor
    public static func slice<SlicedState: MutableApplicationState, Value, SliceValue>(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: KeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> OptionalSlice<SlicedState, Value, SliceValue, KeyPath<Value, SliceValue>> where SlicedState.Value == Value? {
        let slice = OptionalSlice(
            stateKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let stateKeyPathString = String(describing: stateKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                if let value = slice.value {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> \(value)"
                } else {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> nil"
                }
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }

    /**
     Creates a writable `OptionalSlice` from an `ApplicationState` whose `Value` is an optional type (e.g., `State<User?>`).
     This slice provides safe read and write access to a property of the wrapped optional value.
     If the application state's value is `nil`, the slice's value will be `nil`, and writes will be no-ops.
     Modifications to the slice's value (if the source is not `nil`) will reflect in the original state.

     - Parameters:
         - stateKeyPath: A `KeyPath` to an `ApplicationState` whose `Value` is `Optional` (e.g., `\.optionalUserProfileState`).
         - valueKeyPath: A `WritableKeyPath` from the wrapped `Value` (non-optional part) to the desired `SliceValue`
                         (e.g., `\User.address`).
         - fileID: The identifier of the file. Automatically captured.
         - function: The name of the declaration. Automatically captured.
         - line: The line number on which it appears. Automatically captured.
         - column: The column number in which it begins. Automatically captured.
     - Returns: An `OptionalSlice` providing read-write access to a property of an optional application state.
                  Writes are effective only if the source state's value is not `nil`.
     */
    @MainActor
    public static func slice<SlicedState: MutableApplicationState, Value, SliceValue>(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> OptionalSlice<SlicedState, Value, SliceValue, WritableKeyPath<Value, SliceValue>> where SlicedState.Value == Value? {
        let slice = OptionalSlice(
            stateKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let stateKeyPathString = String(describing: stateKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                if let value = slice.value {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> \(value)"
                } else {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> nil"
                }
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }

    /**
     Creates a writable `OptionalSliceOptionalValue` for a scenario where both the `ApplicationState`'s `Value`
     and the target property (`SliceValue`) within that value are optional.
     (e.g., `State<User?>` where `User` has an `optionalMiddleName: String?`).

     This allows safe read and write access to such doubly nested optional properties.
     If the application state's value is `nil`, or if the intermediate path to the target property is `nil`,
     the slice's value will be `nil`. Writes are effective only if the path to the target is valid.

     - Parameters:
         - stateKeyPath: A `KeyPath` to an `ApplicationState` whose `Value` is `Optional` (e.g., `\.optionalUser`).
         - valueKeyPath: A `WritableKeyPath` from the wrapped `Value` to an optional `SliceValue?`
                         (e.g., `\User.optionalNickname`).
         - fileID: The identifier of the file. Automatically captured.
         - function: The name of the declaration. Automatically captured.
         - line: The line number on which it appears. Automatically captured.
         - column: The column number in which it begins. Automatically captured.
     - Returns: An `OptionalSliceOptionalValue` providing read-write access.
     */
    @MainActor
    public static func slice<SlicedState: MutableApplicationState, Value, SliceValue>(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue?>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> OptionalSliceOptionalValue<SlicedState, Value, SliceValue, WritableKeyPath<Value, SliceValue?>> where SlicedState.Value == Value? {
        let slice = OptionalSliceOptionalValue(
            stateKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let stateKeyPathString = String(describing: stateKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                if let value = slice.value {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> \(value)"
                } else {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> nil"
                }
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }
}

// MARK: - DependencySlice Functions

extension Application {
    /**
     Creates a read-only `DependencySlice` from an existing `Dependency`.
     A dependency slice provides focused access to a specific property within the value of a larger dependency object.
     This is useful for exposing only a part of a dependency's data or API.

     The underlying dependency is identified by `dependencyKeyPath`, and the specific property within that
     dependency's value is identified by `valueKeyPath`.

     - Parameters:
         - dependencyKeyPath: A `KeyPath` to an existing `Dependency` instance defined on `Application` (e.g., `\.myServiceDependency`).
                              The `Value` of this dependency will be the source for the slice.
         - valueKeyPath: A `KeyPath` from the `Value` of the `Dependency` to the desired `SliceValue`
                         (e.g., `\MyService.someReadOnlyProperty`).
         - fileID: The identifier of the file. Automatically captured.
         - function: The name of the declaration. Automatically captured.
         - line: The line number on which it appears. Automatically captured.
         - column: The column number in which it begins. Automatically captured.
     - Returns: A `DependencySlice` instance providing read-only access to the specified sub-property of the dependency.
     - Note: This version is for read-only access because `valueKeyPath` is a `KeyPath`.
     */
    @MainActor
    public static func dependencySlice<Value, SliceValue>(
        _ dependencyKeyPath: KeyPath<Application, Dependency<Value>>,
        _ valueKeyPath: KeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> DependencySlice<Value, SliceValue, KeyPath<Value, SliceValue>> {
        let slice = DependencySlice(
            dependencyKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let dependencyKeyPathString = String(describing: dependencyKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                return "🔗 Getting DependencySlice \(dependencyKeyPathString)\(valueKeyPathString) -> \(slice.value)"
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }

    /**
     Creates a writable `DependencySlice` from an existing `Dependency`.
     A dependency slice provides focused read and write access to a specific mutable property
     within the value of a larger dependency object. Modifications to the slice's value will
     reflect in the original dependency object.

     The underlying dependency is identified by `dependencyKeyPath`, and the specific mutable
     property within that dependency's value is identified by `valueKeyPath`.

     - Parameters:
         - dependencyKeyPath: A `KeyPath` to an existing `Dependency` instance defined on `Application` (e.g., `\.myMutableService`).
                              The `Value` of this dependency will be the source for the slice.
         - valueKeyPath: A `WritableKeyPath` from the `Value` of the `Dependency` to the desired `SliceValue`
                         (e.g., `\MyMutableService.someConfigurableProperty`).
         - fileID: The identifier of the file. Automatically captured.
         - function: The name of the declaration. Automatically captured.
         - line: The line number on which it appears. Automatically captured.
         - column: The column number in which it begins. Automatically captured.
     - Returns: A `DependencySlice` instance providing read-write access to the specified sub-property of the dependency.
     */
    @MainActor
    public static func dependencySlice<Value, SliceValue>(
        _ dependencyKeyPath: KeyPath<Application, Dependency<Value>>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> DependencySlice<Value, SliceValue, WritableKeyPath<Value, SliceValue>> {
        let slice = DependencySlice(
            dependencyKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let dependencyKeyPathString = String(describing: dependencyKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                return "🔗 Getting DependencySlice \(dependencyKeyPathString)\(valueKeyPathString) -> \(slice.value)"
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }
}

// MARK: - FileState Functions

public extension Application {
    /// Resets a `FileState` instance to its initial value, deleting the backing file if the initial value is `nil`.
    ///
    /// If the `FileState` was initialized with a non-nil default value, the backing file will be
    /// rewritten with this initial value. If the initial value was `nil`, the backing file
    /// associated with this `FileState` will be deleted from the file system.
    ///
    /// - Parameters:
    ///   - keyPath: The `KeyPath` of the `FileState` to reset (e.g., `\.myDocumentState`).
    ///   - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
    ///   - function: The name of the declaration in which this function is called. Defaults to `#function`.
    ///   - line: The line number on which this function is called. Defaults to `#line`.
    ///   - column: The column number in which this function is called. Defaults to `#column`.
    @MainActor
    static func reset<Value>(
        fileState keyPath: KeyPath<Application, FileState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        log(
            debug: "🗄️ Resetting FileState \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        var fileState = shared.value(keyPath: keyPath)
        fileState.reset()
    }

    /**
     Retrieves a `FileState<Value>` instance from the shared `Application` using its `KeyPath`.

     This function provides access to the `FileState` management object itself, which is backed by
     a file on the disk. You can use this to get or set its `value`. The `Value` must conform to `Codable`.

     - Parameters:
       - keyPath: The `KeyPath` referencing the desired `FileState` property (e.g., `\.myDocumentState`).
       - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
       - function: The name of the declaration in which this function is called. Defaults to `#function`.
       - line: The line number on which this function is called. Defaults to `#line`.
       - column: The column number in which this function is called. Defaults to `#column`.
     - Returns: The requested `FileState<Value>` instance.
     */
    @MainActor
    static func fileState<Value>(
        _ keyPath: KeyPath<Application, FileState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> FileState<Value> {
        let fileState = shared.value(keyPath: keyPath)

        log(
            debug: "🗄️ Getting FileState \(String(describing: keyPath)) -> \(fileState.value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return fileState
    }

    /**
     Defines and retrieves a `FileState<Value>` instance, backed by a file on disk,
     associated with a specific path and filename. The `Value` must conform to `Codable`.

     If a file at the specified `path` and `filename` does not exist (or if the state is not cached),
     the `initial` autoclosure is evaluated. Its result is then set as the initial value for the `FileState`
     and persisted to the specified file. Subsequent calls for the same path and filename will return
     the existing `FileState` instance, reading from the file or cache.

     - Parameters:
        - initial: An autoclosure providing the initial value if the state is new or file doesn't exist.
                   Evaluated only once under these conditions.
        - path: The directory path where the file is stored. Defaults to `FileManager.defaultFileStatePath`.
        - filename: The name of the file used for storing this state.
        - isBase64Encoded: A Boolean indicating if the file content should be Base64 encoded. Defaults to `true`.
                           Set to `false` if storing plain text or directly encoded data that is not Base64.
     - Returns: The `FileState<Value>` instance.
     */
    @MainActor
    func fileState<Value>(
        initial: @escaping @autoclosure () -> Value,
        path: String = FileManager.defaultFileStatePath,
        filename: String,
        isBase64Encoded: Bool = true
    ) -> FileState<Value> {
        FileState(
            initial: initial(),
            scope: Scope(name: path, id: filename),
            isBase64Encoded: isBase64Encoded
        )
    }

    /**
     Defines and retrieves an optional `FileState<Value?>` instance, backed by a file on disk,
     with an initial value of `nil`. The `Value` must conform to `Codable`.

     This is a convenience for creating an optional `FileState`. If no file exists at the specified
     path and filename, the state will represent `nil`.

     - Parameters:
        - path: The directory path where the file is (or will be) stored. Defaults to `FileManager.defaultFileStatePath`.
        - filename: The name of the file.
        - isBase64Encoded: A Boolean indicating if the file content should be Base64 encoded. Defaults to `true`.
     - Returns: The `FileState<Value?>` instance, representing an optional value.
     */
    @MainActor
    func fileState<Value>(
        path: String = FileManager.defaultFileStatePath,
        filename: String,
        isBase64Encoded: Bool = true
    ) -> FileState<Value?> {
        fileState(
            initial: nil,
            path: path,
            filename: filename,
            isBase64Encoded: isBase64Encoded
        )
    }
}
