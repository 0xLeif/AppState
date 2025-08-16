import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif
import XCTest
@testable import AppState

fileprivate extension Application {
    var storedValue: StoredState<Int?> {
        storedState(id: "storedValue")
    }
}

@MainActor
fileprivate struct ExampleStoredValue {
    @StoredState(\.storedValue) var count
}

@MainActor
fileprivate class ExampleStoringViewModel {
    @StoredState(\.storedValue) var count

    func testPropertyWrapper() {
        count = 27
        #if !os(Linux) && !os(Windows)
        _ = TextField(
            value: $count,
            format: .number,
            label: { Text("Count") }
        )
        #endif
    }
}

#if !os(Linux) && !os(Windows)
extension ExampleStoringViewModel: ObservableObject { }
#endif

final class StoredStateTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        Application.logging(isEnabled: true)
    }

    @MainActor
    override func tearDown() async throws {
        let applicationDescription = Application.description

        Application.dependency(\.logger).debug("StoredStateTests \(applicationDescription)")
    }

    @MainActor
    func testStoredState() async {
        XCTAssertNil(Application.storedState(\.storedValue).value)

        let storedValue = ExampleStoredValue()

        XCTAssertEqual(storedValue.count, nil)

        storedValue.count = 1

        XCTAssertEqual(storedValue.count, 1)

        Application.dependency(\.logger).debug("StoredStateTests \(Application.description)")

        storedValue.count = nil

        XCTAssertNil(Application.storedState(\.storedValue).value)
    }

    @MainActor
    func testStoringViewModel() async {
        XCTAssertNil(Application.storedState(\.storedValue).value)

        let viewModel = ExampleStoringViewModel()

        XCTAssertEqual(viewModel.count, nil)

        viewModel.testPropertyWrapper()

        XCTAssertEqual(viewModel.count, 27)

        Application.reset(storedState: \.storedValue)

        XCTAssertNil(viewModel.count)
    }
}
