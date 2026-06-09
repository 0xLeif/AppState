// Only compiled on platforms that ship SwiftUI (Apple platforms).
// Linux and Windows do not have SwiftUI, so the state layer in
// Application+MultiPlatformTracker.swift and TrackerController.swift
// still compile and are fully testable there.
#if !os(Linux) && !os(Windows)

import AppState
import SwiftUI

// MARK: - TrackerView

/// A minimal SwiftUI view that binds directly to the persisted `trackerCount`
/// state via the `@StoredState` property wrapper.
///
/// The view demonstrates that the same `Application` key-path used in headless
/// tests powers live reactive UI with zero extra wiring.
public struct TrackerView: View {

    // MARK: - State

    /// Binds to the shared, persisted tracker count.
    ///
    /// `@StoredState` observes `Application` so the view re-renders whenever
    /// any other code (or another view) mutates `\.trackerCount`.
    @StoredState(\.trackerCount) private var count: Int

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 24) {
            Text("Habit Tracker")
                .font(.title2)
                .fontWeight(.semibold)

            Text("\(count)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: count)

            HStack(spacing: 16) {
                Button {
                    count -= 1 > 0 ? 1 : 0
                    // Clamp via controller for parity with headless usage.
                    let controller = TrackerController()
                    if count < 0 { controller.reset() }
                } label: {
                    Label("Decrement", systemImage: "minus.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title)
                }
                .accessibilityLabel("Decrement count")

                Button {
                    count += 1
                } label: {
                    Label("Increment", systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title)
                }
                .accessibilityLabel("Increment count")
            }

            Button("Reset") {
                TrackerController().reset()
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding()
    }

    // MARK: - Initializer

    /// Creates a `TrackerView`.
    public init() {}
}

// MARK: - Preview

#Preview {
    TrackerView()
}

#endif
