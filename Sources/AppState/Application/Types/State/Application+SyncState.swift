#if !os(Linux) && !os(Windows)
import Foundation

@available(watchOS 9.0, *)
extension Application {
    /// A struct that provides a thread-safe interface for interacting with `NSUbiquitousKeyValueStore`,
    /// which synchronizes small amounts of key-value data across the user's iCloud-enabled devices.
    public struct SendableNSUbiquitousKeyValueStore: UbiquitousKeyValueStoreManaging {
        public func data(forKey key: String) -> Data? {
            NSUbiquitousKeyValueStore.default.data(forKey: key)
        }

        public func set(_ value: Data?, forKey key: String) {
            NSUbiquitousKeyValueStore.default.set(value, forKey: key)
        }

        public func removeObject(forKey key: String) {
            NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
        }
    }

    /// The default `NSUbiquitousKeyValueStore` instance.
    public var icloudStore: Dependency<UbiquitousKeyValueStoreManaging> {
        dependency {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didChangeExternally),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: NSUbiquitousKeyValueStore.default
            )

            return SendableNSUbiquitousKeyValueStore()
        }
    }

    /**
     The `SyncState` struct is a data structure designed to handle the state synchronization of an application that supports the `Codable` type.
     It utilizes Apple's iCloud Key-Value Store to propagate state changes across multiple devices.

     Changes your app writes to the key-value store object are initially held in memory, then written to disk by the system at appropriate times. If you write to the key-value store object when the user is not signed into an iCloud account, the data is stored locally until the next synchronization opportunity. When the user signs into an iCloud account, the system automatically reconciles your local, on-disk keys and values with those on the iCloud server.

     The total amount of space available in your app’s key-value store, for a given user, is 1 MB. There is a per-key value size limit of 1 MB, and a maximum of 1024 keys. If you attempt to write data that exceeds these quotas, the write attempt fails and no change is made to your iCloud key-value storage. In this scenario, the system posts the didChangeExternallyNotification notification with a change reason of NSUbiquitousKeyValueStoreQuotaViolationChange.

     - Note: The key-value store is intended for storing data that changes infrequently. As you test your devices, if the app on a device makes frequent changes to the key-value store, the system may defer the synchronization of some changes in order to minimize the number of round trips to the server. The more frequently the app make changes, the more likely the changes will be deferred and will not immediately show up on the other devices.

     The maximum length for key strings for the iCloud key-value store is 64 bytes using UTF8 encoding. Attempting to write a value to a longer key name results in a runtime error.

     To use this class, you must distribute your app through the App Store or Mac App Store, and you must request the com.apple.developer.ubiquity-kvstore-identifier entitlement in your Xcode project.

     - Warning: Avoid using this class for data that is essential to your app’s behavior when offline; instead, store such data directly into the local user defaults database.
     */
    public struct SyncState<Value: Codable & Sendable>: MutableApplicationState {
        public static var emoji: Character { "☁️" }

        @AppDependency(\.icloudStore) private var icloudStore: UbiquitousKeyValueStoreManaging

        /// The initial value of the state.
        private var initial: () -> Value

        /// The scope in which this state exists.
        private let scope: Scope

        /// The fallback state for when icloudStore doesn't have the data.
        private var storedState: StoredState<Value>

        /// The current state value.
        /// This value is retrieved from the iCloud Key-Value Store or the local cache.
        /// If the value is not found in either, the initial value is returned.
        /// When setting a new value, the value is saved to the iCloud Key-Value Store and the local cache.
        public var value: Value {
            get {
                if
                    let data = icloudStore.data(forKey: scope.key),
                    let storedValue = try? JSONDecoder().decode(Value.self, from: data)
                {
                    return storedValue
                }

                return storedState.value
            }
            set {
                let mirror = Mirror(reflecting: newValue)

                if mirror.displayStyle == .optional,
                   mirror.children.isEmpty {
                    storedState.reset()
                    icloudStore.removeObject(forKey: scope.key)
                } else {
                    storedState.value = newValue

                    do {
                        let data = try JSONEncoder().encode(newValue)
                        icloudStore.set(data, forKey: scope.key)
                    } catch {
                        Application.log(
                            error: error,
                            message: "\(SyncState.emoji) SyncState failed to encode: \(newValue)",
                            fileID: #fileID,
                            function: #function,
                            line: #line,
                            column: #column
                        )
                    }
                }
            }
        }


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
            self.storedState = StoredState(initial: initial(), scope: scope)
        }

        /// Resets the value to the inital value. If the inital value was `nil`, then the value will be removed from `iCloud`
        @MainActor
        public mutating func reset() {
            value = initial()
        }
    }
}
#endif
