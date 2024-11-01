import XCTest
@testable import AppState

fileprivate protocol Networking: Sendable {
    func fetch()
}

fileprivate final class NetworkService: Networking {
    func fetch() {
        fatalError()
    }
}

fileprivate final class MockNetworking: Networking {
    func fetch() { /* no-op */ }
}

@MainActor
fileprivate class ComposableService {
    @AppDependency(\.networking) var networking: Networking
}

fileprivate extension Application {
    var networking: Dependency<Networking> {
        dependency(NetworkService())
    }

    @MainActor
    var composableService: Dependency<ComposableService> {
        dependency(ComposableService())
    }
}

fileprivate struct ExampleDependencyWrapper {
    @AppDependency(\.networking) private var networking

    @MainActor
    func fetch() {
        networking.fetch()
    }
}

@MainActor
final class AppDependencyTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        Application
            .logging(isEnabled: true)
            .promote(\.networking, with: MockNetworking())
    }

    @MainActor
    override func tearDown() async throws {
        let applicationDescription = Application.description

        Application.logger.debug("AppDependencyTests \(applicationDescription)")
    }

    @MainActor
    func testComposableDependencies() {
        let composableService = Application.dependency(\.composableService)

        composableService.networking.fetch()
    }

    @MainActor
    func testDependency() async {
        Application.promote(\.networking, with: NetworkService())

        let networkingOverride = Application.override(\.networking, with: MockNetworking())

        let mockNetworking = Application.dependency(\.networking)

        XCTAssertNotNil(mockNetworking as? MockNetworking)

        mockNetworking.fetch()

        let example = ExampleDependencyWrapper()

        example.fetch()

        await networkingOverride.cancel()

        let networkingService = Application.dependency(\.networking)

        XCTAssertNotNil(networkingService as? NetworkService)
    }
}
