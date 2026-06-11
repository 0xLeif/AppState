#if canImport(SwiftData)
import Foundation
import SwiftData
import XCTest
@testable import AppState

@Model
final class TestItem {
    var title: String
    var value: Int

    init(title: String, value: Int) {
        self.title = title
        self.value = value
    }
}

fileprivate extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(
            try! ModelContainer(
                for: TestItem.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    var items: ModelState<TestItem> {
        modelState(container: \.modelContainer)
    }

    var sortedItems: ModelState<TestItem> {
        modelState(
            container: \.modelContainer,
            fetchDescriptor: FetchDescriptor<TestItem>(
                sortBy: [SortDescriptor(\.value, order: .forward)]
            ),
            id: "sortedItems"
        )
    }
}

@MainActor
fileprivate struct ExampleModelValue {
    @ModelState(\.items) var items
}

@MainActor
fileprivate class ExampleModelViewModel {
    @ModelState(\.items) var items

    func addItem(title: String, value: Int) {
        $items.insert(TestItem(title: title, value: value))
    }
}

final class ModelStateTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        Application.logging(isEnabled: true)

        Application.modelState(\.items).deleteAll()
        XCTAssertTrue(Application.modelState(\.items).models.isEmpty)
    }

    @MainActor
    override func tearDown() async throws {
        Application.modelState(\.items).deleteAll()

        let applicationDescription = Application.description

        Application.dependency(\.logger).debug("ModelStateTests \(applicationDescription)")
    }

    @MainActor
    func testModelContextDependency() async {
        let context = Application.modelContext(\.modelContainer)
        let sameContext = Application.modelContext(\.modelContainer)

        XCTAssertTrue(context === sameContext)

        let item = TestItem(title: "Direct", value: 42)
        context.insert(item)
        try? context.save()

        let fetched = try? context.fetch(FetchDescriptor<TestItem>())

        XCTAssertEqual(fetched?.count, 1)
        XCTAssertEqual(fetched?.first?.title, "Direct")
        XCTAssertEqual(fetched?.first?.value, 42)
    }

    @MainActor
    func testInsertAndFetchThroughApplication() async {
        let state = Application.modelState(\.items)

        XCTAssertTrue(state.models.isEmpty)

        state.insert(TestItem(title: "First", value: 1))
        state.insert(TestItem(title: "Second", value: 2))

        let models = state.models

        XCTAssertEqual(models.count, 2)
        XCTAssertTrue(models.contains { $0.title == "First" && $0.value == 1 })
        XCTAssertTrue(models.contains { $0.title == "Second" && $0.value == 2 })
    }

    @MainActor
    func testPropertyWrapperReadAndProjectedInsert() async {
        let example = ExampleModelValue()

        XCTAssertTrue(example.items.isEmpty)

        example.$items.insert(TestItem(title: "Wrapped", value: 7))

        XCTAssertEqual(example.items.count, 1)
        XCTAssertEqual(example.items.first?.title, "Wrapped")
        XCTAssertEqual(example.items.first?.value, 7)

        let viewModel = ExampleModelViewModel()

        XCTAssertEqual(viewModel.items.count, 1)

        viewModel.addItem(title: "ViewModel", value: 9)

        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertTrue(viewModel.items.contains { $0.title == "ViewModel" && $0.value == 9 })

        XCTAssertEqual(Application.modelState(\.items).models.count, 2)
    }

    @MainActor
    func testProjectedValueCRUD() async {
        let example = ExampleModelValue()

        let first = TestItem(title: "Alpha", value: 1)
        let second = TestItem(title: "Beta", value: 2)

        example.$items.insert(first)
        example.$items.insert(second)

        XCTAssertEqual(example.items.count, 2)

        example.$items.delete(first)

        XCTAssertEqual(example.items.count, 1)
        XCTAssertEqual(example.items.first?.title, "Beta")

        second.value = 99
        example.$items.save()

        XCTAssertEqual(Application.modelState(\.items).models.first?.value, 99)
    }

    @MainActor
    func testDeleteAll() async {
        let state = Application.modelState(\.items)

        state.insert(TestItem(title: "One", value: 1))
        state.insert(TestItem(title: "Two", value: 2))
        state.insert(TestItem(title: "Three", value: 3))

        XCTAssertEqual(state.models.count, 3)

        state.deleteAll()

        XCTAssertTrue(Application.modelState(\.items).models.isEmpty)
    }

    @MainActor
    func testFetchDescriptorSorting() async {
        let items = Application.modelState(\.items)

        items.insert(TestItem(title: "C", value: 30))
        items.insert(TestItem(title: "A", value: 10))
        items.insert(TestItem(title: "B", value: 20))

        let sorted = Application.modelState(\.sortedItems)
        let sortedModels = sorted.models

        XCTAssertEqual(sortedModels.count, 3)
        XCTAssertEqual(sortedModels.map(\.value), [10, 20, 30])
        XCTAssertEqual(sortedModels.map(\.title), ["A", "B", "C"])
    }

    // MARK: - Strict (throwing) API

    @MainActor
    func testStrictMutatorsPerformCRUD() throws {
        let items = Application.modelState(\.items)

        let first = TestItem(title: "first", value: 1)
        try items.strict.insert(first)
        try items.strict.insert(TestItem(title: "second", value: 2))
        XCTAssertEqual(items.models.count, 2)

        first.value = 99
        try items.strict.save()
        XCTAssertEqual(items.models.first(where: { $0.title == "first" })?.value, 99)

        try items.strict.delete(first)
        XCTAssertEqual(items.models.map(\.title), ["second"])

        try items.strict.deleteAll()
        XCTAssertTrue(items.models.isEmpty)
    }

    @MainActor
    func testLenientAndStrictShareTheSameStore() throws {
        let items = Application.modelState(\.items)

        items.insert(TestItem(title: "lenient", value: 1))
        try items.strict.insert(TestItem(title: "strict", value: 2))

        XCTAssertEqual(Set(items.models.map(\.title)), ["lenient", "strict"])
    }
}
#endif
