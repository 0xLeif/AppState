import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif
import XCTest
@testable import AppState

fileprivate class ExampleViewModel {
    var username: String? = nil
    var isLoading: Bool = false
    let value: String = "Hello, World!"
    var mutableValue: String = "..."
}

#if !os(Linux) && !os(Windows)
extension ExampleViewModel: ObservableObject { }
#endif

fileprivate extension Application {
    var exampleViewModel: Dependency<ExampleViewModel> {
        dependency(ExampleViewModel())
    }
}

fileprivate struct ExampleView {
    @DependencySlice(\.exampleViewModel, \.username) var username
    @DependencySlice(\.exampleViewModel, \.isLoading) var isLoading
    @DependencyConstant(\.exampleViewModel, \.value) var constantValue
    @DependencyConstant(\.exampleViewModel, \.mutableValue) var constantMutableValue

    func testPropertyWrappers() {
        username = "Hello, ExampleView"
        #if !os(Linux) && !os(Windows)
        _ = Toggle(isOn: $isLoading) {
            Text(constantMutableValue)
        }
        #endif
    }
}

final class DependencySliceTests: XCTestCase {
    override class func setUp() {
        Application.logging(isEnabled: true)
    }

    override class func tearDown() {
        Application.logger.debug("DependencySliceTests \(Application.description)")
    }

    func testApplicationSliceFunction() {
        var exampleSlice = Application.dependencySlice(\.exampleViewModel, \.username)

        exampleSlice.value = "New Value!"

        XCTAssertEqual(exampleSlice.value, "New Value!")
        XCTAssertEqual(Application.dependencySlice(\.exampleViewModel, \.username).value, "New Value!")
        XCTAssertEqual(Application.dependency(\.exampleViewModel).username, "New Value!")

        exampleSlice.value = "Leif"

        XCTAssertEqual(exampleSlice.value, "Leif")
        XCTAssertEqual(Application.dependencySlice(\.exampleViewModel, \.username).value, "Leif")
        XCTAssertEqual(Application.dependency(\.exampleViewModel).username, "Leif")
    }

    func testPropertyWrappers() {
        let exampleView = ExampleView()

        XCTAssertEqual(exampleView.username, "Leif")

        exampleView.testPropertyWrappers()

        XCTAssertEqual(exampleView.username, "Hello, ExampleView")
        XCTAssertEqual(exampleView.constantValue, "Hello, World!")
        XCTAssertEqual(exampleView.constantMutableValue, "...")
    }
}
