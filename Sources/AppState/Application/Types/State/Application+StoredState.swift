import Foundation

extension Application {
    /// A struct that provides a thread-safe interface for interacting with `UserDefaults`, allowing the storage, retrieval, and removal of user preferences and data.
    public struct SendableUserDefaults: UserDefaultsManaging {
        public func object(forKey key: String) -> Any? {
            UserDefaults.standard.object(forKey: key)
        }

        public func removeObject(forKey key: String) {
            UserDefaults.standard.removeObject(forKey: key)
        }

        public func set(_ value: Any?, forKey key: String) {
            UserDefaults.standard.set(value, forKey: key)
        }
    }

    /// The shared `UserDefaults` instance.
    public var userDefaults: Dependency<UserDefaultsManaging> {
        dependency(SendableUserDefaults())
    }

    /// `StoredState` encapsulates the value within the application's scope and allows any changes to be propagated throughout the scoped area.  State is stored using `UserDefaults`.
    public struct StoredState<Value: Codable & Sendable>: MutableApplicationState {
        public static var emoji: Character { "💾" }

        @AppDependency(\.userDefaults) private var userDefaults: UserDefaultsManaging

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
                    let object = userDefaults.object(forKey: scope.key)
                else { return initial() }

                if 
                    let data = object as? Data,
                    let decodedValue = try? JSONDecoder().decode(Value.self, from: data)
                {
                    return decodedValue
                }

                guard
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

                    if let encodedValue = try? JSONEncoder().encode(newValue) {
                        userDefaults.set(encodedValue, forKey: scope.key)
                    } else {
                        userDefaults.set(newValue, forKey: scope.key)
                    }
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

        /// Resets the value to the inital value. If the inital value was `nil`, then the value will be removed from `UserDefaults`
        @MainActor
        public mutating func reset() {
            value = initial()
        }
    }
}
