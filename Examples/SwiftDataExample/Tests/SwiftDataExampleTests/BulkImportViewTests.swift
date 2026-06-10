import XCTest
import AppState
@testable import SwiftDataExampleLib

#if canImport(SwiftData) && canImport(SwiftUI) && !os(Linux) && !os(Windows)
import SwiftData
import SwiftUI
import ViewInspector

// MARK: - BulkImportViewTests

/// ViewInspector tests for `BulkImportView`.
///
/// These tests verify the static structure of the view — that the generate button, cancel
/// button, and progress indicator elements are present — without exercising the live import
/// flow. The live import is covered by `BulkImporterTests`.
@MainActor
final class BulkImportViewTests: XCTestCase {

    // MARK: - Properties

    private var containerOverride: Application.DependencyOverride?

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        containerOverride = Application.override(
            \.labContainer,
            with: makeInMemoryLabContainer()
        )
    }

    override func tearDown() async throws {
        await containerOverride?.cancel()
        containerOverride = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    /// Returns a freshly rendered `BulkImportView` with a small `targetCount` for speed.
    private func makeSUT(targetCount: Int = 100) -> BulkImportView {
        BulkImportView(targetCount: targetCount)
    }

    // MARK: - Tests: Generate Button

    func testGenerateButtonIsPresent() throws {
        let sut = makeSUT()
        // The generate button contains the label "Generate" somewhere in its hierarchy.
        XCTAssertNoThrow(try sut.inspect().find(button: "Generate 100"))
    }

    func testGenerateButtonIsEnabledInitially() throws {
        let sut = makeSUT()
        let button = try sut.inspect().find(button: "Generate 100")
        XCTAssertFalse(try button.isDisabled(),
                       "Generate button must be enabled when no import is running")
    }

    // MARK: - Tests: Cancel Button

    func testCancelButtonIsPresent() throws {
        let sut = makeSUT()
        XCTAssertNoThrow(try sut.inspect().find(button: "Cancel"))
    }

    func testCancelButtonIsDisabledInitially() throws {
        let sut = makeSUT()
        let button = try sut.inspect().find(button: "Cancel")
        XCTAssertTrue(try button.isDisabled(),
                      "Cancel button must be disabled when no import is running")
    }

    // MARK: - Tests: Progress Indicator

    func testProgressViewIsPresent() throws {
        let sut = makeSUT()
        XCTAssertNoThrow(try sut.inspect().find(ViewType.ProgressView.self))
    }

    // MARK: - Tests: Status Text

    func testReadyStatusTextIsShownInitially() throws {
        let sut = makeSUT()
        XCTAssertNoThrow(try sut.inspect().find(text: "Ready"))
    }

    // MARK: - Tests: View Hierarchy Structure

    func testViewIsWrappedInNavigationStack() throws {
        let sut = makeSUT()
        // `BulkImportView.body` must root in a NavigationStack.
        XCTAssertNoThrow(try sut.inspect().navigationStack())
    }

    func testVStackExistsInsideNavigationStack() throws {
        let sut = makeSUT()
        XCTAssertNoThrow(try sut.inspect().navigationStack().vStack())
    }

    // MARK: - Tests: Progress Counter Text

    func testProgressCounterTextIsPresent() throws {
        let sut = makeSUT(targetCount: 200)
        // The counter label shows "0 / 200 inserted" at rest.
        XCTAssertNoThrow(try sut.inspect().find(text: "0 / 200 inserted"))
    }

    func testPercentageTextStartsAtZero() throws {
        let sut = makeSUT()
        XCTAssertNoThrow(try sut.inspect().find(text: "0%"))
    }

    // MARK: - Tests: Responsiveness Demo Section

    func testUIResponsivenessDemoLabelIsPresent() throws {
        let sut = makeSUT()
        XCTAssertNoThrow(try sut.inspect().find(text: "UI Responsiveness Demo"))
    }

    // MARK: - Tests: Custom Target Count

    func testCustomTargetCountAppearsInGenerateButtonLabel() throws {
        let sut = BulkImportView(targetCount: 500)
        XCTAssertNoThrow(try sut.inspect().find(button: "Generate 500"))
    }

    func testDefaultTargetCountIsNicelyFormatted() throws {
        let sut = BulkImportView()
        // Default is 10,000 — formatted with thousands separator.
        XCTAssertNoThrow(try sut.inspect().find(button: "Generate 10,000"))
    }
}

#endif
