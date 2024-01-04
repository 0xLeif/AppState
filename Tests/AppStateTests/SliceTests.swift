import SwiftUI
import XCTest
@testable import AppState

struct ExampleValue {
    var username: String
    var isLoading: Bool
}

fileprivate extension Application {
    var exampleValue: State<ExampleValue> {
        state(
            initial: ExampleValue(
                username: "Leif",
                isLoading: false
            )
        )
    }
}

fileprivate class ExampleViewModel: ObservableObject {
    @Slice(\.exampleValue, \.username) var username
    
    func testPropertyWrapper() {
        username = "Hello, ExampleView"
    }
}

fileprivate struct ExampleView: View {
    @Slice(\.exampleValue, \.username) var username
    @Slice(\.exampleValue, \.isLoading) var isLoading
    
    var body: some View { fatalError() }
    
    func testPropertyWrappers() {
        username = "Hello, ExampleView"
        _ = Toggle(isOn: $isLoading) {
            Text("Is Loading")
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
    
    func testPropertyWrappers() {
        let exampleView = ExampleView()
        
        XCTAssertEqual(exampleView.username, "Leif")
        
        exampleView.testPropertyWrappers()
        
        XCTAssertEqual(exampleView.username, "Hello, ExampleView")
        
        let viewModel = ExampleViewModel()
        
        XCTAssertEqual(viewModel.username, "Hello, ExampleView")
        
        viewModel.username = "Hello, ViewModel"
        
        XCTAssertEqual(viewModel.username, "Hello, ViewModel")
    }
}
