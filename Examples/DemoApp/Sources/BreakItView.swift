import AppState
import SwiftUI

// MARK: - Break-It stress state

extension Application {
    /// A counter hammered by the stress harness.
    fileprivate var stressCounter: State<Int> {
        state(initial: 0, feature: "BreakIt", id: "stressCounter")
    }

    /// A `UserDefaults`-backed array grown to large sizes by the stress harness.
    fileprivate var stressLog: StoredState<[Int]> {
        storedState(initial: [], id: "breakIt.stressLog")
    }
}

// MARK: - BreakItView

/// An interactive "try to crash it" screen that stays responsive under abuse.
///
/// Every workload runs inside a `Task` and cooperatively yields (or runs entirely off the main
/// actor), so the heavy loops never block the run loop — the spinner keeps animating and the list
/// stays scrollable while AppState is hammered.
@available(iOS 18.0, *)
struct BreakItView: View {

    // MARK: - State

    @AppState(\.stressCounter) private var counter: Int
    @StoredState(\.stressLog) private var log: [Int]

    @State private var lastResult: String = "Tap a workload — heavy work runs without freezing the UI."
    @State private var isRunning: Bool = false
    @State private var progress: Double = 0

    // MARK: - Body

    var body: some View {
        List {
            Section {
                Text(lastResult)
                    .font(.callout.monospaced())
                if isRunning {
                    ProgressView(value: progress)
                    Text("Working off the main loop — try scrolling, it stays smooth.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("counter", value: counter.formatted())
                LabeledContent("stored array", value: "\(log.count.formatted()) items")
            } header: {
                Text("Status")
            }

            Section {
                workloadButton("Hammer @AppState ×200k") { await hammerAppState() }
                workloadButton("Grow @StoredState to 50k") { await growStoredState() }
                workloadButton("Rapid reset churn ×10k") { await resetChurn() }
                workloadButton("Concurrent off-main reads ×50k") { await concurrentReads() }
            } header: {
                Text("Non-blocking workloads")
            } footer: {
                Text("Each runs in a Task that yields (or runs off-main), so the UI never freezes. SwiftData bulk work has its own background-actor screen under SwiftData.")
            }

            Section {
                Button("Reset everything", role: .destructive) {
                    Application.reset(\.stressCounter)
                    log = []
                    lastResult = "Reset."
                }
                .disabled(isRunning)
            }
        }
        .navigationTitle("Break It")
    }

    // MARK: - Workload runner

    private func workloadButton(_ title: String, _ work: @escaping () async -> Void) -> some View {
        Button(title) {
            Task {
                isRunning = true
                progress = 0
                let clock = ContinuousClock()
                let start = clock.now
                await work()
                let elapsed = clock.now - start
                progress = 1
                isRunning = false
                lastResult = "✓ \(title)\n   (\(elapsed.formatted(.units(allowed: [.seconds, .milliseconds], width: .abbreviated))))"
            }
        }
        .disabled(isRunning)
    }

    // MARK: - Workloads

    /// Main-actor writes, but yields periodically so the run loop keeps drawing.
    private func hammerAppState() async {
        let total = 200_000
        for index in 0..<total {
            counter &+= 1
            if index % 4_000 == 0 {
                progress = Double(index) / Double(total)
                await Task.yield()
            }
        }
    }

    /// A single large persisted write — fast, but routed through StoredState/UserDefaults.
    private func growStoredState() async {
        log = Array(0..<50_000)
        progress = 1
    }

    /// Rapid reset churn, yielding so the UI stays live.
    private func resetChurn() async {
        let total = 10_000
        for index in 0..<total {
            Application.reset(\.stressCounter)
            if index % 500 == 0 {
                progress = Double(index) / Double(total)
                await Task.yield()
            }
        }
    }

    /// Concurrent dependency reads driven entirely off the main actor.
    private func concurrentReads() async {
        await Task.detached(priority: .userInitiated) {
            DispatchQueue.concurrentPerform(iterations: 50_000) { _ in
                _ = Application.dependency(\.logger)
            }
        }.value
        progress = 1
    }
}
