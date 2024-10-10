/// A protocol that provides a thread-safe interface for interacting with `UserDefaults`,
/// allowing the storage, retrieval, and removal of user preferences and data.
public protocol UserDefaultsManaging: Sendable {
    /// Retrieves an object from `UserDefaults` for the given key.
    /// - Parameter key: The key used to retrieve the associated value from `UserDefaults`.
    /// - Returns: The value stored in `UserDefaults` for the given key, or `nil` if no value is associated with the key.
    func object(forKey key: String) -> Any?

    /// Removes the value associated with the specified key from `UserDefaults`.
    /// - Parameter key: The key whose associated value should be removed.
    func removeObject(forKey key: String)

    /// Sets the value for the specified key in `UserDefaults`.
    /// - Parameters:
    ///   - value: The value to store in `UserDefaults`. Can be `nil` to remove the value associated with the key.
    ///   - key: The key with which to associate the value.
    func set(_ value: Any?, forKey key: String)
}
