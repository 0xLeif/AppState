import XCTest
import AppState
@testable import TodoCloud

// MARK: - MockTodoService

/// A deterministic `TodoService` for use in unit tests.
///
/// Produces fixed `UUID` values from a pre-populated queue and a fixed `Date`
/// so that assertions on `id` and `createdAt` are stable across test runs.
fileprivate final class MockTodoService: TodoService, @unchecked Sendable {

    // MARK: - Properties

    /// A queue of IDs vended in order; falls back to a new `UUID` when exhausted.
    var nextIDs: [UUID]

    /// The date returned for every `makeDate()` call.
    var fixedDate: Date

    // MARK: - Initializers

    init(
        nextIDs: [UUID] = [],
        fixedDate: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.nextIDs = nextIDs
        self.fixedDate = fixedDate
    }

    // MARK: - TodoService

    func makeID() -> UUID {
        nextIDs.isEmpty ? UUID() : nextIDs.removeFirst()
    }

    func makeDate() -> Date {
        fixedDate
    }
}

// MARK: - InMemoryUserDefaults

/// A fully in-memory `UserDefaultsManaging` substitute for tests.
///
/// Overriding `\.userDefaults` prevents `StoredState` (and the `SyncState` fallback)
/// from ever touching `UserDefaults.standard` or persisting data to disk.
fileprivate final class InMemoryUserDefaults: UserDefaultsManaging, @unchecked Sendable {

    private var storage: [String: Any] = [:]

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

#if !os(Linux) && !os(Windows)
// MARK: - InMemoryKeyValueStore

/// A fully in-memory `UbiquitousKeyValueStoreManaging` substitute for tests.
///
/// Overriding `\.icloudStore` prevents `SyncState` from ever touching
/// `NSUbiquitousKeyValueStore` or iCloud.
fileprivate final class InMemoryKeyValueStore: UbiquitousKeyValueStoreManaging, @unchecked Sendable {

    private var storage: [String: Data] = [:]

    func data(forKey key: String) -> Data? {
        storage[key]
    }

    func set(_ value: Data?, forKey key: String) {
        storage[key] = value
    }

    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}
#endif

// MARK: - TodoCloudTests

/// Tests for the TodoCloud feature, exercising `TodoViewModel` headlessly.
///
/// Each test spins up fresh in-memory replacements for:
/// - `\.userDefaults` — prevents `StoredState` from touching `UserDefaults.standard`
/// - `\.icloudStore` — prevents `SyncState` from touching `NSUbiquitousKeyValueStore`
/// - `\.todoService` — provides deterministic IDs and dates
@MainActor
final class TodoCloudTests: XCTestCase {

    // MARK: - Properties

    private var userDefaultsOverride: Application.DependencyOverride?

    #if !os(Linux) && !os(Windows)
    private var icloudOverride: Application.DependencyOverride?
    #endif

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()

        // Replace UserDefaults with a fresh in-memory store.
        userDefaultsOverride = Application.override(
            \.userDefaults,
            with: InMemoryUserDefaults() as UserDefaultsManaging
        )

        #if !os(Linux) && !os(Windows)
        // Replace iCloud store with a fresh in-memory store.
        icloudOverride = Application.override(
            \.icloudStore,
            with: InMemoryKeyValueStore() as UbiquitousKeyValueStoreManaging
        )
        #endif

        resetTodoState()
    }

    override func tearDown() async throws {
        resetTodoState()

        #if !os(Linux) && !os(Windows)
        await icloudOverride?.cancel()
        icloudOverride = nil
        #endif

        await userDefaultsOverride?.cancel()
        userDefaultsOverride = nil

        try await super.tearDown()
    }

    // MARK: - Helpers

    private func resetTodoState() {
        // Reset transient in-memory state.
        var fallback = Application.state(\.fallbackTodos)
        fallback.value = []

        var titleState = Application.state(\.newTodoTitle)
        titleState.value = ""

        // Reset the SyncState (reads from the already-overridden in-memory icloudStore).
        #if !os(Linux) && !os(Windows)
        if #available(watchOS 9.0, *) {
            var syncState = Application.syncState(\.todos)
            syncState.value = []
        }
        #endif
    }

    /// Creates a `TodoViewModel` with an active `todoService` dependency override.
    ///
    /// The caller must `await override.cancel()` when the test scope ends.
    private func makeSUT(
        mockService: MockTodoService = MockTodoService()
    ) -> (viewModel: TodoViewModel, override: Application.DependencyOverride) {
        let override = Application.override(\.todoService, with: mockService as TodoService)
        let viewModel = TodoViewModel()
        return (viewModel, override)
    }

    // MARK: - Tests: addTodo

    func testAddTodoAppendsItem() async {
        let (viewModel, override) = makeSUT()

        viewModel.addTodo(title: "Buy milk")

        XCTAssertEqual(viewModel.todos.count, 1)
        XCTAssertEqual(viewModel.todos.first?.title, "Buy milk")
        XCTAssertFalse(viewModel.todos.first?.isCompleted ?? true)

        await override.cancel()
    }

    func testAddTodoUsesInjectedServiceID() async {
        let knownID = UUID()
        let mock = MockTodoService(nextIDs: [knownID])
        let (viewModel, override) = makeSUT(mockService: mock)

        viewModel.addTodo(title: "Read a book")

        XCTAssertEqual(viewModel.todos.first?.id, knownID)

        await override.cancel()
    }

    func testAddTodoUsesInjectedServiceDate() async {
        let knownDate = Date(timeIntervalSince1970: 1_700_000_000)
        let mock = MockTodoService(fixedDate: knownDate)
        let (viewModel, override) = makeSUT(mockService: mock)

        viewModel.addTodo(title: "Walk the dog")

        XCTAssertEqual(viewModel.todos.first?.createdAt, knownDate)

        await override.cancel()
    }

    func testAddTodoIgnoresBlankTitle() async {
        let (viewModel, override) = makeSUT()

        viewModel.addTodo(title: "   ")

        XCTAssertTrue(viewModel.todos.isEmpty)

        await override.cancel()
    }

    func testAddTodoTrimsTitleWhitespace() async {
        let (viewModel, override) = makeSUT()

        viewModel.addTodo(title: "  Water plants  ")

        XCTAssertEqual(viewModel.todos.first?.title, "Water plants")

        await override.cancel()
    }

    func testAddTodoClearsNewTodoTitleState() async {
        let (viewModel, override) = makeSUT()

        var titleState = Application.state(\.newTodoTitle)
        titleState.value = "Some draft text"

        viewModel.addTodo(title: "Some draft text")

        XCTAssertEqual(Application.state(\.newTodoTitle).value, "")

        await override.cancel()
    }

    func testAddMultipleTodosPreservesOrder() async {
        let (viewModel, override) = makeSUT()

        viewModel.addTodo(title: "First")
        viewModel.addTodo(title: "Second")
        viewModel.addTodo(title: "Third")

        let titles = viewModel.todos.map { $0.title }
        XCTAssertEqual(titles, ["First", "Second", "Third"])

        await override.cancel()
    }

    // MARK: - Tests: toggleTodo

    func testToggleTodoMarksItemComplete() async {
        let (viewModel, override) = makeSUT()

        viewModel.addTodo(title: "Exercise")
        let id = viewModel.todos[0].id

        XCTAssertFalse(viewModel.todos[0].isCompleted)

        viewModel.toggleTodo(id: id)

        XCTAssertTrue(viewModel.todos[0].isCompleted)

        await override.cancel()
    }

    func testToggleTodoUnmarksPreviouslyCompletedItem() async {
        let (viewModel, override) = makeSUT()

        viewModel.addTodo(title: "Meditate")
        let id = viewModel.todos[0].id

        viewModel.toggleTodo(id: id)
        viewModel.toggleTodo(id: id)

        XCTAssertFalse(viewModel.todos[0].isCompleted)

        await override.cancel()
    }

    func testToggleDoesNotAffectOtherItems() async {
        let (viewModel, override) = makeSUT()

        viewModel.addTodo(title: "Alpha")
        viewModel.addTodo(title: "Beta")
        let betaID = viewModel.todos[1].id

        viewModel.toggleTodo(id: betaID)

        XCTAssertFalse(viewModel.todos[0].isCompleted)
        XCTAssertTrue(viewModel.todos[1].isCompleted)

        await override.cancel()
    }

    func testToggleWithUnknownIDIsNoOp() async {
        let (viewModel, override) = makeSUT()

        viewModel.addTodo(title: "Stable item")

        let snapshot = viewModel.todos
        viewModel.toggleTodo(id: UUID())

        XCTAssertEqual(viewModel.todos, snapshot)

        await override.cancel()
    }

    // MARK: - Tests: removeTodo

    func testRemoveTodoByID() async {
        let (viewModel, override) = makeSUT()

        viewModel.addTodo(title: "Keep me")
        viewModel.addTodo(title: "Remove me")
        let removeID = viewModel.todos[1].id

        viewModel.removeTodo(id: removeID)

        XCTAssertEqual(viewModel.todos.count, 1)
        XCTAssertEqual(viewModel.todos.first?.title, "Keep me")

        await override.cancel()
    }

    func testRemoveTodosByOffsets() async {
        let (viewModel, override) = makeSUT()

        viewModel.addTodo(title: "Alpha")
        viewModel.addTodo(title: "Beta")
        viewModel.addTodo(title: "Gamma")

        viewModel.removeTodos(at: IndexSet([0, 2]))

        XCTAssertEqual(viewModel.todos.count, 1)
        XCTAssertEqual(viewModel.todos.first?.title, "Beta")

        await override.cancel()
    }

    func testRemoveWithUnknownIDIsNoOp() async {
        let (viewModel, override) = makeSUT()

        viewModel.addTodo(title: "Persistent item")

        viewModel.removeTodo(id: UUID())

        XCTAssertEqual(viewModel.todos.count, 1)

        await override.cancel()
    }

    // MARK: - Tests: Todo model

    func testTodoToggledReturnsCopyWithFlippedCompletion() {
        let original = Todo(
            id: UUID(),
            title: "Test",
            isCompleted: false,
            createdAt: Date()
        )
        let toggled = original.toggled()

        XCTAssertEqual(original.id, toggled.id)
        XCTAssertEqual(original.title, toggled.title)
        XCTAssertEqual(original.createdAt, toggled.createdAt)
        XCTAssertTrue(toggled.isCompleted)
    }

    func testTodoCodableRoundTrip() throws {
        let original = Todo(
            id: UUID(),
            title: "Roundtrip test",
            isCompleted: true,
            createdAt: Date(timeIntervalSince1970: 1_000_000)
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Todo.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - Tests: Application state isolation

    func testNewTodoTitleDefaultsToEmptyAfterReset() {
        XCTAssertEqual(Application.state(\.newTodoTitle).value, "")
    }

    func testFallbackTodosDefaultsToEmptyAfterReset() {
        XCTAssertTrue(Application.state(\.fallbackTodos).value.isEmpty)
    }
}
