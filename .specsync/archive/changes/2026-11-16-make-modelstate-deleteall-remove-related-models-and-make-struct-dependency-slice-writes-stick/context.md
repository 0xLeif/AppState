---
change: make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick
artifact: context
---

# Context

Dogfood of every AppState kind, centered on a SwiftData notebook with pages and tags, showed two places where the running code misses the written contract.

`ModelState.deleteAll` called SwiftData's batch `ModelContext.delete(model:where:)`. With a relationship on the model, Core Data rejects that batch ("mandatory OTO/MTM nullify inverse"). The lenient `deleteAll` logs and swallows the error, so the rows stay. A pinned-page descriptor therefore deleted nothing. Flat models in the older tests have no relationships, so they never hit this.

`Application.DependencySlice`'s setter, and the `@DependencySlice` setter, mutated a copy of the `Dependency` struct and called `notifyChange()` before that mutation. Class values still changed, because the copy shares the instance. Struct values did not, and a later `Application.dependency` read returned the original. The public docs say the write shows up on the stored dependency.

Writing that struct back from the init copy caused a second miss: a handle created earlier replaced the current dependency, dropping sibling fields and undoing a later override. The handle now reloads the cached dependency before it reads or writes.

The first fetch-and-delete used the whole descriptor, so a `fetchLimit` or `fetchOffset` hid matching rows from `deleteAll`. Shipped 3.0.1 passed only the predicate to the batch delete, so it ignored both. Leif decided `deleteAll` stays predicate-wide: it clears the limit and offset before its fetch, and `models` still honors them.

The swiftdata spec's `deleteAll` row, behavioral example, and acceptance criterion now state that. The property-wrapper and application spec text does not change.
