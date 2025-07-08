import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif
import XCTest
@testable import AppState

fileprivate extension Application {
    var isLoading: State<Bool> {
        state(initial: false)
    }
    
    var username: State<String> {
        state(initial: "Leif")
    }
    
    var date: State<Date> {
        state(initial: Date())
    }
    
    var colors: State<[String: String]> {
        state(initial: ["primary": "#A020F0"])
    }

    var count: State<Int> {
        state(initial: 42)
    }

    var piValue: State<Double> {
        state(initial: 3.14159)
    }

    var customStruct: State<TestStruct> {
        state(initial: TestStruct(id: 1, name: "InitialStruct"))
    }

    var customEnum: State<TestEnum> {
        state(initial: .caseA)
    }
}

fileprivate struct TestStruct: Equatable, Codable {
    let id: Int
    let name: String
}

fileprivate enum TestEnum: Equatable, Codable {
    case caseA
    case caseB(String)
}

@MainActor
fileprivate class ExampleViewModel {
    @AppState(\.username) var username
    
    func testPropertyWrapper() {
        username = "Hello, ExampleView"
    }
}

#if !os(Linux) && !os(Windows)
extension ExampleViewModel: ObservableObject { }

fileprivate struct ExampleView: View {
    @AppState(\.username) var username
    @AppState(\.isLoading) var isLoading
    
    func testPropertyWrappers() {
        username = "Hello, ExampleView"
        #if !os(Linux) && !os(Windows)
        _ = Toggle(isOn: $isLoading) {
            Text("Is Loading")
        }
        #endif
    }
    
    var body: some View { EmptyView() }
}
#else
@MainActor
fileprivate struct ExampleView {
    @AppState(\.username) var username
    @AppState(\.isLoading) var isLoading
    
    func testPropertyWrappers() {
        username = "Hello, ExampleView"
    }
}
#endif

final class AppStateTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        Application.logging(isEnabled: true)
    }

    @MainActor
    override func tearDown() async throws {
        let applicationDescription = Application.description
        Application.logger.debug("AppStateTests \(applicationDescription)")
        
        var username: Application.State = Application.state(\.username)
        
        username.value = "Leif"
    }

    @MainActor
    func testState() async {
        var appState: Application.State = Application.state(\.username)
        
        XCTAssertEqual(appState.value, "Leif")
        
        appState.value = "0xL"
        
        XCTAssertEqual(appState.value, "0xL")
        XCTAssertEqual(Application.state(\.username).value, "0xL")
    }

    @MainActor
    func testStateClosureCachesValueOnGet() async {
        let dateState: Application.State = Application.state(\.date)
        
        let copyOfDateState: Application.State = Application.state(\.date)
        
        XCTAssertEqual(copyOfDateState.value, dateState.value)
    }

    @MainActor
    func testPropertyWrappers() async {
        let exampleView = ExampleView()
        
        XCTAssertEqual(exampleView.username, "Leif")
        
        exampleView.testPropertyWrappers()
        
        XCTAssertEqual(exampleView.username, "Hello, ExampleView")
        
        let viewModel = ExampleViewModel()
        
        XCTAssertEqual(viewModel.username, "Hello, ExampleView")
        
        viewModel.username = "Hello, ViewModel"
        
        XCTAssertEqual(viewModel.username, "Hello, ViewModel")
    }

    @MainActor
    func testStateWithDifferentDataTypes() async {
        // Test Int
        var countState: Application.State<Int> = Application.state(\.count)
        countState.value = 100
        XCTAssertEqual(Application.state(\.count).value, 100)

        // Test Double
        var piState: Application.State<Double> = Application.state(\.piValue)
        XCTAssertEqual(piState.value, 3.14159)
        piState.value = 3.14
        XCTAssertEqual(Application.state(\.piValue).value, 3.14)

        // Test Dictionary
        var colorsState: Application.State<[String: String]> = Application.state(\.colors)
        XCTAssertEqual(colorsState.value["primary"], "#A020F0")
        colorsState.value["secondary"] = "#FFFFFF"
        XCTAssertEqual(Application.state(\.colors).value["secondary"], "#FFFFFF")

        // Test Custom Struct
        var structState: Application.State<TestStruct> = Application.state(\.customStruct)
        XCTAssertEqual(structState.value, TestStruct(id: 1, name: "InitialStruct"))
        structState.value = TestStruct(id: 2, name: "UpdatedStruct")
        XCTAssertEqual(Application.state(\.customStruct).value, TestStruct(id: 2, name: "UpdatedStruct"))

        // Test Custom Enum
        var enumState: Application.State<TestEnum> = Application.state(\.customEnum)
        XCTAssertEqual(enumState.value, .caseA)
        enumState.value = .caseB("TestValue")
        XCTAssertEqual(Application.state(\.customEnum).value, .caseB("TestValue"))
    }

    @MainActor
    func testLoggingToggle() {
        // Assuming default is true from setUp
        XCTAssertTrue(Application.isLoggingEnabled)
        Application.logger.debug("This should be logged from testLoggingToggle.")

        Application.logging(isEnabled: false)
        XCTAssertFalse(Application.isLoggingEnabled)
        Application.logger.debug("This should NOT be logged from testLoggingToggle.") // This won't be asserted, just for manual check if needed

        Application.logging(isEnabled: true)
        XCTAssertTrue(Application.isLoggingEnabled)
        Application.logger.debug("This should be logged again from testLoggingToggle.")
    }
}
