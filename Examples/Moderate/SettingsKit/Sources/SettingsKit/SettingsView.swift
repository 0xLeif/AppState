#if canImport(SwiftUI)
import AppState
import SwiftUI

// MARK: - SettingsView

/// A SwiftUI settings screen that reads and writes individual fields of the
/// persisted `Settings` struct through `@StoredState` and `@Slice`.
///
/// `@StoredState` binds the entire `Settings` value so the view re-renders
/// whenever *any* field changes.  `@Slice` binds individual scalar fields for
/// direct use with SwiftUI controls, writing through to the same underlying
/// `UserDefaults` key.
public struct SettingsView: View {
    // MARK: - State bindings

    /// The full settings object, persisted to `UserDefaults`.
    @StoredState(\.settings) private var settings: Settings

    /// A slice that exposes only the `isDarkMode` flag for a `Toggle`.
    @Slice(\.settings, \.isDarkMode) private var isDarkMode: Bool

    /// A slice that exposes only `notificationsEnabled` for a `Toggle`.
    @Slice(\.settings, \.notificationsEnabled) private var notificationsEnabled: Bool

    /// A slice that exposes only `fontSize` for a `Slider`.
    @Slice(\.settings, \.fontSize) private var fontSize: Double

    /// A slice that exposes only `username` for a `TextField`.
    @Slice(\.settings, \.username) private var username: String

    // MARK: - Body

    public var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $isDarkMode)
                VStack(alignment: .leading) {
                    Text("Font Size: \(Int(fontSize)) pt")
                    Slider(value: $fontSize, in: 10...32, step: 1)
                }
            }

            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            }

            Section("Account") {
                TextField("Username", text: $username)
                    #if os(iOS) || os(tvOS) || os(visionOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
            }

            Section {
                Button("Restore Defaults", role: .destructive) {
                    Application.reset(storedState: \.settings)
                }
            }
        }
        .navigationTitle("Settings")
    }

    // MARK: - Initializers

    /// Creates a `SettingsView`.  No external arguments are needed because all
    /// state is sourced from the shared `Application` instance.
    @MainActor
    public init() {}
}

// MARK: - Previews

#Preview {
    NavigationStack {
        SettingsView()
    }
}
#endif
