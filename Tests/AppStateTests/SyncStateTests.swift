import SwiftUI
import XCTest
@testable import AppState

@available(iOS 15.0, watchOS 9.0, macOS 11.0, tvOS 15.0, *)
fileprivate extension Application {
    var syncValue: SyncState<Int?> {
        syncState(id: "syncValue")
    }
    
    var syncFailureValue: SyncState<Double> {
        syncState(initial: -1, id: "syncValue")
    }
}

@available(iOS 15.0, watchOS 9.0, macOS 11.0, tvOS 15.0, *)
fileprivate struct ExampleSyncValue {
    @SyncState(\.syncValue) var count
}


@available(iOS 15.0, watchOS 9.0, macOS 11.0, tvOS 15.0, *)
fileprivate struct ExampleFailureSyncValue {
    @SyncState(\.syncFailureValue) var count
}


@available(iOS 15.0, watchOS 9.0, macOS 11.0, tvOS 15.0, *)
fileprivate class ExampleStoringViewModel: ObservableObject {
    @SyncState(\.syncValue) var count

    func testPropertyWrapper() {
        count = 27
        _ = TextField(
            value: $count,
            format: .number,
            label: { Text("Count") }
        )
    }
}


@available(iOS 15.0, watchOS 9.0, macOS 11.0, tvOS 15.0, *)
final class SyncStateTests: XCTestCase {
    override class func setUp() {
        Application
            .logging(isEnabled: true)
            .load(dependency: \.icloudStore)
    }

    override class func tearDown() {
        Application.logger.debug("SyncStateTests \(Application.description)")
    }

    func testSyncState() {
        XCTAssertNil(Application.syncState(\.syncValue).value)

        let syncValue = ExampleSyncValue()

        XCTAssertEqual(syncValue.count, nil)

        syncValue.count = 1

        XCTAssertEqual(syncValue.count, 1)
        
        Application.logger.debug("SyncStateTests \(Application.description)")

        syncValue.count = nil

        XCTAssertNil(Application.syncState(\.syncValue).value)
    }

    func testFailEncodingSyncState() {
        XCTAssertNotNil(Application.syncState(\.syncFailureValue).value)

        let syncValue = ExampleFailureSyncValue()

        XCTAssertEqual(syncValue.count, -1)

        syncValue.count = Double.infinity

        XCTAssertEqual(syncValue.count, Double.infinity)
    }

    func testStoringViewModel() {
        XCTAssertNil(Application.syncState(\.syncValue).value)

        let viewModel = ExampleStoringViewModel()

        XCTAssertEqual(viewModel.count, nil)

        viewModel.testPropertyWrapper()

        XCTAssertEqual(viewModel.count, 27)

        Application.reset(syncState: \.syncValue)

        XCTAssertNil(viewModel.count)
    }
}
