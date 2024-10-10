#if !os(Linux) && !os(Windows)
import Foundation

/// A protocol that provides a thread-safe interface for interacting with `NSUbiquitousKeyValueStore`,
/// which synchronizes key-value data across the user's iCloud-enabled devices.
public protocol UbiquitousKeyValueStoreManaging: Sendable {
    /// Retrieves data stored in iCloud for the specified key.
    /// - Parameter key: The key used to retrieve the associated data from the `NSUbiquitousKeyValueStore`.
    /// - Returns: The `Data` object associated with the key, or `nil` if no data is found.
    func data(forKey key: String) -> Data?

    /// Sets a `Data` object for the specified key in iCloud's key-value store.
    /// - Parameters:
    ///   - value: The `Data` object to store. Pass `nil` to remove the data associated with the key.
    ///   - key: The key with which to associate the data.
    func set(_ value: Data?, forKey key: String)

    /// Removes the value associated with the specified key from iCloud's key-value store.
    /// - Parameter key: The key whose associated value should be removed.
    func removeObject(forKey key: String)
}
#endif
