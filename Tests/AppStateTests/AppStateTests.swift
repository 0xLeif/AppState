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

    var date: State<Date> {
        state(initial: Date())
    }

    var colors: State<[String: String]> {
        state(initial: ["primary": "#A020F0"])
    }
}

fileprivate class ExampleViewModel {
    @AppState(\.username) var username

    func testPropertyWrapper() {
        username = "Hello, ExampleView"
    }
}

#if !os(Linux) && !os(Windows)
extension ExampleViewModel: ObservableObject { }
#endif

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

    func testStateClosureCachesValueOnGet() async {
        let dateState: Application.State = Application.state(\.date)

        let copyOfDateState: Application.State = Application.state(\.date)

        XCTAssertEqual(copyOfDateState.value, dateState.value)
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
