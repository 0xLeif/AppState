#if canImport(SwiftUI)
import AppState
import SwiftUI

// MARK: - DashboardView

/// The primary view for the metrics dashboard.
///
/// Reads all data from `@AppState` property wrappers so the view automatically
/// re-renders whenever the shared application state changes — no additional
/// observable objects or publishers needed.
public struct DashboardView: View {

    // MARK: - State

    @AppState(\.currentMetrics) private var metrics: Metrics
    @AppState(\.isLoadingMetrics) private var isLoading: Bool
    @AppState(\.metricsLoadError) private var loadError: String?

    // MARK: - Private

    private let loader = MetricsLoader()

    // MARK: - Initializers

    public init() {}

    // MARK: - View

    public var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else {
                    metricsContentView
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    refreshButton
                }
            }
            .task {
                await loader.loadMetrics()
            }
        }
    }

    // MARK: - Private Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
            Text("Loading metrics…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var metricsContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let errorMessage = loadError {
                    errorBanner(message: errorMessage)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 16
                ) {
                    MetricCard(
                        title: "Active Users",
                        value: metrics.activeUsers.formatted(),
                        icon: "person.3.fill",
                        tint: .blue
                    )

                    MetricCard(
                        title: "Revenue Today",
                        value: metrics.revenueToday.formatted(.currency(code: "USD")),
                        icon: "dollarsign.circle.fill",
                        tint: .green
                    )

                    MetricCard(
                        title: "Avg Response",
                        value: String(format: "%.1f ms", metrics.averageResponseTime),
                        icon: "bolt.fill",
                        tint: .orange
                    )

                    MetricCard(
                        title: "System Health",
                        value: metrics.systemHealth.formatted(.percent.precision(.fractionLength(0))),
                        icon: "heart.fill",
                        tint: healthTint
                    )
                }
                .padding(.horizontal)

                capturedAtFooter
            }
            .padding(.vertical)
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    private var capturedAtFooter: some View {
        Text("Last updated \(metrics.capturedAt.formatted(date: .omitted, time: .shortened))")
            .font(.caption)
            .foregroundStyle(.tertiary)
    }

    private var refreshButton: some View {
        Button {
            Task { await loader.loadMetrics() }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        .disabled(isLoading)
    }

    private var healthTint: Color {
        switch metrics.systemHealth {
        case 0.9...:  return .green
        case 0.7...:  return .yellow
        default:      return .red
        }
    }
}

// MARK: - MetricCard

/// A single-metric summary card displayed in the dashboard grid.
struct MetricCard: View {

    // MARK: - Properties

    let title: String
    let value: String
    let icon: String
    let tint: Color

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.title2)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Preview

#Preview("Live") {
    DashboardView()
}

#Preview("Mock") {
    Application.preview(
        Application.override(\.metricsService, with: PreviewMetricsService())
    ) {
        DashboardView()
    }
}

// MARK: - PreviewMetricsService

/// An instant-return metrics service for SwiftUI previews.
struct PreviewMetricsService: MetricsService {
    func fetchMetrics() async throws -> Metrics {
        Metrics(
            activeUsers: 999,
            revenueToday: 12_345.67,
            averageResponseTime: 42.0,
            systemHealth: 0.85,
            capturedAt: Date()
        )
    }
}
#endif
