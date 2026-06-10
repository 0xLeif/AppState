#if canImport(SwiftUI) && !os(Linux) && !os(Windows)
import AppState
import SwiftUI
import ViewInspector
import XCTest

@testable import SecureVault

// MARK: - VaultViewTests

/// Exercises the SwiftUI layer (`VaultView`, `LoginView`, `DashboardView`) with
/// ViewInspector so that every view body, branch, and action closure is covered.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@MainActor
final class VaultViewTests: XCTestCase {

    // MARK: - Properties

    private var authServiceOverride: Application.DependencyOverride?

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        Application
            .logging(isEnabled: false)
            .load(dependency: \.keychain)
        Application.reset(secureState: \.authToken)
    }

    override func tearDown() async throws {
        Application.reset(secureState: \.authToken)
        await authServiceOverride?.cancel()
        authServiceOverride = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    /// Writes `token` into the `authToken` SecureState so the authenticated branch renders.
    private func setAuthToken(_ token: String?) {
        if let token {
            var state = Application.secureState(\.authToken)
            state.value = token
        } else {
            Application.reset(secureState: \.authToken)
        }
    }

    // MARK: - Tests: VaultView routing

    /// `VaultView` renders `LoginView` when no token is stored.
    func testVaultViewShowsLoginViewWhenSignedOut() throws {
        setAuthToken(nil)

        let sut = VaultView()

        XCTAssertNoThrow(try sut.inspect().find(LoginView.self))
    }

    /// `VaultView` renders `DashboardView` when a token is stored.
    func testVaultViewShowsDashboardViewWhenSignedIn() throws {
        setAuthToken("valid-api-token-xyz1")

        let sut = VaultView()

        XCTAssertNoThrow(try sut.inspect().find(DashboardView.self))
    }

    // MARK: - Tests: Application+SecureVault authToken accessor

    /// Directly accessing `Application.secureState(\.authToken)` exercises the `authToken`
    /// accessor in `Application+SecureVault.swift`, covering its otherwise-missed region.
    func testApplicationAuthTokenAccessorIsReadable() {
        let secureState = Application.secureState(\.authToken)
        XCTAssertNil(secureState.value)
    }

    // MARK: - Tests: LoginView body

    /// `LoginView` always renders the "SecureVault" title text.
    func testLoginViewRendersTitle() throws {
        let sut = LoginView()

        XCTAssertNoThrow(try sut.inspect().find(text: "SecureVault"))
    }

    /// `LoginView` always renders the instructional subtitle.
    func testLoginViewRendersSubtitle() throws {
        let sut = LoginView()

        XCTAssertNoThrow(try sut.inspect().find(text: "Enter your API token to continue."))
    }

    /// `LoginView` contains a `SecureField` for token entry.
    func testLoginViewContainsSecureField() throws {
        let sut = LoginView()

        XCTAssertNoThrow(try sut.inspect().find(ViewType.SecureField.self))
    }

    /// "Sign In" button is disabled when `tokenInput` is empty (initial state).
    func testSignInButtonDisabledWhenTokenInputEmpty() throws {
        // No tokenInput provided → defaults to "", button must be disabled.
        let sut = LoginView()
        let button = try sut.inspect().find(button: "Sign In")

        XCTAssertTrue(try button.isDisabled())
    }

    /// "Sign In" button is enabled when `tokenInput` is non-empty.
    ///
    /// Pre-populate `tokenInput` via the internal initializer so the view
    /// body evaluates with a non-empty string without needing SwiftUI hosting.
    func testSignInButtonEnabledWhenTokenInputNonEmpty() throws {
        let sut = LoginView(tokenInput: "some-token-value-here")
        let button = try sut.inspect().find(button: "Sign In")

        XCTAssertFalse(try button.isDisabled())
    }

    /// Tapping "Sign In" with a valid token stores it in the Keychain via `authToken`.
    func testSignInWithValidTokenStoresAuthToken() throws {
        let sut = LoginView(tokenInput: "valid-api-token-xyz1")

        try sut.inspect().find(button: "Sign In").tap()

        XCTAssertEqual(Application.secureState(\.authToken).value, "valid-api-token-xyz1")
    }

    /// Tapping "Sign In" with a short (invalid) token executes the error path in `signIn()`.
    ///
    /// The `errorMessage` `@State` mutation happens inside the action closure but is not
    /// observable via headless `inspect()` after the tap.  We verify coverage of the error
    /// path by confirming that `authToken` is NOT stored (error branch does not set it).
    func testSignInWithShortTokenLeavesAuthTokenNil() throws {
        // "short" is only 5 chars — fails AuthService.validate, executes the catch branch.
        let sut = LoginView(tokenInput: "short")

        try sut.inspect().find(button: "Sign In").tap()

        // The error path never writes authToken.
        XCTAssertNil(Application.secureState(\.authToken).value)
    }

    /// A `LoginView` constructed with a pre-existing `errorMessage` renders that error text,
    /// covering the `if let errorMessage` true branch in `LoginView.body`.
    func testLoginViewRendersErrorMessageWhenSet() throws {
        let sut = LoginView(
            tokenInput: "",
            errorMessage: "Invalid token: previous failure"
        )

        XCTAssertNoThrow(try sut.inspect().find(ViewType.Text.self, where: { text in
            (try? text.string())?.contains("Invalid token") == true
        }))
    }

    /// After a successful sign-in, `authToken` is stored, exercising `errorMessage = nil`
    /// (the `errorMessage` reset in the success branch of `signIn()`).
    func testSignInSuccessPathSetsAuthToken() throws {
        let sut = LoginView(
            tokenInput: "valid-api-token-clear",
            errorMessage: "Invalid token: previous failure"
        )

        try sut.inspect().find(button: "Sign In").tap()

        // Success path ran: authToken stored, errorMessage = nil executed.
        XCTAssertEqual(
            Application.secureState(\.authToken).value,
            "valid-api-token-clear"
        )
    }

    /// Tapping "Sign In" trims leading/trailing whitespace before storing the token.
    func testSignInTrimmedTokenIsStored() throws {
        let sut = LoginView(tokenInput: "  padded-token-abcdef  ")

        try sut.inspect().find(button: "Sign In").tap()

        XCTAssertEqual(Application.secureState(\.authToken).value, "padded-token-abcdef")
    }

    /// Tapping "Sign In" when the injected `AuthService` throws a non-`AuthError` exercises
    /// the generic `catch error` fallback branch inside `LoginView.signIn()`.
    func testSignInWithNonAuthErrorExercisesGenericCatchBranch() throws {
        // Inject a custom validator that throws URLError — not an AuthError.
        let throwingService = AuthService(
            name: "ThrowingAuthService",
            customValidator: { _ in throw URLError(.unknown) }
        )
        authServiceOverride = Application.override(\.authService, with: throwingService)

        // A non-empty token bypasses the disabled modifier so the button is tappable.
        let sut = LoginView(tokenInput: "anything-valid-length")

        // tap() invokes signIn() → customValidator throws URLError → generic catch fires.
        try sut.inspect().find(button: "Sign In").tap()

        // The generic catch never writes authToken.
        XCTAssertNil(Application.secureState(\.authToken).value)
    }

    // MARK: - Tests: DashboardView body

    /// `DashboardView` renders the "Vault Unlocked" heading.
    func testDashboardViewRendersTitle() throws {
        setAuthToken("valid-api-token-xyz1")

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().find(text: "Vault Unlocked"))
    }

    /// `DashboardView` shows a redacted token in the GroupBox when signed in with a long token.
    ///
    /// A token longer than 8 characters triggers the `prefix...suffix` redaction path.
    func testDashboardViewShowsRedactedLongToken() throws {
        setAuthToken("abcd1234efgh")

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().find(text: "abcd...efgh"))
    }

    /// `DashboardView` shows all-asterisks for a short token (≤ 8 characters).
    ///
    /// A token with `count <= 8` triggers the `String(repeating:count:)` path in `redacted`.
    func testDashboardViewShowsAsterisksForShortToken() throws {
        // Write the token directly to bypass AuthService minimum-length validation.
        var state = Application.secureState(\.authToken)
        state.value = "short"

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().find(text: "*****"))
    }

    /// `DashboardView` contains a "Sign Out" button.
    func testDashboardViewContainsSignOutButton() throws {
        setAuthToken("valid-api-token-xyz1")

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().find(button: "Sign Out"))
    }

    /// Tapping "Sign Out" clears the `authToken` from the Keychain.
    func testSignOutClearsAuthToken() throws {
        setAuthToken("valid-api-token-xyz1")
        XCTAssertNotNil(Application.secureState(\.authToken).value)

        let sut = DashboardView()
        try sut.inspect().find(button: "Sign Out").tap()

        XCTAssertNil(Application.secureState(\.authToken).value)
    }

    /// `DashboardView` renders the "Vault Unlocked" heading even when `authToken` is nil,
    /// covering the false branch of the `if let token = authToken` conditional.
    func testDashboardViewWithNilTokenRendersHeadingOnly() throws {
        Application.reset(secureState: \.authToken)

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().find(text: "Vault Unlocked"))
        // GroupBox is absent when there is no token.
        XCTAssertThrowsError(try sut.inspect().find(ViewType.GroupBox.self))
    }

    // MARK: - Tests: AuthError.errorDescription

    /// `AuthError.invalidToken` formats its error description correctly.
    func testAuthErrorInvalidTokenDescription() {
        let error = AuthError.invalidToken(reason: "Token must be at least 8 characters.")

        XCTAssertEqual(
            error.errorDescription,
            "Invalid token: Token must be at least 8 characters."
        )
    }

    /// `AuthError` conforms to `LocalizedError` — `localizedDescription` delegates through `errorDescription`.
    func testAuthErrorLocalizedDescription() {
        let error = AuthError.invalidToken(reason: "Too short.")

        XCTAssertEqual(error.localizedDescription, "Invalid token: Too short.")
    }
}
#endif
