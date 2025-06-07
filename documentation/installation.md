# Installation Guide

This guide will walk you through the process of installing **AppState** into your Swift project using Swift Package Manager.

## Swift Package Manager

**AppState** can be easily integrated into your project using Swift Package Manager. Follow the steps below to add **AppState** as a dependency.

### Step 1: Update Your `Package.swift` File

Add **AppState** to the `dependencies` section of your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/AppState.git", from: "2.1.3")
]
```

### Step 2: Add AppState to Your Target

Include AppState in your target’s dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["AppState"]
)
```

### Step 3: Build Your Project

Once you’ve added AppState to your `Package.swift` file, build your project to fetch the dependency and integrate it into your codebase.

```
swift build
```

### Step 4: Import AppState in Your Code

Now, you can start using AppState in your project by importing it at the top of your Swift files:

```swift
import AppState
```

## Xcode

If you prefer to add **AppState** directly through Xcode, follow these steps:

### Step 1: Open Your Xcode Project

Open your Xcode project or workspace.

### Step 2: Add a Swift Package Dependency

1. Navigate to the project navigator and select your project file.
2. In the project editor, select your target, and then go to the "Swift Packages" tab.
3. Click the "+" button to add a package dependency.

### Step 3: Enter the Repository URL

In the "Choose Package Repository" dialog, enter the following URL: `https://github.com/0xLeif/AppState.git`

Then click "Next."

### Step 4: Specify the Version

Choose the version you wish to use. It's recommended to select the "Up to Next Major Version" option and specify `2.1.3` as the lower bound. Then click "Next."

### Step 5: Add the Package

Xcode will fetch the package and present you with options to add **AppState** to your target. Make sure to select the correct target and click "Finish."

### Step 6: Import `AppState` in Your Code

You can now import **AppState** at the top of your Swift files:

```swift
import AppState
```

## Next Steps

With AppState installed, you can move on to the [Usage Overview](usage-overview.md) to see how to implement the key features in your project.
