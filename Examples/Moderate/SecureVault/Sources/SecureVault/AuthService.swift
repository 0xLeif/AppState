import Foundation

// MARK: - AuthService

/// Encapsulates authentication operations for the credential vault.
///
/// The service itself is a pure value type; all persistent state lives in
/// `Application.SecureState` (Keychain-backed) so tests can reset cleanly.
///
/// An optional `customValidator` closure allows tests and previews to inject
/// alternative validation logic — for example, to exercise the generic `catch`
/// branch in `LoginView.signIn()`.
public struct AuthService: Sendable {

    // MARK: - Properties

    /// A short human-readable label for this service, used in log messages.
    public let name: String

    /// An optional custom validator.  When non-nil it replaces the built-in
    /// minimum-length check, enabling tests to inject any `Error` type.
    public let customValidator: (@Sendable (String) throws -> String)?

    // MARK: - Initializers

    /// Creates an `AuthService` with a given display name.
    ///
    /// - Parameters:
    ///   - name: A label identifying this service instance.
    ///   - customValidator: An optional closure that overrides the built-in
    ///     validation rule.  Pass `nil` (the default) to use the standard
    ///     eight-character minimum-length check.
    public init(
        name: String = "SecureVaultAuthService",
        customValidator: (@Sendable (String) throws -> String)? = nil
    ) {
        self.name = name
        self.customValidator = customValidator
    }

    // MARK: - Public Methods

    /// Validates a raw credential string before it is stored in the vault.
    ///
    /// If a `customValidator` was provided at initialisation time it is
    /// invoked instead of the built-in rule, allowing callers to inject
    /// arbitrary error types.
    ///
    /// - Parameter token: The raw credential to validate.
    /// - Returns: The trimmed token on success.
    /// - Throws: `AuthError.invalidToken` when the token does not meet the
    ///           minimum-length requirement (built-in rule), or any error
    ///           thrown by the `customValidator` closure.
    public func validate(token: String) throws -> String {
        if let customValidator {
            return try customValidator(token)
        }

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
