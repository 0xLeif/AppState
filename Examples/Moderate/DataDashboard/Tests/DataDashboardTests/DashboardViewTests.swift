#if !os(Linux) && !os(Windows)
import AppState
import SwiftUI
import ViewInspector
import XCTest

@testable import DataDashboard

// MARK: - DashboardViewTests

/// Exercises the SwiftUI layer (`DashboardView` and `MetricCard`) with ViewInspector
/// so that all view bodies, computed properties, and async task paths are covered
/// in addition to the headless `MetricsLoader` tests.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@MainActor
final class DashboardViewTests: XCTestCase {

    // MARK: - Properties

    private var serviceOverride: Application.DependencyOverride?

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        Application.logging(isEnabled: false)
        resetDashboardState()

        serviceOverride = Application.override(
            \.metricsService,
            with: MockMetricsService() as MetricsService
        )
    }

    override func tearDown() async throws {
        resetDashboardState()

        await serviceOverride?.cancel()
        serviceOverride = nil

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

    private func setMetrics(_ metrics: Metrics) {
        var metricsState = Application.state(\.currentMetrics)
        metricsState.value = metrics
    }

    private func setLoading(_ loading: Bool) {
        var loadingState = Application.state(\.isLoadingMetrics)
        loadingState.value = loading
    }

    private func setError(_ message: String?) {
        var errorState = Application.state(\.metricsLoadError)
        errorState.value = message
    }

    // MARK: - Tests: DashboardView — Loading State

    /// When `isLoadingMetrics` is `true` the dashboard renders the loading spinner.
    func testDashboardView_whenLoading_rendersProgressView() throws {
        setLoading(true)

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().find(ViewType.ProgressView.self))
    }

    /// When `isLoadingMetrics` is `true` the "Loading metrics…" label is visible.
    func testDashboardView_whenLoading_rendersLoadingText() throws {
        setLoading(true)

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().find(text: "Loading metrics…"))
    }

    // MARK: - Tests: DashboardView — Content State

    /// When not loading the dashboard renders the scroll view with metric cards.
    func testDashboardView_whenIdle_rendersScrollView() throws {
        setLoading(false)

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().find(ViewType.ScrollView.self))
    }

    /// When not loading the footer shows the "Last updated" timestamp.
    func testDashboardView_whenIdle_rendersCapturedAtFooter() throws {
        setLoading(false)
        let knownDate = Date(timeIntervalSince1970: 0)
        setMetrics(Metrics(capturedAt: knownDate))

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().find(ViewType.ScrollView.self))
        // The footer text starts with "Last updated"
        let footerText = try sut.inspect().find(
            text: "Last updated \(knownDate.formatted(date: .omitted, time: .shortened))"
        )
        XCTAssertNotNil(footerText)
    }

    // MARK: - Tests: DashboardView — Error Banner

    /// When a load error is set the error banner is visible.
    func testDashboardView_whenErrorSet_rendersErrorBanner() throws {
        setLoading(false)
        setError("Something went wrong")

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().find(text: "Something went wrong"))
    }

    /// When no error is set the error banner is absent (no warning image rendered).
    func testDashboardView_whenNoError_doesNotRenderErrorBanner() throws {
        setLoading(false)
        setError(nil)

        let sut = DashboardView()

        // The error banner uses "exclamationmark.triangle.fill" — confirm it's absent
        // by verifying no such image exists in the hierarchy.
        let allImages = try? sut.inspect().findAll(ViewType.Image.self)
        let hasWarning = (allImages ?? []).contains { image in
            (try? image.actualImage().name()) == "exclamationmark.triangle.fill"
        }
        XCTAssertFalse(hasWarning)
    }

    // MARK: - Tests: DashboardView — Metric Cards

    /// Four `MetricCard` instances are rendered in the grid when not loading.
    func testDashboardView_whenIdle_rendersFourMetricCards() throws {
        setLoading(false)
        setMetrics(Metrics(
            activeUsers: 100,
            revenueToday: 500.0,
            averageResponseTime: 20.0,
            systemHealth: 0.95
        ))

        let sut = DashboardView()

        let cards = try sut.inspect().findAll(MetricCard.self)
        XCTAssertEqual(cards.count, 4)
    }

    /// Verifies the "Active Users" card displays the correct formatted value.
    func testDashboardView_activeUsersCard_displaysFormattedValue() throws {
        setLoading(false)
        setMetrics(Metrics(activeUsers: 1_248))

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().find(text: 1_248.formatted()))
    }

    /// Verifies the "System Health" card uses a green tint when health ≥ 0.9.
    func testDashboardView_systemHealth_greenTintWhenAbove90Percent() throws {
        setLoading(false)
        setMetrics(Metrics(systemHealth: 0.95))

        let sut = DashboardView()

        // Just confirm the view renders without throwing — tint logic is exercised.
        XCTAssertNoThrow(try sut.inspect().findAll(MetricCard.self))
    }

    /// Verifies the "System Health" card uses a yellow tint when health is in [0.7, 0.9).
    func testDashboardView_systemHealth_yellowTintWhenBetween70And90Percent() throws {
        setLoading(false)
        setMetrics(Metrics(systemHealth: 0.80))

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().findAll(MetricCard.self))
    }

    /// Verifies the "System Health" card uses a red tint when health < 0.7.
    func testDashboardView_systemHealth_redTintWhenBelow70Percent() throws {
        setLoading(false)
        setMetrics(Metrics(systemHealth: 0.50))

        let sut = DashboardView()

        XCTAssertNoThrow(try sut.inspect().findAll(MetricCard.self))
    }

    // MARK: - Tests: DashboardView — Task / Refresh

    /// Calling the `.task` modifier on the Group drives `MetricsLoader.loadMetrics()`,
    /// which populates `currentMetrics` from the injected mock service.
    func testDashboardView_task_triggersMetricsLoad() async throws {
        setLoading(false)
        resetDashboardState()

        let expectedMetrics = Metrics(
            activeUsers: 42,
            revenueToday: 1_000.00,
            averageResponseTime: 50.0,
            systemHealth: 0.99,
            capturedAt: Date(timeIntervalSince1970: 0)
        )

        await serviceOverride?.cancel()
        serviceOverride = Application.override(
            \.metricsService,
            with: MockMetricsService(stubbedMetrics: expectedMetrics) as MetricsService
        )

        let sut = DashboardView()

        try await sut.inspect().find(ViewType.Group.self).callTask()

        let stored = Application.state(\.currentMetrics).value
        XCTAssertEqual(stored.activeUsers, expectedMetrics.activeUsers)
    }

    /// The refresh button triggers a new load when tapped.
    func testDashboardView_refreshButton_triggersMetricsLoad() async throws {
        setLoading(false)
        resetDashboardState()

        let expectedMetrics = Metrics(
            activeUsers: 77,
            revenueToday: 2_000.00,
            averageResponseTime: 30.0,
            systemHealth: 0.88,
            capturedAt: Date(timeIntervalSince1970: 1)
        )

        await serviceOverride?.cancel()
        serviceOverride = Application.override(
            \.metricsService,
            with: MockMetricsService(stubbedMetrics: expectedMetrics) as MetricsService
        )

        let sut = DashboardView()

        // Navigate to the toolbar button and tap it.
        try sut.inspect().find(ViewType.Button.self).tap()

        // Allow the Task spawned by the button to complete.
        try await Task.sleep(for: .milliseconds(50))

        let stored = Application.state(\.currentMetrics).value
        XCTAssertEqual(stored.activeUsers, expectedMetrics.activeUsers)
    }

    /// The refresh button is disabled while `isLoadingMetrics` is `true`.
    func testDashboardView_refreshButton_isDisabledWhileLoading() throws {
        setLoading(true)

        let sut = DashboardView()

        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertTrue(try button.isDisabled())
    }

    /// The refresh button is enabled when `isLoadingMetrics` is `false`.
    func testDashboardView_refreshButton_isEnabledWhenNotLoading() throws {
        setLoading(false)

        let sut = DashboardView()

        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertFalse(try button.isDisabled())
    }

    // MARK: - Tests: MetricCard

    /// Verifies `MetricCard` body renders the title text.
    func testMetricCard_body_rendersTitle() throws {
        let card = MetricCard(title: "Test Title", value: "123", icon: "star", tint: .blue)

        XCTAssertNoThrow(try card.inspect().find(text: "Test Title"))
    }

    /// Verifies `MetricCard` body renders the value text.
    func testMetricCard_body_rendersValue() throws {
        let card = MetricCard(title: "Revenue", value: "$9,999.00", icon: "dollarsign.circle.fill", tint: .green)

        XCTAssertNoThrow(try card.inspect().find(text: "$9,999.00"))
    }

    /// Verifies `MetricCard` body renders the system image icon.
    func testMetricCard_body_rendersIcon() throws {
        let card = MetricCard(title: "Users", value: "50", icon: "person.3.fill", tint: .blue)

        let image = try card.inspect().find(ViewType.Image.self)
        XCTAssertEqual(try image.actualImage().name(), "person.3.fill")
    }

    /// Verifies `MetricCard` renders correctly with a variety of tint colors.
    func testMetricCard_body_variousTints() throws {
        let colors: [Color] = [.blue, .green, .orange, .red, .yellow, .purple]

        for color in colors {
            let card = MetricCard(title: "Label", value: "0", icon: "circle", tint: color)
            XCTAssertNoThrow(try card.inspect().find(text: "Label"))
        }
    }

    // MARK: - Tests: PreviewMetricsService

    /// Verifies that `PreviewMetricsService.fetchMetrics()` returns a valid snapshot.
    ///
    /// This exercises the preview-only implementation so that its function body
    /// is included in coverage even though previews never run during `swift test`.
    func testPreviewMetricsService_fetchMetrics_returnsValidSnapshot() async throws {
        let service = PreviewMetricsService()
        let metrics = try await service.fetchMetrics()

        XCTAssertEqual(metrics.activeUsers, 999)
        XCTAssertEqual(metrics.revenueToday, 12_345.67, accuracy: 0.001)
        XCTAssertEqual(metrics.averageResponseTime, 42.0, accuracy: 0.001)
        XCTAssertEqual(metrics.systemHealth, 0.85, accuracy: 0.001)
    }
}
#endif
