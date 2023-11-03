extension Application {
    /// `State` encapsulates the value within the application's scope and allows any changes to be propagated throughout the scoped area.
    public struct State<Value>: CustomStringConvertible {
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
                else { return _value }

                return state._value
            }
            set {
                _value = newValue
                shared.cache.set(
                    value: Application.State(
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
            initial value: Value,
            scope: Scope
        ) {
            self._value = value
            self.scope = scope
        }

        public var description: String {
            "State<\(Value.self)>(\(value)) (\(scope.key))"
        }
    }
}
