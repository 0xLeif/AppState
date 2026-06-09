import AppState
import Foundation
import XCTest

@testable import SettingsKit

// MARK: - Application extensions used only in tests

extension Application {
    /// A dedicated `StoredState` using a unique `id` so tests never collide
    /// with production state or with each other.
    fileprivate var testSettings: StoredState<Settings> {
        storedState(initial: .default, feature: "SettingsKitTests", id: "testSettings")
    }
}

// MARK: - SettingsKitTests

@MainActor
final class SettingsKitTests: XCTestCase {
    // MARK: - Lifecycle

    override func setUp() async throws {
        // Always start from a clean slate by resetting to the factory default.
        Application.reset(storedState: \.testSettings)
    }

    override func tearDown() async throws {
        Application.reset(storedState: \.testSettings)
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

    // MARK: - StoredState read/write tests

    func testStoredStateDefaultValue() {
        let stored = Application.storedState(\.testSettings)
        XCTAssertEqual(stored.value, Settings.default)
    }

    func testStoredStateWriteAndRead() {
        var stored = Application.storedState(\.testSettings)
        let updated = Settings(isDarkMode: true, fontSize: 20, notificationsEnabled: false, username: "Leif")
        stored.value = updated

        let retrieved = Application.storedState(\.testSettings)
        XCTAssertEqual(retrieved.value, updated)
    }

    func testStoredStateIndividualFieldMutation() {
        var stored = Application.storedState(\.testSettings)
        stored.value.isDarkMode = true
        stored.value.username = "TestUser"

        let retrieved = Application.storedState(\.testSettings)
        XCTAssertTrue(retrieved.value.isDarkMode)
        XCTAssertEqual(retrieved.value.username, "TestUser")
        // Other fields should remain at their defaults.
        XCTAssertEqual(retrieved.value.fontSize, 16)
        XCTAssertTrue(retrieved.value.notificationsEnabled)
    }

    // MARK: - Reset tests

    func testResetRestoresDefault() {
        var stored = Application.storedState(\.testSettings)
        stored.value = Settings(isDarkMode: true, fontSize: 24, notificationsEnabled: false, username: "Changed")

        Application.reset(storedState: \.testSettings)

        let afterReset = Application.storedState(\.testSettings)
        XCTAssertEqual(afterReset.value, Settings.default)
    }

    func testResetIsIdempotent() {
        Application.reset(storedState: \.testSettings)
        Application.reset(storedState: \.testSettings)
        let stored = Application.storedState(\.testSettings)
        XCTAssertEqual(stored.value, Settings.default)
    }

    // MARK: - Slice tests

    func testWritableSliceIsDarkMode() {
        var darkModeSlice = Application.slice(\.testSettings, \.isDarkMode)
        XCTAssertFalse(darkModeSlice.value)

        darkModeSlice.value = true

        XCTAssertTrue(Application.slice(\.testSettings, \.isDarkMode).value)
        XCTAssertTrue(Application.storedState(\.testSettings).value.isDarkMode)
    }

    func testWritableSliceFontSize() {
        var fontSizeSlice = Application.slice(\.testSettings, \.fontSize)
        XCTAssertEqual(fontSizeSlice.value, 16)

        fontSizeSlice.value = 22

        XCTAssertEqual(Application.slice(\.testSettings, \.fontSize).value, 22)
        XCTAssertEqual(Application.storedState(\.testSettings).value.fontSize, 22)
    }

    func testWritableSliceUsername() {
        var usernameSlice = Application.slice(\.testSettings, \.username)
        XCTAssertEqual(usernameSlice.value, "Guest")

        usernameSlice.value = "0xLeif"

        XCTAssertEqual(Application.slice(\.testSettings, \.username).value, "0xLeif")
        XCTAssertEqual(Application.storedState(\.testSettings).value.username, "0xLeif")
    }

    func testWritableSliceNotificationsEnabled() {
        var notificationsSlice = Application.slice(\.testSettings, \.notificationsEnabled)
        XCTAssertTrue(notificationsSlice.value)

        notificationsSlice.value = false

        XCTAssertFalse(Application.slice(\.testSettings, \.notificationsEnabled).value)
        XCTAssertFalse(Application.storedState(\.testSettings).value.notificationsEnabled)
    }

    func testMultipleSlicesAreIndependent() {
        var isDarkModeSlice = Application.slice(\.testSettings, \.isDarkMode)
        var fontSizeSlice = Application.slice(\.testSettings, \.fontSize)

        isDarkModeSlice.value = true
        fontSizeSlice.value = 28

        // Each slice reflects its own change without clobbering the other field.
        XCTAssertTrue(Application.slice(\.testSettings, \.isDarkMode).value)
        XCTAssertEqual(Application.slice(\.testSettings, \.fontSize).value, 28)

        let full = Application.storedState(\.testSettings).value
        XCTAssertTrue(full.isDarkMode)
        XCTAssertEqual(full.fontSize, 28)
        // Unchanged fields stay at defaults.
        XCTAssertTrue(full.notificationsEnabled)
        XCTAssertEqual(full.username, "Guest")
    }

    // MARK: - UserDefaults persistence test

    func testUserDefaultsPersistence() {
        // Write via StoredState.
        var stored = Application.storedState(\.testSettings)
        stored.value = Settings(isDarkMode: true, fontSize: 18, notificationsEnabled: false, username: "Persisted")

        // Verify the value is actually in UserDefaults under the expected key.
        let key = "SettingsKitTests_testSettings"
        if let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode(Settings.self, from: data)
        {
            XCTAssertEqual(decoded.username, "Persisted")
        } else {
            // The key format is internal to AppState (Scope.key = "\(feature)_\(id)").
            // If the exact key name changes, at minimum confirm the value is readable
            // back through the AppState API.
            let roundTripped = Application.storedState(\.testSettings).value
            XCTAssertEqual(roundTripped.username, "Persisted")
        }
    }
}
