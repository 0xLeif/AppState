#if canImport(SwiftData)
import Foundation
import SwiftData
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif
import XCTest
@testable import AppState

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
@Model
final class TestItem {
    var title: String
    var value: Int

    init(title: String, value: Int) {
        self.title = title
        self.value = value
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
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

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
@MainActor
fileprivate struct ExampleModelValue {
    @ModelState(\.items) var items
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
@MainActor
fileprivate class ExampleModelViewModel {
    @ModelState(\.items) var items

    func addItem(title: String, value: Int) {
        items = [TestItem(title: title, value: value)]
    }
}

#if !os(Linux) && !os(Windows)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension ExampleModelViewModel: ObservableObject { }
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
final class ModelStateTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        Application.logging(isEnabled: true)

        Application.reset(modelState: \.items)
        XCTAssertTrue(Application.modelState(\.items).value.isEmpty)
    }

    @MainActor
    override func tearDown() async throws {
        Application.reset(modelState: \.items)

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

        XCTAssertTrue(state.value.isEmpty)

        state.insert(TestItem(title: "First", value: 1))
        state.insert(TestItem(title: "Second", value: 2))

        let values = state.value

        XCTAssertEqual(values.count, 2)
        XCTAssertTrue(values.contains { $0.title == "First" && $0.value == 1 })
        XCTAssertTrue(values.contains { $0.title == "Second" && $0.value == 2 })
    }

    @MainActor
    func testPropertyWrapperInsertViaValueSetter() async {
        let example = ExampleModelValue()

        XCTAssertTrue(example.items.isEmpty)

        example.items = [TestItem(title: "Wrapped", value: 7)]

        XCTAssertEqual(example.items.count, 1)
        XCTAssertEqual(example.items.first?.title, "Wrapped")
        XCTAssertEqual(example.items.first?.value, 7)

        let viewModel = ExampleModelViewModel()

        XCTAssertEqual(viewModel.items.count, 1)

        viewModel.addItem(title: "ViewModel", value: 9)

        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertTrue(viewModel.items.contains { $0.title == "ViewModel" && $0.value == 9 })

        XCTAssertEqual(Application.modelState(\.items).value.count, 2)
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

        XCTAssertEqual(Application.modelState(\.items).value.first?.value, 99)
    }

    @MainActor
    func testReset() async {
        let state = Application.modelState(\.items)

        state.insert(TestItem(title: "One", value: 1))
        state.insert(TestItem(title: "Two", value: 2))
        state.insert(TestItem(title: "Three", value: 3))

        XCTAssertEqual(state.value.count, 3)

        Application.reset(modelState: \.items)

        XCTAssertTrue(Application.modelState(\.items).value.isEmpty)
    }

    @MainActor
    func testFetchDescriptorPredicate() async {
        let items = Application.modelState(\.items)

        items.insert(TestItem(title: "C", value: 30))
        items.insert(TestItem(title: "A", value: 10))
        items.insert(TestItem(title: "B", value: 20))

        let sorted = Application.modelState(\.sortedItems)
        let sortedValues = sorted.value

        XCTAssertEqual(sortedValues.count, 3)
        XCTAssertEqual(sortedValues.map(\.value), [10, 20, 30])
        XCTAssertEqual(sortedValues.map(\.title), ["A", "B", "C"])
    }
}
#endif
