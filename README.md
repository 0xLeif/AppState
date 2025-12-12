# AppState

[![macOS Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/macOS.yml?label=macOS&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/macOS.yml)
[![Ubuntu Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/ubuntu.yml?label=Ubuntu&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/ubuntu.yml)
[![Windows Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/windows.yml?label=Windows&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/windows.yml)
[![License](https://img.shields.io/github/license/0xLeif/AppState)](https://github.com/0xLeif/AppState/blob/main/LICENSE)
[![Version](https://img.shields.io/github/v/release/0xLeif/AppState)](https://github.com/0xLeif/AppState/releases)

Read this in other languages: [French](documentation/README.fr.md) | [German](documentation/README.de.md) | [Hindi](documentation/README.hi.md) | [Portuguese](documentation/README.pt.md) | [Russian](documentation/README.ru.md) | [Simplified Chinese](documentation/README.zh-CN.md) | [Spanish](documentation/README.es.md)

**AppState** is a Swift 6 library designed to simplify the management of application state in a thread-safe, type-safe, and SwiftUI-friendly way. It provides a set of tools to centralize and synchronize state across your application, as well as inject dependencies into various parts of your app.

## Requirements

- **iOS**: 15.0+
- **watchOS**: 8.0+
- **macOS**: 11.0+
- **tvOS**: 15.0+
- **visionOS**: 1.0+
- **Swift**: 6.0+
- **Xcode**: 16.0+
  
**Non-Apple Platform Support**: Linux & Windows

> 🍎 Features marked with this symbol are specific to Apple platforms, as they rely on Apple technologies such as iCloud and the Keychain.

## Key Features

**AppState** includes several powerful features to help manage state and dependencies:

- **State**: Centralized state management that allows you to encapsulate and broadcast changes across the app.
- **StoredState**: Persistent state using `UserDefaults`, ideal for saving small amounts of data between app launches.
- **FileState**: Persistent state stored using `FileManager`, useful for storing larger amounts of data securely on disk.
- 🍎 **SyncState**: Synchronize state across multiple devices using iCloud, ensuring consistency in user preferences and settings.
- 🍎 **SecureState**: Store sensitive data securely using the Keychain, protecting user information such as tokens or passwords.
- **Dependency Management**: Inject dependencies like network services or database clients across your app for better modularity and testing.
- **Slicing**: Access specific parts of a state or dependency for granular control without needing to manage the entire application state.
- **Constants**: Access read-only slices of your state when you need immutable values.
- **Observed Dependencies**: Observe `ObservableObject` dependencies so your views update when they change.

## Getting Started

To integrate **AppState** into your Swift project, you’ll need to use the Swift Package Manager. Follow the [Installation Guide](documentation/en/installation.md) for detailed instructions on setting up **AppState**.

After installation, refer to the [Usage Overview](documentation/en/usage-overview.md) for a quick introduction on how to manage state and inject dependencies into your project.

## Quick Example

Below is a minimal example showing how to define a piece of state and access it from a SwiftUI view:

```swift
import AppState
import SwiftUI

private extension Application {
    var counter: State<Int> {
        state(initial: 0)
    }
}

struct ContentView: View {
    @AppState(\.counter) var counter: Int

    var body: some View {
        VStack {
            Text("Count: \(counter)")
            Button("Increment") { counter += 1 }
        }
    }
}
```

This snippet demonstrates defining a state value in an `Application` extension and using the `@AppState` property wrapper to bind it inside a view.

## Examples

Explore our comprehensive [Examples](Examples/) folder with 31 example projects:

| Category | Examples | Description |
|----------|----------|-------------|
| **Focused** | 2 | Production-quality apps (SyncNotes, MultiPlatformTracker) |
| **Moderate** | 4 | Feature-focused apps (TodoCloud, SettingsKit, DataDashboard, SecureVault) |
| **Lightweight** | 25 | Single-concept examples covering all AppState features |

### Featured Examples

- **[SyncNotes](Examples/Focused/SyncNotes/)** - Note-taking with iCloud sync across devices
- **[MultiPlatformTracker](Examples/Focused/MultiPlatformTracker/)** - Habit tracker for iOS/macOS/watchOS
- **[TodoCloud](Examples/Moderate/TodoCloud/)** - Progressive persistence (memory → local → cloud)
- **[SecureVault](Examples/Moderate/SecureVault/)** - Password manager with Keychain storage

See [Examples/README.md](Examples/README.md) for the full list with descriptions.

## Documentation

Here’s a detailed breakdown of **AppState**'s documentation:

- [Installation Guide](documentation/en/installation.md): How to add **AppState** to your project using Swift Package Manager.
- [Usage Overview](documentation/en/usage-overview.md): An overview of key features with example implementations.
  
### Detailed Usage Guides:

- [State and Dependency Management](documentation/en/usage-state-dependency.md): Centralize state and inject dependencies throughout your app.
- [Slicing State](documentation/en/usage-slice.md): Access and modify specific parts of the state.
- [StoredState Usage Guide](documentation/en/usage-storedstate.md): How to persist lightweight data using `StoredState`.
- [FileState Usage Guide](documentation/en/usage-filestate.md): Learn how to persist larger amounts of data securely on disk.
- [Keychain SecureState Usage](documentation/en/usage-securestate.md): Store sensitive data securely using the Keychain.
- [iCloud Syncing with SyncState](documentation/en/usage-syncstate.md): Keep state synchronized across devices using iCloud.
- [FAQ](documentation/en/faq.md): Answers to common questions when using **AppState**.
- [Constant Usage Guide](documentation/en/usage-constant.md): Access read-only values from your state.
- [ObservedDependency Usage Guide](documentation/en/usage-observeddependency.md): Work with `ObservableObject` dependencies in your views.
- [Advanced Usage](documentation/en/advanced-usage.md): Techniques like just‑in‑time creation and preloading dependencies.
- [Best Practices](documentation/en/best-practices.md): Tips for structuring your app’s state effectively.
- [Migration Considerations](documentation/en/migration-considerations.md): Guidance when updating persisted models.

## Contributing

We welcome contributions! Please check out our [Contributing Guide](documentation/en/contributing.md) for how to get involved.

## Next Steps

With **AppState** installed, you can start exploring its key features by checking out the [Usage Overview](documentation/en/usage-overview.md) and more detailed guides. Get started with managing state and dependencies effectively in your Swift projects! For more advanced usage techniques, like Just-In-Time creation and preloading dependencies, see the [Advanced Usage Guide](documentation/en/advanced-usage.md). You can also review the [Constant](documentation/en/usage-constant.md) and [ObservedDependency](documentation/en/usage-observeddependency.md) guides for additional features.
