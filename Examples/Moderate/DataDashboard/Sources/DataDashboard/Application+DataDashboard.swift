import AppState
import Foundation

// MARK: - Application + DataDashboard Dependencies

extension Application {

    /// The injected service responsible for fetching dashboard metrics.
    ///
    /// Override this dependency in tests or SwiftUI previews with a
    /// `MockMetricsService` to exercise loading paths without real network I/O.
    public var metricsService: Dependency<any MetricsService> {
        dependency(LiveMetricsService() as any MetricsService, feature: "DataDashboard", id: "metricsService")
    }
}

// MARK: - Application + DataDashboard State

extension Application {

    /// The most recently loaded metrics snapshot.
    ///
    /// Starts as `Metrics.empty` so the dashboard renders immediately
    /// in a loading state rather than with nil-checks scattered through views.
    public var currentMetrics: State<Metrics> {
        state(initial: .empty, feature: "DataDashboard", id: "currentMetrics")
    }

    /// Whether a metrics fetch is currently in flight.
    public var isLoadingMetrics: State<Bool> {
        state(initial: false, feature: "DataDashboard", id: "isLoadingMetrics")
    }

    /// The most recent error from a failed metrics fetch, if any.
    public var metricsLoadError: State<String?> {
        state(initial: nil, feature: "DataDashboard", id: "metricsLoadError")
    }
}
