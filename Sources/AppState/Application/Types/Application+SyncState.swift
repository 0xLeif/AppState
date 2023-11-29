import Foundation

extension Application {
    /// The default `NSUbiquitousKeyValueStore` instance.
    public var icloudStore: Dependency<NSUbiquitousKeyValueStore> {
        dependency(NSUbiquitousKeyValueStore.default)
    }

    /// The `SyncState` struct is a data structure designed to handle the state synchronization of an application that supports the `Codable` type.
    /// It utilizes Apple's iCloud Key-Value Store to propagate state changes across multiple devices.
    public struct SyncState<Value: Codable>: CustomStringConvertible {
        @AppDependency(\.icloudStore) private var icloudStore: NSUbiquitousKeyValueStore

        /// The initial value of the state.
        private var initial: () -> Value

        /// The current state value.
        /// This value is retrieved from the iCloud Key-Value Store or the local cache.
        /// If the value is not found in either, the initial value is returned.
        /// When setting a new value, the value is saved to the iCloud Key-Value Store and the local cache.
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
                    let data = icloudStore.data(forKey: scope.key),
                    let value = try? JSONDecoder().decode(Value.self, from: data)
                else { return initial() }

                return value
            }
            set {
                let mirror = Mirror(reflecting: newValue)

                if mirror.displayStyle == .optional,
                   mirror.children.isEmpty {
                    shared.cache.remove(scope.key)
                    icloudStore.removeObject(forKey: scope.key)
                    icloudStore.synchronize()
                } else {
                    shared.cache.set(
                        value: Application.State(
                            initial: newValue,
                            scope: scope
                        ),
                        forKey: scope.key
                    )

                    do {
                        let data = try JSONEncoder().encode(newValue)
                        icloudStore.set(data, forKey: scope.key)
                        icloudStore.synchronize()
                    } catch {
                        Application.log(
                            error: error,
                            message: "☁️ SyncState failed to encode: \(newValue)",
                            fileID: #fileID,
                            function: #function,
                            line: #line,
                            column: #column
                        )
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

        public var description: String {
            "SyncState<\(Value.self)>(\(value)) (\(scope.key))"
        }

        /// Removes the value from `iCloud` and resets the value to the inital value.
        public mutating func remove() {
            value = initial()
            icloudStore.removeObject(forKey: scope.key)
            icloudStore.synchronize()
        }
    }
}
