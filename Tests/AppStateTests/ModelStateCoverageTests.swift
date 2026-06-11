#if canImport(SwiftData)
import Foundation
import SwiftData
import XCTest
@testable import AppState

// MARK: - Model Types

/// Uniquely named @Model types to avoid collisions with ModelStateTests.swift.

@Model
fileprivate final class MSCoverageNote {
    var title: String
    var body: String
    var priority: Int

    init(title: String, body: String, priority: Int) {
        self.title = title
        self.body = body
        self.priority = priority
    }
}

@Model
fileprivate final class MSCoverageTag {
    var name: String
    var color: String

    init(name: String, color: String) {
        self.name = name
        self.color = color
    }
}

/// A second, isolated model type used only in the secondary container tests,
/// so the secondary container never holds MSCoverageNote schema.
@Model
fileprivate final class MSCoverageEvent {
    var label: String

    init(label: String) {
        self.label = label
    }
}

// MARK: - Application Extensions

fileprivate extension Application {

    // MARK: Primary container (MSCoverageNote + MSCoverageTag)

    /// Routes through `modelContainer(_:)` — auto-id container.
    var mscPrimaryContainer: Dependency<ModelContainer> {
        modelContainer(
            try! ModelContainer(
                for: MSCoverageNote.self, MSCoverageTag.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    // MARK: Secondary container (MSCoverageEvent only — isolated from primary)

    /// A completely separate ModelContainer to verify multi-container isolation.
    var mscSecondaryContainer: Dependency<ModelContainer> {
        modelContainer(
            try! ModelContainer(
                for: MSCoverageEvent.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    // MARK: ModelState overloads coverage

    /// Overload 1: `modelState(container:)` — auto-id, default FetchDescriptor.
    /// This exercises the auto-id + default-descriptor overload path.
    var mscNotes: Application.ModelState<MSCoverageNote> {
        modelState(container: \.mscPrimaryContainer)
    }

    /// Overload 2: `modelState(container:fetchDescriptor:)` — auto-id, explicit FetchDescriptor.
    /// Uses a sort descriptor to exercise the FetchDescriptor-carrying auto-id overload.
    var mscNotesByPriority: Application.ModelState<MSCoverageNote> {
        modelState(
            container: \.mscPrimaryContainer,
            fetchDescriptor: FetchDescriptor<MSCoverageNote>(
                sortBy: [SortDescriptor(\.priority, order: .forward)]
            )
        )
    }

    /// Overload 3: `modelState(container:feature:id:)` — explicit feature + id, default descriptor.
    /// THIS OVERLOAD WAS PREVIOUSLY UNCOVERED — it has no FetchDescriptor parameter.
    var mscNotesExplicitFeatureID: Application.ModelState<MSCoverageNote> {
        modelState(
            container: \.mscPrimaryContainer,
            feature: "MSCoverageFeature",
            id: "mscNotesExplicitFeatureID"
        )
    }

    /// Overload 4: `modelState(container:fetchDescriptor:feature:id:)` — explicit feature + id + descriptor.
    var mscNotesScopedWithDescriptor: Application.ModelState<MSCoverageNote> {
        modelState(
            container: \.mscPrimaryContainer,
            fetchDescriptor: FetchDescriptor<MSCoverageNote>(
                predicate: #Predicate { $0.priority > 5 }
            ),
            feature: "MSCoverageFeature",
            id: "mscNotesScopedWithDescriptor"
        )
    }

    /// Tags — uses the primary container, different model type.
    var mscTags: Application.ModelState<MSCoverageTag> {
        modelState(container: \.mscPrimaryContainer)
    }

    /// Secondary-container state for isolation tests.
    var mscEvents: Application.ModelState<MSCoverageEvent> {
        modelState(container: \.mscSecondaryContainer)
    }

    /// A fetch-limited state for FetchDescriptor limit coverage.
    var mscNotesLimited: Application.ModelState<MSCoverageNote> {
        modelState(
            container: \.mscPrimaryContainer,
            fetchDescriptor: {
                var descriptor = FetchDescriptor<MSCoverageNote>()
                descriptor.fetchLimit = 2
                return descriptor
            }(),
            feature: "MSCoverageFeature",
            id: "mscNotesLimited"
        )
    }
}

// MARK: - Property Wrapper Helpers

@MainActor
fileprivate struct MSCoverageNoteReader {
    @ModelState(\.mscNotes) var notes
}

@MainActor
fileprivate final class MSCoverageNoteViewModel {
    @ModelState(\.mscNotes) var notes

    func addNote(title: String, body: String, priority: Int) {
        $notes.insert(MSCoverageNote(title: title, body: body, priority: priority))
    }

    func removeNote(_ note: MSCoverageNote) {
        $notes.delete(note)
    }

    func persistChanges() {
        $notes.save()
    }
}

// MARK: - Test Suite

final class ModelStateCoverageTests: XCTestCase {

    // MARK: - setUp / tearDown

    @MainActor
    override func setUp() async throws {
        Application.logging(isEnabled: true)
        Application.modelState(\.mscNotes).deleteAll()
        Application.modelState(\.mscTags).deleteAll()
        Application.modelState(\.mscEvents).deleteAll()
        XCTAssertTrue(Application.modelState(\.mscNotes).models.isEmpty)
        XCTAssertTrue(Application.modelState(\.mscTags).models.isEmpty)
        XCTAssertTrue(Application.modelState(\.mscEvents).models.isEmpty)
    }

    @MainActor
    override func tearDown() async throws {
        Application.modelState(\.mscNotes).deleteAll()
        Application.modelState(\.mscTags).deleteAll()
        Application.modelState(\.mscEvents).deleteAll()
    }

    // MARK: - Emoji

    /// `ModelState.emoji` was previously uncovered (line 20).
    @MainActor
    func testEmoji() {
        let emoji = Application.ModelState<MSCoverageNote>.emoji
        XCTAssertEqual(emoji, "🗃️")
    }

    // MARK: - modelState overloads

    /// Overload: `modelState(container:)` — auto-id, default descriptor (Overload 1).
    @MainActor
    func testOverloadAutoIDDefaultDescriptor() {
        let state = Application.modelState(\.mscNotes)
        XCTAssertTrue(state.models.isEmpty)

        state.insert(MSCoverageNote(title: "Auto-ID", body: "default descriptor", priority: 1))
        XCTAssertEqual(state.models.count, 1)
    }

    /// Overload: `modelState(container:fetchDescriptor:)` — auto-id, explicit descriptor (Overload 2).
    @MainActor
    func testOverloadAutoIDExplicitDescriptor() {
        let baseState = Application.modelState(\.mscNotes)
        baseState.insert(MSCoverageNote(title: "Z", body: "", priority: 30))
        baseState.insert(MSCoverageNote(title: "A", body: "", priority: 10))
        baseState.insert(MSCoverageNote(title: "M", body: "", priority: 20))

        let sortedState = Application.modelState(\.mscNotesByPriority)
        let sorted = sortedState.models

        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted.map(\.priority), [10, 20, 30])
    }

    /// Overload: `modelState(container:feature:id:)` — explicit feature + id, default descriptor (Overload 3).
    /// THIS WAS THE PREVIOUSLY UNCOVERED OVERLOAD.
    @MainActor
    func testOverloadExplicitFeatureIDDefaultDescriptor() {
        let state = Application.modelState(\.mscNotesExplicitFeatureID)

        XCTAssertTrue(state.models.isEmpty)

        state.insert(MSCoverageNote(title: "FeatureID", body: "explicit overload", priority: 5))

        // Same container — also visible through mscNotes
        XCTAssertEqual(state.models.count, 1)
        XCTAssertEqual(Application.modelState(\.mscNotes).models.count, 1)
    }

    /// Overload: `modelState(container:fetchDescriptor:feature:id:)` — explicit feature + id + descriptor (Overload 4).
    @MainActor
    func testOverloadExplicitFeatureIDWithDescriptor() {
        let baseState = Application.modelState(\.mscNotes)
        baseState.insert(MSCoverageNote(title: "Low", body: "", priority: 3))
        baseState.insert(MSCoverageNote(title: "High", body: "", priority: 9))

        let filteredState = Application.modelState(\.mscNotesScopedWithDescriptor)
        let filtered = filteredState.models

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "High")
    }

    // MARK: - modelContainer / modelContext

    /// `modelContainer(_:)` produces a stable dependency; same key path returns the same container instance.
    @MainActor
    func testModelContainerSameContainerIdentity() {
        let context1 = Application.modelContext(\.mscPrimaryContainer)
        let context2 = Application.modelContext(\.mscPrimaryContainer)
        XCTAssertTrue(context1 === context2, "modelContext must return the same mainContext instance")
    }

    /// `modelContext` shares the main context with ModelState's `context` property.
    @MainActor
    func testModelContextMatchesModelStateContext() {
        let directContext = Application.modelContext(\.mscPrimaryContainer)
        let stateContext = Application.modelState(\.mscNotes).context
        XCTAssertTrue(directContext === stateContext)
    }

    /// Inserting through the raw context is reflected in ModelState.models.
    @MainActor
    func testModelContextDirectInsertReflectedInModelState() {
        let ctx = Application.modelContext(\.mscPrimaryContainer)
        ctx.insert(MSCoverageNote(title: "DirectCtx", body: "via context", priority: 1))
        try? ctx.save()

        let notes = Application.modelState(\.mscNotes).models
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.title, "DirectCtx")
    }

    // MARK: - insert

    @MainActor
    func testInsertSingleModel() {
        let state = Application.modelState(\.mscNotes)
        state.insert(MSCoverageNote(title: "InsertOne", body: "body", priority: 1))

        XCTAssertEqual(state.models.count, 1)
        XCTAssertEqual(state.models.first?.title, "InsertOne")
    }

    @MainActor
    func testInsertMultipleModels() {
        let state = Application.modelState(\.mscNotes)
        state.insert(MSCoverageNote(title: "First", body: "", priority: 1))
        state.insert(MSCoverageNote(title: "Second", body: "", priority: 2))
        state.insert(MSCoverageNote(title: "Third", body: "", priority: 3))

        XCTAssertEqual(state.models.count, 3)
        XCTAssertTrue(state.models.contains { $0.title == "First" })
        XCTAssertTrue(state.models.contains { $0.title == "Second" })
        XCTAssertTrue(state.models.contains { $0.title == "Third" })
    }

    // MARK: - delete

    @MainActor
    func testDeleteExistingModel() {
        let state = Application.modelState(\.mscNotes)
        let note = MSCoverageNote(title: "ToDelete", body: "", priority: 1)
        state.insert(note)
        XCTAssertEqual(state.models.count, 1)

        state.delete(note)
        XCTAssertTrue(state.models.isEmpty)
    }

    @MainActor
    func testDeleteOneOfManyModels() {
        let state = Application.modelState(\.mscNotes)
        let keep = MSCoverageNote(title: "Keep", body: "", priority: 1)
        let remove = MSCoverageNote(title: "Remove", body: "", priority: 2)
        state.insert(keep)
        state.insert(remove)

        XCTAssertEqual(state.models.count, 2)
        state.delete(remove)

        let remaining = state.models
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.title, "Keep")
    }

    // MARK: - save (guard early-return path)

    /// Calling `save()` with no pending changes exercises the `guard context.hasChanges else { return }`
    /// early-return path, which was previously an uncovered branch.
    @MainActor
    func testSaveWithNoPendingChangesEarlyReturn() {
        let state = Application.modelState(\.mscNotes)
        // No inserts — context has no changes. save() must complete without error.
        state.save()
        XCTAssertTrue(state.models.isEmpty)
    }

    /// Calling `save()` after a mutation exercises the normal (non-early-return) save path.
    @MainActor
    func testSaveWithPendingChanges() {
        let state = Application.modelState(\.mscNotes)
        let note = MSCoverageNote(title: "SaveTest", body: "needs saving", priority: 7)
        state.insert(note)

        // Mutate without going through insert (which already saves).
        // Re-read via models, then explicitly save.
        let fetched = state.models.first!
        fetched.priority = 99
        state.save()

        XCTAssertEqual(state.models.first?.priority, 99)
    }

    // MARK: - deleteAll

    @MainActor
    func testDeleteAllWhenPopulated() {
        let state = Application.modelState(\.mscNotes)
        state.insert(MSCoverageNote(title: "N1", body: "", priority: 1))
        state.insert(MSCoverageNote(title: "N2", body: "", priority: 2))
        state.insert(MSCoverageNote(title: "N3", body: "", priority: 3))

        XCTAssertEqual(state.models.count, 3)
        state.deleteAll()
        XCTAssertTrue(state.models.isEmpty)
    }

    /// Calling `deleteAll()` on an already-empty store should be a no-op (exercises the
    /// `save(context:action:)` guard branch where `!context.hasChanges`).
    @MainActor
    func testDeleteAllWhenAlreadyEmpty() {
        let state = Application.modelState(\.mscNotes)
        XCTAssertTrue(state.models.isEmpty)

        // Should not crash or error.
        state.deleteAll()
        XCTAssertTrue(state.models.isEmpty)
    }

    // MARK: - FetchDescriptor behaviors

    /// Sorting via FetchDescriptor is applied on every `models` access.
    @MainActor
    func testFetchDescriptorSortsResults() {
        let baseState = Application.modelState(\.mscNotes)
        baseState.insert(MSCoverageNote(title: "Beta", body: "", priority: 2))
        baseState.insert(MSCoverageNote(title: "Alpha", body: "", priority: 1))
        baseState.insert(MSCoverageNote(title: "Gamma", body: "", priority: 3))

        let sorted = Application.modelState(\.mscNotesByPriority).models
        XCTAssertEqual(sorted.map(\.priority), [1, 2, 3])
        XCTAssertEqual(sorted.map(\.title), ["Alpha", "Beta", "Gamma"])
    }

    /// `#Predicate` filtering returns only matching models.
    @MainActor
    func testFetchDescriptorPredicateFiltering() {
        let baseState = Application.modelState(\.mscNotes)
        baseState.insert(MSCoverageNote(title: "Low1", body: "", priority: 1))
        baseState.insert(MSCoverageNote(title: "Low2", body: "", priority: 4))
        baseState.insert(MSCoverageNote(title: "High1", body: "", priority: 8))
        baseState.insert(MSCoverageNote(title: "High2", body: "", priority: 10))

        let filtered = Application.modelState(\.mscNotesScopedWithDescriptor).models
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.priority > 5 })
    }

    /// `fetchLimit` caps the number of returned models.
    @MainActor
    func testFetchDescriptorFetchLimit() {
        let baseState = Application.modelState(\.mscNotes)
        for index in 1...5 {
            baseState.insert(MSCoverageNote(title: "Note\(index)", body: "", priority: index))
        }

        let limited = Application.modelState(\.mscNotesLimited).models
        XCTAssertLessThanOrEqual(limited.count, 2)
    }

    // MARK: - Multi-container isolation

    /// Two distinct ModelContainer dependencies must not share data.
    @MainActor
    func testMultiContainerIsolation() {
        let notes = Application.modelState(\.mscNotes)
        let events = Application.modelState(\.mscEvents)

        notes.insert(MSCoverageNote(title: "NoteA", body: "", priority: 1))
        events.insert(MSCoverageEvent(label: "EventA"))

        XCTAssertEqual(notes.models.count, 1)
        XCTAssertEqual(events.models.count, 1)

        notes.deleteAll()
        XCTAssertTrue(notes.models.isEmpty)
        // Events in the secondary container must be unaffected.
        XCTAssertEqual(events.models.count, 1)
    }

    // MARK: - Feature / id scoping

    /// Two ModelStates with different feature+id values are distinct scopes.
    @MainActor
    func testDifferentFeatureIDsAreDistinctScopes() {
        let stateA = Application.modelState(\.mscNotesExplicitFeatureID)
        let stateB = Application.modelState(\.mscNotesScopedWithDescriptor)

        // stateA — feature "MSCoverageFeature", id "mscNotesExplicitFeatureID"
        // stateB — feature "MSCoverageFeature", id "mscNotesScopedWithDescriptor"
        // Both have different scope ids; the scopes must differ.
        XCTAssertNotEqual(stateA.scope.id, stateB.scope.id)
    }

    /// Two ModelStates on the same container share persisted data.
    @MainActor
    func testSameContainerSharedData() {
        let state1 = Application.modelState(\.mscNotes)
        let state2 = Application.modelState(\.mscNotesByPriority)

        state1.insert(MSCoverageNote(title: "Shared", body: "", priority: 1))

        // Both states read from the same container; state2 must see the inserted note.
        XCTAssertEqual(state2.models.count, 1)
        XCTAssertEqual(state2.models.first?.title, "Shared")
    }

    // MARK: - Multiple model types on same container

    @MainActor
    func testMultipleModelTypesOnSameContainer() {
        let notes = Application.modelState(\.mscNotes)
        let tags = Application.modelState(\.mscTags)

        notes.insert(MSCoverageNote(title: "NoteX", body: "", priority: 1))
        tags.insert(MSCoverageTag(name: "TagX", color: "red"))

        XCTAssertEqual(notes.models.count, 1)
        XCTAssertEqual(tags.models.count, 1)

        notes.deleteAll()
        XCTAssertTrue(notes.models.isEmpty)
        // Tags must be unaffected by deleting notes.
        XCTAssertEqual(tags.models.count, 1)
    }

    // MARK: - @ModelState property wrapper

    /// `wrappedValue` returns the live-fetched models array.
    @MainActor
    func testPropertyWrapperWrappedValue() {
        let reader = MSCoverageNoteReader()
        XCTAssertTrue(reader.notes.isEmpty)

        Application.modelState(\.mscNotes).insert(
            MSCoverageNote(title: "WrapperNote", body: "", priority: 3)
        )

        XCTAssertEqual(reader.notes.count, 1)
        XCTAssertEqual(reader.notes.first?.title, "WrapperNote")
    }

    /// `projectedValue` exposes the underlying `Application.ModelState` for mutations.
    @MainActor
    func testPropertyWrapperProjectedValueInsert() {
        let reader = MSCoverageNoteReader()
        reader.$notes.insert(MSCoverageNote(title: "Projected", body: "", priority: 5))

        XCTAssertEqual(reader.notes.count, 1)
        XCTAssertEqual(reader.notes.first?.title, "Projected")
    }

    @MainActor
    func testPropertyWrapperProjectedValueDelete() {
        let reader = MSCoverageNoteReader()
        let note = MSCoverageNote(title: "DeleteMe", body: "", priority: 1)
        reader.$notes.insert(note)
        XCTAssertEqual(reader.notes.count, 1)

        reader.$notes.delete(note)
        XCTAssertTrue(reader.notes.isEmpty)
    }

    @MainActor
    func testPropertyWrapperProjectedValueSave() {
        let reader = MSCoverageNoteReader()
        let note = MSCoverageNote(title: "SaveMe", body: "", priority: 1)
        reader.$notes.insert(note)

        let fetched = reader.notes.first!
        fetched.body = "updated"
        reader.$notes.save()

        XCTAssertEqual(reader.notes.first?.body, "updated")
    }

    @MainActor
    func testPropertyWrapperProjectedValueDeleteAll() {
        let reader = MSCoverageNoteReader()
        reader.$notes.insert(MSCoverageNote(title: "A", body: "", priority: 1))
        reader.$notes.insert(MSCoverageNote(title: "B", body: "", priority: 2))
        XCTAssertEqual(reader.notes.count, 2)

        reader.$notes.deleteAll()
        XCTAssertTrue(reader.notes.isEmpty)
    }

    /// @ModelState used from a class (@MainActor class ViewModel).
    @MainActor
    func testPropertyWrapperFromViewModelClass() {
        let viewModel = MSCoverageNoteViewModel()
        XCTAssertTrue(viewModel.notes.isEmpty)

        viewModel.addNote(title: "VM-Note1", body: "first", priority: 1)
        viewModel.addNote(title: "VM-Note2", body: "second", priority: 2)

        XCTAssertEqual(viewModel.notes.count, 2)

        let target = viewModel.notes.first { $0.title == "VM-Note1" }!
        viewModel.removeNote(target)

        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertEqual(viewModel.notes.first?.title, "VM-Note2")
    }

    /// Changes made through the ViewModel are visible through the bare Application.modelState.
    @MainActor
    func testViewModelChangesReflectedInApplicationModelState() {
        let viewModel = MSCoverageNoteViewModel()
        viewModel.addNote(title: "Shared-VM", body: "", priority: 42)

        let direct = Application.modelState(\.mscNotes).models
        XCTAssertEqual(direct.count, 1)
        XCTAssertEqual(direct.first?.title, "Shared-VM")
        XCTAssertEqual(direct.first?.priority, 42)
    }

    /// `persistChanges` on the viewModel exercises the public `save()` method
    /// (ensuring the non-early-return path is hit when changes are pending).
    @MainActor
    func testPropertyWrapperSaveWithPendingChanges() {
        let viewModel = MSCoverageNoteViewModel()
        viewModel.addNote(title: "ModifyMe", body: "original", priority: 1)

        let note = viewModel.notes.first!
        note.body = "modified"
        viewModel.persistChanges()

        XCTAssertEqual(Application.modelState(\.mscNotes).models.first?.body, "modified")
    }

    /// Calling `persistChanges()` when there are no pending changes exercises
    /// the `guard context.hasChanges else { return }` early-return path via `save()`.
    @MainActor
    func testPropertyWrapperSaveNoOpWhenNoPendingChanges() {
        let viewModel = MSCoverageNoteViewModel()
        // Nothing inserted; context has no changes.
        viewModel.persistChanges()
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    // MARK: - Scope properties

    @MainActor
    func testModelStateScopeProperties() {
        let state = Application.modelState(\.mscNotesExplicitFeatureID)
        XCTAssertEqual(state.scope.name, "MSCoverageFeature")
        XCTAssertEqual(state.scope.id, "mscNotesExplicitFeatureID")
    }

    @MainActor
    func testModelStateScopeDefaultFeatureName() {
        // The default feature for the explicit-id-no-feature overload uses "App".
        // mscNotesScopedWithDescriptor uses "MSCoverageFeature" explicitly —
        // use a direct call to verify the default-feature path.
        let state: Application.ModelState<MSCoverageNote> = Application.shared.modelState(
            container: \.mscPrimaryContainer,
            id: "mscDefaultFeatureScope"
        )
        XCTAssertEqual(state.scope.name, "App")
        XCTAssertEqual(state.scope.id, "mscDefaultFeatureScope")
    }

    // MARK: - containerKeyPath

    @MainActor
    func testContainerKeyPathProperty() {
        let state = Application.modelState(\.mscNotes)
        let context1 = Application.dependency(state.containerKeyPath).mainContext
        let context2 = Application.modelState(\.mscNotes).context
        XCTAssertTrue(context1 === context2)
    }
}
#endif
