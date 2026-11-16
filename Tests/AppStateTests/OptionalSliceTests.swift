import Foundation
import Observation
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

/// A `Sendable` flag the `@Sendable` `onChange` closure can write to.
/// `withObservationTracking` delivers that closure synchronously, so the tests
/// read the flag after the write. `XCTestCase.fulfillment(of:)` sends the test
/// instance and does not compile on the Swift 6.1 Linux and Windows toolchains.
private final class SliceChangeFlag: @unchecked Sendable {
    var didChange = false
}

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
    @MainActor
    override func setUp() async throws {
        Application.logging(isEnabled: true)
    }

    @MainActor
    override func tearDown() async throws {
        let applicationDescription = Application.description

        Application.dependency(\.logger).debug("AppStateTests \(applicationDescription)")
    }

    @MainActor
    func testApplicationSliceFunction() async {
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
    func testPropertyWrappers() async {
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
    func testNil() async {
        let viewModel = ExampleViewModel()
        viewModel.username = nil
        XCTAssertNil(viewModel.username)
        viewModel.username = "Leif"
        XCTAssertNotNil(viewModel.username)
        viewModel.username = nil
        XCTAssertNil(viewModel.username)
    }

    /// A `nil` written to a non-optional field has nothing to store, so it must not write or notify.
    /// On 3.0.1 the setter wrote the unchanged value back and notified.
    @MainActor
    func testApplicationSliceNilForNonOptionalFieldDoesNotWriteOrNotify() async {
        var isLoadingSlice = Application.slice(\.exampleValue, \.isLoading)

        isLoadingSlice.value = true

        let change = SliceChangeFlag()

        withObservationTracking {
            _ = Application.state(\.exampleValue).value
        } onChange: {
            change.didChange = true
        }

        isLoadingSlice.value = nil

        XCTAssertFalse(change.didChange)

        XCTAssertEqual(isLoadingSlice.value, true)
        XCTAssertEqual(Application.state(\.exampleValue).value?.isLoading, true)
    }

    /// The control for the test above: a `nil` written to an optional field is stored and notifies.
    @MainActor
    func testApplicationSliceNilForOptionalFieldStoresNilAndNotifies() async {
        var usernameSlice = Application.slice(\.exampleValue, \.username)

        usernameSlice.value = "Leif"

        let change = SliceChangeFlag()

        withObservationTracking {
            _ = Application.state(\.exampleValue).value
        } onChange: {
            change.didChange = true
        }

        usernameSlice.value = nil

        XCTAssertTrue(change.didChange)

        XCTAssertNil(usernameSlice.value)
        XCTAssertNotNil(Application.state(\.exampleValue).value)
        XCTAssertNil(Application.state(\.exampleValue).value?.username)
    }

    /// An optional field reached through the non-optional `OptionalSlice` type still clears on `nil`.
    @MainActor
    func testApplicationSliceNilClearsOptionalFieldThroughNonOptionalSliceType() async {
        var usernameSlice: Application.OptionalSlice<
            Application.State<ExampleValue?>,
            ExampleValue,
            String?,
            WritableKeyPath<ExampleValue, String?>
        > = Application.slice(\.exampleValue, \.username)

        usernameSlice.value = "Leif"

        XCTAssertEqual(Application.state(\.exampleValue).value?.username, "Leif")

        usernameSlice.value = nil

        XCTAssertNotNil(Application.state(\.exampleValue).value)
        XCTAssertNil(Application.state(\.exampleValue).value?.username)
    }

    @MainActor
    func testPropertyWrapperNilForNonOptionalFieldDoesNotWriteOrNotify() async {
        let viewModel = ExampleViewModel()

        viewModel.isLoading = true

        #if !os(Linux) && !os(Windows)
        var hostChangeCount = 0
        let cancellable = viewModel.objectWillChange.sink { hostChangeCount += 1 }
        #endif

        let change = SliceChangeFlag()

        withObservationTracking {
            _ = Application.state(\.exampleValue).value
        } onChange: {
            change.didChange = true
        }

        viewModel.isLoading = nil

        XCTAssertFalse(change.didChange)

        XCTAssertEqual(viewModel.isLoading, true)

        #if !os(Linux) && !os(Windows)
        XCTAssertEqual(hostChangeCount, 0)

        viewModel.username = "Leif"
        viewModel.username = nil

        XCTAssertEqual(hostChangeCount, 2)

        cancellable.cancel()
        #endif

        XCTAssertNil(viewModel.username)
    }
}
