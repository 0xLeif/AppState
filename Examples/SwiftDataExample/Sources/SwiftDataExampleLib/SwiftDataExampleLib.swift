// SwiftDataExampleLib.swift
//
// Public entry point for the SwiftDataExampleLib module.
//
// The library is organised into focused files:
//   Models/Schema/LabSchemaV1.swift   — V1 VersionedSchema (TodoList, TodoItem, Tag)
//   Models/Schema/LabSchemaV2.swift   — V2 VersionedSchema + LabMigrationPlan
//   Models/Models.swift               — Current-schema type aliases
//   Containers/ContainerFactories.swift — ModelContainer factories
//   Application/Application+Lab.swift  — AppState dependency + ModelState registrations
//   Stores/TodoListStore.swift         — ObservableObject view-model (lists)
//   Stores/TodoItemStore.swift         — ObservableObject view-model (items within a list)
//   Views/SwiftDataLabView.swift       — Public root SwiftUI view
