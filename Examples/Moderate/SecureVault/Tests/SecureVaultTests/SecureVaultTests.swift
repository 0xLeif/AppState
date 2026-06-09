#if !os(Linux) && !os(Windows)
import AppState
import SecureVault
import XCTest

// MARK: - Application + Test Helpers

extension Application {
    /// A dedicated SecureState key used only within the test suite.
    ///
    /// Using a unique feature + id pair prevents state leaking between runs
    /// and avoids collision with production `authToken` Keychain entries.
    fileprivate var testAuthToken: SecureState {
        secureState(feature: "SecureVaultTests", id: "testAuthToken")
    }
}

// MARK: - SecureVaultTests

/// Tests for the Keychain-backed `SecureState` storage layer.
///
/// Every test follows the same pattern used in the AppState library's own
/// `SecureStateTests` and `KeychainTests`: operate on `@MainActor`, load the
/// keychain dependency in `setUp`, and clean up with `Application.reset` in
/// `tearDown` so that no leftover Keychain items pollute subsequent runs.
final class SecureVaultTests: XCTestCase {

    // MARK: - Setup / Teardown

    @MainActor
    override func setUp() async throws {
        Application
            .logging(isEnabled: false)
            .load(dependency: \.keychain)
    }

    @MainActor
    override func tearDown() async throws {
        // Remove any Keychain entry written during the test.
        Application.reset(secureState: \.testAuthToken)
    }

    // MARK: - SecureState Tests

    /// Verifies that the token begins as `nil` before any value is stored.
    @MainActor
    func testAuthTokenInitiallyNil() {
        let value = Application.secureState(\.testAuthToken).value
        XCTAssertNil(value, "authToken should be nil before any value is written")
    }

    /// Verifies that storing a token persists it in the Keychain.
    @MainActor
    func testStoreAndReadToken() {
        var state = Application.secureState(\.testAuthToken)
        state.value = "test-api-token-abc123"

        let retrieved = Application.secureState(\.testAuthToken).value
        XCTAssertEqual(retrieved, "test-api-token-abc123")
    }

    /// Verifies that writing `nil` removes the token from the Keychain.
    @MainActor
    func testClearTokenBySettingNil() {
        var state = Application.secureState(\.testAuthToken)
        state.value = "temporary-token-xyz"

        XCTAssertNotNil(Application.secureState(\.testAuthToken).value)

        state.value = nil

        XCTAssertNil(Application.secureState(\.testAuthToken).value)
    }

    /// Verifies that `Application.reset(secureState:)` clears the Keychain entry.
    @MainActor
    func testResetClearsToken() {
        var state = Application.secureState(\.testAuthToken)
        state.value = "reset-me-token-12345"

        XCTAssertNotNil(Application.secureState(\.testAuthToken).value)

        Application.reset(secureState: \.testAuthToken)

        XCTAssertNil(Application.secureState(\.testAuthToken).value)
    }

    /// Verifies that overwriting with a new token replaces the old one.
    @MainActor
    func testOverwriteToken() {
        var state = Application.secureState(\.testAuthToken)
        state.value = "first-token-abc12345"

        XCTAssertEqual(Application.secureState(\.testAuthToken).value, "first-token-abc12345")

        state.value = "second-token-xyz67890"

        XCTAssertEqual(Application.secureState(\.testAuthToken).value, "second-token-xyz67890")
        XCTAssertNotEqual(Application.secureState(\.testAuthToken).value, "first-token-abc12345")
    }

    // MARK: - AuthService Tests

    /// Verifies that a valid token passes validation and is returned trimmed.
    @MainActor
    func testAuthServiceValidTokenPassesValidation() throws {
        let service = AuthService()
        let result = try service.validate(token: "valid-api-key-12345")
        XCTAssertEqual(result, "valid-api-key-12345")
    }

    /// Verifies that leading/trailing whitespace is stripped during validation.
    @MainActor
    func testAuthServiceTrimsWhitespace() throws {
        let service = AuthService()
        let result = try service.validate(token: "  padded-token-xyz  ")
        XCTAssertEqual(result, "padded-token-xyz")
    }

    /// Verifies that a token shorter than 8 characters throws `AuthError.invalidToken`.
    @MainActor
    func testAuthServiceRejectsShortToken() {
        let service = AuthService()
        XCTAssertThrowsError(try service.validate(token: "short")) { error in
            guard case AuthError.invalidToken = error else {
                return XCTFail("Expected AuthError.invalidToken, got \(error)")
            }
        }
    }

    /// Verifies that `isAuthenticated` returns `false` when no token is stored.
    @MainActor
    func testIsAuthenticatedReturnsFalseWhenNil() {
        let service = AuthService()
        XCTAssertFalse(service.isAuthenticated(storedToken: nil))
    }

    /// Verifies that `isAuthenticated` returns `true` once a token is present.
    @MainActor
    func testIsAuthenticatedReturnsTrueWithToken() {
        let service = AuthService()
        XCTAssertTrue(service.isAuthenticated(storedToken: "some-token-value"))
    }

    // MARK: - Dependency Override Tests

    /// Verifies that `Application.override` lets tests inject a custom `AuthService`.
    @MainActor
    func testAuthServiceDependencyOverride() async {
        let mockService = AuthService(name: "MockAuthService")
        let override = Application.override(\.authService, with: mockService)
        defer { Task { await override.cancel() } }

        let resolved = Application.dependency(\.authService)
        XCTAssertEqual(resolved.name, "MockAuthService")
    }
}
#endif
