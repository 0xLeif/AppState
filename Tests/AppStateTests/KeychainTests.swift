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
}
#endif
