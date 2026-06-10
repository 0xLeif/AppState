#if !os(Linux) && !os(Windows)
import AppState
import SwiftUI
import ViewInspector
import XCTest

@testable import TodoCloud

// MARK: - TodoListViewTests

/// Exercises the SwiftUI layer (`TodoListView` and `TodoRowView`) with ViewInspector so that the
/// declarative view bodies, their action closures, and the live service implementation are all
/// covered alongside the headless `TodoViewModel` tests.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@MainActor
final class TodoListViewTests: XCTestCase {

    // MARK: - Properties

    private var userDefaultsOverride: Application.DependencyOverride?
    private var icloudOverride: Application.DependencyOverride?
    private var serviceOverride: Application.DependencyOverride?

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()

        userDefaultsOverride = Application.override(
            \.userDefaults,
            with: InMemoryUserDefaults() as UserDefaultsManaging
        )
        icloudOverride = Application.override(
            \.icloudStore,
            with: InMemoryKeyValueStore() as UbiquitousKeyValueStoreManaging
        )
        serviceOverride = Application.override(
            \.todoService,
            with: MockTodoService() as TodoService
        )

        setTodos([])

        var titleState = Application.state(\.newTodoTitle)
        titleState.value = ""
    }

    override func tearDown() async throws {
        setTodos([])

        await serviceOverride?.cancel()
        serviceOverride = nil
        await icloudOverride?.cancel()
        icloudOverride = nil
        await userDefaultsOverride?.cancel()
        userDefaultsOverride = nil

        try await super.tearDown()
    }

    // MARK: - Helpers

    private func setTodos(_ todos: [Todo]) {
        if #available(watchOS 9.0, *) {
            var syncState = Application.syncState(\.todos)
            syncState.value = todos
        }
    }

    private func currentTodos() -> [Todo] {
        if #available(watchOS 9.0, *) {
            return Application.syncState(\.todos).value
        }
        return []
    }

    private func makeTodo(title: String, isCompleted: Bool = false) -> Todo {
        Todo(id: UUID(), title: title, isCompleted: isCompleted, createdAt: Date(timeIntervalSince1970: 0))
    }

    // MARK: - Tests: TodoListView body

    func testEmptyStateRendersContentUnavailableView() throws {
        setTodos([])

        let sut = TodoListView()

        XCTAssertNoThrow(try sut.inspect().find(text: "No Todos"))
    }

    func testNonEmptyStateRendersRowsForEachTodo() throws {
        setTodos([makeTodo(title: "Alpha"), makeTodo(title: "Beta")])

        let sut = TodoListView()
        let rows = try sut.inspect().findAll(TodoRowView.self)

        XCTAssertEqual(rows.count, 2)
    }

    func testItemsHeaderReflectsCount() throws {
        setTodos([makeTodo(title: "Only")])

        let sut = TodoListView()
        let header = try sut.inspect().find(text: "Items (1)")

        XCTAssertEqual(try header.string(), "Items (1)")
    }

    func testTextFieldOnSubmitCommitsNewTodo() throws {
        var titleState = Application.state(\.newTodoTitle)
        titleState.value = "Submitted via return key"

        let sut = TodoListView()
        let field = try sut.inspect().find(ViewType.TextField.self)
        try field.callOnSubmit()

        XCTAssertEqual(currentTodos().map(\.title), ["Submitted via return key"])
        XCTAssertEqual(Application.state(\.newTodoTitle).value, "")
    }

    func testTextFieldBindingWritesNewTodoTitleState() throws {
        let sut = TodoListView()
        let field = try sut.inspect().find(ViewType.TextField.self)

        try field.setInput("Typed text")

        XCTAssertEqual(Application.state(\.newTodoTitle).value, "Typed text")
    }

    func testAddButtonIsDisabledForBlankTitle() throws {
        var titleState = Application.state(\.newTodoTitle)
        titleState.value = "   "

        let sut = TodoListView()
        let button = try sut.inspect().find(ViewType.Button.self)

        XCTAssertTrue(try button.isDisabled())
    }

    func testAddButtonIsEnabledForNonBlankTitle() throws {
        var titleState = Application.state(\.newTodoTitle)
        titleState.value = "Has content"

        let sut = TodoListView()
        let button = try sut.inspect().find(ViewType.Button.self)

        XCTAssertFalse(try button.isDisabled())
    }

    func testAddButtonTapCommitsNewTodo() throws {
        var titleState = Application.state(\.newTodoTitle)
        titleState.value = "Added via button"

        let sut = TodoListView()
        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertEqual(currentTodos().map(\.title), ["Added via button"])
    }

    func testRowToggleClosureFlipsCompletion() throws {
        let todo = makeTodo(title: "Toggle me")
        setTodos([todo])

        let sut = TodoListView()
        let rowButton = try sut.inspect().find(TodoRowView.self).find(ViewType.Button.self)
        try rowButton.tap()

        XCTAssertTrue(currentTodos().first?.isCompleted ?? false)
    }

    func testSwipeToDeleteRemovesTodo() throws {
        setTodos([makeTodo(title: "Keep"), makeTodo(title: "Delete")])

        let sut = TodoListView()
        let forEach = try sut.inspect().find(ViewType.ForEach.self)
        try forEach.callOnDelete(IndexSet(integer: 1))

        XCTAssertEqual(currentTodos().map(\.title), ["Keep"])
    }

    // MARK: - Tests: TodoRowView

    func testRowDisplaysTitle() throws {
        let row = TodoRowView(todo: makeTodo(title: "Row title")) {}

        XCTAssertNoThrow(try row.inspect().find(text: "Row title"))
    }

    func testRowShowsFilledCircleWhenCompleted() throws {
        let row = TodoRowView(todo: makeTodo(title: "Done", isCompleted: true)) {}
        let image = try row.inspect().find(ViewType.Image.self)

        XCTAssertEqual(try image.actualImage().name(), "checkmark.circle.fill")
    }

    func testRowShowsEmptyCircleWhenIncomplete() throws {
        let row = TodoRowView(todo: makeTodo(title: "Pending", isCompleted: false)) {}
        let image = try row.inspect().find(ViewType.Image.self)

        XCTAssertEqual(try image.actualImage().name(), "circle")
    }

    func testRowButtonInvokesOnToggle() throws {
        var toggled = false
        let row = TodoRowView(todo: makeTodo(title: "Tap")) { toggled = true }

        try row.inspect().find(ViewType.Button.self).tap()

        XCTAssertTrue(toggled)
    }

    // MARK: - Tests: LiveTodoService

    func testLiveServiceMakesUniqueIDs() {
        let service = LiveTodoService()

        XCTAssertNotEqual(service.makeID(), service.makeID())
    }

    func testLiveServiceMakesCurrentDate() {
        let service = LiveTodoService()
        let before = Date()

        let made = service.makeDate()

        XCTAssertGreaterThanOrEqual(made.timeIntervalSince1970, before.timeIntervalSince1970)
    }
}
#endif
