#if canImport(SwiftUI) && !os(Linux) && !os(Windows)
import AppState
import SwiftUI

// MARK: - NotesView

/// A minimal view that demonstrates `@SyncState` for a list of notes.
///
/// Each mutation (add/delete) writes through `NSUbiquitousKeyValueStore`
/// and propagates to every device signed into the same iCloud account.
public struct NotesView: View {

    // MARK: - State

    /// The cloud-synced notes list, bound two-way through AppState.
    @SyncState(\.notes) internal var notes: [Note]

    /// The draft text currently typed into the new-note input field.
    @AppState(\.newNoteText) internal var newNoteText: String

    // MARK: - Initializers

    /// Creates a `NotesView`.
    public init() {}

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            List {
                ForEach(notes) { note in
                    Text(note.text)
                }
                .onDelete { indexSet in
                    notes = notes.removing(at: indexSet)
                }
            }
            .navigationTitle("SyncNotes")
            #if !os(macOS)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            #endif
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TextField("New note…", text: $newNoteText)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        addNote()
                    }
                    .disabled(newNoteText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                .background(.regularMaterial)
            }
        }
    }

    // MARK: - Internal Methods

    /// Appends a new note from the current `newNoteText` draft, then clears the draft.
    ///
    /// Whitespace-only drafts are silently discarded. This method is `internal` so that
    /// tests can invoke it directly to exercise the guard branch.
    internal func addNote() {
        let trimmed = newNoteText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        notes = notes + [Note(text: trimmed)]
        newNoteText = ""
    }
}

// MARK: - Array + Safe Removal

extension Array {
    /// Returns a copy of the array with the elements at `offsets` removed.
    internal func removing(at offsets: IndexSet) -> [Element] {
        enumerated()
            .compactMap { offsets.contains($0.offset) ? nil : $0.element }
    }
}

// MARK: - Preview

#Preview {
    NotesView()
}
#endif
