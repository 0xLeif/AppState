import XCTest
@testable import AppState

fileprivate protocol Networking {
    func fetch()
}

fileprivate struct NetworkService: Networking {
    func fetch() {
        fatalError()
    }
}

fileprivate struct MockNetworking: Networking {
    func fetch() {

    }
}

fileprivate extension Application {
    var networking: Dependency<Networking> {
        dependency(NetworkService())
    }
}

fileprivate struct ExampleDependencyWrapper {
    @AppDependency(\.networking) private var networking

    func fetch() {
        networking.fetch()
    }
}

final class AppDependencyTests: XCTestCase {
    override class func setUp() {
        Application.logging(isEnabled: true)
    }

    override class func tearDown() {
        Application.logger.debug("AppDependencyTests \(Application.description)")
    }

    func testDependency() {
        let networkingOverride = Application.override(\.networking, with: MockNetworking())

        let mockNetworking = Application.dependency(\.networking)

        XCTAssertNotNil(mockNetworking as? MockNetworking)

        mockNetworking.fetch()

        let example = ExampleDependencyWrapper()

        example.fetch()

        networkingOverride.cancel()

        let networkingService = Application.dependency(\.networking)

        XCTAssertNotNil(networkingService as? NetworkService)
    }
}
