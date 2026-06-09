import Foundation

// MARK: - Metrics

/// A snapshot of the dashboard metrics at a single point in time.
///
/// Keeping this as a value type ensures copies are cheap and independent,
/// which is critical when broadcasting state changes across the app.
public struct Metrics: Sendable, Equatable {

    // MARK: - Properties

    /// Total number of active users at the time this snapshot was taken.
    public var activeUsers: Int

    /// Cumulative revenue (in USD) recorded so far today.
    public var revenueToday: Double

    /// Average response time in milliseconds for the last 100 requests.
    public var averageResponseTime: Double

    /// Overall system health as a value from 0.0 (down) to 1.0 (perfect).
    public var systemHealth: Double

    /// The instant at which this snapshot was captured.
    public var capturedAt: Date

    // MARK: - Initializers

    /// Creates a `Metrics` value with all fields explicitly specified.
    ///
    /// - Parameters:
    ///   - activeUsers: Number of active users. Defaults to `0`.
    ///   - revenueToday: Today's revenue in USD. Defaults to `0`.
    ///   - averageResponseTime: Mean response time in ms. Defaults to `0`.
    ///   - systemHealth: Health ratio in [0, 1]. Defaults to `1`.
    ///   - capturedAt: Snapshot timestamp. Defaults to `Date()`.
    public init(
        activeUsers: Int = 0,
        revenueToday: Double = 0,
        averageResponseTime: Double = 0,
        systemHealth: Double = 1,
        capturedAt: Date = Date()
    ) {
        self.activeUsers = activeUsers
        self.revenueToday = revenueToday
        self.averageResponseTime = averageResponseTime
        self.systemHealth = systemHealth
        self.capturedAt = capturedAt
    }

    // MARK: - Static Helpers

    /// A zero-value placeholder useful as an initial state before data loads.
    public static let empty = Metrics()
}
