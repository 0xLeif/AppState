#if canImport(Security)
import Cache
import Foundation
import os

/**
 A `Keychain` class that adopts the `Cacheable` protocol.

 This class provides a secure method for storing and retrieving string key-value pairs. It leverages Apple's Keychain
 services for secure data storage ensuring that data saved using this `Keychain` class is encrypted and
 kept secure in the device's keychain. It provides methods for getting, setting, and removing values
 associated with a specific key. It also includes methods for throwing errors when specified key(s)
 do not exist and for returning all keys and their associated values.

 Usage Example:

 ```swift
 let keychain = Keychain()

 keychain.set(value: "<TOKEN>", forKey: "token")

 let token = try keychain.resolve("token")
 ```
 */
public final class Keychain: Sendable {
    public typealias Key = String
    public typealias Value = String

    /// Serializes Keychain *write* operations (`set`/`remove`) so multi-call sequences such as
    /// `set`'s update-then-add are atomic. Reads are thread-safe at the system level and stay lock-free.
    private let writeLock: NSLock
    /// The in-memory index of known keys, used by ``values(ofType:)``. Guarded by its own lock so
    /// `Keychain` is `Sendable` without an `@unchecked` escape; the critical sections are short and
    /// never span a Keychain syscall.
    private let index: OSAllocatedUnfairLock<Set<Key>>

    /// Default initializer
    public init() {
        self.writeLock = NSLock()
        self.index = OSAllocatedUnfairLock(initialState: [])
    }

    /**
     Initialize with a predefined set of keys.
     - Parameter keys: The predefined set of keys.
     */
    public init(keys: Set<Key>) {
        self.writeLock = NSLock()
        self.index = OSAllocatedUnfairLock(initialState: keys)
    }

    /**
     Retrieve a value from the keychain for a given key and type.
     - Parameter key: The key to look up in the keychain.
     - Parameter as: The type of the expected output value.
     - Returns: The value from the keychain if it exists, otherwise returns `nil`.
     */
    public func get<Output>(_ key: Key, as: Output.Type) -> Output? {
        let query: [NSString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        // Reads are a single, system-serialized syscall — no AppState-level lock required.
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard
            status == noErr,
            let data = dataTypeRef as? Data,
            let output = String(data: data, encoding: .utf8) as? Output
        else { return nil }

        return output
    }

    /**
     Retrieve a value from the keychain for a given key and type, throwing an error if the value is not found.
     - Parameter key: The key to look up in the keychain.
     - Parameter as: The type of the expected output value.
     - Returns: The value from the keychain.
     - Throws: `MissingRequiredKeysError` if the key is not found.
     */
    public func resolve<Output>(_ key: Key, as: Output.Type) throws -> Output {
        guard let output = get(key, as: Output.self) else {
            throw MissingRequiredKeysError(keys: [key])
        }

        return output
    }

    /**
     Set a value in the keychain for a given key.
     - Parameter value: The value to store in the keychain.
     - Parameter key: The key associated with the value.
     */
    public func set(value: String, forKey key: Key) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [NSString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
        ]

        let updateAttributes: [NSString: Any] = [
            kSecValueData: data
        ]

        // The update/add pair must be atomic: without serialization, two concurrent `set` calls for
        // the same key can both see `errSecItemNotFound` and both attempt `SecItemAdd`.
        writeLock.lock()
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
        writeLock.unlock()

        index.withLock { keys in _ = keys.insert(key) }
    }

    /**
     Remove a value from the keychain for a given key.
     - Parameter key: The key to remove from the keychain.
     */
    public func remove(_ key: Key) {
        let query: [NSString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]

        writeLock.lock()
        SecItemDelete(query as CFDictionary)
        writeLock.unlock()

        index.withLock { keys in _ = keys.remove(key) }
    }

    /**
     Check whether a key exists in the keychain.
     - Parameter key: The key to check for.
     - Returns: `true` if the key exists, `false` otherwise.
     */
    public func contains(_ key: Key) -> Bool {
        get(key, as: String.self) != nil
    }

    /**
     Ensure the specified set of keys exist in the keychain.
     - Parameter keys: The set of keys to check for.
     - Returns: The `Keychain` instance if all keys exist.
     - Throws: `MissingRequiredKeysError` if any key is missing.
     */
    public func require(keys: Set<Key>) throws -> Self {
        let missingKeys = keys
            .filter { contains($0) == false }

        guard missingKeys.isEmpty else {
            throw MissingRequiredKeysError(keys: missingKeys)
        }

        return self
    }

    /**
     Ensure a specific key exists in the keychain.
     - Parameter key: The key to check for.
     - Returns: The `Keychain` instance if the key exists.
     - Throws: `MissingRequiredKeysError` if the key is missing.
     */
    public func require(_ key: Key) throws -> Self {
        try require(keys: [key])
    }

    /**
     Retrieve all keys and their values from the keychain.
     - Parameter ofType: The type of the values expected.
     - Returns: A dictionary with keys and their associated values.
     */
    @MainActor
    public func values<Output>(ofType: Output.Type) -> [Key: Output] {
        // Snapshot the index under its lock, then read each value lock-free. Capturing the snapshot
        // first avoids holding the index lock across Keychain syscalls.
        let storedKeys = index.withLock { Array($0) }
        var values: [Key: Output] = [:]

        for key in storedKeys {
            if let value = get(key, as: Output.self) {
                values[key] = value
            }
        }

        return values
    }
}

public extension Keychain {
    /**
     Retrieve a string value from the keychain for a given key.
     - Parameter key: The key for the value.
     - Returns: Value from the keychain if it exists.
     */
    func get(_ key: Key) -> String? {
        get(key, as: String.self)
    }

    /**
     Retrieve a string value from the keychain for a given key and throws an error if the key is not found.
     - Parameter key: The key for the value.
     - Returns: Value from the keychain.
     - Throws: Error if the value is not found.
     */
    func resolve(_ key: Key) throws -> String {
        try resolve(key, as: String.self)
    }

    /**
     Returns all keys and their string values currently in the keychain.
     - Returns: A dictionary with keys and their corresponding string values.
     */
    @MainActor
    func values() -> [Key: String] {
        values(ofType: String.self)
    }
}
#endif
