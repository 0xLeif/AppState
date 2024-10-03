# AppState

[![macOS](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/macOS.yml?branch=main)](https://github.com/0xLeif/AppState/actions)
[![Ubuntu](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/Ubuntu.yml?branch=main)](https://github.com/0xLeif/AppState/actions)
[![License](https://img.shields.io/github/license/0xLeif/AppState)](https://github.com/0xLeif/AppState/blob/main/LICENSE)
[![Version](https://img.shields.io/github/v/release/0xLeif/AppState)](https://github.com/0xLeif/AppState/releases)

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

## Getting Started

To integrate **AppState** into your Swift project, you’ll need to use the Swift Package Manager. Follow the [Installation Guide](documentation/installation.md) for detailed instructions on setting up **AppState**.

After installation, refer to the [Usage Overview](documentation/usage-overview.md) for a quick introduction on how to manage state and inject dependencies into your project.

## Documentation

Here’s a detailed breakdown of **AppState**'s documentation:

- [Installation Guide](documentation/installation.md): How to add **AppState** to your project using Swift Package Manager.
- [Usage Overview](documentation/usage-overview.md): An overview of key features with example implementations.
  
### Detailed Usage Guides:

- [State and Dependency Management](documentation/usage-state-dependency.md): Centralize state and inject dependencies throughout your app.
- [Slicing State](documentation/usage-slice.md): Access and modify specific parts of the state.
- [StoredState Usage Guide](documentation/usage-storedstate.md): How to persist lightweight data using `StoredState`.
- [FileState Usage Guide](documentation/usage-filestate.md): Learn how to persist larger amounts of data securely on disk.
- [Keychain SecureState Usage](documentation/usage-securestate.md): Store sensitive data securely using the Keychain.
- [iCloud Syncing with SyncState](documentation/usage-syncstate.md): Keep state synchronized across devices using iCloud.

## Contributing

We welcome contributions! Please check out our [Contributing Guide](documentation/contributing.md) for how to get involved.

## Next Steps

With **AppState** installed, you can start exploring its key features by checking out the [Usage Overview](documentation/usage-overview.md) and more detailed guides. Get started with managing state and dependencies effectively in your Swift projects! For more advanced usage techniques, like Just-In-Time creation and preloading dependencies, see the [Advanced Usage Guide](documentation/advanced-usage.md).
