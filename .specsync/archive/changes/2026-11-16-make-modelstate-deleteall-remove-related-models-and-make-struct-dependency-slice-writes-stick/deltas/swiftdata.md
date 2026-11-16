## ADDED

### REQUIREMENT REQ-swiftdata-001

ModelState.deleteAll() SHALL delete every persisted model matching the predicate of the state's FetchDescriptor, including models that have relationships, and SHALL ignore fetchLimit and fetchOffset. It SHALL then save. The next models read for that predicate SHALL be empty.

Acceptance Criteria

- A filtered deleteAll removes only the models that predicate matches, including models with relationships, and leaves other models in the same container.
- A state with fetchLimit or fetchOffset still deletes every match of the predicate.
- After deleteAll, the next models read is empty for that predicate.
