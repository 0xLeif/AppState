import XCTest
import AppState
@testable import SwiftDataExampleLib

#if canImport(SwiftData)
import SwiftData

// MARK: - SwiftDataExampleTests (legacy TodoItem model)

/// Retained for backward compatibility — exercises the original `TodoItem` shape
/// (which is now `LabSchemaV2.TodoItem` via the `TodoItem` typealias).
///
/// Each test overrides `\.labContainer` with a fresh in-memory container so that
/// tests are fully isolated from one another.
///
/// ### Uncoverable branches
/// The `catch`/`fatalError` paths inside `makeInMemoryLabContainer()`,
/// `makeInMemoryV1Container()`, and `makeInMemoryMigratedContainer()` cannot be
/// reached by tests — SwiftData raises uncatchable `NSException`s for container
/// failures (not Swift errors), so exercising those paths would crash the test runner
/// rather than letting XCTest catch a thrown error. They are the single
/// deliberately-uncovered regions in this module.
@MainActor
final class SwiftDataExampleTests: XCTestCase {

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
        // The container override installed in setUp() is fresh per test;
        // cancelling it discards the entire in-memory store, so explicit deleteAll() calls
        // are unnecessary here and would produce CoreData constraint-violation noise.
        await containerOverride?.cancel()
        containerOverride = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func itemState() -> Application.ModelState<TodoItem> {
        Application.modelState(\.allItems)
    }

    private func tagState() -> Application.ModelState<Tag> {
        Application.modelState(\.allTags)
    }

    private func listState() -> Application.ModelState<TodoList> {
        Application.modelState(\.todoLists)
    }

    // MARK: - Tests: Container factories

    func testMakeInMemoryLabContainerReturnsContainer() {
        XCTAssertNotNil(makeInMemoryLabContainer())
    }

    func testTwoLabContainersAreIndependent() {
        let a = makeInMemoryLabContainer()
        let b = makeInMemoryLabContainer()
        let ctxA = a.mainContext
        ctxA.insert(TodoItem(title: "Only in A"))
        XCTAssertNoThrow(try ctxA.save())
        let fetched = (try? b.mainContext.fetch(FetchDescriptor<TodoItem>())) ?? []
        XCTAssertTrue(fetched.isEmpty, "Containers must be independent")
    }

    func testMakeInMemoryV1ContainerReturnsContainer() {
        XCTAssertNotNil(makeInMemoryV1Container())
    }

    func testMakeInMemoryMigratedContainerReturnsContainer() {
        XCTAssertNotNil(makeInMemoryMigratedContainer())
    }

    // MARK: - Tests: Application extensions

    func testLabContainerDependencyIsAccessible() {
        XCTAssertNotNil(Application.dependency(\.labContainer))
    }

    func testTodoListsModelStateIsAccessible() {
        XCTAssertTrue(listState().models.isEmpty)
    }

    func testAllItemsModelStateIsAccessible() {
        XCTAssertTrue(itemState().models.isEmpty)
    }

    func testAllTagsModelStateIsAccessible() {
        XCTAssertTrue(tagState().models.isEmpty)
    }

    // MARK: - Tests: TodoItem model (V2 shape)

    func testTodoItemDefaultsIsDoneFalse() {
        XCTAssertFalse(TodoItem(title: "Default").isDone)
    }

    func testTodoItemDefaultPriorityIsZero() {
        XCTAssertEqual(TodoItem(title: "P").priority, 0)
    }

    func testTodoItemDefaultDueDateIsNil() {
        XCTAssertNil(TodoItem(title: "D").dueDate)
    }

    func testTodoItemCustomInit() {
        let due = Date(timeIntervalSince1970: 1_000_000)
        let item = TodoItem(title: "Custom", isDone: true, priority: 3, dueDate: due)
        XCTAssertEqual(item.title, "Custom")
        XCTAssertTrue(item.isDone)
        XCTAssertEqual(item.priority, 3)
        XCTAssertEqual(item.dueDate, due)
    }

    func testTodoItemPropertiesAreMutable() {
        let item = TodoItem(title: "Mutable")
        item.title = "Changed"
        item.isDone = true
        item.priority = 5
        XCTAssertEqual(item.title, "Changed")
        XCTAssertTrue(item.isDone)
        XCTAssertEqual(item.priority, 5)
    }
}

// MARK: - RelationshipTests

/// Tests exercising the `TodoList → TodoItem` (cascade) and `TodoItem ↔ Tag` (nullify)
/// relationships.
@MainActor
final class RelationshipTests: XCTestCase {

    private var containerOverride: Application.DependencyOverride?

    override func setUp() async throws {
        try await super.setUp()
        containerOverride = Application.override(\.labContainer, with: makeInMemoryLabContainer())
    }

    override func tearDown() async throws {
        await containerOverride?.cancel()
        containerOverride = nil
        try await super.tearDown()
    }

    // MARK: - One-to-many: TodoList → items

    func testAddingItemToListPopulatesRelationship() {
        let store = TodoListStore()
        store.createList(titled: "Groceries")
        guard let list = store.lists.first else {
            return XCTFail("Expected a list")
        }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Milk")
        XCTAssertEqual(list.items.count, 1)
        XCTAssertEqual(list.items.first?.title, "Milk")
    }

    func testItemBelongsToItsParentList() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Work")
        guard let list = listStore.lists.first else {
            return XCTFail("Expected a list")
        }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Deploy")
        guard let item = list.items.first else {
            return XCTFail("Expected an item")
        }
        XCTAssertTrue(item.list === list)
    }

    func testMultipleItemsInOneList() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Shopping")
        guard let list = listStore.lists.first else {
            return XCTFail("Expected a list")
        }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Eggs")
        itemStore.addItem(titled: "Butter")
        itemStore.addItem(titled: "Cheese")
        XCTAssertEqual(list.items.count, 3)
    }

    // MARK: - Cascade delete (TodoList → TodoItem)

    func testDeletingListCascadesToItems() {
        // Insert a list with two items.
        let listStore = TodoListStore()
        listStore.createList(titled: "Cascade")
        guard let list = listStore.lists.first else {
            return XCTFail("Expected a list")
        }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Child A")
        itemStore.addItem(titled: "Child B")
        XCTAssertEqual(Application.modelState(\.allItems).models.count, 2)

        // Delete the list — cascade rule should remove children.
        listStore.delete(list)

        XCTAssertEqual(Application.modelState(\.allItems).models.count, 0,
                       "Cascade delete must remove child items")
    }

    func testCascadeDeleteOnlyRemovesChildrenOfDeletedList() {
        let listStore = TodoListStore()
        listStore.createList(titled: "List A")
        listStore.createList(titled: "List B")

        guard
            let listA = listStore.lists.first(where: { $0.title == "List A" }),
            let listB = listStore.lists.first(where: { $0.title == "List B" })
        else {
            return XCTFail("Expected both lists")
        }

        let storeA = TodoItemStore(list: listA)
        let storeB = TodoItemStore(list: listB)
        storeA.addItem(titled: "A-Item")
        storeB.addItem(titled: "B-Item")

        // Delete only List A.
        listStore.delete(listA)

        let remaining = Application.modelState(\.allItems).models
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.title, "B-Item")
    }

    // MARK: - Many-to-many: TodoItem ↔ Tag (nullify)

    func testAttachingTagCreatesRelationship() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Tagged")
        guard let list = listStore.lists.first else {
            return XCTFail("Expected a list")
        }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Task")
        guard let item = list.items.first else {
            return XCTFail("Expected an item")
        }

        itemStore.attachTag(named: "urgent", to: item)

        XCTAssertEqual(item.tags.count, 1)
        XCTAssertEqual(item.tags.first?.name, "urgent")
    }

    func testTagInverseRelationshipIsPopulated() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Inverse")
        guard let list = listStore.lists.first else {
            return XCTFail("Expected a list")
        }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Task")
        guard let item = list.items.first else {
            return XCTFail("Expected an item")
        }

        itemStore.attachTag(named: "feature", to: item)

        let tags = Application.modelState(\.allTags).models
        XCTAssertEqual(tags.count, 1)
        guard let tag = tags.first else { return XCTFail("Expected a tag") }
        XCTAssertTrue(tag.items.contains { $0.title == "Task" },
                      "Tag.items inverse relationship must include the item")
    }

    func testDeletingItemNullifiesTagInverse() {
        // nullify rule: deleting an item should remove it from Tag.items but keep the Tag.
        let listStore = TodoListStore()
        listStore.createList(titled: "Nullify")
        guard let list = listStore.lists.first else {
            return XCTFail("Expected a list")
        }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Tagged task")
        guard let item = list.items.first else {
            return XCTFail("Expected an item")
        }
        itemStore.attachTag(named: "keepme", to: item)
        XCTAssertEqual(Application.modelState(\.allTags).models.count, 1)

        // Delete the item.
        itemStore.delete(item)

        // Tag must still exist.
        let tagsAfter = Application.modelState(\.allTags).models
        XCTAssertEqual(tagsAfter.count, 1, "Tag must survive item deletion (nullify rule)")
        XCTAssertTrue(tagsAfter.first?.items.isEmpty ?? false,
                      "Tag.items must be empty after the item is deleted")
    }

    func testTagSharedAcrossMultipleItems() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Shared Tag")
        guard let list = listStore.lists.first else {
            return XCTFail("Expected a list")
        }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Item 1")
        itemStore.addItem(titled: "Item 2")

        let items = list.items
        guard items.count == 2 else { return XCTFail("Expected 2 items") }

        itemStore.attachTag(named: "shared", to: items[0])
        itemStore.attachTag(named: "shared", to: items[1])

        // Only one Tag model must exist (unique constraint).
        let tags = Application.modelState(\.allTags).models
        XCTAssertEqual(tags.count, 1, "Unique tag must be reused, not duplicated")
        XCTAssertEqual(tags.first?.items.count, 2, "Both items must reference the shared tag")
    }

    func testDetachingTagRemovesItFromItem() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Detach")
        guard let list = listStore.lists.first else {
            return XCTFail("Expected a list")
        }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Detach task")
        guard let item = list.items.first else {
            return XCTFail("Expected an item")
        }
        itemStore.attachTag(named: "removable", to: item)
        guard let tag = item.tags.first else { return XCTFail("Expected a tag") }

        itemStore.detachTag(tag, from: item)

        XCTAssertTrue(item.tags.isEmpty, "Tag must be detached from the item")
        // Tag itself must still exist in the store.
        XCTAssertEqual(Application.modelState(\.allTags).models.count, 1,
                       "Tag model must persist after detach")
    }
}

// MARK: - QueryTests

/// Tests exercising compound predicates, multi-key sort, and fetch limits.
@MainActor
final class QueryTests: XCTestCase {

    private var containerOverride: Application.DependencyOverride?

    override func setUp() async throws {
        try await super.setUp()
        containerOverride = Application.override(\.labContainer, with: makeInMemoryLabContainer())
    }

    override func tearDown() async throws {
        await containerOverride?.cancel()
        containerOverride = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeListWithItems() -> (TodoList, TodoItemStore) {
        let listStore = TodoListStore()
        listStore.createList(titled: "Query Test")
        guard let list = listStore.lists.first else {
            fatalError("Expected list")
        }
        return (list, TodoItemStore(list: list))
    }

    // MARK: - Tests: incompleteItems(taggedWith:)

    func testIncompleteItemsTaggedWithFiltersByTagAndDone() {
        let (list, itemStore) = makeListWithItems()

        itemStore.addItem(titled: "Incomplete tagged",   priority: 2)
        itemStore.addItem(titled: "Incomplete untagged", priority: 1)
        itemStore.addItem(titled: "Complete tagged",     priority: 3)

        let items = list.items
        guard items.count == 3 else { return XCTFail("Expected 3 items") }

        let incompleteTagged   = items.first { $0.title == "Incomplete tagged" }!
        let completeTagged     = items.first { $0.title == "Complete tagged" }!

        itemStore.attachTag(named: "swift", to: incompleteTagged)
        itemStore.attachTag(named: "swift", to: completeTagged)

        // Mark completeTagged as done.
        completeTagged.isDone = true
        Application.modelState(\.allItems).save()

        let filtered = itemStore.incompleteItems(taggedWith: "swift")

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "Incomplete tagged")
    }

    func testIncompleteItemsTaggedWithReturnsEmptyForUnknownTag() {
        let (list, itemStore) = makeListWithItems()
        itemStore.addItem(titled: "Task")
        guard let item = list.items.first else { return XCTFail("Expected item") }
        itemStore.attachTag(named: "known", to: item)

        let result = itemStore.incompleteItems(taggedWith: "unknown")
        XCTAssertTrue(result.isEmpty)
    }

    func testIncompleteItemsTaggedWithExcludesDoneItems() {
        let (list, itemStore) = makeListWithItems()
        itemStore.addItem(titled: "Done task")
        guard let item = list.items.first else { return XCTFail("Expected item") }
        itemStore.attachTag(named: "tag", to: item)
        itemStore.toggleDone(item)

        let result = itemStore.incompleteItems(taggedWith: "tag")
        XCTAssertTrue(result.isEmpty)
    }

    func testIncompleteItemsSortedByPriorityThenTitle() {
        let (list, itemStore) = makeListWithItems()
        itemStore.addItem(titled: "Zebra",  priority: 1)
        itemStore.addItem(titled: "Apple",  priority: 2)
        itemStore.addItem(titled: "Mango",  priority: 2)

        let items = list.items
        for item in items {
            itemStore.attachTag(named: "sort-test", to: item)
        }

        let result = itemStore.incompleteItems(taggedWith: "sort-test")

        XCTAssertEqual(result.count, 3)
        // Priority 2 items first (Apple then Mango alphabetically), then priority 1 (Zebra).
        XCTAssertEqual(result.map(\.title), ["Apple", "Mango", "Zebra"])
    }

    // MARK: - Tests: Application.incompleteItems(tagName:fetchLimit:)

    func testApplicationLevelIncompleteItemsQueryFiltersCorrectly() {
        let listStore = TodoListStore()
        listStore.createList(titled: "App Query")
        guard let list = listStore.lists.first else { return XCTFail("Expected list") }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Tagged incomplete", priority: 1)
        itemStore.addItem(titled: "Tagged done",       priority: 2)
        let items = list.items
        guard items.count == 2 else { return XCTFail("Expected 2 items") }

        let incompleteItem = items.first { $0.title == "Tagged incomplete" }!
        let doneItem       = items.first { $0.title == "Tagged done" }!

        itemStore.attachTag(named: "filter", to: incompleteItem)
        itemStore.attachTag(named: "filter", to: doneItem)
        doneItem.isDone = true
        Application.modelState(\.allItems).save()

        let results = fetchIncompleteItems(tagName: "filter")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Tagged incomplete")
    }

    func testApplicationLevelIncompleteItemsFetchLimit() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Limit Test")
        guard let list = listStore.lists.first else { return XCTFail("Expected list") }
        let itemStore = TodoItemStore(list: list)
        for i in 1...5 {
            itemStore.addItem(titled: "Task \(i)", priority: i)
        }
        for item in list.items {
            itemStore.attachTag(named: "limit-tag", to: item)
        }

        let results = fetchIncompleteItems(tagName: "limit-tag", fetchLimit: 3)
        XCTAssertEqual(results.count, 3, "fetchLimit must cap results at 3")
    }

    func testHighPriorityIncompleteItemsFiltersCorrectly() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Priority")
        guard let list = listStore.lists.first else { return XCTFail("Expected list") }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Low",  priority: 0)
        itemStore.addItem(titled: "High", priority: 3)
        itemStore.addItem(titled: "Done", priority: 5)

        guard let done = list.items.first(where: { $0.title == "Done" }) else {
            return XCTFail("Expected Done item")
        }
        done.isDone = true
        Application.modelState(\.allItems).save()

        let results = fetchHighPriorityIncompleteItems(threshold: 1)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "High")
    }

    func testHighPriorityFetchLimitIsRespected() {
        let listStore = TodoListStore()
        listStore.createList(titled: "FetchLimit")
        guard let list = listStore.lists.first else { return XCTFail("Expected list") }
        let itemStore = TodoItemStore(list: list)
        for i in 1...10 {
            itemStore.addItem(titled: "Item \(i)", priority: i)
        }

        let results = fetchHighPriorityIncompleteItems(threshold: 1, fetchLimit: 4)
        XCTAssertEqual(results.count, 4)
    }

    // MARK: - Tests: Multi-key sort in allItems / todoLists

    func testAllItemsAreSortedByTitle() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Sort")
        guard let list = listStore.lists.first else { return XCTFail("Expected list") }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Zebra")
        itemStore.addItem(titled: "Apple")
        itemStore.addItem(titled: "Mango")

        let titles = Application.modelState(\.allItems).models.map(\.title)
        XCTAssertEqual(titles, ["Apple", "Mango", "Zebra"])
    }

    func testTodoListsSortedByCreatedAtDescending() {
        let listStore = TodoListStore()
        listStore.createList(titled: "First")
        listStore.createList(titled: "Second")
        listStore.createList(titled: "Third")

        let names = listStore.lists.map(\.title)
        // Newest first — insertion order is preserved by createdAt which increments per insert.
        XCTAssertEqual(names.first, "Third")
    }
}

// MARK: - UniqueConstraintTests

/// Tests exercising `@Attribute(.unique)` on `Tag.name` (upsert-on-conflict behaviour).
@MainActor
final class UniqueConstraintTests: XCTestCase {

    private var containerOverride: Application.DependencyOverride?

    override func setUp() async throws {
        try await super.setUp()
        containerOverride = Application.override(\.labContainer, with: makeInMemoryLabContainer())
    }

    override func tearDown() async throws {
        await containerOverride?.cancel()
        containerOverride = nil
        try await super.tearDown()
    }

    func testInsertingDuplicateTagNameDoesNotDuplicate() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Unique")
        guard let list = listStore.lists.first else { return XCTFail("Expected list") }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Item A")
        itemStore.addItem(titled: "Item B")
        let items = list.items
        guard items.count == 2 else { return XCTFail("Expected 2 items") }

        // Attach "swift" to both items — the second call should reuse the existing Tag.
        itemStore.attachTag(named: "swift", to: items[0])
        itemStore.attachTag(named: "swift", to: items[1])

        let allTags = Application.modelState(\.allTags).models
        XCTAssertEqual(allTags.count, 1, "Unique constraint must prevent duplicate Tag records")
        XCTAssertEqual(allTags.first?.name, "swift")
    }

    func testUpsertPreservesExistingTagRelationships() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Upsert")
        guard let list = listStore.lists.first else { return XCTFail("Expected list") }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Task X")
        itemStore.addItem(titled: "Task Y")
        let items = list.items
        guard items.count == 2 else { return XCTFail("Expected 2 items") }

        itemStore.attachTag(named: "reused", to: items[0])
        // Re-attaching to a second item should reuse, not create, the "reused" tag.
        itemStore.attachTag(named: "reused", to: items[1])

        guard let tag = Application.modelState(\.allTags).models.first else {
            return XCTFail("Expected a tag")
        }
        // The single tag must reference both items.
        XCTAssertEqual(tag.items.count, 2)
    }

    func testDistinctTagNamesCreateDistinctRecords() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Distinct")
        guard let list = listStore.lists.first else { return XCTFail("Expected list") }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Item")
        guard let item = list.items.first else { return XCTFail("Expected item") }

        itemStore.attachTag(named: "alpha", to: item)
        itemStore.attachTag(named: "beta",  to: item)
        itemStore.attachTag(named: "gamma", to: item)

        XCTAssertEqual(Application.modelState(\.allTags).models.count, 3)
        XCTAssertEqual(item.tags.count, 3)
    }

    func testAttachingSameTagTwiceToSameItemIsIdempotent() {
        let listStore = TodoListStore()
        listStore.createList(titled: "Idempotent")
        guard let list = listStore.lists.first else { return XCTFail("Expected list") }
        let itemStore = TodoItemStore(list: list)
        itemStore.addItem(titled: "Once")
        guard let item = list.items.first else { return XCTFail("Expected item") }

        itemStore.attachTag(named: "dup", to: item)
        itemStore.attachTag(named: "dup", to: item)

        XCTAssertEqual(item.tags.count, 1, "Attaching same tag twice must not create duplicates on the item")
        XCTAssertEqual(Application.modelState(\.allTags).models.count, 1)
    }
}

// MARK: - SchemaMigrationTests

/// Tests exercising the V1 → V2 lightweight migration via `LabMigrationPlan`.
///
/// Because the migration is lightweight (additive columns: `priority` Int default 0,
/// `dueDate` optional Date), an in-memory container opened with the migration plan
/// immediately makes V2 fields available. The test strategy is to:
/// 1. Open a `makeInMemoryMigratedContainer()` — this simulates a store that has passed
///    through the migration plan.
/// 2. Verify V2 fields (`priority`, `dueDate`) are accessible and have sensible defaults.
///
/// ### Why no "insert V1, open with V2" test?
/// SwiftData's in-memory store does **not** persist between container instances — each
/// `ModelContainer(isStoredInMemoryOnly: true)` starts from an empty store, so there is no
/// data to migrate. On-disk migration testing requires a temporary file-backed store, which
/// introduces test-environment complexity (temp directories, cleanup) beyond the scope of this
/// example. The test below focuses on verifying that the V2 container is functional and that
/// the migration plan types are correctly declared.
@MainActor
final class SchemaMigrationTests: XCTestCase {

    func testMigratedContainerSupportsV2Fields() {
        let container = makeInMemoryMigratedContainer()
        let ctx = container.mainContext

        let item = TodoItem(title: "V2 item", priority: 4, dueDate: Date(timeIntervalSince1970: 1_000_000))
        ctx.insert(item)
        XCTAssertNoThrow(try ctx.save())

        let fetched = (try? ctx.fetch(FetchDescriptor<TodoItem>())) ?? []
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.priority, 4)
        XCTAssertNotNil(fetched.first?.dueDate)
    }

    func testMigratedContainerDefaultPriorityIsZero() {
        let container = makeInMemoryMigratedContainer()
        let ctx = container.mainContext

        let item = TodoItem(title: "Default priority")
        ctx.insert(item)
        XCTAssertNoThrow(try ctx.save())

        let fetched = (try? ctx.fetch(FetchDescriptor<TodoItem>())) ?? []
        XCTAssertEqual(fetched.first?.priority, 0)
    }

    func testMigratedContainerDefaultDueDateIsNil() {
        let container = makeInMemoryMigratedContainer()
        let ctx = container.mainContext

        let item = TodoItem(title: "No due date")
        ctx.insert(item)
        XCTAssertNoThrow(try ctx.save())

        let fetched = (try? ctx.fetch(FetchDescriptor<TodoItem>())) ?? []
        XCTAssertNil(fetched.first?.dueDate)
    }

    func testLabMigrationPlanDeclaresTwoSchemas() {
        XCTAssertEqual(LabMigrationPlan.schemas.count, 2)
    }

    func testLabMigrationPlanDeclaresOneStage() {
        XCTAssertEqual(LabMigrationPlan.stages.count, 1)
    }

    func testLabSchemaV1VersionIdentifier() {
        XCTAssertEqual(LabSchemaV1.versionIdentifier, Schema.Version(1, 0, 0))
    }

    func testLabSchemaV2VersionIdentifier() {
        XCTAssertEqual(LabSchemaV2.versionIdentifier, Schema.Version(2, 0, 0))
    }

    func testLabSchemaV1DeclaresThreeModelTypes() {
        XCTAssertEqual(LabSchemaV1.models.count, 3)
    }

    func testLabSchemaV2DeclaresThreeModelTypes() {
        XCTAssertEqual(LabSchemaV2.models.count, 3)
    }

    func testV1ContainerSupportsV1Items() {
        let container = makeInMemoryV1Container()
        let ctx = container.mainContext

        let item = LabSchemaV1.TodoItem(title: "V1 task")
        ctx.insert(item)
        XCTAssertNoThrow(try ctx.save())

        let fetched = (try? ctx.fetch(FetchDescriptor<LabSchemaV1.TodoItem>())) ?? []
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "V1 task")
    }

    func testV1TodoListCascadeDeleteStillWorksinV1Container() {
        let container = makeInMemoryV1Container()
        let ctx = container.mainContext

        let list = LabSchemaV1.TodoList(title: "V1 List")
        let item = LabSchemaV1.TodoItem(title: "V1 Item")
        list.items.append(item)
        ctx.insert(list)
        ctx.insert(item)
        XCTAssertNoThrow(try ctx.save())

        // Cascade-delete the list.
        ctx.delete(list)
        XCTAssertNoThrow(try ctx.save())

        let remainingItems = (try? ctx.fetch(FetchDescriptor<LabSchemaV1.TodoItem>())) ?? []
        XCTAssertTrue(remainingItems.isEmpty, "Cascade delete must remove V1 items")
    }
}

// MARK: - TodoListStoreTests

@MainActor
final class TodoListStoreTests: XCTestCase {

    private var containerOverride: Application.DependencyOverride?

    override func setUp() async throws {
        try await super.setUp()
        containerOverride = Application.override(\.labContainer, with: makeInMemoryLabContainer())
    }

    override func tearDown() async throws {
        await containerOverride?.cancel()
        containerOverride = nil
        try await super.tearDown()
    }

    func testTodoListStoreInitialisesEmpty() {
        XCTAssertTrue(TodoListStore().lists.isEmpty)
    }

    func testCreateListInsertsRecord() {
        let store = TodoListStore()
        store.createList(titled: "My List")
        XCTAssertEqual(store.lists.count, 1)
        XCTAssertEqual(store.lists.first?.title, "My List")
    }

    func testCreateMultipleLists() {
        let store = TodoListStore()
        store.createList(titled: "A")
        store.createList(titled: "B")
        store.createList(titled: "C")
        XCTAssertEqual(store.lists.count, 3)
    }

    func testDeleteListRemovesRecord() {
        let store = TodoListStore()
        store.createList(titled: "Ephemeral")
        guard let list = store.lists.first else { return XCTFail("Expected a list") }
        store.delete(list)
        XCTAssertTrue(store.lists.isEmpty)
    }

    func testSaveDoesNotCrash() {
        let store = TodoListStore()
        store.createList(titled: "Saved")
        store.save()
        store.save()
        XCTAssertEqual(store.lists.count, 1)
    }

    func testListsAreOrderedNewestFirst() {
        let store = TodoListStore()
        store.createList(titled: "Old")
        store.createList(titled: "New")
        XCTAssertEqual(store.lists.first?.title, "New",
                       "Newest list must appear first (sorted by createdAt descending)")
    }
}

// MARK: - TodoItemStoreTests

@MainActor
final class TodoItemStoreTests: XCTestCase {

    private var containerOverride: Application.DependencyOverride?
    private var list: TodoList!
    private var itemStore: TodoItemStore!

    override func setUp() async throws {
        try await super.setUp()
        containerOverride = Application.override(\.labContainer, with: makeInMemoryLabContainer())

        let listStore = TodoListStore()
        listStore.createList(titled: "Test List")
        guard let created = listStore.lists.first else {
            XCTFail("Expected a list")
            return
        }
        list = created
        itemStore = TodoItemStore(list: created)
    }

    override func tearDown() async throws {
        itemStore = nil
        list = nil
        await containerOverride?.cancel()
        containerOverride = nil
        try await super.tearDown()
    }

    func testAddItemCreatesRecord() {
        itemStore.addItem(titled: "Task")
        XCTAssertEqual(itemStore.items.count, 1)
    }

    func testAddItemSetsTitle() {
        itemStore.addItem(titled: "Important")
        XCTAssertEqual(itemStore.items.first?.title, "Important")
    }

    func testAddItemSetsPriority() {
        itemStore.addItem(titled: "Urgent", priority: 5)
        XCTAssertEqual(itemStore.items.first?.priority, 5)
    }

    func testAddItemSetsDueDate() {
        let due = Date(timeIntervalSinceNow: 3600)
        itemStore.addItem(titled: "Due", dueDate: due)
        XCTAssertNotNil(itemStore.items.first?.dueDate)
    }

    func testAddItemDefaultsIsDoneToFalse() {
        itemStore.addItem(titled: "New")
        XCTAssertFalse(itemStore.items.first?.isDone ?? true)
    }

    func testDeleteItemRemovesRecord() {
        itemStore.addItem(titled: "Delete me")
        guard let item = itemStore.items.first else { return XCTFail("Expected item") }
        itemStore.delete(item)
        XCTAssertTrue(itemStore.items.isEmpty)
    }

    func testToggleDoneFlipsState() {
        itemStore.addItem(titled: "Toggle")
        guard let item = itemStore.items.first else { return XCTFail("Expected item") }
        XCTAssertFalse(item.isDone)
        itemStore.toggleDone(item)
        XCTAssertTrue(item.isDone)
        itemStore.toggleDone(item)
        XCTAssertFalse(item.isDone)
    }

    func testAttachTagAddsTagToItem() {
        itemStore.addItem(titled: "Tagged")
        guard let item = itemStore.items.first else { return XCTFail("Expected item") }
        itemStore.attachTag(named: "swift", to: item)
        XCTAssertEqual(item.tags.count, 1)
        XCTAssertEqual(item.tags.first?.name, "swift")
    }

    func testDetachTagRemovesTagFromItem() {
        itemStore.addItem(titled: "Detach")
        guard let item = itemStore.items.first else { return XCTFail("Expected item") }
        itemStore.attachTag(named: "removable", to: item)
        guard let tag = item.tags.first else { return XCTFail("Expected tag") }
        itemStore.detachTag(tag, from: item)
        XCTAssertTrue(item.tags.isEmpty)
    }

    func testItemsSortedAlphabetically() {
        itemStore.addItem(titled: "Zap")
        itemStore.addItem(titled: "Alpha")
        itemStore.addItem(titled: "Middle")
        XCTAssertEqual(itemStore.items.map(\.title), ["Alpha", "Middle", "Zap"])
    }

    func testItemsBelongToCorrectList() {
        itemStore.addItem(titled: "List item")
        guard let item = itemStore.items.first else { return XCTFail("Expected item") }
        XCTAssertTrue(item.list === list)
    }
}

// MARK: - ModelStateContextTests

@MainActor
final class ModelStateContextTests: XCTestCase {

    private var containerOverride: Application.DependencyOverride?

    override func setUp() async throws {
        try await super.setUp()
        containerOverride = Application.override(\.labContainer, with: makeInMemoryLabContainer())
    }

    override func tearDown() async throws {
        await containerOverride?.cancel()
        containerOverride = nil
        try await super.tearDown()
    }

    func testAllItemsContextIsMainContext() {
        let state = Application.modelState(\.allItems)
        let container = Application.dependency(\.labContainer)
        XCTAssertTrue(state.context === container.mainContext)
    }

    func testAllTagsContextIsMainContext() {
        let state = Application.modelState(\.allTags)
        let container = Application.dependency(\.labContainer)
        XCTAssertTrue(state.context === container.mainContext)
    }

    func testTodoListsContextIsMainContext() {
        let state = Application.modelState(\.todoLists)
        let container = Application.dependency(\.labContainer)
        XCTAssertTrue(state.context === container.mainContext)
    }
}

#endif
