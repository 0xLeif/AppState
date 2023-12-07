import Foundation

// MARK: - Application Functions

public extension Application {
    /// Provides a description of the current application state
    static var description: String {
        let state = shared.cache.allValues
            .map { key, value in
                "\t- \(value)"
            }
            .sorted(by: <)
            .joined(separator: "\n")

        return """
               {
               \(state)
               }
               """
    }

    /**
     This static function promotes the shared singleton instance of the Application class to a custom Application type.

     - Parameters:
        - customApplication: A custom Application subclass to be promoted to.

     - Returns: The type of the custom Application subclass.

     This function is particularly useful when your Application subclass needs to override the `didChangeExternally(notification:)` function. It allows you to extend the functionalities of the Application class and use your custom Application type throughout your application.

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
         }
     }
     ```

     To use the `promote` function to promote the shared singleton to `CustomApplication`:

     ```swift
     Application.promote(to: CustomApplication.self)
     ```

     In this way, your custom Application subclass becomes the shared singleton instance, which you can then use throughout your application.
     */
    @discardableResult
    static func promote<CustomApplication: Application>(
        to customApplication: CustomApplication.Type
    ) -> CustomApplication.Type {
        NotificationCenter.default.removeObserver(shared)

        let cache = shared.cache
        shared = customApplication.init()

        for (key, value) in cache.allValues {
            shared.cache.set(value: value, forKey: key)
            cache.remove(key)
        }

        return CustomApplication.self
    }

    /// Enables or disabled the default logging inside of Application.
    @discardableResult
    static func logging(isEnabled: Bool) -> Application.Type {
        Application.isLoggingEnabled = isEnabled

        return Application.self
    }
}

// MARK: Dependency Functions

public extension Application {
    /**
     Use this function to make sure Dependencies are intialized. If a Dependency is not loaded, it will be initialized whenever it is used next.

     - Parameter dependency: KeyPath of the Dependency to be loaded
     - Returns: `Application.self` to allow chaining.
     */
    @discardableResult
    static func load<Value>(
        dependency keyPath: KeyPath<Application, Dependency<Value>>
    ) -> Application.Type {
        shared.load(dependency: keyPath)

        return Application.self
    }

    /**
     Retrieves a state from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the Dependency to be fetched
     - Returns: The requested state of type `Value`.
     */
    static func dependency<Value>(
        _ keyPath: KeyPath<Application, Dependency<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Value {
        log(
            debug: "🔗 Getting Dependency \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return shared.value(keyPath: keyPath).value
    }

    /**
     Overrides the specified `Dependency` with the given value. This is particularly useful for SwiftUI Previews and Unit Tests.
     - Parameters:
     - keyPath: Key path of the dependency to be overridden.
     - value: The new value to override the current dependency.

     - Returns: A `DependencyOverride` object. You should retain this token for as long as you want your override to be effective. Once the token is deallocated or the `cancel()` method is called on it, the original dependency is restored.

     Note: If the `DependencyOverride` object gets deallocated without calling `cancel()`, it will automatically cancel the override, restoring the original dependency.
     */
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

        return DependencyOverride {
            log(
                debug: "🔗 Cancelling Dependency Override \(String(describing: keyPath)) ",
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )

            shared.cache.set(
                value: dependency,
                forKey: dependency.scope.key
            )
        }
    }

    /**
     Retrieves a dependency for the provided `id`. If dependency is not present, it is created once using the provided closure.

     - Parameters:
     - object: The closure returning the dependency.
     - feature: The name of the feature to which the dependency belongs, default is "App".
     - id: The specific identifier for this dependency.
     - Returns: The requested dependency of type `Dependency<Value>`.
     */
    func dependency<Value>(
        _ object: @autoclosure () -> Value,
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


    /// Overloaded version of `dependency(_:feature:id:)` function where id is generated from the code context.
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

// MARK: State Functions

public extension Application {
    /**
     Retrieves a state from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the state value to be fetched
     - Returns: The requested state of type `Value`.
     */
    static func state<Value>(
        _ keyPath: KeyPath<Application, State<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> State<Value> {
        let appState = shared.value(keyPath: keyPath)

        log(
            debug: "🔄 Getting State \(String(describing: keyPath)) -> \(appState.value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return appState
    }

    /**
     Retrieves a state for the provided `id`. If the state is not present, it initializes a new state with the `initial` value.

     - Parameters:
     - initial: The closure that returns initial state value.
     - feature: The name of the feature to which the state belongs, default is "App".
     - id: The specific identifier for this state.
     - Returns: The state of type `Value`.
     */
    func state<Value>(
        initial: @autoclosure () -> Value,
        feature: String = "App",
        id: String
    ) -> State<Value> {
        let scope = Scope(name: feature, id: id)
        let key = scope.key

        guard let value = cache.get(key, as: Value.self) else {
            let value = initial()
            return State(type: .state, initial: value, scope: scope)
        }

        return State(type: .state, initial: value, scope: scope)
    }

    /// Overloaded version of `state(initial:feature:id:)` function where id is generated from the code context.
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

// MARK: StoredState Functions

public extension Application {
    /// Resets the value to the inital value. If the inital value was `nil`, then the value will be removed from `UserDefaults`
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

    /// Removes the value from `UserDefaults` and resets the value to the inital value.
    @available(*, deprecated, renamed: "reset")
    static func remove<Value>(
        storedState keyPath: KeyPath<Application, StoredState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        reset(
            storedState: keyPath,
            fileID,
            function,
            line,
            column
        )
    }

    /**
     Retrieves a stored state from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the state value to be fetched
     - Returns: The requested state of type `Value`.
     */
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
     Retrieves a `UserDefaults` backed state for the provided `id`. If the state is not present, it initializes a new state with the `initial` value.

     - Parameters:
     - initial: The closure that returns initial state value.
     - feature: The name of the feature to which the state belongs, default is "App".
     - id: The specific identifier for this state.
     - Returns: The state of type `Value`.
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
     Retrieves a `UserDefaults` backed state for the provided `id` with a default value of `nil`.

     - Parameters:
     - feature: The name of the feature to which the state belongs, default is "App".
     - id: The specific identifier for this state.
     - Returns: The state of type `Value`.
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

// MARK: SyncState Functions

@available(iOS 15.0, watchOS 9.0, macOS 11.0, tvOS 15.0, *)
public extension Application {
    /// Resets the value to the inital value. If the inital value was `nil`, then the value will be removed from `iClouds`
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

    /// Removes the value from `iCloud` and resets the value to the inital value.
    @available(*, deprecated, renamed: "reset")
    static func remove<Value>(
        syncState keyPath: KeyPath<Application, SyncState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        reset(
            syncState: keyPath,
            fileID,
            function,
            line,
            column
        )
    }

    /**
     Retrieves a state backed by iCloud from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the state value to be fetched
     - Returns: The requested state of type `Value`.
     */
    static func syncState<Value: Codable>(
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
     Retrieves an `iCloud` backed state for the provided `id`. If the state is not present, it initializes a new state with the `initial` value.

     - Parameters:
     - initial: The closure that returns initial state value.
     - feature: The name of the feature to which the state belongs, default is "App".
     - id: The specific identifier for this state.
     - Returns: The state of type `Value`.
     */
    func syncState<Value: Codable>(
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
     Retrieves an `iCloud` backed state for the provided `id` with a default value of `nil`.

     - Parameters:
     - feature: The name of the feature to which the state belongs, default is "App".
     - id: The specific identifier for this state.
     - Returns: The state of type `Value`.
     */
    func syncState<Value: Codable>(
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
