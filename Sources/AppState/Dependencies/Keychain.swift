#if !os(Linux) && !os(Windows)
import Cache
import Foundation

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
public class Keychain: Cacheable {
    public typealias Key = String
    public typealias Value = String
    
    private let lock: NSLock
    private var keys: Set<Key>
    
    /// Default initializer
    public init() {
        self.lock = NSLock()
        self.keys = []
    }
    
    /**
     Initialize with a predefined set of keys.
     - Parameter keys: The predefined set of keys.
     */
    public init(keys: Set<Key>) {
        self.lock = NSLock()
        self.keys = keys
    }
    
    /**
     Initialize a new instance with key-value pairs.
     - Parameter initialValues: The key-value pairs to add to the keychain.
     */
    public required init(initialValues: [Key: String]) {
        self.lock = NSLock()
        self.keys = []
        
        for (key, value) in initialValues {
            set(value: value, forKey: key)
        }
    }
    
    public func get<Output>(_ key: Key, as: Output.Type) -> Output? {
        let query: [NSString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        
        lock.lock()
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        lock.unlock()
        
        guard
            status == noErr,
            let data = dataTypeRef as? Data,
            let output = String(data: data, encoding: .utf8) as? Output
        else { return nil }
        
        return output
    }
    
    public func resolve<Output>(_ key: Key, as: Output.Type) throws -> Output {
        guard let output = get(key, as: Output.self) else {
            throw MissingRequiredKeysError(keys: [key])
        }
        
        return output
    }
    
    public func set(value: String, forKey key: Key) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [NSString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
        ]
        
        let updateAttributes: [NSString: Any] = [
            kSecValueData: data
        ]
        
        lock.lock()
        
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
        
        keys.insert(key)
        
        lock.unlock()
    }
    
    public func remove(_ key: Key) {
        let query: [NSString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        
        lock.lock()
        SecItemDelete(query as CFDictionary)
        lock.unlock()
    }
    
    public func contains(_ key: Key) -> Bool {
        get(key, as: String.self) != nil
    }
    
    public func require(keys: Set<Key>) throws -> Self {
        let missingKeys = keys
            .filter { contains($0) == false }
        
        guard missingKeys.isEmpty else {
            throw MissingRequiredKeysError(keys: missingKeys)
        }
        
        return self
    }
    
    public func require(_ key: Key) throws -> Self {
        try require(keys: [key])
    }
    
    public func values<Output>(ofType: Output.Type) -> [Key: Output] {
        let storedKeys: [Key]
        var values: [Key: Output] = [:]
        
        lock.lock()
        storedKeys = Array(keys)
        lock.unlock()
        
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
    func values() -> [Key: String] {
        values(ofType: String.self)
    }
}
#endif
