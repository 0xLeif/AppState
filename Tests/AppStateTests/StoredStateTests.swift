import SwiftUI
import XCTest
@testable import AppState

fileprivate extension Application {
    var storedValue: StoredState<Int?> {
        storedState(initial: nil, id: "storedValue")
    }
}

fileprivate struct ExampleStoredValue {
    @StoredState(\.storedValue) var count
}

fileprivate class ExampleStoringViewModel: ObservableObject {
    @StoredState(\.storedValue) var count

    func testPropertyWrapper() {
        count = 27
        _ = TextField(
            value: $count,
            format: .number,
            label: { Text("Count") }
        )
    }
}

final class StoredStateTests: XCTestCase {
    override class func tearDown() {
        Application.logger.debug("StoredStateTests \(Application.description)")
    }

    func testStoredState() {
        XCTAssertNil(Application.storedState(\.storedValue).value)

        let storedValue = ExampleStoredValue()

        XCTAssertEqual(storedValue.count, nil)

        storedValue.count = 1

        XCTAssertEqual(storedValue.count, 1)

        storedValue.count = nil

        XCTAssertNil(Application.storedState(\.storedValue).value)
    }

    func testStoringViewModel() {
        XCTAssertNil(Application.storedState(\.storedValue).value)

        let viewModel = ExampleStoringViewModel()

        XCTAssertEqual(viewModel.count, nil)

        viewModel.testPropertyWrapper()

        XCTAssertEqual(viewModel.count, 27)

        Application.remove(storedState: \.storedValue)

        XCTAssertNil(viewModel.count)
    }
}