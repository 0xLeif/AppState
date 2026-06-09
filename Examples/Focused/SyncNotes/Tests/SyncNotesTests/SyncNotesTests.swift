#if !os(Linux) && !os(Windows)
import AppState
import Foundation
import SyncNotes
import XCTest

// MARK: - Application + Test State

@available(watchOS 9.0, *)
extension Application {
    /// Isolated test key — distinct feature/id avoids colliding with the production `notes` key.
    fileprivate var testNotes: SyncState<[Note]> {
        syncState(initial: [], feature: "SyncNotesTests", id: "testNotes")
    }
}

// MARK: - SyncNotesTests

@available(watchOS 9.0, *)
@MainActor
final class SyncNotesTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        Application
            .logging(isEnabled: false)
            .load(dependency: \.icloudStore)

        // Start each test with a clean slate.
        Application.reset(syncState: \.testNotes)
    }

    override func tearDown() async throws {
        // Leave the store clean after each test.
        Application.reset(syncState: \.testNotes)
    }

    // MARK: - Tests

    /// Adding a note appends it to the synced list.
    func testAddNote() {
        var syncState = Application.syncState(\.testNotes)
        XCTAssertTrue(syncState.value.isEmpty, "Initial notes list should be empty")

        let note = Note(id: UUID(), text: "Hello, iCloud!")
        syncState.value = syncState.value + [note]

        let stored = Application.syncState(\.testNotes).value
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.text, "Hello, iCloud!")
        XCTAssertEqual(stored.first?.id, note.id)
    }

    /// Adding multiple notes preserves insertion order.
    func testAddMultipleNotes() {
        var syncState = Application.syncState(\.testNotes)

        let first = Note(id: UUID(), text: "First")
        let second = Note(id: UUID(), text: "Second")
        let third = Note(id: UUID(), text: "Third")

        syncState.value = [first, second, third]

        let stored = Application.syncState(\.testNotes).value
        XCTAssertEqual(stored.count, 3)
        XCTAssertEqual(stored.map(\.text), ["First", "Second", "Third"])
    }

    /// Removing a note by id filters it out of the synced list.
    func testRemoveNote() {
        let keepNote = Note(id: UUID(), text: "Keep me")
        let removeNote = Note(id: UUID(), text: "Remove me")

        var syncState = Application.syncState(\.testNotes)
        syncState.value = [keepNote, removeNote]

        XCTAssertEqual(syncState.value.count, 2)

        syncState.value = syncState.value.filter { $0.id != removeNote.id }

        let stored = Application.syncState(\.testNotes).value
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.id, keepNote.id)
    }

    /// Resetting the sync state restores the initial empty list.
    func testResetRestoresInitialValue() {
        var syncState = Application.syncState(\.testNotes)
        syncState.value = [Note(id: UUID(), text: "Temporary")]

        XCTAssertFalse(Application.syncState(\.testNotes).value.isEmpty)

        Application.reset(syncState: \.testNotes)

        XCTAssertTrue(Application.syncState(\.testNotes).value.isEmpty)
    }

    /// Notes are Equatable — identical value objects compare equal.
    func testNoteEquality() {
        let id = UUID()
        let date = Date()
        let noteA = Note(id: id, text: "Same", createdAt: date)
        let noteB = Note(id: id, text: "Same", createdAt: date)

        XCTAssertEqual(noteA, noteB)
    }

    /// Notes with different ids are not equal even when text matches.
    func testNoteInequalityOnId() {
        let date = Date()
        let noteA = Note(id: UUID(), text: "Duplicate", createdAt: date)
        let noteB = Note(id: UUID(), text: "Duplicate", createdAt: date)

        XCTAssertNotEqual(noteA, noteB)
    }

    /// A `Note` round-trips through JSON encoding without data loss.
    func testNoteCodableRoundTrip() throws {
        let original = Note(id: UUID(), text: "Codable check")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Note.self, from: data)

        XCTAssertEqual(original, decoded)
    }
}
#endif
