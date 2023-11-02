import XCTest
@testable import AppState

protocol Networking { }

struct NetworkService: Networking { }
struct MockNetworking: Networking { }

extension Application {
    // DI - Live
    static var networking: Networking {
        dependency(NetworkService())
    }

    // SwiftUI State / App State
    var isLoading: Application.State<Bool> {
        state(initial: false)
    }

    // SwiftUI State / App State
    var username: State<String> {
        state(initial: "Leif")
    }

    // SwiftUI State / App State
    var colors: State<[String: CGColor]> {
        state(initial: ["primary": CGColor(red: 1, green: 0, blue: 1, alpha: 1)])
    }
}

final class AppStateTests: XCTestCase {
    func testExample() throws {
        var appState: Application.State = Application.state(\.username)

        XCTAssertEqual(appState.value, "Leif")

        appState.value = "0xL"

        XCTAssertEqual(appState.value, "0xL")
        XCTAssertEqual(Application.state(\.username).value, "0xL")
    }
}
