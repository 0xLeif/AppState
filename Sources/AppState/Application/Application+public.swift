public extension Application {
    // MARK: - Type Methods

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
        _ keyPath: KeyPath<Application, Dependency<Value>>
    ) -> Value {
        shared.value(keyPath: keyPath).value
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
        with value: Value
    ) -> DependencyOverride {
        let dependency = shared.value(keyPath: keyPath)

        shared.cache.set(
            value: Dependency(value, scope: dependency.scope),
            forKey: dependency.scope.key
        )

        return DependencyOverride {
            shared.cache.set(
                value: dependency,
                forKey: dependency.scope.key
            )
        }
    }

    static func remove<Value>(
        storedState keyPath: KeyPath<Application, StoredState<Value>>
    ) {
        var storedState = shared.value(keyPath: keyPath)
        storedState.remove()
    }

    /**
     Retrieves a state from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the state value to be fetched
     - Returns: The requested state of type `Value`.
     */
    static func state<Value>(
        _ keyPath: KeyPath<Application, State<Value>>
    ) -> State<Value> {
        shared.value(keyPath: keyPath)
    }

    /**
     Retrieves a stored state from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the state value to be fetched
     - Returns: The requested state of type `Value`.
     */
    static func storedState<Value>(
        _ keyPath: KeyPath<Application, StoredState<Value>>
    ) -> StoredState<Value> {
        shared.value(keyPath: keyPath)
    }

    // MARK: - Instance Methods

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


    // Overloaded version of `dependency(_:feature:id:)` function where id is generated from the code context.
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
            return State(initial: value, scope: scope)
        }

        return State(initial: value, scope: scope)
    }

    // Overloaded version of `state(initial:feature:id:)` function where id is generated from the code context.
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
}