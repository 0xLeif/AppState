# Lesson bundle: make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick

Material for folding this change's lessons into each affected module's lesson file.
Synthesise from what actually happened below; do not restate the change description.

## What this change was

- **Title**: Make ModelState.deleteAll remove related models, and make struct dependency slice writes stick
- **Kind**: BugFix
- **Specs**: swiftdata, property-wrappers, application
- **Paths**: Sources/AppState/Application/Types/State/Application+ModelState.swift, Sources/AppState/Application/Types/Dependency/Slice/Application+DependencySlice.swift, Sources/AppState/PropertyWrappers/Dependency/Slice/DependencySlice.swift
- **Acceptance**: Filtered ModelState.deleteAll removes only matching related models, and a struct DependencySlice write stays visible on the stored dependency.

## Evidence

- Verification commit: `2ad56485d09a8bd78daeb561126d281911716034`
- Base commit: `5053feab3497605386613e4309bc0cf8c95dc5c4`
- Verified by: `specsync check --spec application --spec property-wrappers --spec swiftdata`

## From the change's context.md

# Context

Dogfood of every AppState kind, centered on a SwiftData notebook with pages and tags, showed two places where the running code misses the written contract.

`ModelState.deleteAll` called SwiftData's batch `ModelContext.delete(model:where:)`. With a relationship on the model, Core Data rejects that batch ("mandatory OTO/MTM nullify inverse"). The lenient `deleteAll` logs and swallows the error, so the rows stay. A pinned-page descriptor therefore deleted nothing. Flat models in the older tests have no relationships, so they never hit this.

`Application.DependencySlice`'s setter, and the `@DependencySlice` setter, mutated a copy of the `Dependency` struct and called `notifyChange()` before that mutation. Class values still changed, because the copy shares the instance. Struct values did not, and a later `Application.dependency` read returned the original. The public docs say the write shows up on the stored dependency.

Writing that struct back from the init copy caused a second miss: a handle created earlier replaced the current dependency, dropping sibling fields and undoing a later override. The handle now reloads the cached dependency before it reads or writes.

The first fetch-and-delete used the whole descriptor, so a `fetchLimit` or `fetchOffset` hid matching rows from `deleteAll`. Shipped 3.0.1 passed only the predicate to the batch delete, so it ignored both. Leif decided `deleteAll` stays predicate-wide: it clears the limit and offset before its fetch, and `models` still honors them.

The swiftdata spec's `deleteAll` row, behavioral example, and acceptance criterion now state that. The property-wrapper and application spec text does not change.

## From the change's design.md

# Design

`deleteAll` copies the state's `FetchDescriptor`, sets `fetchLimit` and `fetchOffset` to `nil` on the copy, fetches, deletes those objects on the context, then saves once. It does not use the batch delete API. The delete is predicate-wide, as it was in 3.0.1, where the batch delete took only the descriptor's predicate. `models` still fetches with the unchanged descriptor, so it still honors the limit and offset. Cascade and nullify run as normal context deletes.

Both dependency-slice setters assign the field, write the `Dependency` struct back with `cache.set` under `dependency.scope.key`, then call `notifyChange()`. Observers read the stored value, not the pre-write copy.

`Application.DependencySlice` does not write the copy it captured at init. Each read and each write loads the `Dependency` currently stored for that scope, changes the one field, and stores that value. A handle created before a sibling write, an `override`, or a `promote` therefore edits the current dependency. The init value remains only as a fallback when the scope is no longer cached. The `@DependencySlice` wrapper already re-reads on each write.

## From the change's testing.md

# Testing

`Tests/AppStateTests/DogfoodAppTests.swift` is the check.

- `testFilteredDeleteAllLeavesOtherPagesAndCascadeRemovesTheGraph` builds a notebook, a pinned page, a loose page, and a tag. It asserts the tag has that page, then `strict.deleteAll` on the pinned descriptor leaves the loose page and the tag and clears the tag's page link. `strict.deleteAll` on the notebook state then cascades the remaining page and leaves the tag.
- `testDeleteAllIgnoresFetchLimitAndRemovesEveryMatch` inserts two pages and reads one through a state with `fetchLimit = 1`. `strict.deleteAll` on that state removes both pages and leaves the notebook.
- `testDeleteAllIgnoresFetchOffsetAndRemovesEveryMatch` does the same through a state with `fetchOffset = 1`.
- `testStructDependencySliceWriteReachesTheStoredDependency` writes a struct field through `@DependencySlice` and through `Application.dependencySlice`, and reads it back from both.
- `testHeldDependencySliceKeepsSiblingFieldsAndReadsLive` holds a name slice, writes that same field through another slice, and the held slice reads the new name. A later note write stays when the held slice then writes the name.
- `testHeldDependencySliceWritesThroughAnOverride` holds a class slice, overrides the clock, writes the label, and checks the override's other field. After cancel, a write through the same handle updates the restored clock.
- `testHeldStructDependencySliceWritesThroughAnOverride` does the same for a struct. A write during the override keeps the override's other field. Cancel restores the pre-override struct.
- `DogfoodPersistentEdgeTests` is extra dogfood. It is not evidence for this change. Secure and sync uses stay inside `canImport(Security)` so the Linux and Windows test build can compile the file.
- `ModelStateCoverageTests.testDeleteAllIgnoresFetchLimit` inserts five flat notes and calls `deleteAll` on a state with `fetchLimit = 2`. No note remains.
- Existing `ModelStateTests`, `ModelStateCoverageTests`, and `DependencySliceTests` cover the flat-model and class-slice paths that must keep passing.

With the two lines that clear the limit and offset removed, the three new `deleteAll` tests fail.

## Requirement evidence

| Requirement | Evidence |
|---|---|
| REQ-swiftdata-001 | `DogfoodAppTests.testFilteredDeleteAllLeavesOtherPagesAndCascadeRemovesTheGraph`, `testDeleteAllIgnoresFetchLimitAndRemovesEveryMatch`, `testDeleteAllIgnoresFetchOffsetAndRemovesEveryMatch`, and `ModelStateCoverageTests.testDeleteAllIgnoresFetchLimit` |
| REQ-property-wrappers-001 | `DogfoodAppTests.testStructDependencySliceWriteReachesTheStoredDependency`, `testHeldDependencySliceKeepsSiblingFieldsAndReadsLive`, `testHeldDependencySliceWritesThroughAnOverride`, and `testHeldStructDependencySliceWritesThroughAnOverride` |
| REQ-application-001 | The same held-slice and struct-write tests in `DogfoodAppTests`, which call `Application.dependencySlice` |


Run `APPSTATE_STRICT=1 swift test --filter 'DogfoodAppTests|ModelStateTests|ModelStateCoverageTests|DependencySliceTests'`. Do not run an unfiltered `swift test` in this checkout.

## Where these lessons go

- `specs/swiftdata/context.md`
- `specs/property-wrappers/context.md`
- `specs/application/context.md`
