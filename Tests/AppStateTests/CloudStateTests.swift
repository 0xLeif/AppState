#if !os(Linux) && !os(Windows)
import SwiftUI
import XCTest
@testable import AppState

@available(watchOS 9.0, *)
fileprivate extension Application {
    var cloudValue: CloudState<Int?> {
        cloudState(filename: "cloudValue")
    }

    var cloudFailureValue: CloudState<Double> {
        cloudState(initial: -1, filename: "cloudValue")
    }
}

@available(watchOS 9.0, *)
fileprivate struct ExampleSyncValue {
    @CloudState(\.cloudValue) var count
}


@available(watchOS 9.0, *)
fileprivate struct ExampleFailureSyncValue {
    @CloudState(\.cloudFailureValue) var count
}


@available(watchOS 9.0, *)
fileprivate class ExampleStoringViewModel: ObservableObject {
    @CloudState(\.cloudValue) var count

    func testPropertyWrapper() {
        count = 27
        _ = TextField(
            value: $count,
            format: .number,
            label: { Text("Count") }
        )
    }
}

@available(watchOS 9.0, *)
final class CloudStateTests: XCTestCase {
    override class func setUp() {
        Application
            .logging(isEnabled: true)
            .load(dependency: \.icloudStore)
    }

    override class func tearDown() {
        Application.logger.debug("CloudStateTests \(Application.description)")
    }

    func testCloudState() {
        XCTAssertNil(Application.cloudState(\.cloudValue).value)

        let cloudValue = ExampleSyncValue()

        XCTAssertEqual(cloudValue.count, nil)

        cloudValue.count = 1

        XCTAssertEqual(cloudValue.count, 1)

        Application.logger.debug("CloudStateTests \(Application.description)")

        cloudValue.count = nil

        XCTAssertNil(Application.cloudState(\.cloudValue).value)
    }

    func testFailEncodingCloudState() {
        XCTAssertNotNil(Application.cloudState(\.cloudFailureValue).value)

        let cloudValue = ExampleFailureSyncValue()

        XCTAssertEqual(cloudValue.count, -1)

        cloudValue.count = Double.infinity

        XCTAssertEqual(cloudValue.count, Double.infinity)
    }

    func testStoringViewModel() {
        XCTAssertNil(Application.cloudState(\.cloudValue).value)

        let viewModel = ExampleStoringViewModel()

        XCTAssertEqual(viewModel.count, nil)

        viewModel.testPropertyWrapper()

        XCTAssertEqual(viewModel.count, 27)

        Application.reset(cloudState: \.cloudValue)

        XCTAssertNil(viewModel.count)
    }
}
#endif
