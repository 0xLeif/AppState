## ADDED

### REQUIREMENT REQ-application-001

Application.DependencySlice SHALL load the dependency currently stored for its scope on each read and write, SHALL write one mutated field back into that stored dependency, and SHALL notify after the write.

Acceptance Criteria

- A struct field write through a DependencySlice is visible on the dependency stored in Application.
- A held DependencySlice follows a later override instead of writing back the dependency captured at init.
