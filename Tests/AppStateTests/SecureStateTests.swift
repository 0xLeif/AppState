import SwiftUI
import XCTest
@testable import AppState

fileprivate extension Application {
    var secureValue: SecureState {
        secureState(id: "secureState")
    }
}

fileprivate struct ExampleStoredValue {
    @SecureState(\.secureValue) var token: String?
}

fileprivate class ExampleStoringViewModel: ObservableObject {
    @SecureState(\.secureValue) var token: String?

    func testPropertyWrapper() {
        token = "QWERTY"
        _ = Picker("Picker", selection: $token, content: EmptyView.init)
    }
}

final class SecureStateTests: XCTestCase {
    override class func setUp() {
        Application.logging(isEnabled: true)
    }

    override class func tearDown() {
        Application.logger.debug("StoredStateTests \(Application.description)")
    }

    func testStoredState() {
        XCTAssertNil(Application.secureState(\.secureValue).value)

        let secureValue = ExampleStoredValue()

        XCTAssertEqual(secureValue.token, nil)

        secureValue.token = "QWERTY"

        XCTAssertEqual(secureValue.token, "QWERTY")

        Application.logger.debug("StoredStateTests \(Application.description)")

        secureValue.token = nil

        XCTAssertNil(Application.secureState(\.secureValue).value)
    }

    func testStoringViewModel() {
        XCTAssertNil(Application.secureState(\.secureValue).value)

        let viewModel = ExampleStoringViewModel()

        XCTAssertEqual(viewModel.token, nil)

        viewModel.testPropertyWrapper()

        XCTAssertEqual(viewModel.token, "QWERTY")

        Application.reset(secureState: \.secureValue)

        XCTAssertNil(viewModel.token)
    }
}