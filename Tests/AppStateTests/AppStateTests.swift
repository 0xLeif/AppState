import XCTest
@testable import AppState

protocol Networking { }

struct NetworkService: Networking { }
struct MockNetworking: Networking { }

// App Folder Target

extension App {
    // DI - Live
    static var networking: Networking {
        dependency(NetworkService())
    }

    // SwiftUI State / App State
    static var isLoading: App.State<Bool> {
        state(initial: false)
    }

    // SwiftUI State / App State
    static var username: State<String> {
        state(initial: "Leif")
    }

    enum Colors {
        // SwiftUI State / App State
        static var tint: State<CGColor> {
            state(initial: CGColor(red: 1, green: 0, blue: 1, alpha: 1))
        }
    }
}

final class AppStateTests: XCTestCase {
    func testExample() throws {
        var appState: App.State = App.username

        XCTAssertEqual(appState.value, "Leif")

        appState.value = "0xL"

        XCTAssertEqual(appState.value, "0xL")
        XCTAssertEqual(App.username.value, "0xL")
    }

    func testARC() {
        class Bar {
            weak var object: AnyObject?

            init(object: AnyObject) {
                self.object = object
            }

            deinit {
                print("DEINIT Bar")
            }
        }

        class Manager {
            lazy var bar: Bar = Bar(
                object: self
            )

            deinit {
                print("DEINIT Manager")
            }
        }

        var manager: Manager? = Manager()

        _ = manager?.bar

        manager = nil
    }
}
