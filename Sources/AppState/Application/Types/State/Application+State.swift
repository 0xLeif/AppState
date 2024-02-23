import Foundation

extension Application {
    /// `State` encapsulates the value within the application's scope and allows any changes to be propagated throughout the scoped area.
    public struct State<Value>: MutableApplicationState, CustomStringConvertible {
        enum StateType {
            case state
            case stored
            case sync
            case file
        }

        private let type: StateType

        /// A private backing storage for the value.
        private var _value: Value

        /// The current state value.
        public var value: Value {
            get {
                guard
                    let state = shared.cache.get(
                        scope.key,
                        as: State<Value>.self
                    )
                else {
                    defer {
                        let setValue = {
                            shared.cache.set(
                                value: Application.State(
                                    type: .state,
                                    initial: _value,
                                    scope: scope
                                ),
                                forKey: scope.key
                            )
                        }

                        #if (!os(Linux) && !os(Windows))
                        if ProcessInfo().environment["XCTestConfigurationFilePath"] == nil {
                            Task {
                                await MainActor.run {
                                    setValue()
                                }
                            }
                        } else {
                            setValue()
                        }
                        #else
                        setValue()
                        #endif
                    }
                    return _value
                }
                return state._value
            }
            set {
                _value = newValue
                shared.cache.set(
                    value: Application.State(
                        type: .state,
                        initial: newValue,
                        scope: scope
                    ),
                    forKey: scope.key
                )
            }
        }

        /// The scope in which this state exists.
        let scope: Scope

        /**
         Creates a new state within a given scope initialized with the provided value.

         - Parameters:
             - value: The initial value of the state
             - scope: The scope in which the state exists
         */
        init(
            type: StateType,
            initial value: Value,
            scope: Scope
        ) {
            self.type = type
            self._value = value
            self.scope = scope
        }

        public var description: String {
            switch type {
            case .state:    return "State<\(Value.self)>(\(value)) (\(scope.key))"
            case .stored:   return "StoredState<\(Value.self)>(\(value)) (\(scope.key))"
            case .sync:     return "SyncState<\(Value.self)>(\(value)) (\(scope.key))"
            case .file:     return "FileState<\(Value.self)>(\(value)) (\(scope.key))"
            }
        }
    }
}
