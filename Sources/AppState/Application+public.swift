public extension Application {
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

    static func state<Value>(_ keyPath: KeyPath<Application, Value>) -> Value {
        shared.value(keyPath: keyPath)
    }

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

    func state<Value>(
        initial: @autoclosure () -> Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: StaticBigInt = #line,
        _ column: StaticBigInt = #column
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

    static func dependency<Value>(
        _ object: @autoclosure () -> Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: StaticBigInt = #line,
        _ column: StaticBigInt = #column
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
}
