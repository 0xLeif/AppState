import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif
import XCTest
@testable import AppState

fileprivate extension Application {
    var isLoading: State<Bool> {
        state(initial: false)
    }

    var username: State<String> {
        state(initial: "Leif")
    }

    var colors: State<[String: CGColor]> {
        state(initial: ["primary": CGColor(red: 1, green: 0, blue: 1, alpha: 1)])
    }
}

fileprivate class ExampleViewModel: ObservableObject {
    @AppState(\.username) var username

    func testPropertyWrapper() {
        username = "Hello, ExampleView"
    }
}

fileprivate struct ExampleView {
    @AppState(\.username) var username
    @AppState(\.isLoading) var isLoading

    func testPropertyWrappers() {
        username = "Hello, ExampleView"
        #if !os(Linux) && !os(Windows)
        _ = Toggle(isOn: $isLoading) {
            Text("Is Loading")
        }
        #endif
    }
}

final class AppStateTests: XCTestCase {
    override class func setUp() {
        Application.logging(isEnabled: true)
    }
    
    override class func tearDown() {
        Application.logger.debug("AppStateTests \(Application.description)")
    }

    override func tearDown() {
        var username: Application.State = Application.state(\.username)
        username.value = "Leif"
    }

    func testState() {
        var appState: Application.State = Application.state(\.username)

        XCTAssertEqual(appState.value, "Leif")

        appState.value = "0xL"

        XCTAssertEqual(appState.value, "0xL")
        XCTAssertEqual(Application.state(\.username).value, "0xL")
    }

    func testPropertyWrappers() {
        let exampleView = ExampleView()

        XCTAssertEqual(exampleView.username, "Leif")

        exampleView.testPropertyWrappers()

        XCTAssertEqual(exampleView.username, "Hello, ExampleView")

        let viewModel = ExampleViewModel()

        XCTAssertEqual(viewModel.username, "Hello, ExampleView")

        viewModel.username = "Hello, ViewModel"

        XCTAssertEqual(viewModel.username, "Hello, ViewModel")
    }
}
