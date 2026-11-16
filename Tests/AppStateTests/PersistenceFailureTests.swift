import Foundation
import XCTest

@testable import AppState

// MARK: - Fixtures

fileprivate struct FailureReading: Codable, Sendable, Equatable {
    var celsius: Double
}

// An iOS app cannot write to its working directory, so the fixtures live in the temporary directory.
fileprivate let failureDirectory = NSTemporaryDirectory() + "PersistenceFailureTests"
fileprivate let failureBlocker = failureDirectory + "/blocker"

fileprivate struct FailureDeleteRefused: Error {}

/// Reads and writes like the real file manager, and refuses every delete.
fileprivate struct DeleteRefusingFileManager: FileManaging {
    func `in`<Value: Decodable>(path: String, filename: String) throws -> Value {
        try FileManager.default.in(path: path, filename: filename)
    }

    func `out`<Value: Encodable>(_ value: Value, path: String, filename: String, base64Encoded: Bool) throws {
        try FileManager.default.out(value, path: path, filename: filename, base64Encoded: base64Encoded)
    }

    func `delete`(path: String, filename: String) throws {
        throw FailureDeleteRefused()
    }

    func removeItem(atPath path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }
}

@MainActor
fileprivate final class RecordingApplication: Application {
    static var failures: [PersistenceFailure] = []

    override func didFailToPersist(_ failure: PersistenceFailure) {
        RecordingApplication.failures.append(failure)
    }
}

extension Application {
    @MainActor
    fileprivate var failureGoodFile: FileState<Int> {
        fileState(initial: 7, path: failureDirectory, filename: "good")
    }

    @MainActor
    fileprivate var failureCorruptFile: FileState<Int> {
        fileState(initial: 7, path: failureDirectory, filename: "corrupt")
    }

    @MainActor
    fileprivate var failureMissingFile: FileState<Int?> {
        fileState(path: failureDirectory, filename: "missing")
    }

    @MainActor
    fileprivate var failureOptionalFile: FileState<Int?> {
        fileState(path: failureDirectory, filename: "optional")
    }

    /// The directory of this state is a regular file, so nothing can be written below it.
    @MainActor
    fileprivate var failureBlockedFile: FileState<Int> {
        fileState(initial: 7, path: failureBlocker, filename: "blocked")
    }

    fileprivate var failureReading: StoredState<FailureReading> {
        storedState(initial: FailureReading(celsius: 0), feature: "PersistenceFailure", id: "reading")
    }

    #if canImport(Security)
    @available(watchOS 9.0, *)
    fileprivate var failureSyncReading: SyncState<FailureReading> {
        syncState(initial: FailureReading(celsius: 0), feature: "PersistenceFailure", id: "syncReading")
    }
    #endif
}

// MARK: - PersistenceFailureTests

/// `Application.didFailToPersist(_:)` hears each failure once and stays quiet otherwise.
final class PersistenceFailureTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        try? FileManager.default.removeItem(atPath: failureDirectory)
        try FileManager.default.createDirectory(atPath: failureDirectory, withIntermediateDirectories: true)

        Application.promote(to: RecordingApplication.self)
        RecordingApplication.failures = []
    }

    @MainActor
    override func tearDown() async throws {
        Application.promote(to: Application.self)
        RecordingApplication.failures = []

        try? FileManager.default.removeItem(atPath: failureDirectory)
    }

    @MainActor
    private func forgetCachedValue(for key: String) {
        Application.shared.cache.remove(key)
    }

    @MainActor
    func testSuccessfulFileStateRoundTripReportsNothing() async {
        var good = Application.fileState(\.failureGoodFile)
        good.value = 12

        forgetCachedValue(for: Application.shared.failureGoodFile.scope.key)

        XCTAssertEqual(Application.fileState(\.failureGoodFile).value, 12)
        XCTAssertTrue(RecordingApplication.failures.isEmpty)
    }

    @MainActor
    func testFileStateThatWasNeverWrittenReportsNothing() async {
        XCTAssertNil(Application.fileState(\.failureMissingFile).value)

        var missing = Application.fileState(\.failureMissingFile)
        missing.value = nil

        XCTAssertTrue(RecordingApplication.failures.isEmpty)
    }

    @MainActor
    func testUnreadableFileReportsReadFailureAndFallsBackToInitial() async throws {
        let key = Application.shared.failureCorruptFile.scope.key

        try Data("{ not json".utf8).write(to: URL(fileURLWithPath: failureDirectory).appendingPathComponent("corrupt"))
        forgetCachedValue(for: key)

        XCTAssertEqual(Application.fileState(\.failureCorruptFile).value, 7)

        XCTAssertEqual(RecordingApplication.failures.count, 1)
        XCTAssertEqual(RecordingApplication.failures.first?.store, .fileState)
        XCTAssertEqual(RecordingApplication.failures.first?.operation, .read)
        XCTAssertEqual(RecordingApplication.failures.first?.key, key)
        XCTAssertTrue(RecordingApplication.failures.first?.error is DecodingError)

        // A view reads its state on every render. The same unreadable file is reported once.
        for _ in 0..<5 {
            XCTAssertEqual(Application.fileState(\.failureCorruptFile).value, 7)
        }

        XCTAssertEqual(RecordingApplication.failures.count, 1)

        // After a successful write the file is readable again, and a new failure is a new report.
        var corrupt = Application.fileState(\.failureCorruptFile)
        corrupt.value = 8

        try Data("{ still not json".utf8).write(to: URL(fileURLWithPath: failureDirectory).appendingPathComponent("corrupt"))
        forgetCachedValue(for: key)

        XCTAssertEqual(Application.fileState(\.failureCorruptFile).value, 7)
        XCTAssertEqual(RecordingApplication.failures.count, 2)
    }

    @MainActor
    func testUnwritableFileReportsWriteFailure() async throws {
        let key = Application.shared.failureBlockedFile.scope.key

        try Data("not a directory".utf8).write(to: URL(fileURLWithPath: failureBlocker))

        var blocked = Application.fileState(\.failureBlockedFile)
        blocked.value = 9

        let writes = RecordingApplication.failures.filter { $0.operation == .write }

        XCTAssertEqual(writes.count, 1)
        XCTAssertEqual(writes.first?.store, .fileState)
        XCTAssertEqual(writes.first?.key, key)

        forgetCachedValue(for: key)
    }

    @MainActor
    func testRefusedDeleteReportsDeleteFailure() async {
        let fileManagerOverride = Application.override(\.fileManager, with: DeleteRefusingFileManager())

        var optional = Application.fileState(\.failureOptionalFile)
        optional.value = 3

        XCTAssertTrue(RecordingApplication.failures.isEmpty)

        optional.value = nil

        XCTAssertEqual(RecordingApplication.failures.count, 1)
        XCTAssertEqual(RecordingApplication.failures.first?.store, .fileState)
        XCTAssertEqual(RecordingApplication.failures.first?.operation, .delete)
        XCTAssertTrue(RecordingApplication.failures.first?.error is FailureDeleteRefused)

        await fileManagerOverride.cancel()
    }

    @MainActor
    func testRejectedStoredStateValueReportsWriteFailure() async {
        let key = Application.shared.failureReading.scope.key

        var reading = Application.storedState(\.failureReading)
        reading.value = FailureReading(celsius: 21)

        XCTAssertTrue(RecordingApplication.failures.isEmpty)

        reading.value = FailureReading(celsius: .nan)

        XCTAssertEqual(Application.storedState(\.failureReading).value, FailureReading(celsius: 21))
        XCTAssertEqual(RecordingApplication.failures.count, 1)
        XCTAssertEqual(RecordingApplication.failures.first?.store, .storedState)
        XCTAssertEqual(RecordingApplication.failures.first?.operation, .write)
        XCTAssertEqual(RecordingApplication.failures.first?.key, key)
        XCTAssertTrue(RecordingApplication.failures.first?.error is EncodingError)

        Application.reset(storedState: \.failureReading)
    }

    #if canImport(Security)
    @available(watchOS 9.0, *)
    @MainActor
    func testSyncStateValueThatCannotBeEncodedReportsWriteFailure() async {
        let key = "PersistenceFailure/syncReading"

        var reading = Application.syncState(\.failureSyncReading)
        reading.value = FailureReading(celsius: .nan)

        XCTAssertEqual(RecordingApplication.failures.count, 1)
        XCTAssertEqual(RecordingApplication.failures.first?.store, .syncState)
        XCTAssertEqual(RecordingApplication.failures.first?.operation, .write)
        XCTAssertEqual(RecordingApplication.failures.first?.key, key)
    }
    #endif

    /// An application that does not override the method behaves as it did before the method existed.
    @MainActor
    func testDefaultApplicationIgnoresFailures() async throws {
        Application.promote(to: Application.self)

        try Data("{ not json".utf8).write(to: URL(fileURLWithPath: failureDirectory).appendingPathComponent("corrupt"))
        forgetCachedValue(for: Application.shared.failureCorruptFile.scope.key)

        XCTAssertEqual(Application.fileState(\.failureCorruptFile).value, 7)
        XCTAssertTrue(RecordingApplication.failures.isEmpty)
    }
}
