# 安装指南

本指南将引导您完成使用 Swift Package Manager 将 **AppState** 安装到您的 Swift 项目中的过程。

## Swift Package Manager

**AppState** 可以使用 Swift Package Manager 轻松集成到您的项目中。请按照以下步骤添加 **AppState** 作为依赖项。

### 步骤 1：更新您的 `Package.swift` 文件

将 **AppState** 添加到您的 `Package.swift` 文件的 `dependencies` 部分：

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/AppState.git", from: "2.2.0")
]
```

### 步骤 2：将 AppState 添加到您的目标

在您的目标依赖项中包含 AppState：

```swift
.target(
    name: "YourTarget",
    dependencies: ["AppState"]
)
```

### 步骤 3：构建您的项目

将 AppState 添加到您的 `Package.swift` 文件后，构建您的项目以获取依赖项并将其集成到您的代码库中。

```
swift build
```

### 步骤 4：在您的代码中导入 AppState

现在，您可以通过在 Swift 文件的顶部导入 AppState 来开始在您的项目中使用它：

```swift
import AppState
```

## Xcode

如果您希望直接通过 Xcode 添加 **AppState**，请按照以下步骤操作：

### 步骤 1：打开您的 Xcode 项目

打开您的 Xcode 项目或工作区。

### 步骤 2：添加 Swift 包依赖项

1. 导航到项目导航器并选择您的项目文件。
2. 在项目编辑器中，选择您的目标，然后转到“Swift Packages”选项卡。
3. 单击“+”按钮以添加包依赖项。

### 步骤 3：输入仓库 URL

在“选择包仓库”对话框中，输入以下 URL：`https://github.com/0xLeif/AppState.git`

然后单击“下一步”。

### 步骤 4：指定版本

选择您要使用的版本。建议选择“直到下一个主要版本”选项，并将 `2.0.0` 指定为下限。然后单击“下一步”。

### 步骤 5：添加包

Xcode 将获取该包并为您提供将 **AppState** 添加到您的目标的选项。请确保选择正确的目标，然后单击“完成”。

### 步骤 6：在您的代码中导入 `AppState`

现在，您可以在 Swift 文件的顶部导入 **AppState**：

```swift
import AppState
```

## 后续步骤

安装 AppState 后，您可以转到[用法概述](usage-overview.md)以了解如何在您的项目中实现关键功能。

---
这是使用 [Jules](https://jules.google) 生成的，可能会出现错误。如果您是母语人士，请提出包含任何应有修复的拉取请求。
