---
change: make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick
artifact: research
---

# Research

Dogfood run of `DogfoodAppTests` on macOS, before the fix:

- Session, stored, file, secure, and sync state composed and passed.
- Explicit-id and call-site dependency factories each ran once.
- A SwiftData notebook, pages, tags, sort, fetch limit, and a direct `ModelContext` insert passed.
- `deleteAll` on a pinned predicate left both the pinned and the loose page. Console: `Batch delete failed due to mandatory OTO nullify inverse on DogfoodPage/notebook`, and the same class of error for the tag relationship.
- A struct `DependencySlice` write left the stored name as `start`.
- Tracking `@Constant` did not observe a later session write. `@Slice` is the wrapper that calls `registerObservation()`.
