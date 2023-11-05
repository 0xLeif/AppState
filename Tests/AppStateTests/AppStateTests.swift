import SwiftUI
import XCTest
@testable import AppState

protocol Networking {
    func fetch()
}

struct NetworkService: Networking {
    func fetch() {
        fatalError()
    }
}

struct MockNetworking: Networking {
    func fetch() {

    }
}

extension Application {
    var networking: Dependency<Networking> {
        dependency(NetworkService())
    }

    var isLoading: State<Bool> {
        state(initial: false)
    }

    var username: State<String> {
        state(initial: "Leif")
    }

    var colors: State<[String: CGColor]> {
        state(initial: ["primary": CGColor(red: 1, green: 0, blue: 1, alpha: 1)])
    }

    var storedValue: StoredState<Int> {
        storedState(initial: -1, id: "storedValue")
    }
}

class ExampleViewModel: ObservableObject {
    @AppState(\.username) var username

    func testPropertyWrapper() {
        username = "Hello, ExampleView"
    }
}

class ExampleStoringViewModel: ObservableObject {
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

struct ExampleStoredValue {
    @StoredState(\.storedValue) var count
}

struct ExampleView: View {
    @AppDependency(\.networking) var networking
    @AppState(\.username) var username
    @AppState(\.isLoading) var isLoading

    var body: some View { fatalError() }

    func testPropertyWrappers() {
        username = "Hello, ExampleView"
        networking.fetch()
        _ = Toggle(isOn: $isLoading) {
            Text("Is Loading")
        }
    }
}

final class AppStateTests: XCTestCase {
    override class func tearDown() {
        Application.logger.debug("\(Application.description)")
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

    func testDependency() {
        let networkingOverride = Application.override(\.networking, with: MockNetworking())

        let mockNetworking = Application.dependency(\.networking)

        XCTAssertNotNil(mockNetworking as? MockNetworking)

        mockNetworking.fetch()

        networkingOverride.cancel()

        let networkingService = Application.dependency(\.networking)

        XCTAssertNotNil(networkingService as? NetworkService)
    }

    func testPropertyWrappers() {
        let exampleView = ExampleView()

        let networkingOverride = Application.override(\.networking, with: MockNetworking())
        defer { networkingOverride.cancel() }

        XCTAssertNotNil(exampleView.networking as? MockNetworking)
        XCTAssertEqual(exampleView.username, "Leif")

        exampleView.testPropertyWrappers()

        XCTAssertEqual(exampleView.username, "Hello, ExampleView")

        let viewModel = ExampleViewModel()

        XCTAssertEqual(viewModel.username, "Hello, ExampleView")

        viewModel.username = "Hello, ViewModel"

        XCTAssertEqual(viewModel.username, "Hello, ViewModel")
    }

    func testStoredState() {
        XCTAssertEqual(Application.storedState(\.storedValue).value, -1)

        let storedValue = ExampleStoredValue()

        XCTAssertEqual(storedValue.count, -1)

        storedValue.count = 2

        XCTAssertEqual(storedValue.count, 2)

        Application.remove(storedState: \.storedValue)

        XCTAssertEqual(Application.storedState(\.storedValue).value, -1)
    }

    func testStoringViewModel() {
        XCTAssertEqual(Application.storedState(\.storedValue).value, -1)

        let viewModel = ExampleStoringViewModel()

        XCTAssertEqual(viewModel.count, -1)

        viewModel.count = 2

        XCTAssertEqual(viewModel.count, 2)

        Application.remove(storedState: \.storedValue)

        XCTAssertEqual(viewModel.count, -1)
    }
}
