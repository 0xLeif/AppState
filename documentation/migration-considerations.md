
# Migration Considerations

When updating your data model, particularly for persisted or synchronized data, you need to handle backward compatibility to avoid potential issues when older data is loaded. Here are a few important points to keep in mind:

## 1. Adding Non-Optional Fields
If you add new non-optional fields to your model, decoding old data (which won't contain those fields) may fail. To avoid this:
- Consider giving new fields default values.
- Make the new fields optional to ensure compatibility with older versions of your app.

### Example:
```swift
struct Settings: Codable {
    var text: String
    var isDarkMode: Bool
    var newField: String? // New field is optional
}
```

## 2. Data Format Changes
If you modify the structure of a model (e.g., changing a type from `Int` to `String`), the decoding process might fail when reading older data. Plan for a smooth migration by:
- Creating migration logic to convert old data formats to the new structure.
- Using `Decodable`'s custom initializer to handle old data and map it to your new model.

### Example:
```swift
struct Settings: Codable {
    var text: String
    var isDarkMode: Bool
    var version: Int

    // Custom decoding logic for older versions
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        self.isDarkMode = try container.decode(Bool.self, forKey: .isDarkMode)
        self.version = (try? container.decode(Int.self, forKey: .version)) ?? 1 // Default for older data
    }
}
```

## 3. Handling Deleted or Deprecated Fields
If you remove a field from the model, ensure that old versions of the app can still decode the new data without crashing. You can:
- Ignore extra fields when decoding.
- Use custom decoders to handle older data and manage deprecated fields properly.

## 4. Versioning Your Models

Versioning your models allows you to handle changes in your data structure over time. By keeping a version number as part of your model, you can easily implement migration logic to convert older data formats to newer ones. This approach ensures that your app can handle older data structures while smoothly transitioning to new versions.

- **Why Versioning is Important**: When users update their app, they may still have older data persisted on their devices. Versioning helps your app recognize the data's format and apply the correct migration logic.
- **How to Use**: Add a `version` field to your model and check it during the decoding process to determine if migration is needed.

### Example:
```swift
struct Settings: Codable {
    var version: Int
    var text: String
    var isDarkMode: Bool

    // Handle version-specific decoding logic
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(Int.self, forKey: .version)
        self.text = try container.decode(String.self, forKey: .text)
        self.isDarkMode = try container.decode(Bool.self, forKey: .isDarkMode)

        // If migrating from an older version, apply necessary transformations here
        if version < 2 {
            // Migrate older data to newer format
        }
    }
}
```

- **Best Practice**: Start with a `version` field from the beginning. Each time you update your model structure, increment the version and handle the necessary migration logic.

## 5. Testing Migration
Always test your migration thoroughly by simulating loading old data with new versions of your model to ensure your app behaves as expected.
