import Foundation

// MARK: - AuthService

/// Encapsulates authentication operations for the credential vault.
///
/// The service itself is a pure value type; all persistent state lives in
/// `Application.SecureState` (Keychain-backed) so tests can reset cleanly.
public struct AuthService: Sendable {

    // MARK: - Properties

    /// A short human-readable label for this service, used in log messages.
    public let name: String

    // MARK: - Initializers

    /// Creates an `AuthService` with a given display name.
    ///
    /// - Parameter name: A label identifying this service instance.
    public init(name: String = "SecureVaultAuthService") {
        self.name = name
    }

    // MARK: - Public Methods

    /// Validates a raw credential string before it is stored in the vault.
    ///
    /// The rule is intentionally simple: a token must be non-empty and at
    /// least eight characters long so test cases can exercise the error path.
    ///
    /// - Parameter token: The raw credential to validate.
    /// - Returns: The trimmed token on success.
    /// - Throws: `AuthError.invalidToken` when the token does not meet the
    ///           minimum-length requirement.
    public func validate(token: String) throws -> String {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 8 else {
            throw AuthError.invalidToken(reason: "Token must be at least 8 characters.")
        }

        return trimmed
    }

    /// Returns `true` when a non-nil, non-empty token is currently stored.
    ///
    /// - Parameter storedToken: The current value read from `SecureState`.
    public func isAuthenticated(storedToken: String?) -> Bool {
        guard let token = storedToken else { return false }
        return !token.isEmpty
    }
}

// MARK: - AuthError

/// Errors that `AuthService` operations can produce.
public enum AuthError: Error, LocalizedError, Sendable {
    /// The supplied token did not pass validation.
    case invalidToken(reason: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidToken(let reason):
            return "Invalid token: \(reason)"
        }
    }
}
