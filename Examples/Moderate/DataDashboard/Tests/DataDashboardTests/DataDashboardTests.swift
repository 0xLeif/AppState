import AppState
import XCTest

@testable import DataDashboard

// MARK: - Mock Services

/// A deterministic mock that returns a fixed `Metrics` snapshot immediately.
private struct MockMetricsService: MetricsService {
    let stubbedMetrics: Metrics

    init(stubbedMetrics: Metrics = Metrics(
        activeUsers: 42,
        revenueToday: 1_000.00,
        averageResponseTime: 50.0,
        systemHealth: 0.99,
        capturedAt: Date(timeIntervalSince1970: 0)
    )) {
        self.stubbedMetrics = stubbedMetrics
    }

    func fetchMetrics() async throws -> Metrics {
        stubbedMetrics
    }
}

/// A mock that always throws a `MetricsServiceError.noData` error.
private struct FailingMetricsService: MetricsService {
    func fetchMetrics() async throws -> Metrics {
        throw MetricsServiceError.noData
    }
}

/// A mock that always throws a `MetricsServiceError.networkFailure` error.
private struct NetworkFailingMetricsService: MetricsService {
    func fetchMetrics() async throws -> Metrics {
        throw MetricsServiceError.networkFailure(underlying: "timeout")
    }
}

// MARK: - DataDashboardTests

@MainActor
final class DataDashboardTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        Application.logging(isEnabled: false)
        resetDashboardState()
    }

    override func tearDown() async throws {
        resetDashboardState()
    }

    // MARK: - Helpers

    private func resetDashboardState() {
        var metricsState = Application.state(\.currentMetrics)
        metricsState.value = .empty

        var loadingState = Application.state(\.isLoadingMetrics)
        loadingState.value = false

        var errorState = Application.state(\.metricsLoadError)
        errorState.value = nil
    }

    // MARK: - Success Path Tests

    /// Verifies that a successful fetch populates `currentMetrics` with the service's response.
    func testLoadMetrics_succeeds_updatesCurrentMetrics() async {
        let expectedMetrics = Metrics(
            activeUsers: 42,
            revenueToday: 1_000.00,
            averageResponseTime: 50.0,
            systemHealth: 0.99,
            capturedAt: Date(timeIntervalSince1970: 0)
        )

        let override = Application.override(
            \.metricsService,
            with: MockMetricsService(stubbedMetrics: expectedMetrics)
        )

        let loader = MetricsLoader()
        await loader.loadMetrics()

        let stored = Application.state(\.currentMetrics).value
        XCTAssertEqual(stored.activeUsers, expectedMetrics.activeUsers)
        XCTAssertEqual(stored.revenueToday, expectedMetrics.revenueToday, accuracy: 0.001)
        XCTAssertEqual(stored.averageResponseTime, expectedMetrics.averageResponseTime, accuracy: 0.001)
        XCTAssertEqual(stored.systemHealth, expectedMetrics.systemHealth, accuracy: 0.001)

        await override.cancel()
    }

    /// Verifies that `isLoadingMetrics` is `false` and no error is set after a successful fetch.
    func testLoadMetrics_succeeds_clearsLoadingAndError() async {
        let override = Application.override(
            \.metricsService,
            with: MockMetricsService()
        )

        let loader = MetricsLoader()
        await loader.loadMetrics()

        XCTAssertFalse(Application.state(\.isLoadingMetrics).value)
        XCTAssertNil(Application.state(\.metricsLoadError).value)

        await override.cancel()
    }

    // MARK: - Error Path Tests

    /// Verifies that a `.noData` service error populates `metricsLoadError` with a description.
    func testLoadMetrics_noDataError_setsLoadError() async {
        let override = Application.override(
            \.metricsService,
            with: FailingMetricsService()
        )

        let loader = MetricsLoader()
        await loader.loadMetrics()

        let errorMessage = Application.state(\.metricsLoadError).value
        XCTAssertNotNil(errorMessage)

        let expectedDescription = MetricsServiceError.noData.localizedDescription
        XCTAssertEqual(errorMessage, expectedDescription)

        await override.cancel()
    }

    /// Verifies that a `.networkFailure` error surfaces the underlying cause in the error state.
    func testLoadMetrics_networkFailure_setsLoadErrorWithCause() async {
        let override = Application.override(
            \.metricsService,
            with: NetworkFailingMetricsService()
        )

        let loader = MetricsLoader()
        await loader.loadMetrics()

        let errorMessage = Application.state(\.metricsLoadError).value
        XCTAssertNotNil(errorMessage)

        let expectedDescription = MetricsServiceError.networkFailure(underlying: "timeout").localizedDescription
        XCTAssertEqual(errorMessage, expectedDescription)

        await override.cancel()
    }

    /// Verifies that `isLoadingMetrics` returns to `false` even after a service failure.
    func testLoadMetrics_onFailure_clearsLoadingFlag() async {
        let override = Application.override(
            \.metricsService,
            with: FailingMetricsService()
        )

        let loader = MetricsLoader()
        await loader.loadMetrics()

        XCTAssertFalse(Application.state(\.isLoadingMetrics).value)

        await override.cancel()
    }

    // MARK: - Override Restoration Test

    /// Verifies that cancelling a dependency override restores the original live service.
    func testOverride_whenCancelled_restoresOriginalService() async {
        let override = Application.override(
            \.metricsService,
            with: MockMetricsService()
        )

        let mockedService = Application.dependency(\.metricsService)
        XCTAssert(mockedService is MockMetricsService, "Expected MockMetricsService while override is active")

        await override.cancel()

        let restoredService = Application.dependency(\.metricsService)
        XCTAssert(
            restoredService is LiveMetricsService,
            "Expected LiveMetricsService after cancel but got \(type(of: restoredService))"
        )
    }

    // MARK: - Metrics Model Tests

    /// Verifies `Metrics.empty` has the documented zero-value defaults.
    func testMetrics_empty_hasZeroDefaults() {
        let empty = Metrics.empty

        XCTAssertEqual(empty.activeUsers, 0)
        XCTAssertEqual(empty.revenueToday, 0)
        XCTAssertEqual(empty.averageResponseTime, 0)
        XCTAssertEqual(empty.systemHealth, 1.0, accuracy: 0.001)
    }

    /// Verifies `MetricsServiceError` descriptions contain meaningful text.
    func testMetricsServiceError_localizedDescriptions_areNonEmpty() {
        let noData = MetricsServiceError.noData
        let network = MetricsServiceError.networkFailure(underlying: "DNS error")

        XCTAssertFalse(noData.localizedDescription.isEmpty)
        XCTAssertFalse(network.localizedDescription.isEmpty)
        XCTAssertTrue(network.localizedDescription.contains("DNS error"))
    }
}
