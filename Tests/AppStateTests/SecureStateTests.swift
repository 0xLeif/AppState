#if !os(Linux) && !os(Windows)
import SwiftUI
import XCTest
@testable import AppState

fileprivate extension Application {
    var secureValue: SecureState {
        secureState(id: "secureState")
    }
}

fileprivate struct ExampleSecureValue {
    @SecureState(\.secureValue) var token: String?
}

fileprivate class ExampleSecureViewModel: ObservableObject {
    @SecureState(\.secureValue) var token: String?

    func testPropertyWrapper() {
        token = "QWERTY"
        _ = Picker("Picker", selection: $token, content: EmptyView.init)
    }
}

final class SecureStateTests: XCTestCase {
    override class func setUp() {
        Application
            .logging(isEnabled: true)
            .load(dependency: \.keychain)
    }

    override class func tearDown() {
        Application.logger.debug("SecureStateTests \(Application.description)")
    }

    func testSecureState() {
        XCTAssertNil(Application.secureState(\.secureValue).value)

        let secureValue = ExampleSecureValue()

        XCTAssertEqual(secureValue.token, nil)
        
        secureValue.token = "QWERTY"

        XCTAssertEqual(secureValue.token, "QWERTY")
        
        secureValue.token = UUID().uuidString

        XCTAssertNotEqual(secureValue.token, "QWERTY")

        Application.logger.debug("SecureStateTests \(Application.description)")

        secureValue.token = nil

        XCTAssertNil(Application.secureState(\.secureValue).value)
    }

    func testStoringViewModel() {
        XCTAssertNil(Application.secureState(\.secureValue).value)

        let viewModel = ExampleSecureViewModel()

        XCTAssertEqual(viewModel.token, nil)

        viewModel.testPropertyWrapper()

        XCTAssertEqual(viewModel.token, "QWERTY")

        Application.reset(secureState: \.secureValue)

        XCTAssertNil(viewModel.token)
    }
}
#endif
