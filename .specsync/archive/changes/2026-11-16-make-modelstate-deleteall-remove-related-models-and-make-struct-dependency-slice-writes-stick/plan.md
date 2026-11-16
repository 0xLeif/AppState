---
change: make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick
artifact: plan
---

# Plan

## Approach

Change the two implementations that miss the existing contract. In the swiftdata spec, reword only the `deleteAll` sentences so they say the delete is predicate-wide. Leave the other canonical specs alone.

## Out of scope

No new state kinds, no migration of on-disk SwiftData stores, and no change to `@Constant` observation. `@Constant` does not call `registerObservation()`; the property-wrapper spec's `DynamicProperty` table already excludes it.

## Steps

1. Fetch-and-delete in `deleteAll`, with `fetchLimit` and `fetchOffset` cleared on the descriptor used for that fetch.
2. Store the updated `Dependency` from both slice setters, then notify. `Application.DependencySlice` reloads the cached dependency on each access so the stored struct is the current one, not the copy from init.
3. Run the dogfood tests and the existing model and dependency-slice suites.

## Risks

Fetch-and-delete is slower than a batch delete on a huge table, and it loads every matching model, because the limit and offset do not bound the delete. That matches 3.0.1, where the batch path used only the predicate.

## Constraints consulted

none
