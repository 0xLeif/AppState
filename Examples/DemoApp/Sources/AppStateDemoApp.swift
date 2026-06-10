import SwiftUI

import DataDashboard
import MultiPlatformTracker
import SecureVault
import SettingsKit
import SyncNotes
import TodoCloud

#if canImport(SwiftData)
import SwiftDataExampleLib
#endif

// MARK: - App entry point

/// A host app that showcases every AppState example view on a real device or simulator.
///
/// Each row drives into the corresponding example's *public* root view, so what you see running
/// here is exactly the SwiftUI that the example packages ship and test.
@main
struct AppStateDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleCatalogView()
        }
    }
}

// MARK: - Catalog

/// The list of examples, grouped the same way the repository organizes them.
@available(iOS 18.0, *)
struct ExampleCatalogView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Moderate") {
                    NavigationLink("TodoCloud — @SyncState") {
                        TodoListView()
                    }
                    NavigationLink("SettingsKit — @StoredState + @Slice") {
                        SettingsView()
                    }
                    NavigationLink("DataDashboard — Dependency injection") {
                        DataDashboard.DashboardView()
                    }
                    NavigationLink("SecureVault — @SecureState") {
                        VaultView()
                    }
                }

                Section("Focused") {
                    NavigationLink("SyncNotes — @SyncState") {
                        NotesView()
                    }
                    NavigationLink("MultiPlatformTracker — @StoredState") {
                        TrackerView()
                    }
                }

                #if canImport(SwiftData)
                Section("SwiftData (3.0.0)") {
                    NavigationLink("SwiftData Lab — relationships, queries, migration") {
                        SwiftDataLabView()
                    }
                }
                #endif

                Section("Stress") {
                    NavigationLink("Break It — try to crash AppState") {
                        BreakItView()
                    }
                }
            }
            .navigationTitle("AppState 3.0.0")
        }
    }
}
