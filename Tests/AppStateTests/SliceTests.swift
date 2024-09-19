import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif
import XCTest
@testable import AppState

fileprivate struct ExampleValue {
    var username: String?
    var isLoading: Bool
    let value: String
    var mutableValue: String
}

fileprivate extension Application {
    var exampleValue: State<ExampleValue> {
        state(
            initial: ExampleValue(
                username: "Leif",
                isLoading: false,
                value: "value",
                mutableValue: ""
            )
        )
    }
}

@MainActor
fileprivate class ExampleViewModel {
    @Slice(\.exampleValue, \.username) var username
    @Constant(\.exampleValue, \.value) var value

    func testPropertyWrapper() {
        username = "Hello, ExampleView"
    }
}

#if !os(Linux) && !os(Windows)
extension ExampleViewModel: ObservableObject { }
#endif

@MainActor
fileprivate struct ExampleView {
    @Slice(\.exampleValue, \.username) var username
    @Slice(\.exampleValue, \.isLoading) var isLoading
    @Constant(\.exampleValue, \.mutableValue) var constantMutableValue
    
    func testPropertyWrappers() {
        username = "Hello, ExampleView"
        #if !os(Linux) && !os(Windows)
        _ = Toggle(isOn: $isLoading) {
            Text(constantMutableValue)
        }
        #endif
    }
}

final class SliceTests: XCTestCase {
    override func setUp() async throws {
        await Application.logging(isEnabled: true)
    }

    override func tearDown() async throws {
        let applicationDescription = await Application.description

        Application.logger.debug("AppStateTests \(applicationDescription)")
    }

    @MainActor
    func testApplicationSliceFunction() {
        var exampleSlice = Application.slice(\.exampleValue, \.username)

        exampleSlice.value = "New Value!"

        XCTAssertEqual(exampleSlice.value, "New Value!")
        XCTAssertEqual(Application.slice(\.exampleValue, \.username).value, "New Value!")
        XCTAssertEqual(Application.state(\.exampleValue).value.username, "New Value!")

        exampleSlice.value = "Leif"

        XCTAssertEqual(exampleSlice.value, "Leif")
        XCTAssertEqual(Application.slice(\.exampleValue, \.username).value, "Leif")
        XCTAssertEqual(Application.state(\.exampleValue).value.username, "Leif")
    }

    @MainActor
    func testPropertyWrappers() {
        let exampleView = ExampleView()
        
        XCTAssertEqual(exampleView.username, "Leif")
        
        exampleView.testPropertyWrappers()
        
        XCTAssertEqual(exampleView.username, "Hello, ExampleView")
        
        let viewModel = ExampleViewModel()
        
        XCTAssertEqual(viewModel.username, "Hello, ExampleView")
        
        viewModel.username = "Hello, ViewModel"
        
        XCTAssertEqual(viewModel.username, "Hello, ViewModel")

        XCTAssertEqual(viewModel.value, "value")
    }
}
