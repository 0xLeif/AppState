import AppState
import XCTest

@testable import DataDashboard

// MARK: - Mock Services

/// A deterministic mock that returns a fixed `Metrics` snapshot immediately.
struct MockMetricsService: MetricsService {

    // MARK: - Properties

    let stubbedMetrics: Metrics

    // MARK: - Initializers

    init(stubbedMetrics: Metrics = Metrics(
        activeUsers: 42,
        revenueToday: 1_000.00,
        averageResponseTime: 50.0,
        systemHealth: 0.99,
        capturedAt: Date(timeIntervalSince1970: 0)
    )) {
        self.stubbedMetrics = stubbedMetrics
    }

    // MARK: - MetricsService

    func fetchMetrics() async throws -> Metrics {
        stubbedMetrics
    }
}

/// A mock that always throws a `MetricsServiceError.noData` error.
struct FailingMetricsService: MetricsService {

    // MARK: - MetricsService

    func fetchMetrics() async throws -> Metrics {
        throw MetricsServiceError.noData
    }
}

/// A mock that always throws a `MetricsServiceError.networkFailure` error.
struct NetworkFailingMetricsService: MetricsService {

    // MARK: - MetricsService

    func fetchMetrics() async throws -> Metrics {
        throw MetricsServiceError.networkFailure(underlying: "timeout")
    }
}

/// A mock that always throws a plain (non-`MetricsServiceError`) error,
/// exercising the generic `catch` branch in `MetricsLoader.loadMetrics()`.
struct GenericFailingMetricsService: MetricsService {

    // MARK: - MetricsService

    func fetchMetrics() async throws -> Metrics {
        struct PlainError: Error, @unchecked Sendable {}
        throw PlainError()
    }
}

// MARK: - DataDashboardTests

/// Unit tests for the DataDashboard feature, exercising `MetricsLoader`,
/// `Metrics`, `MetricsServiceError`, and `LiveMetricsService` headlessly.
///
/// Each test uses `Application.override(\.metricsService, with:)` to inject a
/// deterministic mock so no real network I/O occurs.
@MainActor
final class DataDashboardTests: XCTestCase {

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        Application.logging(isEnabled: false)
        resetDashboardState()
    }

    override func tearDown() async throws {
        resetDashboardState()
        try await super.tearDown()
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

    // MARK: - Tests: Success Path

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

    // MARK: - Tests: Error Paths

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

    /// Verifies that a generic (non-`MetricsServiceError`) error also sets an error message,
    /// exercising the fallback `catch` branch in `MetricsLoader.loadMetrics()`.
    func testLoadMetrics_genericError_setsLoadError() async {
        let override = Application.override(
            \.metricsService,
            with: GenericFailingMetricsService()
        )

        let loader = MetricsLoader()
        await loader.loadMetrics()

        let errorMessage = Application.state(\.metricsLoadError).value
        XCTAssertNotNil(errorMessage)

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

    // MARK: - Tests: Override Restoration

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

    // MARK: - Tests: Metrics Model

    /// Verifies `Metrics.empty` has the documented zero-value defaults.
    func testMetrics_empty_hasZeroDefaults() {
        let empty = Metrics.empty

        XCTAssertEqual(empty.activeUsers, 0)
        XCTAssertEqual(empty.revenueToday, 0)
        XCTAssertEqual(empty.averageResponseTime, 0)
        XCTAssertEqual(empty.systemHealth, 1.0, accuracy: 0.001)
    }

    /// Verifies equality semantics for `Metrics`.
    func testMetrics_equatableSemantics() {
        let date = Date(timeIntervalSince1970: 0)
        let a = Metrics(activeUsers: 1, revenueToday: 2.0, averageResponseTime: 3.0, systemHealth: 0.5, capturedAt: date)
        let b = Metrics(activeUsers: 1, revenueToday: 2.0, averageResponseTime: 3.0, systemHealth: 0.5, capturedAt: date)
        let c = Metrics(activeUsers: 99, revenueToday: 2.0, averageResponseTime: 3.0, systemHealth: 0.5, capturedAt: date)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - Tests: MetricsServiceError

    /// Verifies `MetricsServiceError` descriptions contain meaningful text.
    func testMetricsServiceError_localizedDescriptions_areNonEmpty() {
        let noData = MetricsServiceError.noData
        let network = MetricsServiceError.networkFailure(underlying: "DNS error")

        XCTAssertFalse(noData.localizedDescription.isEmpty)
        XCTAssertFalse(network.localizedDescription.isEmpty)
        XCTAssertTrue(network.localizedDescription.contains("DNS error"))
    }

    /// Verifies `MetricsServiceError.noData` error description matches expected copy.
    func testMetricsServiceError_noData_errorDescription() {
        let error = MetricsServiceError.noData

        XCTAssertEqual(error.errorDescription, "The metrics service returned no data.")
    }

    /// Verifies `MetricsServiceError.networkFailure` error description embeds the cause.
    func testMetricsServiceError_networkFailure_errorDescriptionEmbedsCause() {
        let error = MetricsServiceError.networkFailure(underlying: "connection reset")

        XCTAssertEqual(error.errorDescription, "Network failure: connection reset")
    }

    // MARK: - Tests: LiveMetricsService

    /// Verifies that `LiveMetricsService.fetchMetrics()` returns a non-empty `Metrics` snapshot
    /// with positive active users and health within the valid range.
    func testLiveMetricsService_fetchMetrics_returnsValidSnapshot() async throws {
        let service = LiveMetricsService()
        let metrics = try await service.fetchMetrics()

        XCTAssertGreaterThan(metrics.activeUsers, 0)
        XCTAssertGreaterThan(metrics.revenueToday, 0)
        XCTAssertGreaterThan(metrics.averageResponseTime, 0)
        XCTAssertGreaterThan(metrics.systemHealth, 0)
        XCTAssertLessThanOrEqual(metrics.systemHealth, 1.0)
    }

    /// Verifies that `LiveMetricsService` can be instantiated with the public initialiser.
    func testLiveMetricsService_init() {
        let service = LiveMetricsService()

        XCTAssertNotNil(service)
    }
}
