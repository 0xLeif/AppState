---
change: make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick
artifact: requirements
---

# Requirements

- `deleteAll` removes every model matching the predicate of the state's `FetchDescriptor`, including models that have relationships, then saves.
- `deleteAll` ignores the descriptor's `fetchLimit` and `fetchOffset`. `models` still honors them. After `deleteAll`, the next `models` read is empty for that predicate.
- A descriptor with a predicate removes only the models that predicate matches. Other models in the same container stay.
- A writable dependency slice of a struct value updates the dependency stored in `Application`, whether the write goes through `Application.dependencySlice` or `@DependencySlice`.
- A held `Application.DependencySlice` reads and writes the dependency currently in the cache. It keeps sibling fields written after the handle was created, and it edits an `override` installed after the handle was created instead of restoring the previous dependency.
- Class dependency slices keep working.
- Lenient `deleteAll` still logs and swallows a fetch failure. Strict `deleteAll` still throws it.
