import Foundation

// MARK: - Settings

/// The user-configurable settings for the application.
///
/// All fields have sensible defaults so a freshly installed app is immediately
/// usable without any migration logic.
public struct Settings: Codable, Sendable, Equatable {
    // MARK: - Properties

    /// Controls whether the UI renders in dark mode.
    public var isDarkMode: Bool

    /// The preferred body-text size (in points).
    public var fontSize: Double

    /// Whether the app may deliver push notifications.
    public var notificationsEnabled: Bool

    /// The display name chosen by the user.
    public var username: String

    // MARK: - Initializers

    /// Creates a `Settings` value with explicit field values.
    ///
    /// - Parameters:
    ///   - isDarkMode: Dark-mode preference. Defaults to `false`.
    ///   - fontSize: Body-text size in points. Defaults to `16`.
    ///   - notificationsEnabled: Push-notification opt-in. Defaults to `true`.
    ///   - username: Display name. Defaults to `"Guest"`.
    public init(
        isDarkMode: Bool = false,
        fontSize: Double = 16,
        notificationsEnabled: Bool = true,
        username: String = "Guest"
    ) {
        self.isDarkMode = isDarkMode
        self.fontSize = fontSize
        self.notificationsEnabled = notificationsEnabled
        self.username = username
    }

    /// The factory default settings used when no persisted value exists.
    public static let `default` = Settings()
}
