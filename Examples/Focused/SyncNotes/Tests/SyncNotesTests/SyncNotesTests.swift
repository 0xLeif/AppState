import AppState
import Foundation
import XCTest

@testable import SyncNotes

// MARK: - InMemoryUserDefaults

/// A fully in-memory `UserDefaultsManaging` substitute for tests.
///
/// Overriding `\.userDefaults` prevents `StoredState` (and the `SyncState` fallback)
/// from ever touching `UserDefaults.standard` or persisting data to disk.
final class InMemoryUserDefaults: UserDefaultsManaging, @unchecked Sendable {

    private var storage: [String: Any] = [:]

    func object(forKey key: String) -> Any? {
        storage[key]
    }

    func set(_ value: Any?, forKey key: String) {
        storage[key] = value
    }

    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}

#if !os(Linux) && !os(Windows)
// MARK: - InMemoryKeyValueStore

/// A fully in-memory `UbiquitousKeyValueStoreManaging` substitute for tests.
///
/// Overriding `\.icloudStore` prevents `SyncState` from ever touching
/// `NSUbiquitousKeyValueStore` or iCloud.
final class InMemoryKeyValueStore: UbiquitousKeyValueStoreManaging, @unchecked Sendable {

    private var storage: [String: Data] = [:]

    func data(forKey key: String) -> Data? {
        storage[key]
    }

    func set(_ value: Data?, forKey key: String) {
        storage[key] = value
    }

    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}
#endif

#if !os(Linux) && !os(Windows)
// MARK: - SyncNotesTests

/// Tests for the SyncNotes feature, exercising `Note` and the production
/// `Application.notes` SyncState key with fully in-memory backing stores.
@MainActor
final class SyncNotesTests: XCTestCase {

    // MARK: - Properties

    private var userDefaultsOverride: Application.DependencyOverride?
    private var icloudOverride: Application.DependencyOverride?

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()

        userDefaultsOverride = Application.override(
            \.userDefaults,
            with: InMemoryUserDefaults() as UserDefaultsManaging
        )
        icloudOverride = Application.override(
            \.icloudStore,
            with: InMemoryKeyValueStore() as UbiquitousKeyValueStoreManaging
        )

        resetNotesState()
    }

    override func tearDown() async throws {
        resetNotesState()

        await icloudOverride?.cancel()
        icloudOverride = nil
        await userDefaultsOverride?.cancel()
        userDefaultsOverride = nil

        try await super.tearDown()
    }

    // MARK: - Helpers

    private func resetNotesState() {
        var syncState = Application.syncState(\.notes)
        syncState.value = []

        var draftState = Application.state(\.newNoteText)
        draftState.value = ""
    }

    // MARK: - Tests: Application.notes SyncState

    /// Exercises the `Application.notes` computed property (Application+SyncNotes.swift).
    func testNotesPropertyReturnsSyncState() {
        let syncState = Application.syncState(\.notes)
        XCTAssertTrue(syncState.value.isEmpty, "Initial notes list should be empty")
    }

    func testNewNoteTextPropertyDefaultsToEmpty() {
        let state = Application.state(\.newNoteText)
        XCTAssertEqual(state.value, "")
    }

    func testNewNoteTextPropertyCanBeUpdated() {
        var state = Application.state(\.newNoteText)
        state.value = "Hello"
        XCTAssertEqual(Application.state(\.newNoteText).value, "Hello")
    }

    func testAddNoteAppendsToNotes() {
        var syncState = Application.syncState(\.notes)
        let note = Note(id: UUID(), text: "Hello, iCloud!")
        syncState.value = [note]

        let stored = Application.syncState(\.notes).value
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.text, "Hello, iCloud!")
        XCTAssertEqual(stored.first?.id, note.id)
    }

    func testAddMultipleNotesPreservesOrder() {
        var syncState = Application.syncState(\.notes)
        let first = Note(id: UUID(), text: "First")
        let second = Note(id: UUID(), text: "Second")
        let third = Note(id: UUID(), text: "Third")
        syncState.value = [first, second, third]

        let stored = Application.syncState(\.notes).value
        XCTAssertEqual(stored.count, 3)
        XCTAssertEqual(stored.map(\.text), ["First", "Second", "Third"])
    }

    func testRemoveNoteFiltersByID() {
        let keepNote = Note(id: UUID(), text: "Keep me")
        let removeNote = Note(id: UUID(), text: "Remove me")

        var syncState = Application.syncState(\.notes)
        syncState.value = [keepNote, removeNote]
        syncState.value = syncState.value.filter { $0.id != removeNote.id }

        let stored = Application.syncState(\.notes).value
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.id, keepNote.id)
    }

    func testResetRestoresEmptyList() {
        var syncState = Application.syncState(\.notes)
        syncState.value = [Note(id: UUID(), text: "Temporary")]
        XCTAssertFalse(Application.syncState(\.notes).value.isEmpty)

        resetNotesState()
        XCTAssertTrue(Application.syncState(\.notes).value.isEmpty)
    }

    // MARK: - Tests: Note model — Equatable

    func testNoteEqualityWhenAllFieldsMatch() {
        let id = UUID()
        let date = Date()
        let noteA = Note(id: id, text: "Same", createdAt: date)
        let noteB = Note(id: id, text: "Same", createdAt: date)
        XCTAssertEqual(noteA, noteB)
    }

    func testNoteInequalityOnDifferentID() {
        let date = Date()
        let noteA = Note(id: UUID(), text: "Duplicate", createdAt: date)
        let noteB = Note(id: UUID(), text: "Duplicate", createdAt: date)
        XCTAssertNotEqual(noteA, noteB)
    }

    // MARK: - Tests: Note model — Codable

    func testNoteCodableRoundTrip() throws {
        let original = Note(id: UUID(), text: "Codable check")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Note.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testNoteCodablePreservesAllFields() throws {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_000_000)
        let original = Note(id: id, text: "Full field check", createdAt: date)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Note.self, from: data)

        XCTAssertEqual(decoded.id, id)
        XCTAssertEqual(decoded.text, "Full field check")
        XCTAssertEqual(decoded.createdAt.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.001)
    }

    // MARK: - Tests: Note — default initializer values

    func testNoteDefaultIDIsUnique() {
        let noteA = Note(text: "A")
        let noteB = Note(text: "B")
        XCTAssertNotEqual(noteA.id, noteB.id)
    }

    func testNoteDefaultCreatedAtIsRecent() {
        let before = Date()
        let note = Note(text: "Timestamped")
        let after = Date()
        XCTAssertGreaterThanOrEqual(note.createdAt, before)
        XCTAssertLessThanOrEqual(note.createdAt, after)
    }
}
#endif
