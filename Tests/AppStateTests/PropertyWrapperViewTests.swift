#if canImport(SwiftUI) && !os(Linux) && !os(Windows)
import Foundation
import Observation
import SwiftUI
import ViewInspector
import XCTest
@testable import AppState

// MARK: - In-memory test doubles

/// Isolated in-memory UserDefaults so `StoredState` never touches `UserDefaults.standard`.
private final class UIWrapperInMemoryUserDefaults: UserDefaultsManaging, @unchecked Sendable {
    private var storage: [String: Any] = [:]
    func object(forKey key: String) -> Any? { storage[key] }
    func set(_ value: Any?, forKey key: String) { storage[key] = value }
    func removeObject(forKey key: String) { storage.removeValue(forKey: key) }
}

/// Isolated in-memory iCloud store so `SyncState` never touches `NSUbiquitousKeyValueStore`.
@available(watchOS 9.0, *)
private final class UIWrapperInMemoryKeyValueStore: UbiquitousKeyValueStoreManaging, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    func data(forKey key: String) -> Data? { storage[key] }
    func set(_ value: Data?, forKey key: String) { storage[key] = value }
    func removeObject(forKey key: String) { storage.removeValue(forKey: key) }
}

// MARK: - Application state extensions (UIWrapper-prefixed to avoid collisions)

fileprivate extension Application {
    var uiWrapperCounter: State<Int> {
        state(initial: 0, id: "uiWrapperCounter")
    }

    var uiWrapperLabel: State<String> {
        state(initial: "initial", id: "uiWrapperLabel")
    }

    var uiWrapperStoredInt: StoredState<Int> {
        storedState(initial: 0, id: "uiWrapperStoredInt")
    }

    @available(watchOS 9.0, *)
    var uiWrapperSyncString: SyncState<String> {
        syncState(initial: "syncInitial", id: "uiWrapperSyncString")
    }

    var uiWrapperSecureToken: SecureState {
        secureState(feature: "UIWrapperTests", id: "uiWrapperSecureToken")
    }

    @MainActor
    var uiWrapperFileString: FileState<String?> {
        fileState(path: "./UIWrapperTests", filename: "uiWrapperFileString")
    }

    var uiWrapperPoint: State<UIWrapperPoint> {
        state(initial: UIWrapperPoint(x: 0, y: 0), id: "uiWrapperPoint")
    }

    var uiWrapperOptionalPoint: State<UIWrapperPoint?> {
        state(initial: nil, id: "uiWrapperOptionalPoint")
    }

    var uiWrapperMathService: Dependency<UIWrapperMathService> {
        dependency(UIWrapperMathService(), id: "uiWrapperMathService")
    }

    var uiWrapperObservableService: Dependency<UIWrapperObservableService> {
        dependency(UIWrapperObservableService(), id: "uiWrapperObservableService")
    }
}

// MARK: - Supporting value types

private struct UIWrapperPoint: Equatable, Codable, Sendable {
    var x: Int
    var y: Int
}

/// Using a class so DependencySlice mutations (which modify the reference in place) persist.
@MainActor
private final class UIWrapperMathService: Sendable {
    var multiplier: Int = 2
    func compute(_ input: Int) -> Int { input * multiplier }
}

private final class UIWrapperObservableService: ObservableObject, @unchecked Sendable {
    @Published var tick: Int = 0
    func increment() { tick += 1 }
}

// MARK: - @AppState view

private struct ObsViewAppState: View {
    @AppState(\.uiWrapperCounter) private var counter: Int

    var body: some View {
        VStack {
            Text("count:\(counter)")
            Button("inc") { counter += 1 }
        }
    }
}

// MARK: - @StoredState view

private struct ObsViewStoredState: View {
    @StoredState(\.uiWrapperStoredInt) private var value: Int

    var body: some View {
        VStack {
            Text("stored:\(value)")
            Button("set42") { value = 42 }
        }
    }
}

// MARK: - @SyncState view

@available(watchOS 9.0, *)
private struct ObsViewSyncState: View {
    @SyncState(\.uiWrapperSyncString) private var label: String

    var body: some View {
        VStack {
            Text("sync:\(label)")
            Button("setSynced") { label = "synced" }
        }
    }
}

// MARK: - @SecureState view

private struct ObsViewSecureState: View {
    @SecureState(\.uiWrapperSecureToken) private var token: String?

    var body: some View {
        VStack {
            Text("token:\(token ?? "nil")")
            Button("setToken") { token = "secret123" }
            Button("clearToken") { token = nil }
        }
    }
}

// MARK: - @FileState view

private struct ObsViewFileState: View {
    @FileState(\.uiWrapperFileString) private var content: String?

    var body: some View {
        VStack {
            Text("file:\(content ?? "nil")")
            Button("writeFile") { content = "hello-file" }
            Button("clearFile") { content = nil }
        }
    }
}

// MARK: - @Slice view

private struct ObsViewSlice: View {
    @Slice(\.uiWrapperPoint, \.x) private var xCoord: Int

    var body: some View {
        VStack {
            Text("x:\(xCoord)")
            Button("setX") { xCoord = 99 }
        }
    }
}

// MARK: - @OptionalSlice view

private struct ObsViewOptionalSlice: View {
    @OptionalSlice(\.uiWrapperOptionalPoint, \.x) private var optX: Int?

    var body: some View {
        VStack {
            Text("optX:\(optX.map(String.init) ?? "nil")")
            Button("setOptX") { optX = 7 }
        }
    }
}

// MARK: - @Constant view

private struct ObsViewConstant: View {
    @Constant(\.uiWrapperPoint, \.y) private var yConst: Int

    var body: some View {
        Text("y:\(yConst)")
    }
}

// MARK: - @OptionalConstant view

private struct ObsViewOptionalConstant: View {
    @OptionalConstant(\.uiWrapperOptionalPoint, \.x) private var optXConst: Int?

    var body: some View {
        Text("optXConst:\(optXConst.map(String.init) ?? "nil")")
    }
}

// MARK: - @AppDependency view

private struct ObsViewAppDependency: View {
    @AppDependency(\.uiWrapperMathService) private var math: UIWrapperMathService

    var body: some View {
        Text("result:\(math.compute(5))")
    }
}

// MARK: - @ObservedDependency view

private struct ObsViewObservedDependency: View {
    @ObservedDependency(\.uiWrapperObservableService) private var service: UIWrapperObservableService

    var body: some View {
        VStack {
            Text("tick:\(service.tick)")
            Button("tick") { service.increment() }
        }
    }
}

// MARK: - @DependencySlice view

private struct ObsViewDependencySlice: View {
    @DependencySlice(\.uiWrapperMathService, \.multiplier) private var multiplier: Int

    var body: some View {
        VStack {
            Text("mult:\(multiplier)")
            Button("double") { multiplier = 4 }
        }
    }
}

// MARK: - @ModelState view (SwiftData, macOS 14+)

#if canImport(SwiftData)
import SwiftData

/// A SwiftData model used only inside PropertyWrapperViewTests to avoid collision
/// with TestItem in ModelStateTests.
@Model
private final class UIWrapperTodo {
    var title: String
    init(title: String) { self.title = title }
}

fileprivate extension Application {
    var uiWrapperModelContainer: Dependency<ModelContainer> {
        modelContainer(
            try! ModelContainer(
                for: UIWrapperTodo.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    var uiWrapperTodos: ModelState<UIWrapperTodo> {
        modelState(container: \.uiWrapperModelContainer, id: "uiWrapperTodos")
    }
}

private struct ObsViewModelState: View {
    @ModelState(\.uiWrapperTodos) private var todos: [UIWrapperTodo]

    var body: some View {
        VStack {
            Text("count:\(todos.count)")
            Button("addTodo") {
                $todos.insert(UIWrapperTodo(title: "new-todo"))
            }
            Button("deleteAll") {
                $todos.deleteAll()
            }
        }
    }
}
#endif

// MARK: - ObservableObject ViewModels (module-scope to satisfy Swift 6 actor isolation rules)

/// These are defined outside the test class so that the `@MainActor`-isolated property-wrapper
/// `init` is called in a context where the compiler can confirm main-actor isolation applies.

@MainActor
private final class UIWrapperAppStateViewModel: ObservableObject {
    @AppState(\.uiWrapperCounter) var counter: Int
}

@MainActor
private final class UIWrapperStoredStateViewModel: ObservableObject {
    @StoredState(\.uiWrapperStoredInt) var value: Int
}

@available(watchOS 9.0, *)
@MainActor
private final class UIWrapperSyncStateViewModel: ObservableObject {
    @SyncState(\.uiWrapperSyncString) var label: String
}

@MainActor
private final class UIWrapperSecureStateViewModel: ObservableObject {
    @SecureState(\.uiWrapperSecureToken) var token: String?
}

@MainActor
private final class UIWrapperFileStateViewModel: ObservableObject {
    @FileState(\.uiWrapperFileString) var content: String?
}

@MainActor
private final class UIWrapperSliceViewModel: ObservableObject {
    @Slice(\.uiWrapperPoint, \.x) var xCoord: Int
}

@MainActor
private final class UIWrapperOptionalSliceViewModel: ObservableObject {
    @OptionalSlice(\.uiWrapperOptionalPoint, \.x) var optX: Int?
}

@MainActor
private final class UIWrapperDependencySliceViewModel: ObservableObject {
    @DependencySlice(\.uiWrapperMathService, \.multiplier) var multiplier: Int
}

// MARK: - Test class

/// Exercises every property wrapper inside a real SwiftUI view body using ViewInspector.
/// Verifies that the displayed value reflects `Application` state, and that tapping a
/// `Button` mutates state and the re-inspected view reflects it.
@MainActor
final class PropertyWrapperViewTests: XCTestCase {

    // MARK: - Overrides

    private var userDefaultsOverride: Application.DependencyOverride?
    private var icloudOverride: Application.DependencyOverride?
    private var mathServiceOverride: Application.DependencyOverride?
    private var observableServiceOverride: Application.DependencyOverride?

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        Application.logging(isEnabled: false)

        userDefaultsOverride = Application.override(
            \.userDefaults,
            with: UIWrapperInMemoryUserDefaults() as UserDefaultsManaging
        )

        if #available(watchOS 9.0, *) {
            icloudOverride = Application.override(
                \.icloudStore,
                with: UIWrapperInMemoryKeyValueStore() as UbiquitousKeyValueStoreManaging
            )
        }

        // Provide fresh service instances each test so DependencySlice mutations don't bleed over.
        mathServiceOverride = Application.override(\.uiWrapperMathService, with: UIWrapperMathService())
        observableServiceOverride = Application.override(\.uiWrapperObservableService, with: UIWrapperObservableService())

        // Reset all state keys used in this file
        Application.reset(\.uiWrapperCounter)
        Application.reset(\.uiWrapperLabel)
        Application.reset(storedState: \.uiWrapperStoredInt)
        Application.reset(secureState: \.uiWrapperSecureToken)
        Application.reset(fileState: \.uiWrapperFileString)
        Application.reset(\.uiWrapperPoint)
        Application.reset(\.uiWrapperOptionalPoint)

        if #available(watchOS 9.0, *) {
            Application.reset(syncState: \.uiWrapperSyncString)
        }

        FileManager.defaultFileStatePath = "./UIWrapperTests"
    }

    override func tearDown() async throws {
        Application.reset(\.uiWrapperCounter)
        Application.reset(\.uiWrapperLabel)
        Application.reset(storedState: \.uiWrapperStoredInt)
        Application.reset(secureState: \.uiWrapperSecureToken)
        Application.reset(fileState: \.uiWrapperFileString)
        Application.reset(\.uiWrapperPoint)
        Application.reset(\.uiWrapperOptionalPoint)

        if #available(watchOS 9.0, *) {
            Application.reset(syncState: \.uiWrapperSyncString)
        }

        try? Application.dependency(\.fileManager).removeItem(atPath: "./UIWrapperTests")

        await observableServiceOverride?.cancel()
        observableServiceOverride = nil
        await mathServiceOverride?.cancel()
        mathServiceOverride = nil
        await icloudOverride?.cancel()
        icloudOverride = nil
        await userDefaultsOverride?.cancel()
        userDefaultsOverride = nil

        try await super.tearDown()
    }

    // MARK: - @AppState tests

    func testAppStateViewDisplaysInitialValue() throws {
        let sut = ObsViewAppState()
        let text = try sut.inspect().find(text: "count:0")
        XCTAssertEqual(try text.string(), "count:0")
    }

    func testAppStateViewButtonMutatesStateAndViewReflectsChange() throws {
        let sut = ObsViewAppState()

        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertEqual(Application.state(\.uiWrapperCounter).value, 1)
        let text = try sut.inspect().find(text: "count:1")
        XCTAssertEqual(try text.string(), "count:1")
    }

    func testAppStateDirectMutation() throws {
        var state = Application.state(\.uiWrapperCounter)
        state.value = 5

        let sut = ObsViewAppState()
        let text = try sut.inspect().find(text: "count:5")
        XCTAssertEqual(try text.string(), "count:5")
    }

    // MARK: - @StoredState tests

    func testStoredStateViewDisplaysInitialValue() throws {
        let sut = ObsViewStoredState()
        let text = try sut.inspect().find(text: "stored:0")
        XCTAssertEqual(try text.string(), "stored:0")
    }

    func testStoredStateViewButtonMutatesStateAndViewReflectsChange() throws {
        let sut = ObsViewStoredState()

        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertEqual(Application.storedState(\.uiWrapperStoredInt).value, 42)
        let text = try sut.inspect().find(text: "stored:42")
        XCTAssertEqual(try text.string(), "stored:42")
    }

    // MARK: - @SyncState tests

    @available(watchOS 9.0, *)
    func testSyncStateViewDisplaysInitialValue() throws {
        let sut = ObsViewSyncState()
        let text = try sut.inspect().find(text: "sync:syncInitial")
        XCTAssertEqual(try text.string(), "sync:syncInitial")
    }

    @available(watchOS 9.0, *)
    func testSyncStateViewButtonMutatesStateAndViewReflectsChange() throws {
        let sut = ObsViewSyncState()

        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertEqual(Application.syncState(\.uiWrapperSyncString).value, "synced")
        let text = try sut.inspect().find(text: "sync:synced")
        XCTAssertEqual(try text.string(), "sync:synced")
    }

    // MARK: - @SecureState tests

    func testSecureStateViewDisplaysNilInitially() throws {
        let sut = ObsViewSecureState()
        let text = try sut.inspect().find(text: "token:nil")
        XCTAssertEqual(try text.string(), "token:nil")
    }

    func testSecureStateViewSetTokenButton() throws {
        let sut = ObsViewSecureState()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        // First button is "setToken"
        try buttons[0].tap()

        XCTAssertEqual(Application.secureState(\.uiWrapperSecureToken).value, "secret123")
        let text = try sut.inspect().find(text: "token:secret123")
        XCTAssertEqual(try text.string(), "token:secret123")
    }

    func testSecureStateViewClearTokenButton() throws {
        // Set a value first
        var state = Application.secureState(\.uiWrapperSecureToken)
        state.value = "existing"

        let sut = ObsViewSecureState()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        // Second button is "clearToken"
        try buttons[1].tap()

        XCTAssertNil(Application.secureState(\.uiWrapperSecureToken).value)
    }

    // MARK: - @FileState tests

    func testFileStateViewDisplaysNilInitially() throws {
        let sut = ObsViewFileState()
        let text = try sut.inspect().find(text: "file:nil")
        XCTAssertEqual(try text.string(), "file:nil")
    }

    func testFileStateViewWriteFileButton() throws {
        let sut = ObsViewFileState()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        try buttons[0].tap()

        XCTAssertEqual(Application.fileState(\.uiWrapperFileString).value, "hello-file")
        let text = try sut.inspect().find(text: "file:hello-file")
        XCTAssertEqual(try text.string(), "file:hello-file")
    }

    func testFileStateViewClearFileButton() throws {
        var state = Application.fileState(\.uiWrapperFileString)
        state.value = "existing"

        let sut = ObsViewFileState()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        try buttons[1].tap()

        XCTAssertNil(Application.fileState(\.uiWrapperFileString).value)
    }

    // MARK: - @Slice tests

    func testSliceViewDisplaysInitialValue() throws {
        let sut = ObsViewSlice()
        let text = try sut.inspect().find(text: "x:0")
        XCTAssertEqual(try text.string(), "x:0")
    }

    func testSliceViewButtonMutatesSliceAndViewReflectsChange() throws {
        let sut = ObsViewSlice()

        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertEqual(Application.state(\.uiWrapperPoint).value.x, 99)
        let text = try sut.inspect().find(text: "x:99")
        XCTAssertEqual(try text.string(), "x:99")
    }

    // MARK: - @OptionalSlice tests

    func testOptionalSliceViewDisplaysNilWhenOptionalStateIsNil() throws {
        let sut = ObsViewOptionalSlice()
        let text = try sut.inspect().find(text: "optX:nil")
        XCTAssertEqual(try text.string(), "optX:nil")
    }

    func testOptionalSliceViewButtonIsNoOpWhenStateIsNil() throws {
        // State is nil, so the set should be a no-op
        let sut = ObsViewOptionalSlice()
        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertNil(Application.state(\.uiWrapperOptionalPoint).value)
    }

    func testOptionalSliceViewButtonMutatesWhenStateHasValue() throws {
        var pointState = Application.state(\.uiWrapperOptionalPoint)
        pointState.value = UIWrapperPoint(x: 0, y: 0)

        let sut = ObsViewOptionalSlice()
        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertEqual(Application.state(\.uiWrapperOptionalPoint).value?.x, 7)
        let text = try sut.inspect().find(text: "optX:7")
        XCTAssertEqual(try text.string(), "optX:7")
    }

    // MARK: - @Constant tests

    func testConstantViewDisplaysInitialValue() throws {
        let sut = ObsViewConstant()
        let text = try sut.inspect().find(text: "y:0")
        XCTAssertEqual(try text.string(), "y:0")
    }

    func testConstantViewReflectsExternalStateChange() throws {
        var state = Application.state(\.uiWrapperPoint)
        state.value.y = 77

        let sut = ObsViewConstant()
        let text = try sut.inspect().find(text: "y:77")
        XCTAssertEqual(try text.string(), "y:77")
    }

    // MARK: - @OptionalConstant tests

    func testOptionalConstantViewDisplaysNilWhenStateIsNil() throws {
        let sut = ObsViewOptionalConstant()
        let text = try sut.inspect().find(text: "optXConst:nil")
        XCTAssertEqual(try text.string(), "optXConst:nil")
    }

    func testOptionalConstantViewDisplaysValueWhenStateIsSet() throws {
        var state = Application.state(\.uiWrapperOptionalPoint)
        state.value = UIWrapperPoint(x: 55, y: 0)

        let sut = ObsViewOptionalConstant()
        let text = try sut.inspect().find(text: "optXConst:55")
        XCTAssertEqual(try text.string(), "optXConst:55")
    }

    // MARK: - @AppDependency tests

    func testAppDependencyViewDisplaysComputedResult() throws {
        let sut = ObsViewAppDependency()
        let text = try sut.inspect().find(text: "result:10")
        XCTAssertEqual(try text.string(), "result:10")
    }

    // MARK: - @ObservedDependency tests

    func testObservedDependencyViewDisplaysInitialTick() throws {
        let sut = ObsViewObservedDependency()
        let text = try sut.inspect().find(text: "tick:0")
        XCTAssertEqual(try text.string(), "tick:0")
    }

    func testObservedDependencyViewTickButtonIncrementsService() throws {
        let sut = ObsViewObservedDependency()

        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertEqual(Application.dependency(\.uiWrapperObservableService).tick, 1)
    }

    // MARK: - @DependencySlice tests

    func testDependencySliceViewDisplaysInitialMultiplier() throws {
        let sut = ObsViewDependencySlice()
        let text = try sut.inspect().find(text: "mult:2")
        XCTAssertEqual(try text.string(), "mult:2")
    }

    func testDependencySliceViewButtonChangeMultiplier() throws {
        let sut = ObsViewDependencySlice()

        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertEqual(Application.dependency(\.uiWrapperMathService).multiplier, 4)
        let text = try sut.inspect().find(text: "mult:4")
        XCTAssertEqual(try text.string(), "mult:4")
    }

    // MARK: - ObservableObject subscript path coverage

    /// Exercises the `static subscript(_enclosingInstance:wrapped:storage:)` path on
    /// each wrapper — the path triggered when a wrapper is embedded in an `ObservableObject`.
    /// ViewModels are defined at module scope to satisfy Swift 6's requirement that
    /// `@MainActor`-isolated default values not be initialised in a nonisolated context.
    func testObservableObjectSubscriptPathForAppState() {
        let vm = UIWrapperAppStateViewModel()
        XCTAssertEqual(vm.counter, 0)
        vm.counter = 7
        XCTAssertEqual(vm.counter, 7)
    }

    func testObservableObjectSubscriptPathForStoredState() {
        let vm = UIWrapperStoredStateViewModel()
        XCTAssertEqual(vm.value, 0)
        vm.value = 13
        XCTAssertEqual(vm.value, 13)
    }

    @available(watchOS 9.0, *)
    func testObservableObjectSubscriptPathForSyncState() {
        let vm = UIWrapperSyncStateViewModel()
        XCTAssertEqual(vm.label, "syncInitial")
        vm.label = "changed"
        XCTAssertEqual(vm.label, "changed")
    }

    func testObservableObjectSubscriptPathForSecureState() {
        let vm = UIWrapperSecureStateViewModel()
        XCTAssertNil(vm.token)
        vm.token = "tok"
        XCTAssertEqual(vm.token, "tok")
        vm.token = nil
        XCTAssertNil(vm.token)
    }

    func testObservableObjectSubscriptPathForFileState() {
        let vm = UIWrapperFileStateViewModel()
        XCTAssertNil(vm.content)
        vm.content = "persisted"
        XCTAssertEqual(vm.content, "persisted")
    }

    func testObservableObjectSubscriptPathForSlice() {
        let vm = UIWrapperSliceViewModel()
        XCTAssertEqual(vm.xCoord, 0)
        vm.xCoord = 33
        XCTAssertEqual(vm.xCoord, 33)
    }

    func testObservableObjectSubscriptPathForOptionalSlice() {
        let vm = UIWrapperOptionalSliceViewModel()
        XCTAssertNil(vm.optX)
        // Set the parent state so the slice has something to work on
        var pointState = Application.state(\.uiWrapperOptionalPoint)
        pointState.value = UIWrapperPoint(x: 0, y: 0)
        vm.optX = 44
        XCTAssertEqual(Application.state(\.uiWrapperOptionalPoint).value?.x, 44)
    }

    func testObservableObjectSubscriptPathForDependencySlice() {
        let vm = UIWrapperDependencySliceViewModel()
        XCTAssertEqual(vm.multiplier, 2)
        vm.multiplier = 8
        XCTAssertEqual(vm.multiplier, 8)
    }

    // MARK: - @ModelState tests

#if canImport(SwiftData)
    func testModelStateViewDisplaysEmptyInitially() throws {
        Application.modelState(\.uiWrapperTodos).deleteAll()

        let sut = ObsViewModelState()
        let text = try sut.inspect().find(text: "count:0")
        XCTAssertEqual(try text.string(), "count:0")
    }

    func testModelStateViewAddTodoButton() throws {
        Application.modelState(\.uiWrapperTodos).deleteAll()

        let sut = ObsViewModelState()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        // First button is "addTodo"
        try buttons[0].tap()

        XCTAssertEqual(Application.modelState(\.uiWrapperTodos).models.count, 1)
        let text = try sut.inspect().find(text: "count:1")
        XCTAssertEqual(try text.string(), "count:1")
    }

    func testModelStateViewDeleteAllButton() throws {
        Application.modelState(\.uiWrapperTodos).insert(UIWrapperTodo(title: "a"))
        Application.modelState(\.uiWrapperTodos).insert(UIWrapperTodo(title: "b"))

        let sut = ObsViewModelState()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        // Second button is "deleteAll"
        try buttons[1].tap()

        XCTAssertTrue(Application.modelState(\.uiWrapperTodos).models.isEmpty)
    }
#endif
}

#endif // canImport(SwiftUI) && !os(Linux) && !os(Windows)
