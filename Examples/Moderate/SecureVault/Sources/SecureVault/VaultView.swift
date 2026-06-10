#if canImport(SwiftUI) && !os(Linux) && !os(Windows)
import AppState
import SwiftUI

// MARK: - VaultView

/// The top-level credential-vault view.
///
/// Displays a `LoginView` when no token is stored in the Keychain, and a
/// `DashboardView` once the user has successfully signed in.
public struct VaultView: View {

    // MARK: - State

    /// The Keychain-backed auth token.  `nil` means the user is signed out.
    @SecureState(\.authToken) private var authToken: String?

    // MARK: - Initializers

    /// Creates a `VaultView`.
    public init() {}

    // MARK: - Body

    public var body: some View {
        Group {
            if authToken != nil {
                DashboardView()
            } else {
                LoginView()
            }
        }
    }
}

// MARK: - LoginView

/// Collects a token from the user and stores it securely in the Keychain.
struct LoginView: View {

    // MARK: - State

    @SecureState(\.authToken) private var authToken: String?
    @State var tokenInput: String
    @State var errorMessage: String?

    private let authService = Application.dependency(\.authService)

    // MARK: - Initializers

    /// Creates a `LoginView` with an optional pre-populated token input.
    ///
    /// - Parameter tokenInput: The initial value for the token input field.
    ///   Defaults to an empty string (standard sign-in presentation).
    init(tokenInput: String = "", errorMessage: String? = nil) {
        _tokenInput = State(wrappedValue: tokenInput)
        _errorMessage = State(wrappedValue: errorMessage)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            Text("SecureVault")
                .font(.largeTitle)
                .bold()

            Text("Enter your API token to continue.")
                .foregroundStyle(.secondary)

            SecureField("API Token", text: $tokenInput)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button("Sign In") {
                signIn()
            }
            .buttonStyle(.borderedProminent)
            .disabled(tokenInput.isEmpty)
        }
        .padding()
    }

    // MARK: - Private Methods

    @MainActor
    private func signIn() {
        do {
            let validated = try authService.validate(token: tokenInput)
            authToken = validated
            errorMessage = nil
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - DashboardView

/// Displays the stored token summary and lets the user sign out.
struct DashboardView: View {

    // MARK: - State

    @SecureState(\.authToken) private var authToken: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            Text("Vault Unlocked")
                .font(.title)
                .bold()

            if let token = authToken {
                GroupBox("Stored Token") {
                    Text(redacted(token: token))
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
            }

            Button("Sign Out", role: .destructive) {
                signOut()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Private Methods

    /// Masks the middle portion of the token for display purposes.
    private func redacted(token: String) -> String {
        guard token.count > 8 else { return String(repeating: "*", count: token.count) }
        let prefix = token.prefix(4)
        let suffix = token.suffix(4)
        return "\(prefix)...\(suffix)"
    }

    @MainActor
    private func signOut() {
        Application.reset(secureState: \.authToken)
    }
}

// MARK: - Previews

#Preview("Signed Out") {
    VaultView()
}

#Preview("Signed In") {
    Application.preview(
        Application.override(\.authService, with: AuthService(name: "Preview"))
    ) {
        VaultView()
    }
}
#endif
