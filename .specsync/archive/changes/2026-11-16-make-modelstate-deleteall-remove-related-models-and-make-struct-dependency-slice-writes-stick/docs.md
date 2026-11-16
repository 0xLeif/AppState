---
change: make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick
artifact: docs
---

# Docs

Two documentation edits ride along with this change, and the `deleteAll` wording is corrected.

- `documentation/en/usage-overview.md` gained a map: a mermaid flowchart that shows, for each property wrapper, where the value lives, whether it is Apple-only, and whether a read calls `registerObservation()`. Best Practices gained one sentence saying `@Constant` and `@ModelState` do not by themselves refresh a SwiftUI view.
- `AGENTS.md` was added at the repo root with the durable rules for an agent in this checkout.

The other languages under `documentation/` were not translated, so they do not have the map yet.

`deleteAll` is predicate-wide, and the wording now says so: it deletes every model matching the descriptor's predicate, ignores `fetchLimit` and `fetchOffset`, saves, and the next `models` read is empty. That sentence changed in `documentation/en/usage-modelstate.md`, the `deleteAll` doc comments in `Application+ModelState.swift`, `specs/swiftdata/swiftdata.spec.md` (the `deleteAll` row, the behavioral example, spec version 3), and `specs/swiftdata/requirements.md`. The other languages still carry the old sentence.

`CHANGELOG.md` is new and has a 3.0.2 section listing the three fixes.

The dependency-slice docs already say a write shows up on the original dependency. The code now does that for struct values.
