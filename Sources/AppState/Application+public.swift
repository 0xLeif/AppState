public extension Application {
    /// Provides a description of the current application state
    static var description: String {
        let state = shared.cache.allValues
            .sorted { lhsKeyValue, rhsKeyValue in
                lhsKeyValue.key < rhsKeyValue.key
            }
            .map { key, value in
                "- \(value) (\(key))"
            }
            .joined(separator: "\n")

        return """
                App:
                \(state)
                """
    }

    /**
     Retrieves a dependency for the provided `id`. If dependency is not present, it is created once using the provided closure.

     - Parameters:
         - object: The closure returning the dependency.
         - feature: The name of the feature to which the dependency belongs, default is "App".
         - id: The specific identifier for this dependency.
     - Returns: The requested dependency of type `Value`.
     */
    static func dependency<Value>(
        _ object: @autoclosure () -> Value,
        feature: String = "App",
        id: String
    ) -> Value {
        let scope = Scope(name: feature, id: id)
        let key = scope.key

        guard let value = shared.cache.get(key, as: Value.self) else {
            let value = object()
            shared.cache.set(value: value, forKey: key)
            return value
        }

        return value
    }

    // Overloaded version of `dependency(_:feature:id:)` function where id is generated from the code context.
    static func dependency<Value>(
        _ object: @autoclosure () -> Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Value {
        dependency(
            object(),
            id: codeID(
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }

    /**
     Retrieves a state from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the state value to be fetched
     - Returns: The requested state of type `Value`.
     */
    static func state<Value>(_ keyPath: KeyPath<Application, Value>) -> Value {
        shared.value(keyPath: keyPath)
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

}
