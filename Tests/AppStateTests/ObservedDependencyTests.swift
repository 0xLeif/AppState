//#if !os(Linux) && !os(Windows)
//import SwiftUI
//import XCTest
//@testable import AppState
//
//@MainActor
//fileprivate class ObservableService: ObservableObject {
//    @Published var count: Int
//
//    init() {
//        count = 0
//    }
//}
//
//fileprivate extension Application {
//    var test: Dependency<String> {
//        dependency("!!!")
//    }
//
//    @MainActor
//    var observableService: Dependency<ObservableService> {
//        dependency(ObservableService())
//    }
//}
//
//@MainActor
//fileprivate struct ExampleDependencyWrapper {
//    @ObservedDependency(\.observableService) var service
//
//    func test() {
//        service.count += 1
//
//        _ = Picker("", selection: $service.count, content: EmptyView.init)
//    }
//}
//
//@MainActor
//final class ObservedDependencyTests: XCTestCase {
//    override func setUp() async throws {
//        Application.logging(isEnabled: true)
//    }
//
//    override func tearDown() async throws {
//        let applicationDescription = Application.description
//
//        Application.logger.debug("ObservedDependencyTests \(applicationDescription)")
//    }
//
//    func testDependency() {
//        let example = ExampleDependencyWrapper()
//
//        XCTAssertEqual(example.service.count, 0)
//
//        example.test()
//
//        XCTAssertEqual(example.service.count, 1)
//    }
//}
//#endif
