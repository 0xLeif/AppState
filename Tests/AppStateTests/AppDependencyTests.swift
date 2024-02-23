import Waiter
import XCTest
@testable import AppState

fileprivate protocol Networking {
    func fetch()
}

fileprivate class NetworkService: Networking {
    func fetch() {
        fatalError()
    }
}

fileprivate class MockNetworking: Networking {
    func fetch() { /* no-op */ }
}

fileprivate class ComposableService {
    let networking: Networking

    init(networking: Networking) {
        self.networking = networking
    }
}

fileprivate extension Application {
    var networking: Dependency<Networking> {
        dependency(NetworkService())
    }

    var composableService: Dependency<ComposableService> {
        dependency(ComposableService(networking: Application.dependency(\.networking)))
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
        Application
            .logging(isEnabled: true)
            .promote(\.networking, with: MockNetworking())
    }

    override class func tearDown() {
        Application.logger.debug("AppDependencyTests \(Application.description)")
    }

    func testComposableDependencies() {
        let composableService = Application.dependency(\.composableService)

        composableService.networking.fetch()
    }

    func testDependency() async throws {
        Application.promote(\.networking, with: NetworkService())

        let networkingOverride = Application.override(\.networking, with: MockNetworking())

        let mockNetworking = Application.dependency(\.networking)

        XCTAssertNotNil(mockNetworking as? MockNetworking)

        mockNetworking.fetch()

        let example = ExampleDependencyWrapper()

        example.fetch()

        networkingOverride.cancel()

        try await Waiter.wait(
            on: Application.shared,
            for: \.networking,
            expecting: { $0.value is NetworkService }
        )

        let networkingService = Application.dependency(\.networking)

        XCTAssertNotNil(networkingService as? NetworkService)
    }
}
