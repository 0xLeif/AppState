import XCTest
import AppState
@testable import SwiftDataExampleLib

#if canImport(SwiftData) && canImport(SwiftUI) && !os(Linux) && !os(Windows)
import SwiftData
import SwiftUI
import ViewInspector

// MARK: - TodoListRowViewTests

/// ViewInspector tests for `TodoListRowView`.
@MainActor
final class TodoListRowViewTests: XCTestCase {

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

    private func makeList(title: String, itemCount: Int = 0) -> TodoList {
        let list = TodoList(title: title)
        Application.modelState(\.todoLists).insert(list)
        for i in 1...max(1, itemCount) {
            let item = TodoItem(title: "Item \(i)")
            list.items.append(item)
            Application.modelState(\.allItems).insert(item)
        }
        return list
    }

    // MARK: - Tests

    func testRowDisplaysListTitle() throws {
        let list = makeList(title: "My List")
        let sut = TodoListRowView(list: list)

        XCTAssertNoThrow(try sut.inspect().find(text: "My List"))
    }

    func testRowDisplaysItemCount() throws {
        let list = makeList(title: "Counted", itemCount: 3)
        let sut = TodoListRowView(list: list)

        XCTAssertNoThrow(try sut.inspect().find(text: "3"))
    }

    func testRowWithZeroItemsShowsZeroCount() throws {
        let list = TodoList(title: "Empty")
        Application.modelState(\.todoLists).insert(list)

        let sut = TodoListRowView(list: list)
        XCTAssertNoThrow(try sut.inspect().find(text: "0"))
    }
}

// MARK: - TodoItemRowViewTests

/// ViewInspector tests for `TodoItemRowView`.
@MainActor
final class TodoItemRowViewTests: XCTestCase {

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

    // MARK: - Tests

    func testRowDisplaysTitle() throws {
        let item = TodoItem(title: "Row title")
        let sut = TodoItemRowView(item: item) {}

        XCTAssertNoThrow(try sut.inspect().find(text: "Row title"))
    }

    func testRowShowsFilledCircleWhenCompleted() throws {
        let item = TodoItem(title: "Done", isDone: true)
        let sut = TodoItemRowView(item: item) {}

        let image = try sut.inspect().find(ViewType.Image.self)
        XCTAssertEqual(try image.actualImage().name(), "checkmark.circle.fill")
    }

    func testRowShowsEmptyCircleWhenIncomplete() throws {
        let item = TodoItem(title: "Pending", isDone: false)
        let sut = TodoItemRowView(item: item) {}

        let image = try sut.inspect().find(ViewType.Image.self)
        XCTAssertEqual(try image.actualImage().name(), "circle")
    }

    func testRowButtonInvokesOnToggle() throws {
        var toggled = false
        let item = TodoItem(title: "Tap me")
        let sut = TodoItemRowView(item: item) { toggled = true }

        try sut.inspect().find(ViewType.Button.self).tap()
        XCTAssertTrue(toggled)
    }

    func testRowWithPriorityShowsBadge() throws {
        let item = TodoItem(title: "Urgent", priority: 4)
        let sut = TodoItemRowView(item: item) {}

        XCTAssertNoThrow(try sut.inspect().find(text: "P4"))
    }

    func testRowWithZeroPriorityHasNoBadge() throws {
        let item = TodoItem(title: "Normal", priority: 0)
        let sut = TodoItemRowView(item: item) {}

        // P0 badge text must not appear.
        XCTAssertThrowsError(try sut.inspect().find(text: "P0"))
    }
}

// MARK: - TagEditorViewTests

/// ViewInspector tests for `TagEditorView`.
@MainActor
final class TagEditorViewTests: XCTestCase {

    private var containerOverride: Application.DependencyOverride?
    private var list: TodoList!
    private var itemStore: TodoItemStore!

    override func setUp() async throws {
        try await super.setUp()
        containerOverride = Application.override(\.labContainer, with: makeInMemoryLabContainer())

        let listStore = TodoListStore()
        listStore.createList(titled: "View Test List")
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

    func testTagEditorShowsNoTagsPlaceholderWhenEmpty() throws {
        itemStore.addItem(titled: "Untagged")
        guard let item = list.items.first else { return XCTFail("Expected item") }

        let sut = TagEditorView(item: item, store: itemStore)
        XCTAssertNoThrow(try sut.inspect().find(text: "No tags yet"))
    }

    func testTagEditorDisplaysExistingTags() throws {
        itemStore.addItem(titled: "Tagged item")
        guard let item = list.items.first else { return XCTFail("Expected item") }
        itemStore.attachTag(named: "visible", to: item)

        let sut = TagEditorView(item: item, store: itemStore)
        XCTAssertNoThrow(try sut.inspect().find(text: "visible"))
    }

    func testTagEditorHasDoneButton() throws {
        itemStore.addItem(titled: "Item")
        guard let item = list.items.first else { return XCTFail("Expected item") }

        let sut = TagEditorView(item: item, store: itemStore)
        XCTAssertNoThrow(try sut.inspect().find(button: "Done"))
    }

    func testTagEditorHasAttachButton() throws {
        itemStore.addItem(titled: "Item")
        guard let item = list.items.first else { return XCTFail("Expected item") }

        let sut = TagEditorView(item: item, store: itemStore)
        XCTAssertNoThrow(try sut.inspect().find(button: "Attach"))
    }
}

#endif
