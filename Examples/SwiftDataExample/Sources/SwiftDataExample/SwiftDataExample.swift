import AppState
import Foundation
import SwiftDataExampleLib

#if canImport(SwiftData)
import SwiftData

// MARK: - Entry point

@main
struct SwiftDataExample {
    /// `main()` is `@MainActor` because every `ModelState` / `ModelContext` operation is
    /// bound to the main actor.
    @MainActor
    static func main() {
        Application.logging(isEnabled: true)

        print("== SwiftData Lab + AppState example ==\n")

        // ── Reset to a clean slate ────────────────────────────────────────────────────────
        Application.modelState(\.allItems).deleteAll()
        Application.modelState(\.allTags).deleteAll()
        Application.modelState(\.todoLists).deleteAll()
        precondition(Application.modelState(\.todoLists).models.isEmpty)

        // ── 1. TodoList creation + relationship ──────────────────────────────────────────
        print("1. Creating lists…")
        let listStore = TodoListStore()
        listStore.createList(titled: "Work")
        listStore.createList(titled: "Personal")
        precondition(listStore.lists.count == 2, "Expected 2 lists")
        print("   \(listStore.lists.map(\.title))")

        guard let workList = listStore.lists.first(where: { $0.title == "Work" }) else {
            fatalError("Work list not found")
        }

        // ── 2. Item insertion + priority/dueDate (V2 fields) ─────────────────────────────
        print("\n2. Adding items to Work list…")
        let itemStore = TodoItemStore(list: workList)
        itemStore.addItem(titled: "Write unit tests", priority: 5)
        itemStore.addItem(titled: "Review PR",        priority: 3, dueDate: Date(timeIntervalSinceNow: 86400))
        itemStore.addItem(titled: "Update README",    priority: 1)
        precondition(workList.items.count == 3, "Expected 3 items in Work list")
        print("   Items: \(workList.items.map(\.title))")

        // ── 3. Tag attachment + unique constraint (upsert) ───────────────────────────────
        print("\n3. Attaching tags (including duplicate to trigger upsert)…")
        guard let testItem = workList.items.first(where: { $0.title == "Write unit tests" }) else {
            fatalError("Test item not found")
        }
        itemStore.attachTag(named: "swift", to: testItem)
        itemStore.attachTag(named: "testing", to: testItem)

        guard let prItem = workList.items.first(where: { $0.title == "Review PR" }) else {
            fatalError("PR item not found")
        }
        itemStore.attachTag(named: "swift", to: prItem)   // reuse existing "swift" tag

        let allTags = Application.modelState(\.allTags).models
        print("   Total unique tags: \(allTags.count) → \(allTags.map(\.name))")
        precondition(allTags.count == 2, "Expected exactly 2 unique tags (upsert behaviour)")

        // ── 4. Compound query: incomplete items with a given tag ─────────────────────────
        print("\n4. Compound query: incomplete 'swift'-tagged items…")
        let swiftIncomplete = itemStore.incompleteItems(taggedWith: "swift")
        print("   Found \(swiftIncomplete.count) items: \(swiftIncomplete.map(\.title))")
        precondition(swiftIncomplete.count == 2)

        // ── 5. Toggle done, then re-run compound query ────────────────────────────────────
        print("\n5. Marking '\(testItem.title)' done; re-running query…")
        itemStore.toggleDone(testItem)
        let swiftIncompleteAfter = itemStore.incompleteItems(taggedWith: "swift")
        print("   Now \(swiftIncompleteAfter.count) incomplete 'swift' item(s)")
        precondition(swiftIncompleteAfter.count == 1)

        // ── 6. Cascade delete: deleting a list removes its items ─────────────────────────
        print("\n6. Cascade-deleting Work list…")
        let itemCountBefore = Application.modelState(\.allItems).models.count
        print("   Items before delete: \(itemCountBefore)")
        listStore.delete(workList)
        let itemCountAfter = Application.modelState(\.allItems).models.count
        print("   Items after delete: \(itemCountAfter)")
        precondition(itemCountAfter == 0, "Cascade delete should have removed all items")

        // Tags survive (nullify rule on TodoItem.tags)
        let tagsAfter = Application.modelState(\.allTags).models.count
        print("   Tags still present (nullify, not cascade): \(tagsAfter)")

        // ── 7. Migration container smoke-test ────────────────────────────────────────────
        print("\n7. Migration container smoke-test (V1→V2 with LabMigrationPlan)…")
        let migratedContainer = makeInMemoryMigratedContainer()
        let ctx = migratedContainer.mainContext
        let v2Item = TodoItem(title: "Post-migration item", priority: 4, dueDate: Date())
        ctx.insert(v2Item)
        try? ctx.save()
        let fetched = (try? ctx.fetch(FetchDescriptor<TodoItem>())) ?? []
        print("   V2 item in migrated container: \(fetched.map(\.title))")
        precondition(fetched.count == 1)
        precondition(fetched[0].priority == 4, "V2 priority field must be accessible")

        print("\n== Example completed successfully ==")
        exit(0)
    }
}

#else

@main
struct SwiftDataExample {
    static func main() {
        print("SwiftData unavailable on this platform; nothing to demonstrate.")
    }
}

#endif
