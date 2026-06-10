import AppState
import SwiftUI

#if canImport(SwiftData)
import SwiftDataExampleLib
#endif

// MARK: - Break-It stress state

extension Application {
    /// A counter hammered by the stress harness.
    fileprivate var stressCounter: State<Int> {
        state(initial: 0)
    }

    /// A `UserDefaults`-backed array grown to large sizes by the stress harness.
    fileprivate var stressLog: StoredState<[Int]> {
        storedState(initial: [], id: "breakIt.stressLog")
    }
}

// MARK: - BreakItView

/// An interactive "try to crash it" screen.
///
/// Every button runs an abusive workload against AppState — tight mutation loops, large persisted
/// arrays, mass SwiftData inserts, rapid `reset` churn, and concurrent off-main writes — and reports
/// how long it took and that the app is still standing. The point is to *watch it survive* on a real
/// device or simulator.
@available(iOS 18.0, *)
struct BreakItView: View {

    // MARK: - State

    @AppState(\.stressCounter) private var counter: Int
    @StoredState(\.stressLog) private var log: [Int]

    @State private var lastResult: String = "Tap a button to try to break AppState."
    @State private var isRunning: Bool = false

    // MARK: - Body

    var body: some View {
        List {
            Section {
                Text(lastResult)
                    .font(.callout.monospaced())
                LabeledContent("counter", value: "\(counter)")
                LabeledContent("stored array", value: "\(log.count) items")
            } header: {
                Text("Status")
            }

            Section {
                stressButton("Hammer @AppState ×100k") {
                    for _ in 0..<100_000 { counter &+= 1 }
                    return "counter survived 100k writes → \(counter)"
                }
                stressButton("Grow @StoredState to 20k") {
                    log = Array(0..<20_000)
                    return "UserDefaults-backed array → \(log.count) items"
                }
                stressButton("Rapid reset churn ×5k") {
                    for _ in 0..<5_000 {
                        Application.reset(\.stressCounter)
                    }
                    return "survived 5k resets; counter = \(counter)"
                }
                stressButton("Concurrent off-main writes ×10k") {
                    DispatchQueue.concurrentPerform(iterations: 10_000) { index in
                        _ = Application.dependency(\.logger)
                        _ = index
                    }
                    return "10k concurrent dependency reads, no crash"
                }
                #if canImport(SwiftData)
                stressButton("Mass SwiftData insert ×2k") {
                    let store = TodoListStore()
                    store.createList(titled: "Stress \(counter)")
                    guard let list = store.lists.last else {
                        return "no list created"
                    }
                    let items = TodoItemStore(list: list)
                    for index in 0..<2_000 {
                        items.addItem(titled: "Item \(index)", priority: index % 5)
                    }
                    let total = Application.modelState(\.allItems).models.count
                    return "inserted 2k SwiftData items → \(total) total"
                }
                stressButton("Cascade-delete everything") {
                    let store = TodoListStore()
                    for list in store.lists {
                        store.delete(list)
                    }
                    let remaining = Application.modelState(\.allItems).models.count
                    return "cascade-deleted all lists → \(remaining) items remain"
                }
                #endif
            } header: {
                Text("Abusive workloads")
            } footer: {
                Text("Each runs synchronously on the main actor, then reports elapsed time. If the app is still responsive afterwards, AppState held up.")
            }

            Section {
                Button("Reset everything", role: .destructive) {
                    Application.reset(\.stressCounter)
                    log = []
                    lastResult = "Reset."
                }
            }
        }
        .navigationTitle("Break It")
        .disabled(isRunning)
    }

    // MARK: - Helpers

    private func stressButton(_ title: String, _ work: @escaping () -> String) -> some View {
        Button(title) {
            isRunning = true
            let clock = ContinuousClock()
            var summary = ""
            let elapsed = clock.measure { summary = work() }
            let millis = Double(elapsed.components.attoseconds) / 1_000_000_000_000_000 + Double(elapsed.components.seconds) * 1_000
            lastResult = "✓ \(summary)\n   (\(String(format: "%.1f", millis)) ms)"
            isRunning = false
        }
    }
}
