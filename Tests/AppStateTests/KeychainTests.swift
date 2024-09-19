#if !os(Linux) && !os(Windows)
import XCTest
@testable import AppState

@MainActor
final class KeychainTests: XCTestCase {
    func testKeychainInitKeys() throws {
        let keychain = Keychain(keys: ["key"])
        
        XCTAssertThrowsError(try keychain.resolve("key"))
    }
    
    func testKeychainInitValues() throws {
        let keychain = Keychain(keys: ["key"])
        
        keychain.set(value: "abc", forKey: "key")
        
        let value = try keychain.resolve("key")
        
        XCTAssertEqual(value, "abc")
        
        keychain.remove("key")
    }
    
    func testKeychainContains() throws {
        let keychain = Keychain()
        
        XCTAssertFalse(keychain.contains("key"))
        
        keychain.set(value: "abc", forKey: "key")
        
        XCTAssertTrue(keychain.contains("key"))
        
        keychain.remove("key")
    }
    
    func testKeychainRequiresSuccess() throws {
        let keychain = Keychain(keys: ["key"])
        
        keychain.set(value: "abs", forKey: "key")
        
        XCTAssertNoThrow(try keychain.require("key"))
        
        keychain.remove("key")
    }
    
    func testKeychainRequiresFailure() throws {
        let keychain = Keychain()
        
        XCTAssertThrowsError(try keychain.require("key"))
    }
    
    func testKeychainValues() throws {
        let keychain = Keychain(keys: ["key"])
        
        keychain.set(value: "abc", forKey: "key")
        
        let values = keychain.values()
        let secureValue = keychain.get("key")
        
        XCTAssertEqual(values.count, 1)
        XCTAssertNotNil(secureValue)
        XCTAssertEqual(secureValue, "abc")
        
        keychain.remove("key")
        
        XCTAssertEqual(keychain.values().count, 0)
        XCTAssertNil(keychain.get("key"))
    }
}
#endif
