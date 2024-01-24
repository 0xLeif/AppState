#if !os(Linux) && !os(Windows)
import SwiftUI
import XCTest
@testable import AppState

fileprivate class ObservableService: ObservableObject {
    @Published var count: Int

    init() { 
        count = 0
    }
}

fileprivate extension Application {
    var test: Dependency<String> {
        dependency("!!!")
    }

    var observableService: Dependency<ObservableService> {
        dependency(ObservableService())
    }
}

fileprivate struct ExampleDependencyWrapper {
    @ObservedDependency(\.observableService) var service

    func test() {
        service.count += 1

        _ = Picker("", selection: $service.count, content: EmptyView.init)
    }
}

final class ObservedDependencyTests: XCTestCase {
    override class func setUp() {
        Application.logging(isEnabled: true)
    }

    override class func tearDown() {
        Application.logger.debug("ObservedDependencyTests \(Application.description)")
    }

    func testDependency() {
        let example = ExampleDependencyWrapper()

        XCTAssertEqual(example.service.count, 0)

        example.test()

        XCTAssertEqual(example.service.count, 1)
    }
}
#endif
