import Cache
import Foundation

public class Keychain: Cacheable {
    public typealias Key = String
    public typealias Value = String

    private let lock: NSLock
    private var keys: Set<Key>

    public init() {
        self.lock = NSLock()
        self.keys = []
    }

    public init(keys: Set<Key>) {
        self.lock = NSLock()
        self.keys = keys
    }

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
            kSecValueData: data
        ]

        lock.lock()
        SecItemAdd(query as CFDictionary, nil)
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
    func get(_ key: Key) -> String? {
        get(key, as: String.self)
    }

    func resolve(_ key: Key) throws -> String {
        try resolve(key, as: String.self)
    }

    func values() -> [Key: String] {
        values(ofType: String.self)
    }
}
