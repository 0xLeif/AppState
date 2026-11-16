---
change: make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick
artifact: tasks
---

# Tasks

- Replace batch delete in `ModelState.deleteAll` with a fetch of the descriptor, with `fetchLimit` and `fetchOffset` cleared, followed by per-object delete and one save.
- Write struct dependency-slice mutations back to the application cache from both the `Application.DependencySlice` setter and the `@DependencySlice` setter, and notify after the write.
- Make `Application.DependencySlice` load the cached dependency on each read and write, so a held handle does not restore sibling fields or a pre-override value.
- Reword the `deleteAll` sentences in the swiftdata spec, its requirements, the English ModelState page, and the doc comments. Add `CHANGELOG.md` with a 3.0.2 section.
- Cover both with `DogfoodAppTests`, including a two-row `fetchLimit = 1` delete. The filtered delete uses `strict.deleteAll`, and the notebook cascade is also `strict.deleteAll`.
