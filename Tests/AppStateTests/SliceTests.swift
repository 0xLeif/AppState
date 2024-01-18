import SwiftUI
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

fileprivate class ExampleViewModel: ObservableObject {
    @Slice(\.exampleValue, \.username) var username
    @Constant(\.exampleValue, \.value) var value

    func testPropertyWrapper() {
        username = "Hello, ExampleView"
    }
}

fileprivate struct ExampleView: View {
    @Slice(\.exampleValue, \.username) var username
    @Slice(\.exampleValue, \.isLoading) var isLoading
    @Constant(\.exampleValue, \.mutableValue) var constantMutableValue

    var body: some View { fatalError() }
    
    func testPropertyWrappers() {
        username = "Hello, ExampleView"
        _ = Toggle(isOn: $isLoading) {
            Text(constantMutableValue)
        }
    }
}

final class SliceTests: XCTestCase {
    override class func setUp() {
        Application.logging(isEnabled: true)
    }
    
    override class func tearDown() {
        Application.logger.debug("AppStateTests \(Application.description)")
    }

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
