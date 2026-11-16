#if canImport(SwiftUI) && (canImport(UIKit) || canImport(AppKit)) && !os(watchOS)
import SwiftUI
import XCTest

@testable import AppState

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Hosting

/// Puts a SwiftUI view in a real window, so its body runs and re-runs the way it does in an app.
@MainActor
fileprivate final class HostedView<Content: View> {
    #if canImport(UIKit)
    private let window: UIWindow
    private let controller: UIHostingController<Content>

    init(_ content: Content) {
        controller = UIHostingController(rootView: content)
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = controller
        window.isHidden = false
    }

    private func layout() {
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
    }

    func close() {
        window.isHidden = true
        window.rootViewController = nil
    }
    #else
    private let window: NSWindow
    private let hostingView: NSHostingView<Content>

    init(_ content: Content) {
        _ = NSApplication.shared
        hostingView = NSHostingView(rootView: content)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        window.orderFrontRegardless()
    }

    private func layout() {
        hostingView.needsLayout = true
        hostingView.layoutSubtreeIfNeeded()
    }

    func close() {
        window.contentView = nil
        window.close()
    }
    #endif

    /// Lays the view out and lets the main run loop deliver pending SwiftUI updates.
    func render() async {
        for _ in 0..<3 {
            layout()
            try? await Task.sleep(nanoseconds: 30_000_000)
        }

        layout()
    }
}

// MARK: - Fixtures

/// Records each body evaluation and the value the body saw.
@MainActor
fileprivate final class BodyProbe<Value> {
    private(set) var values: [Value] = []

    func record(_ value: Value) {
        values.append(value)
    }
}

fileprivate struct HostedProfile: Codable, Sendable, Equatable {
    var name: String
    var visits: Int
}

fileprivate let hostedDirectory = NSTemporaryDirectory() + "SwiftUIHostingTests"
fileprivate let hostedBlocker = NSTemporaryDirectory() + "SwiftUIHostingTests/blocker"

extension Application {
    fileprivate var hostedCounter: State<Int> {
        state(initial: 0, feature: "SwiftUIHosting", id: "counter")
    }

    fileprivate var hostedAppearCounter: State<Int> {
        state(initial: 0, feature: "SwiftUIHosting", id: "appearCounter")
    }

    fileprivate var hostedProfile: State<HostedProfile> {
        state(initial: HostedProfile(name: "Ada", visits: 0), feature: "SwiftUIHosting", id: "profile")
    }

    fileprivate var hostedStored: StoredState<Int> {
        storedState(initial: 0, feature: "SwiftUIHosting", id: "stored")
    }

    @MainActor
    fileprivate var hostedFile: FileState<Int> {
        fileState(initial: 0, path: hostedDirectory, filename: "file")
    }

    /// The directory of this state is a regular file, so the write fails.
    @MainActor
    fileprivate var hostedBlockedFile: FileState<Int> {
        fileState(initial: 0, path: hostedBlocker, filename: "blocked")
    }

    fileprivate var hostedService: Dependency<String> {
        dependency("real", feature: "SwiftUIHosting", id: "service")
    }
}

fileprivate struct CounterView: View {
    @AppState(\.hostedCounter) private var counter: Int

    let probe: BodyProbe<Int>

    var body: some View {
        let _ = probe.record(counter)

        Text("\(counter)")
    }
}

/// Reads the state in its body and writes it as soon as it appears.
fileprivate struct AppearWriterView: View {
    @AppState(\.hostedAppearCounter) private var counter: Int

    let probe: BodyProbe<Int>

    var body: some View {
        let _ = probe.record(counter)

        Text("\(counter)")
            .onAppear { counter = 9 }
    }
}

fileprivate struct PersistedView: View {
    @StoredState(\.hostedStored) private var stored: Int
    @FileState(\.hostedFile) private var file: Int
    @Slice(\.hostedProfile, \.name) private var name: String

    let probe: BodyProbe<String>

    var body: some View {
        let summary = "\(stored)|\(file)|\(name)"
        let _ = probe.record(summary)

        Text(summary)
    }
}

fileprivate struct BlockedWriterView: View {
    @FileState(\.hostedBlockedFile) private var blocked: Int

    var body: some View {
        Text("\(blocked)")
            .onAppear { blocked = 4 }
    }
}

fileprivate struct ServiceView: View {
    @AppDependency(\.hostedService) private var service: String

    let probe: BodyProbe<String>

    var body: some View {
        let _ = probe.record(service)

        Text(service)
    }
}

@MainActor
fileprivate final class HostedRecordingApplication: Application {
    static var failures: [PersistenceFailure] = []

    override func didFailToPersist(_ failure: PersistenceFailure) {
        HostedRecordingApplication.failures.append(failure)
    }
}

// MARK: - SwiftUIHostingTests

/// Runs the property wrappers inside views hosted in a real window, on every platform that has one.
final class SwiftUIHostingTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        try? FileManager.default.removeItem(atPath: hostedDirectory)
        try FileManager.default.createDirectory(atPath: hostedDirectory, withIntermediateDirectories: true)

        Application.reset(\.hostedCounter)
        Application.reset(\.hostedAppearCounter)
        Application.reset(\.hostedProfile)
        Application.reset(storedState: \.hostedStored)
        Application.reset(fileState: \.hostedFile)
    }

    @MainActor
    override func tearDown() async throws {
        Application.reset(storedState: \.hostedStored)
        Application.reset(fileState: \.hostedFile)

        try? FileManager.default.removeItem(atPath: hostedDirectory)
    }

    /// The getter fills the cache on the first read. That must not make the view render again, and
    /// a later write must render exactly the new value.
    @MainActor
    func testViewSettlesAfterFirstReadAndRendersWrites() async {
        let probe = BodyProbe<Int>()
        let host = HostedView(CounterView(probe: probe))

        await host.render()

        let settled = probe.values.count

        XCTAssertGreaterThan(settled, 0)
        XCTAssertEqual(probe.values.last, 0)

        await host.render()

        XCTAssertEqual(probe.values.count, settled, "The view rendered again without a change")

        var counter = Application.state(\.hostedCounter)
        counter.value = 5

        await host.render()

        XCTAssertEqual(probe.values.last, 5)
        XCTAssertGreaterThan(probe.values.count, settled)

        let afterWrite = probe.values.count

        await host.render()

        XCTAssertEqual(probe.values.count, afterWrite, "The view kept rendering after the write")

        host.close()
    }

    /// A write made as the view appears, right after its first read, is kept and rendered.
    @MainActor
    func testWriteOnAppearAfterFirstReadIsKeptAndRendered() async {
        let probe = BodyProbe<Int>()
        let host = HostedView(AppearWriterView(probe: probe))

        await host.render()
        await host.render()

        XCTAssertEqual(Application.state(\.hostedAppearCounter).value, 9)
        XCTAssertEqual(probe.values.first, 0)
        XCTAssertEqual(probe.values.last, 9)

        host.close()
    }

    @MainActor
    func testStoredFileAndSliceWrappersRenderWrites() async {
        let probe = BodyProbe<String>()
        let host = HostedView(PersistedView(probe: probe))

        await host.render()

        XCTAssertEqual(probe.values.last, "0|0|Ada")

        var stored = Application.storedState(\.hostedStored)
        stored.value = 1

        await host.render()

        XCTAssertEqual(probe.values.last, "1|0|Ada")

        var file = Application.fileState(\.hostedFile)
        file.value = 2

        await host.render()

        XCTAssertEqual(probe.values.last, "1|2|Ada")

        var name = Application.slice(\.hostedProfile, \.name)
        name.value = "Grace"

        await host.render()

        XCTAssertEqual(probe.values.last, "1|2|Grace")

        host.close()
    }

    /// A write that fails inside a view reaches `didFailToPersist`, and the view keeps running.
    @MainActor
    func testFailedWriteFromViewReachesDidFailToPersist() async throws {
        try Data("not a directory".utf8).write(to: URL(fileURLWithPath: hostedBlocker))

        Application.promote(to: HostedRecordingApplication.self)
        HostedRecordingApplication.failures = []

        let host = HostedView(BlockedWriterView())

        await host.render()

        let writes = HostedRecordingApplication.failures.filter { $0.operation == .write }

        XCTAssertEqual(writes.count, 1)
        XCTAssertEqual(writes.first?.store, .fileState)

        host.close()

        Application.shared.cache.remove(Application.shared.hostedBlockedFile.scope.key)
        Application.promote(to: Application.self)
        HostedRecordingApplication.failures = []
    }

    /// `Application.preview` holds its overrides for as long as the previewed view is on screen.
    @MainActor
    func testPreviewKeepsOverrideWhileViewIsHosted() async {
        let probe = BodyProbe<String>()

        XCTAssertEqual(Application.dependency(\.hostedService), "real")

        let host = HostedView(
            Application.preview(Application.override(\.hostedService, with: "mock")) {
                ServiceView(probe: probe)
            }
        )

        await host.render()
        await host.render()

        XCTAssertEqual(probe.values.last, "mock")
        XCTAssertEqual(Application.dependency(\.hostedService), "mock")

        host.close()
    }
}
#endif
