#if canImport(SwiftUI) && !os(Linux) && !os(Windows)
import AppState
import SwiftUI
import ViewInspector
import XCTest

@testable import SyncNotes

// MARK: - NotesViewTests

/// Exercises the SwiftUI layer (`NotesView`) with ViewInspector so that the
/// declarative view body, its action closures, and the `Array.removing(at:)` helper
/// are all covered alongside the headless `SyncNotesTests`.
@MainActor
final class NotesViewTests: XCTestCase {

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

        resetState()
    }

    override func tearDown() async throws {
        resetState()

        await icloudOverride?.cancel()
        icloudOverride = nil
        await userDefaultsOverride?.cancel()
        userDefaultsOverride = nil

        try await super.tearDown()
    }

    // MARK: - Helpers

    private func resetState() {
        var syncState = Application.syncState(\.notes)
        syncState.value = []

        var draftState = Application.state(\.newNoteText)
        draftState.value = ""
    }

    private func setNotes(_ notes: [Note]) {
        var syncState = Application.syncState(\.notes)
        syncState.value = notes
    }

    private func currentNotes() -> [Note] {
        Application.syncState(\.notes).value
    }

    private func makeNote(text: String) -> Note {
        Note(id: UUID(), text: text, createdAt: Date(timeIntervalSince1970: 0))
    }

    // MARK: - Tests: NotesView init

    func testNotesViewInitIsAccessible() {
        let sut = NotesView()
        XCTAssertNoThrow(try sut.inspect())
    }

    // MARK: - Tests: empty state

    func testEmptyStateRendersListWithForEach() throws {
        setNotes([])
        let sut = NotesView()
        let list = try sut.inspect().find(ViewType.List.self)
        XCTAssertNotNil(list)
    }

    func testEmptyStateForeachHasZeroItems() throws {
        setNotes([])
        let sut = NotesView()
        let forEach = try sut.inspect().find(ViewType.ForEach.self)
        XCTAssertEqual(forEach.count, 0)
    }

    // MARK: - Tests: non-empty state

    func testNonEmptyStateRendersTextForEachNote() throws {
        setNotes([makeNote(text: "Alpha"), makeNote(text: "Beta")])
        let sut = NotesView()
        XCTAssertNoThrow(try sut.inspect().find(text: "Alpha"))
        XCTAssertNoThrow(try sut.inspect().find(text: "Beta"))
    }

    func testForEachRendersAllNotes() throws {
        let notes = [makeNote(text: "One"), makeNote(text: "Two"), makeNote(text: "Three")]
        setNotes(notes)
        let sut = NotesView()
        let forEach = try sut.inspect().find(ViewType.ForEach.self)
        XCTAssertEqual(forEach.count, 3)
    }

    // MARK: - Tests: TextField binding (via Application state)

    func testTextFieldSetInputWritesToNewNoteTextState() throws {
        let sut = NotesView()
        let field = try sut.inspect().find(ViewType.TextField.self)
        try field.setInput("Typed text")

        XCTAssertEqual(Application.state(\.newNoteText).value, "Typed text")
    }

    // MARK: - Tests: Button disabled state

    func testAddButtonIsDisabledForBlankNewNoteText() throws {
        var draftState = Application.state(\.newNoteText)
        draftState.value = "   "

        let sut = NotesView()
        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertTrue(try button.isDisabled())
    }

    func testAddButtonIsDisabledForEmptyNewNoteText() throws {
        var draftState = Application.state(\.newNoteText)
        draftState.value = ""

        let sut = NotesView()
        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertTrue(try button.isDisabled())
    }

    func testAddButtonIsEnabledForNonBlankNewNoteText() throws {
        var draftState = Application.state(\.newNoteText)
        draftState.value = "Has content"

        let sut = NotesView()
        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertFalse(try button.isDisabled())
    }

    // MARK: - Tests: Add Button tap

    func testAddButtonTapAddsNoteAndClearsDraft() throws {
        var draftState = Application.state(\.newNoteText)
        draftState.value = "Button-added note"

        let sut = NotesView()
        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertEqual(currentNotes().map(\.text), ["Button-added note"])
        XCTAssertEqual(Application.state(\.newNoteText).value, "")
    }

    func testAddButtonTapWithBlankDraftCallsAddNoteButGuardSaves() throws {
        var draftState = Application.state(\.newNoteText)
        draftState.value = "   "

        // Verify button is disabled for blank text (guard in addNote prevents insertion)
        let sut = NotesView()
        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertTrue(try button.isDisabled())
        // Notes remain empty since button is disabled/guard blocks
        XCTAssertTrue(currentNotes().isEmpty)
    }

    func testAddButtonTapTrimsDraftBeforeSaving() throws {
        var draftState = Application.state(\.newNoteText)
        draftState.value = "  Trimmed text  "

        let sut = NotesView()
        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertEqual(currentNotes().first?.text, "Trimmed text")
    }

    func testMultipleAddTapsAppendNotes() throws {
        var draftState = Application.state(\.newNoteText)
        draftState.value = "First"

        let sut = NotesView()
        try sut.inspect().find(ViewType.Button.self).tap()

        draftState.value = "Second"
        try sut.inspect().find(ViewType.Button.self).tap()

        XCTAssertEqual(currentNotes().count, 2)
        XCTAssertEqual(currentNotes().map(\.text), ["First", "Second"])
    }

    // MARK: - Tests: onDelete (Array.removing(at:))

    func testSwipeToDeleteRemovesSingleNote() throws {
        setNotes([makeNote(text: "Keep"), makeNote(text: "Delete me")])

        let sut = NotesView()
        let forEach = try sut.inspect().find(ViewType.ForEach.self)
        try forEach.callOnDelete(IndexSet(integer: 1))

        XCTAssertEqual(currentNotes().map(\.text), ["Keep"])
    }

    func testSwipeToDeleteRemovesFirstNote() throws {
        setNotes([makeNote(text: "Remove first"), makeNote(text: "Keep")])

        let sut = NotesView()
        let forEach = try sut.inspect().find(ViewType.ForEach.self)
        try forEach.callOnDelete(IndexSet(integer: 0))

        XCTAssertEqual(currentNotes().map(\.text), ["Keep"])
    }

    func testSwipeToDeleteRemovesMultipleNotes() throws {
        setNotes([
            makeNote(text: "Alpha"),
            makeNote(text: "Beta"),
            makeNote(text: "Gamma"),
        ])

        let sut = NotesView()
        let forEach = try sut.inspect().find(ViewType.ForEach.self)
        try forEach.callOnDelete(IndexSet([0, 2]))

        XCTAssertEqual(currentNotes().map(\.text), ["Beta"])
    }

    func testDeleteAllNotesProducesEmptyList() throws {
        setNotes([makeNote(text: "Only")])

        let sut = NotesView()
        let forEach = try sut.inspect().find(ViewType.ForEach.self)
        try forEach.callOnDelete(IndexSet(integer: 0))

        XCTAssertTrue(currentNotes().isEmpty)
    }

    // MARK: - Tests: addNote guard branch

    func testAddNoteDirectlyWithBlankTextDoesNotInsert() {
        var draftState = Application.state(\.newNoteText)
        draftState.value = "   "

        let sut = NotesView()
        sut.addNote() // Calls addNote() with whitespace-only text; guard should return early

        XCTAssertTrue(currentNotes().isEmpty)
    }

    func testAddNoteDirectlyWithEmptyTextDoesNotInsert() {
        var draftState = Application.state(\.newNoteText)
        draftState.value = ""

        let sut = NotesView()
        sut.addNote()

        XCTAssertTrue(currentNotes().isEmpty)
    }

    // MARK: - Tests: Array.removing(at:) helper directly

    func testRemovingAtMiddleIndex() {
        let input = ["a", "b", "c", "d"]
        let result = input.removing(at: IndexSet(integer: 1))
        XCTAssertEqual(result, ["a", "c", "d"])
    }

    func testRemovingAtMultipleIndices() {
        let input = [1, 2, 3, 4, 5]
        let result = input.removing(at: IndexSet([0, 2, 4]))
        XCTAssertEqual(result, [2, 4])
    }

    func testRemovingAtEmptyIndexSetReturnsOriginal() {
        let input = ["x", "y", "z"]
        let result = input.removing(at: IndexSet())
        XCTAssertEqual(result, ["x", "y", "z"])
    }
}
#endif
