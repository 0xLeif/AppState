import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif
import XCTest
@testable import AppState

fileprivate enum FlintPersistTempDirectory {
    static let baseDirectory: String = NSTemporaryDirectory() + "/AppState.FlintPersist.Dogfood"
}

fileprivate struct FlintPersistSettings: Codable, Sendable {
    var theme: Int
    var fontSize: Int
}

fileprivate extension Application {
    @MainActor
    var flintPersistStoredPrefs: StoredState<Int?> {
        storedState(id: "dogfoodStoredPrefs")
    }

    @MainActor
    var flintPersistDraft: FileState<String?> {
        fileState(
            path: FlintPersistTempDirectory.baseDirectory,
            filename: "dogfoodDraft",
            isBase64Encoded: false
        )
    }

    @MainActor
    var flintPersistSettings: StoredState<FlintPersistSettings> {
        storedState(
            initial: FlintPersistSettings(theme: 1, fontSize: 14),
            id: "dogfoodSettings"
        )
    }

    @MainActor
    var flintPersistDraftCorrupt: FileState<String?> {
        fileState(
            path: FlintPersistTempDirectory.baseDirectory,
            filename: "dogfoodDraftCorrupt",
            isBase64Encoded: false
        )
    }
}

#if canImport(Security)
@available(watchOS 9.0, *)
fileprivate extension Application {
    @MainActor
    var flintPersistToken: SecureState {
        secureState(feature: "FlintPersist", id: "dogfoodToken")
    }

    @available(watchOS 9.0, *)
    var flintPersistSyncName: SyncState<String> {
        syncState(initial: "FlintPersistDogfood", id: "dogfoodSyncName")
    }
}
#endif

@MainActor
fileprivate class FlintPersistSettingsFlow {
    @StoredState(\.flintPersistStoredPrefs) var storedPrefs: Int?
    @FileState(\.flintPersistDraft) var draft: String?

    @Slice(\.flintPersistSettings, \FlintPersistSettings.theme) var theme: Int

    #if canImport(Security)
    @SecureState(\.flintPersistToken) var token: String?
    @available(watchOS 9.0, *)
    @SyncState(\.flintPersistSyncName) var syncName: String
    #endif

    func save(storedPrefs: Int?, draft: String?, theme: Int) {
        self.storedPrefs = storedPrefs
        self.draft = draft
        self.theme = theme
    }

    #if canImport(Security)
    func saveApple(token: String?, syncName: String) {
        self.token = token
        self.syncName = syncName
    }
    #endif
}

#if !os(Linux) && !os(Windows)
extension FlintPersistSettingsFlow: ObservableObject { }
#endif

@available(watchOS 9.0, *)
final class DogfoodPersistentEdgeTests: XCTestCase {
    private var tempDirectory: String!

    @MainActor
    override func setUp() async throws {
        Application.logging(isEnabled: true)
        #if canImport(Security)
        Application.load(dependency: \.keychain)
        #endif

        tempDirectory = FlintPersistTempDirectory.baseDirectory

        try FileManager.default.createDirectory(atPath: tempDirectory, withIntermediateDirectories: true)
    }

    @MainActor
    override func tearDown() async throws {
        let applicationDescription = Application.description

        Application.dependency(\.logger).debug("DogfoodPersistentEdgeTests \(applicationDescription)")

        Application.reset(storedState: \.flintPersistStoredPrefs)
        Application.reset(storedState: \.flintPersistSettings)
        Application.reset(fileState: \.flintPersistDraft)
        Application.reset(fileState: \.flintPersistDraftCorrupt)

        #if canImport(Security)
        Application.reset(secureState: \.flintPersistToken)
        Application.reset(syncState: \.flintPersistSyncName)
        #endif

        try? FileManager.default.removeItem(atPath: tempDirectory)
    }

    @MainActor
    func testFlintPersistFlowPersistsAcrossWrapperInstances() async {
        let flow = FlintPersistSettingsFlow()

        flow.save(storedPrefs: 42, draft: "dogfood-draft-body", theme: 7)
        #if canImport(Security)
        flow.saveApple(token: "dogfood-secure-token", syncName: "dogfood-sync-name")
        #endif

        let secondFlow = FlintPersistSettingsFlow()

        XCTAssertEqual(secondFlow.storedPrefs, 42)
        XCTAssertEqual(secondFlow.draft, "dogfood-draft-body")
        XCTAssertEqual(secondFlow.theme, 7)
        #if canImport(Security)
        XCTAssertEqual(secondFlow.token, "dogfood-secure-token")
        XCTAssertEqual(secondFlow.syncName, "dogfood-sync-name")
        #endif
    }

    @MainActor
    func testResettingStoredPrefsLeavesTokenFileAndSyncNameIntact() async {
        let flow = FlintPersistSettingsFlow()

        flow.save(storedPrefs: 42, draft: "dogfood-draft-body", theme: 7)
        #if canImport(Security)
        flow.saveApple(token: "dogfood-secure-token", syncName: "dogfood-sync-name")
        #endif

        Application.reset(storedState: \.flintPersistStoredPrefs)

        XCTAssertNil(Application.storedState(\.flintPersistStoredPrefs).value)
        XCTAssertEqual(Application.fileState(\.flintPersistDraft).value, "dogfood-draft-body")
        #if canImport(Security)
        XCTAssertEqual(Application.secureState(\.flintPersistToken).value, "dogfood-secure-token")
        XCTAssertEqual(Application.syncState(\.flintPersistSyncName).value, "dogfood-sync-name")
        #endif
    }

    @MainActor
    func testSliceOfIntInsideStoredStateRoundTripsThroughApplicationStoredState() async {
        let flow = FlintPersistSettingsFlow()

        XCTAssertEqual(flow.theme, 1)

        flow.theme = 42

        XCTAssertEqual(Application.storedState(\.flintPersistSettings).value.theme, 42)

        Application.reset(storedState: \.flintPersistSettings)

        XCTAssertEqual(Application.storedState(\.flintPersistSettings).value.theme, 1)
    }

    @MainActor
    func testFlintPersistDraftFileStateWritesPlainJSONAndReadsBack() async throws {
        var draft = Application.fileState(\.flintPersistDraft)

        XCTAssertNil(draft.value)

        draft.value = "dogfood-draft-body"

        let fileURL = URL(fileURLWithPath: tempDirectory)
            .appendingPathComponent("dogfoodDraft")

        let data = try Data(contentsOf: fileURL)
        let writtenValue: String = try JSONDecoder().decode(String.self, from: data)

        XCTAssertEqual(writtenValue, "dogfood-draft-body")
        XCTAssertEqual(draft.value, "dogfood-draft-body")

        Application.reset(fileState: \.flintPersistDraft)
    }

    @MainActor
    func testFlintPersistDraftFallsBackToInitialValueWhenFileIsCorrupt() async throws {
        let corruptURL = URL(fileURLWithPath: tempDirectory)
            .appendingPathComponent("dogfoodDraftCorrupt")

        try Data("not-a-valid-json".utf8).write(to: corruptURL)

        let corruptState = Application.fileState(\.flintPersistDraftCorrupt)

        XCTAssertNil(corruptState.value)

        try? FileManager.default.removeItem(at: corruptURL)
    }

    @available(watchOS 9.0, *)
    @MainActor
    func testFlintPersistSecureTokenSetSecondReaderSetNilReadNil() async {
        #if canImport(Security)
        var firstToken = Application.secureState(\.flintPersistToken)

        XCTAssertNil(firstToken.value)

        firstToken.value = "dogfood-secure-token"

        var secondReader = Application.secureState(\.flintPersistToken)

        XCTAssertEqual(secondReader.value, "dogfood-secure-token")

        secondReader.value = nil

        XCTAssertNil(Application.secureState(\.flintPersistToken).value)
        #endif
    }

    @available(watchOS 9.0, *)
    @MainActor
    func testFlintPersistSyncStateAndStoredStateWithDifferentIdsStayIndependent() async {
        var storedPrefs = Application.storedState(\.flintPersistStoredPrefs)
        storedPrefs.value = 99

        #if canImport(Security)
        var syncName = Application.syncState(\.flintPersistSyncName)
        syncName.value = "dogfood-sync-name"
        #endif

        XCTAssertEqual(storedPrefs.value, 99)
        #if canImport(Security)
        XCTAssertEqual(syncName.value, "dogfood-sync-name")
        #endif

        Application.reset(storedState: \.flintPersistStoredPrefs)

        XCTAssertNil(storedPrefs.value)
        #if canImport(Security)
        XCTAssertEqual(syncName.value, "dogfood-sync-name")
        #endif
    }
}