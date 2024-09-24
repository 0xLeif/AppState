import Foundation

extension Application {
    /// A struct that provides a thread-safe interface for interacting with `UserDefaults`, allowing the storage,
    /// retrieval, and removal of user preferences and data. This struct is marked as `Sendable`, enabling safe
    /// use in concurrent environments.
    public struct SendableUserDefaults: Sendable {

        /// Retrieves an object from `UserDefaults` for the given key.
        /// - Parameter key: The key used to retrieve the associated value from `UserDefaults`.
        /// - Returns: The value stored in `UserDefaults` for the given key, or `nil` if no value is associated with the key.
        public func object(forKey key: String) -> Any? {
            UserDefaults.standard.object(forKey: key)
        }

        /// Removes the value associated with the specified key from `UserDefaults`.
        /// - Parameter key: The key whose associated value should be removed.
        public func removeObject(forKey key: String) {
            UserDefaults.standard.removeObject(forKey: key)
        }

        /// Sets the value for the specified key in `UserDefaults`.
        /// - Parameters:
        ///   - value: The value to store in `UserDefaults`. Can be `nil` to remove the value associated with the key.
        ///   - key: The key with which to associate the value.
        public func set(_ value: Any?, forKey key: String) {
            UserDefaults.standard.set(value, forKey: key)
        }
    }

    /// The shared `UserDefaults` instance.
    public var userDefaults: Dependency<SendableUserDefaults> {
        dependency(SendableUserDefaults())
    }

    /// `StoredState` encapsulates the value within the application's scope and allows any changes to be propagated throughout the scoped area.  State is stored using `UserDefaults`.
    public struct StoredState<Value: Codable & Sendable>: MutableApplicationState {
        public static var emoji: Character { "💾" }

        @AppDependency(\.userDefaults) private var userDefaults: SendableUserDefaults

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
