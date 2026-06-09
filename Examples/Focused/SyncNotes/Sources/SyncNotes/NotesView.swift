#if canImport(SwiftUI) && !os(Linux) && !os(Windows)
import AppState
import SwiftUI

// MARK: - NotesView

/// A minimal view that demonstrates `@SyncState` for a list of notes.
///
/// Each mutation (add/delete) writes through `NSUbiquitousKeyValueStore`
/// and propagates to every device signed into the same iCloud account.
@available(watchOS 9.0, *)
public struct NotesView: View {

    // MARK: - State

    /// The cloud-synced notes list, bound two-way through AppState.
    @SyncState(\.notes) private var notes: [Note]

    /// The text the user has typed into the new-note field.
    @SwiftUI.State private var draftText: String = ""

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
                    TextField("New note…", text: $draftText)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        addNote()
                    }
                    .disabled(draftText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                .background(.regularMaterial)
            }
        }
    }

    // MARK: - Private Methods

    private func addNote() {
        let trimmed = draftText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        notes = notes + [Note(text: trimmed)]
        draftText = ""
    }
}

// MARK: - Array + Safe Removal

private extension Array {
    /// Returns a copy of the array with the elements at `offsets` removed.
    func removing(at offsets: IndexSet) -> [Element] {
        enumerated()
            .compactMap { offsets.contains($0.offset) ? nil : $0.element }
    }
}

// MARK: - Preview

@available(watchOS 9.0, *)
#Preview {
    NotesView()
}
#endif
