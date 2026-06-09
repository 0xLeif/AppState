import Foundation

// MARK: - MetricsService

/// An async service that fetches a fresh `Metrics` snapshot.
///
/// Abstracting the data-fetching contract behind a protocol makes it trivial
/// to swap in a deterministic mock during testing without changing any
/// call-site code.
public protocol MetricsService: Sendable {

    /// Fetches and returns the current dashboard metrics.
    ///
    /// - Throws: `MetricsServiceError` if the fetch cannot complete.
    /// - Returns: A `Metrics` snapshot representing the current state.
    func fetchMetrics() async throws -> Metrics
}

// MARK: - LiveMetricsService

/// The production implementation of `MetricsService`.
///
/// Simulates a network call with a short artificial delay so the loading
/// path is exercised in previews and real builds without needing a server.
public struct LiveMetricsService: MetricsService {

    // MARK: - Initializers

    public init() {}

    // MARK: - MetricsService

    public func fetchMetrics() async throws -> Metrics {
        // Simulate a short network round-trip.
        try await Task.sleep(for: .milliseconds(200))

        return Metrics(
            activeUsers: 1_248,
            revenueToday: 47_392.50,
            averageResponseTime: 134.7,
            systemHealth: 0.97,
            capturedAt: Date()
        )
    }
}
