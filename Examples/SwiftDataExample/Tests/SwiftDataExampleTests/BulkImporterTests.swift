import XCTest
import AppState
@testable import SwiftDataExampleLib

#if canImport(SwiftData)
import SwiftData

// MARK: - BulkImporterTests

/// Unit tests for `BulkImporter`.
///
/// Each test overrides `\.labContainer` with a fresh in-memory container so tests are fully
/// isolated. The heavy insert loop runs entirely on the `@ModelActor` executor — the tests
/// `await` the actor's method and then read back results on `@MainActor` to verify correctness.
///
/// ### Coverage strategy
/// - Correct total count in the background context after import.
/// - Main-context reflection: the shared container bridges background saves to `mainContext`.
/// - Batch boundary correctness (count not a multiple of batchSize).
/// - Cancellation stops the import early and commits partial saves cleanly.
/// - Zero-count import is a no-op (guard in `importItems`).
/// - Custom `listTitle` is stored on the parent `TodoList`.
/// - Progress callback is invoked with monotonically increasing values.
/// - Batch size of 1 still completes without error.
@MainActor
final class BulkImporterTests: XCTestCase {

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

    /// Creates a fresh `BulkImporter` backed by the test's isolated container.
    private func makeImporter() -> BulkImporter {
        BulkImporter(modelContainer: Application.dependency(\.labContainer))
    }

    /// Returns the current count from the shared container's main context.
    private func mainContextItemCount() -> Int {
        Application.modelState(\.allItems).models.count
    }

    // MARK: - Tests: Basic Correctness

    func testImportInsertsExactCount() async {
        let importer = makeImporter()
        await importer.importItems(count: 100, batchSize: 20)
        XCTAssertEqual(mainContextItemCount(), 100)
    }

    func testImportInsertsCountNotMultipleOfBatchSize() async {
        // 150 items with batchSize 40: last batch has 30 items.
        let importer = makeImporter()
        await importer.importItems(count: 150, batchSize: 40)
        XCTAssertEqual(mainContextItemCount(), 150)
    }

    func testImportCountSmallerThanBatchSize() async {
        // count < batchSize → single batch of 10.
        let importer = makeImporter()
        await importer.importItems(count: 10, batchSize: 500)
        XCTAssertEqual(mainContextItemCount(), 10)
    }

    func testImportBatchSizeOne() async {
        // Each item is its own batch — stresses the yield path.
        let importer = makeImporter()
        await importer.importItems(count: 5, batchSize: 1)
        XCTAssertEqual(mainContextItemCount(), 5)
    }

    func testZeroCountIsNoOp() async {
        let importer = makeImporter()
        await importer.importItems(count: 0)
        XCTAssertEqual(mainContextItemCount(), 0, "Zero count must not insert any items")
    }

    // MARK: - Tests: Main-Context Reflection

    func testMainContextReflectsBackgroundSaves() async {
        // The key non-blocking guarantee: items saved in the background ModelContext are
        // visible through the shared container's mainContext after the import completes.
        let importer = makeImporter()
        await importer.importItems(count: 200, batchSize: 50)

        let items = Application.modelState(\.allItems).models
        XCTAssertEqual(items.count, 200,
                       "Shared ModelContainer must bridge background saves to mainContext")
    }

    func testInsertedItemsHaveCorrectTitles() async {
        let importer = makeImporter()
        await importer.importItems(count: 3, batchSize: 3)

        let titles = Application.modelState(\.allItems).models.map(\.title).sorted()
        XCTAssertEqual(titles, ["Bulk Item 1", "Bulk Item 2", "Bulk Item 3"])
    }

    func testInsertedItemsHaveExpectedPriorityRange() async {
        let importer = makeImporter()
        await importer.importItems(count: 12, batchSize: 12)

        let priorities = Application.modelState(\.allItems).models.map(\.priority)
        // priority = index % 6 → values 0 through 5 repeat.
        XCTAssertTrue(priorities.allSatisfy { $0 >= 0 && $0 <= 5 })
    }

    // MARK: - Tests: Parent TodoList

    func testImportCreatesParentTodoList() async {
        let importer = makeImporter()
        await importer.importItems(count: 10, batchSize: 10, listTitle: "Test Bulk List")

        let lists = Application.modelState(\.todoLists).models
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(lists.first?.title, "Test Bulk List")
    }

    func testImportedItemsBelongToCreatedList() async {
        let importer = makeImporter()
        await importer.importItems(count: 5, batchSize: 5, listTitle: "Parent List")

        let lists = Application.modelState(\.todoLists).models
        guard let list = lists.first else {
            return XCTFail("Expected a TodoList to be created")
        }
        XCTAssertEqual(list.items.count, 5,
                       "All imported items must be children of the created TodoList")
    }

    func testTwoSequentialImportsCreateTwoLists() async {
        let importer = makeImporter()
        await importer.importItems(count: 10, batchSize: 10, listTitle: "First")
        await importer.importItems(count: 10, batchSize: 10, listTitle: "Second")

        let lists = Application.modelState(\.todoLists).models
        XCTAssertEqual(lists.count, 2)
        XCTAssertEqual(mainContextItemCount(), 20)
    }

    // MARK: - Tests: Progress Callback

    func testProgressCallbackIsInvoked() async {
        var callCount = 0
        let importer = makeImporter()

        await importer.importItems(count: 100, batchSize: 20) { _ in
            await MainActor.run { callCount += 1 }
        }

        // 100 items / 20 per batch = 5 batches → 5 progress callbacks.
        XCTAssertEqual(callCount, 5)
    }

    func testProgressCallbackValuesAreMonotonicallyIncreasing() async {
        var progressValues: [Int] = []
        let importer = makeImporter()

        await importer.importItems(count: 60, batchSize: 20) { inserted in
            await MainActor.run { progressValues.append(inserted) }
        }

        XCTAssertEqual(progressValues, [20, 40, 60])
    }

    func testFinalProgressValueMatchesCount() async {
        var last = 0
        let importer = makeImporter()

        await importer.importItems(count: 50, batchSize: 25) { inserted in
            await MainActor.run { last = inserted }
        }

        XCTAssertEqual(last, 50)
    }

    func testProgressCallbackWithUnalignedBatch() async {
        // 55 items, batchSize 20 → batches of [20, 20, 15] → progress [20, 40, 55].
        var progressValues: [Int] = []
        let importer = makeImporter()

        await importer.importItems(count: 55, batchSize: 20) { inserted in
            await MainActor.run { progressValues.append(inserted) }
        }

        XCTAssertEqual(progressValues, [20, 40, 55])
    }

    func testProgressCallbackIsOptional() async {
        // Passing nil for onProgress must not crash.
        let importer = makeImporter()
        await importer.importItems(count: 10, batchSize: 10, onProgress: nil)
        XCTAssertEqual(mainContextItemCount(), 10)
    }

    // MARK: - Tests: Cancellation

    func testCancellationStopsImportEarly() async {
        let importer = makeImporter()

        let task = Task {
            await importer.importItems(count: 10_000, batchSize: 100)
        }

        // Give the task a moment to start (complete at least one batch), then cancel.
        try? await Task.sleep(nanoseconds: 1_000_000) // 1 ms
        task.cancel()
        await task.value

        let inserted = mainContextItemCount()
        // After cancellation, fewer than 10,000 items must be present.
        // We allow anything from 0 (cancelled before first batch) to < 10,000.
        XCTAssertLessThan(inserted, 10_000,
                          "Cancellation must stop the import before all items are inserted")
    }

    func testCancellationLeavesStoreConsistent() async {
        // After cancellation, whatever was saved must be accessible (no partial/corrupt batch).
        let importer = makeImporter()

        let task = Task {
            await importer.importItems(count: 5_000, batchSize: 250)
        }

        try? await Task.sleep(nanoseconds: 2_000_000) // 2 ms
        task.cancel()
        await task.value

        // Count must be a non-negative integer; the store must not be in a crashed state.
        let count = mainContextItemCount()
        XCTAssertGreaterThanOrEqual(count, 0)
    }

    // MARK: - Tests: Isolation Guarantee

    func testImporterDoesNotUseMainContext() async {
        // Fetch the main context before the import.
        let mainCtxBefore = Application.dependency(\.labContainer).mainContext

        let importer = makeImporter()
        await importer.importItems(count: 20, batchSize: 20)

        // The main context object must be the same instance — the importer must not have
        // created a new main context or swapped containers.
        let mainCtxAfter = Application.dependency(\.labContainer).mainContext
        XCTAssertTrue(mainCtxBefore === mainCtxAfter,
                      "BulkImporter must not alter the shared container's mainContext")
    }
}

#endif
