import XCTest
import AppState
@testable import SwiftDataExampleLib

#if canImport(SwiftData)
import SwiftData

// MARK: - SwiftDataExampleTests

/// Tests for the SwiftDataExample library, exercising `TodoItem`, `TodoStore`,
/// the `Application` extensions, and the `makeInMemoryTodoContainer()` factory.
///
/// Each test obtains a fresh in-memory `ModelContainer` override so tests are
/// fully isolated from one another and from the shared application state.
@MainActor
final class SwiftDataExampleTests: XCTestCase {

    // MARK: - Properties

    private var containerOverride: Application.DependencyOverride?

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        containerOverride = Application.override(
            \.modelContainer,
            with: makeInMemoryTodoContainer()
        )
        // Start each test with a completely empty store.
        Application.modelState(\.todos).deleteAll()
    }

    override func tearDown() async throws {
        Application.modelState(\.todos).deleteAll()
        await containerOverride?.cancel()
        containerOverride = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func todoState() -> Application.ModelState<TodoItem> {
        Application.modelState(\.todos)
    }

    // MARK: - Tests: makeInMemoryTodoContainer

    func testMakeInMemoryTodoContainerReturnsContainer() {
        let container = makeInMemoryTodoContainer()
        XCTAssertNotNil(container)
    }

    func testMakeInMemoryTodoContainerIsInMemory() {
        // Two separately created containers should produce independent stores,
        // confirming each is a fresh in-memory instance.
        let containerA = makeInMemoryTodoContainer()
        let containerB = makeInMemoryTodoContainer()

        let contextA = containerA.mainContext
        let contextB = containerB.mainContext

        contextA.insert(TodoItem(title: "Only in A"))
        XCTAssertNoThrow(try contextA.save())

        let fetchedInB = (try? contextB.fetch(FetchDescriptor<TodoItem>())) ?? []
        XCTAssertTrue(fetchedInB.isEmpty, "Container B must not share data with container A")
    }

    func testMakeInMemoryTodoContainerSucceeds() {
        // Exercises the success path of makeInMemoryTodoContainer(). The `catch`/`fatalError` trap
        // is a defensive, structurally-uncoverable branch (see the factory's docs).
        let container = makeInMemoryTodoContainer()
        XCTAssertNotNil(container)
    }

    // MARK: - Tests: Application extensions

    func testApplicationModelContainerDependencyIsAccessible() {
        // Accessing the dependency must not crash.
        let container = Application.dependency(\.modelContainer)
        XCTAssertNotNil(container)
    }

    func testApplicationTodosModelStateIsAccessible() {
        let state = Application.modelState(\.todos)
        // A fresh container holds no items.
        XCTAssertTrue(state.models.isEmpty)
    }

    // MARK: - Tests: TodoItem model

    func testTodoItemDefaultIsDoneFalse() {
        let item = TodoItem(title: "Default")
        XCTAssertFalse(item.isDone)
    }

    func testTodoItemCustomInitialiser() {
        let item = TodoItem(title: "Custom", isDone: true)
        XCTAssertEqual(item.title, "Custom")
        XCTAssertTrue(item.isDone)
    }

    func testTodoItemPropertiesAreMutable() {
        let item = TodoItem(title: "Mutable")
        item.title = "Changed"
        item.isDone = true
        XCTAssertEqual(item.title, "Changed")
        XCTAssertTrue(item.isDone)
    }

    // MARK: - Tests: ModelState insert

    func testModelStateInsertAddsItem() {
        let state = todoState()
        state.insert(TodoItem(title: "Inserted"))
        XCTAssertEqual(state.models.count, 1)
    }

    func testModelStateInsertSetsTitle() {
        let state = todoState()
        state.insert(TodoItem(title: "Buy milk"))
        XCTAssertEqual(state.models.first?.title, "Buy milk")
    }

    func testModelStateInsertMultipleItems() {
        let state = todoState()
        state.insert(TodoItem(title: "A"))
        state.insert(TodoItem(title: "B"))
        state.insert(TodoItem(title: "C"))
        XCTAssertEqual(state.models.count, 3)
    }

    // MARK: - Tests: ModelState delete

    func testModelStateDeleteRemovesItem() {
        let state = todoState()
        let item = TodoItem(title: "To delete")
        state.insert(item)
        XCTAssertEqual(state.models.count, 1)

        state.delete(item)
        XCTAssertTrue(state.models.isEmpty)
    }

    func testModelStateDeleteOnlyRemovesTargetItem() {
        let state = todoState()
        let keep = TodoItem(title: "Keep")
        let remove = TodoItem(title: "Remove")
        state.insert(keep)
        state.insert(remove)

        state.delete(remove)

        XCTAssertEqual(state.models.count, 1)
        XCTAssertEqual(state.models.first?.title, "Keep")
    }

    // MARK: - Tests: ModelState save

    func testModelStateSaveDoesNotThrow() {
        let state = todoState()
        state.insert(TodoItem(title: "Saved"))
        // Calling save() a second time (no pending changes) must not crash.
        state.save()
        state.save()
        XCTAssertEqual(state.models.count, 1)
    }

    func testModelStateSavePersistsMutation() {
        let state = todoState()
        state.insert(TodoItem(title: "Mutate me"))
        guard let item = state.models.first else {
            return XCTFail("Expected one item after insert")
        }
        item.isDone = true
        state.save()
        XCTAssertTrue(state.models.first?.isDone == true)
    }

    // MARK: - Tests: ModelState deleteAll

    func testModelStateDeleteAllClearsStore() {
        let state = todoState()
        state.insert(TodoItem(title: "One"))
        state.insert(TodoItem(title: "Two"))
        state.insert(TodoItem(title: "Three"))

        state.deleteAll()

        XCTAssertTrue(state.models.isEmpty)
    }

    func testModelStateDeleteAllOnEmptyStoreIsNoOp() {
        let state = todoState()
        // Must not crash when the store is already empty.
        state.deleteAll()
        XCTAssertTrue(state.models.isEmpty)
    }

    // MARK: - Tests: ModelState context

    func testModelStateContextIsMainContext() {
        let state = todoState()
        let container = Application.dependency(\.modelContainer)
        // The context exposed by ModelState must be the container's main context.
        XCTAssertTrue(state.context === container.mainContext)
    }

    // MARK: - Tests: TodoStore

    func testTodoStoreInitialisesEmpty() {
        let store = TodoStore()
        XCTAssertTrue(store.todos.isEmpty)
    }

    func testTodoStoreAddInsertsItem() {
        let store = TodoStore()
        store.add("Wash dishes")
        XCTAssertEqual(store.todos.count, 1)
        XCTAssertEqual(store.todos.first?.title, "Wash dishes")
    }

    func testTodoStoreAddMultipleItems() {
        let store = TodoStore()
        store.add("Alpha")
        store.add("Beta")
        store.add("Gamma")
        XCTAssertEqual(store.todos.count, 3)
    }

    func testTodoStoreAddDefaultsIsDoneToFalse() {
        let store = TodoStore()
        store.add("Pending")
        XCTAssertFalse(store.todos.first?.isDone ?? true)
    }

    func testTodoStoreSavePersistsMutation() {
        let store = TodoStore()
        store.add("Mark done")
        guard let item = store.todos.first else {
            return XCTFail("Expected one item after add")
        }
        item.isDone = true
        store.save()
        XCTAssertTrue(store.todos.first?.isDone == true)
    }

    func testTodoStoreSaveOnCleanContextIsNoOp() {
        let store = TodoStore()
        store.add("No mutation")
        store.save() // no pending changes after insert already saved
        store.save() // second save must not crash
        XCTAssertEqual(store.todos.count, 1)
    }

    func testTodoStoreSharesContainerWithApplicationState() {
        // Inserts made via `TodoStore.add` must be visible through `Application.modelState`.
        let store = TodoStore()
        store.add("Shared item")

        let appItems = Application.modelState(\.todos).models
        XCTAssertEqual(appItems.count, 1)
        XCTAssertEqual(appItems.first?.title, "Shared item")
    }

    func testApplicationStateInsertsVisibleInTodoStore() {
        // Inserts made via `Application.modelState` must be visible through `TodoStore`.
        Application.modelState(\.todos).insert(TodoItem(title: "App-level insert"))

        let store = TodoStore()
        XCTAssertEqual(store.todos.count, 1)
        XCTAssertEqual(store.todos.first?.title, "App-level insert")
    }

    func testDeleteViaApplicationStateVisibleInStore() {
        let store = TodoStore()
        store.add("Will be deleted")
        guard let item = Application.modelState(\.todos).models.first else {
            return XCTFail("Expected one item")
        }
        Application.modelState(\.todos).delete(item)
        XCTAssertTrue(store.todos.isEmpty)
    }

    func testDeleteAllViaApplicationStateVisibleInStore() {
        let store = TodoStore()
        store.add("Item 1")
        store.add("Item 2")
        Application.modelState(\.todos).deleteAll()
        XCTAssertTrue(store.todos.isEmpty)
    }
}

#endif
