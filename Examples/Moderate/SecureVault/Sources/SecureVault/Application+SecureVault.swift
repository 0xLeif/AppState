#if !os(Linux) && !os(Windows)
import AppState
import Foundation

// MARK: - Application + SecureVault

extension Application {

    // MARK: - SecureState

    /// The Keychain-backed auth token for the current user.
    ///
    /// A `nil` value indicates the user is signed out. Writing `nil` removes
    /// the entry from the Keychain via `Application.reset(secureState:)`.
    public var authToken: SecureState {
        secureState(feature: "SecureVault", id: "authToken")
    }

    // MARK: - Dependency

    /// The shared `AuthService` dependency injected through the `Application`.
    ///
    /// Override this in tests via `Application.override(\.authService, with:)`
    /// to supply a custom implementation without touching production Keychain data.
    public var authService: Dependency<AuthService> {
        dependency(AuthService(), feature: "SecureVault", id: "authService")
    }
}
#endif
