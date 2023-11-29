import Foundation

extension Application {
    /// The shared `UserDefaults` instance.
    public var userDefaults: Dependency<UserDefaults> {
        dependency(UserDefaults.standard)
    }

    /// `StoredState` encapsulates the value within the application's scope and allows any changes to be propagated throughout the scoped area.  State is stored using `UserDefaults`.
    public struct StoredState<Value> {
        @AppDependency(\.userDefaults) private var userDefaults: UserDefaults

        /// The initial value of the state.
        private var initial: () -> Value

        /// The current state value.
        public var value: Value {
            get {
                let cachedValue = shared.cache.get(
                    scope.key,
                    as: State<Value>.self
                )

                if let cachedValue = cachedValue {
                    return cachedValue.value
                }

                guard
                    let object = userDefaults.object(forKey: scope.key),
                    let storedValue = object as? Value
                else { return initial() }

                return storedValue
            }
            set {
                let mirror = Mirror(reflecting: newValue)

                if mirror.displayStyle == .optional,
                   mirror.children.isEmpty {
                    shared.cache.remove(scope.key)
                    userDefaults.removeObject(forKey: scope.key)
                } else {
                    shared.cache.set(
                        value: Application.State(
                            type: .stored,
                            initial: newValue,
                            scope: scope
                        ),
                        forKey: scope.key
                    )
                    userDefaults.set(newValue, forKey: scope.key)
                }
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
            initial: @escaping @autoclosure () -> Value,
            scope: Scope
        ) {
            self.initial = initial
            self.scope = scope
        }

        /// Removes the value from `UserDefaults` and resets the value to the inital value.
        public mutating func remove() {
            value = initial()
            userDefaults.removeObject(forKey: scope.key)
        }
    }
}
