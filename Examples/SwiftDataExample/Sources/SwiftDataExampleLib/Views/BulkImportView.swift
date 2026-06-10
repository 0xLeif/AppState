import AppState
import Foundation

#if canImport(SwiftData) && canImport(SwiftUI)
import SwiftData
import SwiftUI

// MARK: - BulkImportView

/// A SwiftUI view that demonstrates fully non-blocking bulk SwiftData inserts via `BulkImporter`.
///
/// All heavy insert/save work runs inside the `@ModelActor` `BulkImporter` on a background
/// executor. The view's main-actor state is updated only with tiny progress values — the UI
/// stays scrollable, animatable, and cancellable at all times.
///
/// ### Integration
/// Present this view directly from any host app — no additional setup is needed beyond the
/// standard `labContainer` dependency provided by `Application+Lab.swift`.
///
/// ```swift
/// BulkImportView()
/// ```
public struct BulkImportView: View {

    // MARK: - Properties

    /// Running count of items inserted by the background actor.
    @State private var progressCount: Int = 0

    /// Whether an import is currently in flight.
    @State private var isRunning: Bool = false

    /// Whether the last import was cancelled by the user.
    @State private var wasCancelled: Bool = false

    /// The total items visible in the main-context after the import completes.
    @State private var finalCount: Int = 0

    /// The `Task` wrapping the import — retained so the Cancel button can cancel it.
    @State private var importTask: Task<Void, Never>?

    /// Total items to generate per import run.
    private let targetCount: Int

    // MARK: - Initialiser

    /// Creates a `BulkImportView`.
    ///
    /// - Parameter targetCount: Number of `TodoItem`s to generate per import. Defaults to `10_000`.
    public init(targetCount: Int = 10_000) {
        self.targetCount = targetCount
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                statusHeader
                progressSection
                controlButtons
                finalCountSection
                Spacer()
                interactivityDemoSection
            }
            .padding()
            .navigationTitle("Bulk Import")
        }
    }

    // MARK: - Sub-views

    private var statusHeader: some View {
        VStack(spacing: 6) {
            Text(statusText)
                .font(.headline)
                .foregroundStyle(statusColor)
                .animation(.easeInOut, value: isRunning)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: progressFraction)
                .progressViewStyle(.linear)
                .animation(.linear(duration: 0.1), value: progressCount)

            HStack {
                Text("\(progressCount) / \(targetCount) inserted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                Text(percentageText)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var controlButtons: some View {
        HStack(spacing: 16) {
            generateButton
            cancelButton
        }
    }

    private var generateButton: some View {
        Button {
            startImport()
        } label: {
            Label("Generate \(formattedCount(targetCount))", systemImage: "bolt.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isRunning)
    }

    private var cancelButton: some View {
        Button(role: .destructive) {
            cancelImport()
        } label: {
            Label("Cancel", systemImage: "xmark.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(!isRunning)
    }

    @ViewBuilder
    private var finalCountSection: some View {
        if !isRunning && finalCount > 0 {
            VStack(spacing: 6) {
                Divider()
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Main context now holds \(finalCount) item(s)")
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }

    /// A scrollable, animated list proving the main thread is never blocked.
    private var interactivityDemoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UI Responsiveness Demo")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0 ..< 20, id: \.self) { index in
                        ResponsivenessChip(index: index, isRunning: isRunning)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Computed Helpers

    private var progressFraction: Double {
        guard targetCount > 0 else { return 0 }
        return Double(progressCount) / Double(targetCount)
    }

    private var percentageText: String {
        let pct = Int(progressFraction * 100)
        return "\(pct)%"
    }

    private var statusText: String {
        if isRunning { return "Importing in background…" }
        if wasCancelled { return "Import cancelled" }
        if progressCount == targetCount { return "Import complete" }
        return "Ready"
    }

    private var statusColor: Color {
        if isRunning { return .orange }
        if wasCancelled { return .red }
        if progressCount == targetCount { return .green }
        return .secondary
    }

    // MARK: - Actions

    /// Launches the background import inside a detached `Task`, keeping the main actor free.
    ///
    /// The `BulkImporter` is created with the shared `labContainer` so its background context
    /// and the main-actor `mainContext` share the same persistent store. All inserts committed
    /// by the actor are immediately visible through `Application.modelState(\.allItems).models`
    /// once the task completes.
    private func startImport() {
        guard !isRunning else { return }

        progressCount = 0
        finalCount = 0
        wasCancelled = false
        isRunning = true

        let container = Application.dependency(\.labContainer)
        let count = targetCount

        importTask = Task {
            let importer = BulkImporter(modelContainer: container)

            await importer.importItems(count: count) { [count] inserted in
                let clamped = min(inserted, count)
                await MainActor.run {
                    progressCount = clamped
                }
            }

            // The actor's task has finished (completed or cancelled).
            // Hop back to the main actor to read the final persisted count.
            await MainActor.run {
                isRunning = false
                finalCount = Application.modelState(\.allItems).models.count
            }
        }
    }

    private func cancelImport() {
        importTask?.cancel()
        importTask = nil
        wasCancelled = true
        isRunning = false
    }

    // MARK: - Private Helpers

    private func formattedCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
}

// MARK: - ResponsivenessChip

/// A small animated chip used to prove the main thread is free during bulk import.
///
/// Each chip pulses independently, demonstrating that animations continue without stutter
/// even while the background actor is committing thousands of SwiftData inserts.
private struct ResponsivenessChip: View {

    // MARK: Properties

    let index: Int
    let isRunning: Bool

    @State private var animating: Bool = false

    // MARK: Body

    var body: some View {
        Text("Live \(index + 1)")
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(chipColor.opacity(animating ? 0.9 : 0.3), in: Capsule())
            .foregroundStyle(animating ? .white : chipColor)
            .scaleEffect(animating ? 1.06 : 1.0)
            .animation(
                isRunning
                    ? .easeInOut(duration: 0.5).repeatForever().delay(Double(index) * 0.08)
                    : .default,
                value: animating
            )
            .onChange(of: isRunning) { _, running in
                animating = running
            }
    }

    private var chipColor: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .teal, .green, .indigo]
        return colors[index % colors.count]
    }
}

#endif
