#if !os(Linux) && !os(Windows)
import XCTest
@testable import AppState

final class KeychainTests: XCTestCase {
    @MainActor
    func testKeychainInitKeys() async throws {
        let keychain = Keychain(keys: ["key"])

        XCTAssertThrowsError(try keychain.resolve("key"))
    }

    @MainActor
    func testKeychainInitValues() async throws {
        let keychain = Keychain(keys: ["key"])

        keychain.set(value: "abc", forKey: "key")

        let value = try keychain.resolve("key")

        XCTAssertEqual(value, "abc")

        keychain.remove("key")
    }

    @MainActor
    func testKeychainContains() async throws {
        let keychain = Keychain()

        XCTAssertFalse(keychain.contains("key"))

        keychain.set(value: "abc", forKey: "key")

        XCTAssertTrue(keychain.contains("key"))

        keychain.remove("key")
    }

    @MainActor
    func testKeychainRequiresSuccess() async throws {
        let keychain = Keychain(keys: ["key"])

        keychain.set(value: "abs", forKey: "key")

        XCTAssertNoThrow(try keychain.require("key"))

        keychain.remove("key")
    }

    @MainActor
    func testKeychainRequiresFailure() async throws {
        let keychain = Keychain()

        XCTAssertThrowsError(try keychain.require("key"))
    }

    @MainActor
    func testKeychainValues() async throws {
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

    /// A `get` beside a `remove` of the same key used to deadlock inside Security.framework, because
    /// `get` did not take the lock that `set` and `remove` hold. Two instances are used on purpose:
    /// they share one system keychain, so the lock must cover both.
    func testConcurrentGetSetRemoveOfSameKeyReturns() {
        let writer = Keychain()
        let reader = Keychain()
        let key = "keychainSameKey_\(UUID().uuidString)"
        defer { writer.remove(key) }

        DispatchQueue.concurrentPerform(iterations: 600) { iteration in
            switch iteration % 3 {
            case 0: writer.set(value: "value_\(iteration)", forKey: key)
            case 1: _ = reader.get(key)
            default: writer.remove(key)
            }
        }

        writer.set(value: "sentinel", forKey: key)
        XCTAssertEqual(reader.get(key), "sentinel")
    }
}
#endif
