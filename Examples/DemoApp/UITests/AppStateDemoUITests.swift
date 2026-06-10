import XCTest

// MARK: - AppStateDemoUITests

/// End-to-end UI tests that drive the AppState demo app through the real SwiftUI UI on a simulator:
/// launch the app, navigate into every example, interact with the controls, and assert the on-screen
/// result. These complement the per-package ViewInspector unit tests with true UICTest coverage.
final class AppStateDemoUITests: XCTestCase {

    // MARK: - Catalog row labels

    private enum Row {
        static let todoCloud = "TodoCloud — @SyncState"
        static let settingsKit = "SettingsKit — @StoredState + @Slice"
        static let dataDashboard = "DataDashboard — Dependency injection"
        static let secureVault = "SecureVault — @SecureState"
        static let syncNotes = "SyncNotes — @SyncState"
        static let tracker = "MultiPlatformTracker — @StoredState"
        static let swiftDataLab = "SwiftData Lab — relationships, queries, migration"
        static let breakIt = "Break It — try to crash AppState"

        static let all = [
            todoCloud, settingsKit, dataDashboard, secureVault,
            syncNotes, tracker, swiftDataLab, breakIt,
        ]
    }

    // MARK: - Lifecycle

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
    }

    // MARK: - Helpers

    /// Taps a catalog row, optionally scrolling it into view first.
    private func openExample(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = app.buttons[label]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Catalog row '\(label)' not found", file: file, line: line)
        if !row.isHittable {
            app.swipeUp()
        }
        row.tap()
    }

    /// Returns to the catalog from a pushed screen via the back button.
    private func goBack() {
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists {
            back.tap()
        }
    }

    private func assertOnCatalog(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            app.staticTexts["AppState 3.0.0"].waitForExistence(timeout: 5),
            "Expected to be on the catalog screen",
            file: file,
            line: line
        )
    }

    // MARK: - Catalog

    func testCatalogListsEveryExample() {
        assertOnCatalog()
        for row in Row.all {
            let element = app.buttons[row]
            if !element.exists {
                app.swipeUp()
            }
            XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing catalog row: \(row)")
        }
    }

    /// The "everything is reachable" guarantee — every example pushes a screen and returns cleanly.
    func testEveryScreenIsReachable() {
        // Each probe resolves a distinctive element on the destination screen. TrackerView has no
        // navigation title, so it is probed by its increment button instead of a nav bar.
        let probes: [(row: String, marker: () -> XCUIElement)] = [
            (Row.todoCloud, { self.app.navigationBars["TodoCloud"] }),
            (Row.settingsKit, { self.app.navigationBars["Settings"] }),
            (Row.dataDashboard, { self.app.navigationBars["Dashboard"] }),
            (Row.syncNotes, { self.app.navigationBars["SyncNotes"] }),
            (Row.tracker, { self.app.buttons["Increment count"] }),
            (Row.breakIt, { self.app.navigationBars["Break It"] }),
        ]
        for probe in probes {
            openExample(probe.row)
            XCTAssertTrue(
                probe.marker().waitForExistence(timeout: 8),
                "Screen for '\(probe.row)' did not load its expected element"
            )
            goBack()
            assertOnCatalog()
        }
    }

    // MARK: - TodoCloud (@SyncState)

    func testTodoCloudAddsTodo() {
        openExample(Row.todoCloud)

        let field = app.textFields["New todo…"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        let title = "UITest todo \(Int.random(in: 1000...9999))"
        field.typeText(title)

        app.buttons["Add"].firstMatch.tap()

        XCTAssertTrue(
            app.staticTexts[title].waitForExistence(timeout: 5),
            "Added todo '\(title)' did not appear"
        )
    }

    // MARK: - SettingsKit (@StoredState + @Slice)

    func testSettingsKitTogglesDarkMode() {
        openExample(Row.settingsKit)

        let toggle = app.switches["Dark Mode"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))

        let before = (toggle.value as? String) ?? ""
        // Tap the switch control on the trailing edge of the row, not the label in the center.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()

        // Wait for the bound StoredState to flip the switch value.
        let changed = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in (toggle.value as? String) != before },
            object: nil
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [changed], timeout: 5),
            .completed,
            "Dark Mode toggle did not change state"
        )
    }

    // MARK: - SyncNotes (@SyncState)

    func testSyncNotesAddsNote() {
        openExample(Row.syncNotes)

        let field = app.textFields["New note…"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        let note = "UITest note \(Int.random(in: 1000...9999))"
        field.typeText(note)

        app.buttons["Add"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts[note].waitForExistence(timeout: 5), "Note '\(note)' did not appear")
    }

    // MARK: - MultiPlatformTracker (@StoredState)

    func testMultiPlatformTrackerIncrements() {
        openExample(Row.tracker)

        let increment = app.buttons["Increment count"]
        XCTAssertTrue(increment.waitForExistence(timeout: 5))

        increment.tap()
        increment.tap()

        // Tap reset to return to a known state, then verify a fresh increment reads "1".
        app.buttons["Reset"].tap()
        increment.tap()
        XCTAssertTrue(app.staticTexts["1"].waitForExistence(timeout: 5), "Counter did not read 1 after reset+increment")
    }

    // MARK: - SecureVault (@SecureState / Keychain)

    func testSecureVaultLoginAndLogout() {
        openExample(Row.secureVault)

        // Ensure a logged-out starting point.
        let signOut = app.buttons["Sign Out"]
        if signOut.waitForExistence(timeout: 3) {
            signOut.tap()
        }

        let tokenField = app.secureTextFields["API Token"]
        XCTAssertTrue(tokenField.waitForExistence(timeout: 5))
        tokenField.tap()
        tokenField.typeText("valid-token-1234567890")

        app.buttons["Sign In"].tap()

        XCTAssertTrue(
            app.staticTexts["Vault Unlocked"].waitForExistence(timeout: 5),
            "Vault did not unlock after sign in"
        )

        app.buttons["Sign Out"].tap()
        XCTAssertTrue(
            app.buttons["Sign In"].waitForExistence(timeout: 5),
            "Did not return to the sign-in screen after sign out"
        )
    }

    // MARK: - DataDashboard (dependency injection)

    func testDataDashboardLoadsMetrics() {
        openExample(Row.dataDashboard)
        XCTAssertTrue(app.navigationBars["Dashboard"].waitForExistence(timeout: 5))

        // The async loader populates the grid; a "Last updated" footer appears once loaded.
        let footer = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Last updated'")).firstMatch
        XCTAssertTrue(footer.waitForExistence(timeout: 10), "Dashboard metrics did not load")
    }

    // MARK: - SwiftData Lab (relationships, queries, migration)

    func testSwiftDataLabCreatesList() {
        openExample(Row.swiftDataLab)

        let field = app.textFields["New list…"]
        XCTAssertTrue(field.waitForExistence(timeout: 8), "SwiftData Lab list field not found")
        field.tap()
        let listName = "UITest list \(Int.random(in: 1000...9999))"
        field.typeText(listName)

        app.buttons["Add"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts[listName].waitForExistence(timeout: 5), "Created list '\(listName)' did not appear")
    }

    // MARK: - Break It (stress)

    func testBreakItSurvivesStress() {
        openExample(Row.breakIt)
        XCTAssertTrue(app.navigationBars["Break It"].waitForExistence(timeout: 5))

        app.buttons["Hammer @AppState ×100k"].tap()

        // The status row updates to a "✓ …" summary; the app must remain responsive.
        let survived = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '✓'")).firstMatch
        XCTAssertTrue(survived.waitForExistence(timeout: 10), "Break It workload did not report a result")
    }
}
