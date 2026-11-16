---
change: make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick
artifact: design
---

# Design

`deleteAll` copies the state's `FetchDescriptor`, sets `fetchLimit` and `fetchOffset` to `nil` on the copy, fetches, deletes those objects on the context, then saves once. It does not use the batch delete API. The delete is predicate-wide, as it was in 3.0.1, where the batch delete took only the descriptor's predicate. `models` still fetches with the unchanged descriptor, so it still honors the limit and offset. Cascade and nullify run as normal context deletes.

Both dependency-slice setters assign the field, write the `Dependency` struct back with `cache.set` under `dependency.scope.key`, then call `notifyChange()`. Observers read the stored value, not the pre-write copy.

`Application.DependencySlice` does not write the copy it captured at init. Each read and each write loads the `Dependency` currently stored for that scope, changes the one field, and stores that value. A handle created before a sibling write, an `override`, or a `promote` therefore edits the current dependency. The init value remains only as a fallback when the scope is no longer cached. The `@DependencySlice` wrapper already re-reads on each write.
