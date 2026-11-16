## ADDED

### REQUIREMENT REQ-property-wrappers-001

A writable DependencySlice of a struct value SHALL write the mutated field back onto the dependency stored in Application, and a later read SHALL show that write. A held slice SHALL read and write the dependency currently in the cache, keeping sibling fields written after the handle was created.

Acceptance Criteria

- A struct write through Application.dependencySlice or @DependencySlice stays visible on the stored dependency.
- A held DependencySlice does not restore sibling fields or a dependency captured when the handle was created.
