#if !os(Linux) && !os(Windows)
import SwiftUI
import XCTest
@testable import AppState

@available(watchOS 9.0, *)
fileprivate extension Application {
    var syncValue: SyncState<Int?> {
        syncState(id: "syncValue")
    }
    
    var syncFailureValue: SyncState<Double> {
        syncState(initial: -1, id: "syncValue")
    }
}

@available(watchOS 9.0, *)
@MainActor
fileprivate struct ExampleSyncValue {
    @SyncState(\.syncValue) var count
}


@available(watchOS 9.0, *)
@MainActor
fileprivate struct ExampleFailureSyncValue {
    @SyncState(\.syncFailureValue) var count
}


@available(watchOS 9.0, *)
@MainActor
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


@available(watchOS 9.0, *)
final class SyncStateTests: XCTestCase {
    override func setUp() async throws {
        await Application
            .logging(isEnabled: true)
            .load(dependency: \.icloudStore)
    }

    override func tearDown() async throws {
        let applicationDescription = await Application.description

        Application.logger.debug("SyncStateTests \(applicationDescription)")
    }

    @MainActor
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

    @MainActor
    func testFailEncodingSyncState() {
        XCTAssertNotNil(Application.syncState(\.syncFailureValue).value)

        let syncValue = ExampleFailureSyncValue()

        XCTAssertEqual(syncValue.count, -1)

        syncValue.count = Double.infinity

        XCTAssertEqual(syncValue.count, Double.infinity)
    }

    @MainActor
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
#endif
