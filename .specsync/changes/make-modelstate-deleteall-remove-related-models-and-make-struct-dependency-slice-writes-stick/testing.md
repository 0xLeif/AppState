---
change: make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick
artifact: testing
---

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

Run `APPSTATE_STRICT=1 swift test --filter 'DogfoodAppTests|ModelStateTests|ModelStateCoverageTests|DependencySliceTests'`. Do not run an unfiltered `swift test` in this checkout.
