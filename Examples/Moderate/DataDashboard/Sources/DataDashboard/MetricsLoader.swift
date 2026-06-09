import AppState
import Foundation

// MARK: - MetricsLoader

/// Coordinates metric fetches and writes results into `Application` state.
///
/// By injecting `MetricsService` through `@AppDependency` rather than creating
/// it directly, every call site automatically picks up test overrides registered
/// via `Application.override(\.metricsService, with:)`.
@MainActor
public final class MetricsLoader {

    // MARK: - Dependencies

    /// The service used to fetch metrics; resolved from the dependency graph.
    @AppDependency(\.metricsService) private var service: any MetricsService

    // MARK: - Initializers

    /// Creates a `MetricsLoader` backed by whatever `metricsService` dependency
    /// is currently registered in `Application`.
    public init() {}

    // MARK: - Public Methods

    /// Fetches fresh metrics and updates the relevant application state keys.
    ///
    /// Sets `isLoadingMetrics` to `true` for the duration of the fetch,
    /// then writes either the new `Metrics` value or a human-readable error
    /// message depending on the outcome.
    public func loadMetrics() async {
        var loadingState = Application.state(\.isLoadingMetrics)
        loadingState.value = true

        var errorState = Application.state(\.metricsLoadError)
        errorState.value = nil

        do {
            let metrics = try await service.fetchMetrics()
            var metricsState = Application.state(\.currentMetrics)
            metricsState.value = metrics
        } catch let error as MetricsServiceError {
            var errState = Application.state(\.metricsLoadError)
            errState.value = error.localizedDescription
        } catch {
            var errState = Application.state(\.metricsLoadError)
            errState.value = error.localizedDescription
        }

        var doneState = Application.state(\.isLoadingMetrics)
        doneState.value = false
    }
}
