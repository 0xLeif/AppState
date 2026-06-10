import AppState
import Foundation
import XCTest

@testable import SettingsKit

// MARK: - InMemoryUserDefaults

/// A fully in-memory `UserDefaultsManaging` substitute for tests.
///
/// Overriding `\.userDefaults` prevents `StoredState` from ever touching
/// `UserDefaults.standard` or persisting data to disk.
final class InMemoryUserDefaults: UserDefaultsManaging, @unchecked Sendable {

    // MARK: - Properties

    private var storage: [String: Any] = [:]

    // MARK: - UserDefaultsManaging

    func object(forKey key: String) -> Any? {
        storage[key]
    }

    func set(_ value: Any?, forKey key: String) {
        storage[key] = value
    }

    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}

// MARK: - SettingsKitTests

/// Tests for the SettingsKit feature, exercising `Settings`, `Application+Settings`,
/// and `StoredState` / `Slice` APIs headlessly.
///
/// Each test overrides `\.userDefaults` with a fresh in-memory store so that
/// `StoredState` never touches `UserDefaults.standard`.
@MainActor
final class SettingsKitTests: XCTestCase {

    // MARK: - Properties

    private var userDefaultsOverride: Application.DependencyOverride?

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()

        userDefaultsOverride = Application.override(
            \.userDefaults,
            with: InMemoryUserDefaults() as UserDefaultsManaging
        )

        Application.reset(storedState: \.settings)
    }

    override func tearDown() async throws {
        Application.reset(storedState: \.settings)

        await userDefaultsOverride?.cancel()
        userDefaultsOverride = nil

        try await super.tearDown()
    }

    // MARK: - Settings model tests

    func testDefaultSettingsValues() {
        let settings = Settings.default
        XCTAssertFalse(settings.isDarkMode)
        XCTAssertEqual(settings.fontSize, 16)
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertEqual(settings.username, "Guest")
    }

    func testSettingsEquality() {
        let first = Settings(isDarkMode: true, fontSize: 18, notificationsEnabled: false, username: "Alice")
        let second = Settings(isDarkMode: true, fontSize: 18, notificationsEnabled: false, username: "Alice")
        XCTAssertEqual(first, second)
    }

    func testSettingsInequality() {
        let first = Settings.default
        let second = Settings(isDarkMode: true)
        XCTAssertNotEqual(first, second)
    }

    // MARK: - Application+Settings coverage

    func testApplicationSettingsReturnsStoredState() {
        let stored = Application.storedState(\.settings)
        XCTAssertEqual(stored.value, Settings.default)
    }

    // MARK: - StoredState read/write tests

    func testStoredStateDefaultValue() {
        let stored = Application.storedState(\.settings)
        XCTAssertEqual(stored.value, Settings.default)
    }

    func testStoredStateWriteAndRead() {
        var stored = Application.storedState(\.settings)
        let updated = Settings(isDarkMode: true, fontSize: 20, notificationsEnabled: false, username: "Leif")
        stored.value = updated

        let retrieved = Application.storedState(\.settings)
        XCTAssertEqual(retrieved.value, updated)
    }

    func testStoredStateIndividualFieldMutation() {
        var stored = Application.storedState(\.settings)
        stored.value.isDarkMode = true
        stored.value.username = "TestUser"

        let retrieved = Application.storedState(\.settings)
        XCTAssertTrue(retrieved.value.isDarkMode)
        XCTAssertEqual(retrieved.value.username, "TestUser")
        XCTAssertEqual(retrieved.value.fontSize, 16)
        XCTAssertTrue(retrieved.value.notificationsEnabled)
    }

    // MARK: - Reset tests

    func testResetRestoresDefault() {
        var stored = Application.storedState(\.settings)
        stored.value = Settings(isDarkMode: true, fontSize: 24, notificationsEnabled: false, username: "Changed")

        Application.reset(storedState: \.settings)

        let afterReset = Application.storedState(\.settings)
        XCTAssertEqual(afterReset.value, Settings.default)
    }

    func testResetIsIdempotent() {
        Application.reset(storedState: \.settings)
        Application.reset(storedState: \.settings)
        let stored = Application.storedState(\.settings)
        XCTAssertEqual(stored.value, Settings.default)
    }

    // MARK: - Slice tests

    func testWritableSliceIsDarkMode() {
        var darkModeSlice = Application.slice(\.settings, \.isDarkMode)
        XCTAssertFalse(darkModeSlice.value)

        darkModeSlice.value = true

        XCTAssertTrue(Application.slice(\.settings, \.isDarkMode).value)
        XCTAssertTrue(Application.storedState(\.settings).value.isDarkMode)
    }

    func testWritableSliceFontSize() {
        var fontSizeSlice = Application.slice(\.settings, \.fontSize)
        XCTAssertEqual(fontSizeSlice.value, 16)

        fontSizeSlice.value = 22

        XCTAssertEqual(Application.slice(\.settings, \.fontSize).value, 22)
        XCTAssertEqual(Application.storedState(\.settings).value.fontSize, 22)
    }

    func testWritableSliceUsername() {
        var usernameSlice = Application.slice(\.settings, \.username)
        XCTAssertEqual(usernameSlice.value, "Guest")

        usernameSlice.value = "0xLeif"

        XCTAssertEqual(Application.slice(\.settings, \.username).value, "0xLeif")
        XCTAssertEqual(Application.storedState(\.settings).value.username, "0xLeif")
    }

    func testWritableSliceNotificationsEnabled() {
        var notificationsSlice = Application.slice(\.settings, \.notificationsEnabled)
        XCTAssertTrue(notificationsSlice.value)

        notificationsSlice.value = false

        XCTAssertFalse(Application.slice(\.settings, \.notificationsEnabled).value)
        XCTAssertFalse(Application.storedState(\.settings).value.notificationsEnabled)
    }

    func testMultipleSlicesAreIndependent() {
        var isDarkModeSlice = Application.slice(\.settings, \.isDarkMode)
        var fontSizeSlice = Application.slice(\.settings, \.fontSize)

        isDarkModeSlice.value = true
        fontSizeSlice.value = 28

        XCTAssertTrue(Application.slice(\.settings, \.isDarkMode).value)
        XCTAssertEqual(Application.slice(\.settings, \.fontSize).value, 28)

        let full = Application.storedState(\.settings).value
        XCTAssertTrue(full.isDarkMode)
        XCTAssertEqual(full.fontSize, 28)
        XCTAssertTrue(full.notificationsEnabled)
        XCTAssertEqual(full.username, "Guest")
    }

    // MARK: - Settings custom init tests

    func testSettingsCustomInitAllFields() {
        let settings = Settings(
            isDarkMode: true,
            fontSize: 20,
            notificationsEnabled: false,
            username: "Custom"
        )
        XCTAssertTrue(settings.isDarkMode)
        XCTAssertEqual(settings.fontSize, 20)
        XCTAssertFalse(settings.notificationsEnabled)
        XCTAssertEqual(settings.username, "Custom")
    }

    func testSettingsCodableRoundTrip() throws {
        let original = Settings(isDarkMode: true, fontSize: 24, notificationsEnabled: false, username: "RoundTrip")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Settings.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
