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
}

fileprivate extension Application {
    var exampleValue: State<ExampleValue?> {
        state(
            initial: ExampleValue(
                username: nil,
                isLoading: false,
                value: "value"
            )
        )
    }
}

@MainActor
fileprivate class ExampleViewModel {
    @OptionalSlice(\.exampleValue, \.username) var username
    @OptionalConstant(\.exampleValue, \.value) var value
    @OptionalSlice(\.exampleValue, \.isLoading) var isLoading
    @OptionalConstant(\.exampleValue, \.username) var constantUsername

    func testPropertyWrapper() {
        username = "Hello, ExampleView"
    }
}

#if !os(Linux) && !os(Windows)
extension ExampleViewModel: ObservableObject { }
#endif

@MainActor
fileprivate struct ExampleView {
    @OptionalSlice(\.exampleValue, \.username) var username
    @OptionalSlice(\.exampleValue, \.isLoading) var isLoading

    func testPropertyWrappers() {
        username = "Hello, ExampleView"
        #if !os(Linux) && !os(Windows)
        _ = Picker("Picker", selection: $isLoading, content: EmptyView.init)
        #endif
    }
}

final class OptionalSliceTests: XCTestCase {
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
        XCTAssertEqual(Application.state(\.exampleValue).value?.username, "New Value!")

        exampleSlice.value = "Leif"

        XCTAssertEqual(exampleSlice.value, "Leif")
        XCTAssertEqual(Application.slice(\.exampleValue, \.username).value, "Leif")
        XCTAssertEqual(Application.state(\.exampleValue).value?.username, "Leif")

        exampleSlice.value = nil
    }

    @MainActor
    func testPropertyWrappers() {
        let exampleView = ExampleView()

        exampleView.username = "Leif"

        XCTAssertEqual(exampleView.username, "Leif")

        exampleView.testPropertyWrappers()

        XCTAssertEqual(exampleView.username, "Hello, ExampleView")

        let viewModel = ExampleViewModel()

        XCTAssertEqual(viewModel.username, "Hello, ExampleView")

        viewModel.username = "Hello, ViewModel"

        XCTAssertEqual(viewModel.username, "Hello, ViewModel")
        XCTAssertEqual(viewModel.constantUsername, "Hello, ViewModel")

        viewModel.username = nil

        viewModel.isLoading = nil

        XCTAssertNil(viewModel.username)
        XCTAssertNotNil(viewModel.isLoading)

        XCTAssertEqual(viewModel.value, "value")
    }

    @MainActor
    func testNil() {
        let viewModel = ExampleViewModel()
        viewModel.username = nil
        XCTAssertNil(viewModel.username)
        viewModel.username = "Leif"
        XCTAssertNotNil(viewModel.username)
        viewModel.username = nil
        XCTAssertNil(viewModel.username)
    }
}
