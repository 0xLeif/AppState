//import Foundation
//#if !os(Linux) && !os(Windows)
//import SwiftUI
//#endif
//import XCTest
//@testable import AppState
//
//fileprivate extension Application {
//    var storedValue: StoredState<Int?> {
//        storedState(id: "storedValue")
//    }
//}
//
//@MainActor
//fileprivate struct ExampleStoredValue {
//    @StoredState(\.storedValue) var count
//}
//
//@MainActor
//fileprivate class ExampleStoringViewModel {
//    @StoredState(\.storedValue) var count
//
//    func testPropertyWrapper() {
//        count = 27
//        #if !os(Linux) && !os(Windows)
//        _ = TextField(
//            value: $count,
//            format: .number,
//            label: { Text("Count") }
//        )
//        #endif
//    }
//}
//
//#if !os(Linux) && !os(Windows)
//extension ExampleStoringViewModel: ObservableObject { }
//#endif
//
//@MainActor
//final class StoredStateTests: XCTestCase {
//    override func setUp() async throws {
//        Application.logging(isEnabled: true)
//    }
//
//    override func tearDown() async throws {
//        let applicationDescription = Application.description
//
//        Application.logger.debug("StoredStateTests \(applicationDescription)")
//    }
//
//    func testStoredState() {
//        XCTAssertNil(Application.storedState(\.storedValue).value)
//
//        let storedValue = ExampleStoredValue()
//
//        XCTAssertEqual(storedValue.count, nil)
//
//        storedValue.count = 1
//
//        XCTAssertEqual(storedValue.count, 1)
//
//        Application.logger.debug("StoredStateTests \(Application.description)")
//
//        storedValue.count = nil
//
//        XCTAssertNil(Application.storedState(\.storedValue).value)
//    }
//
//    func testStoringViewModel() {
//        XCTAssertNil(Application.storedState(\.storedValue).value)
//
//        let viewModel = ExampleStoringViewModel()
//
//        XCTAssertEqual(viewModel.count, nil)
//
//        viewModel.testPropertyWrapper()
//
//        XCTAssertEqual(viewModel.count, 27)
//
//        Application.reset(storedState: \.storedValue)
//
//        XCTAssertNil(viewModel.count)
//    }
//}
