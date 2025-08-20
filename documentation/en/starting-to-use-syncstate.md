To utilize SyncState, you will first need to set up iCloud capabilities and entitlements in your Xcode project. Here's an introduction to guide you through the process:

### Setting Up iCloud Capabilities:

1. Open your Xcode project and adjust the Bundle Identifiers for both macOS and iOS targets to match your own.
2. Next, you need to add the iCloud capability to your project. To do this, select your project in the Project Navigator, then select your target. In the tab bar at the top of the editor area, click on "Capabilities".
3. In the Capabilities pane, turn on iCloud by clicking the switch in the iCloud row. You should see the switch move to the On position.
4. Once you have enabled iCloud, you need to enable Key-Value storage. You can do this by checking the "Key-Value storage" checkbox.

### Updating the Entitlements:

1. You will now need to update your entitlements file. Open the entitlements file for your target.
2. Make sure the iCloud Key-Value Store value matches your unique key-value store ID. Your unique ID should follow the format `$(TeamIdentifierPrefix)<your key-value_store ID>`. The default value should be something like, `$(TeamIdentifierPrefix)$(CFBundleIdentifier)`. This is fine for single platform apps, but if your app is on multiple Apple OSs, it’s important that the key-value store ID portions are the same for both targets.

### Configuring the Devices:

In addition to configuring the project itself, you also need to prepare the devices that will run the project.

- Ensure that iCloud Drive is enabled on both iOS and macOS devices.
- Log into both devices using the same iCloud account.

If you have any questions or run into any issues, feel free to reach out or submit an issue.
