import XCTest
#if canImport(Observation)
import Observation
#endif

@testable import AppState

#if canImport(Combine)
import Combine
#endif

// MARK: - Fixtures

fileprivate final class InitialCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock(); defer { lock.unlock() }
        return count
    }

    func next() -> Int {
        lock.lock(); defer { lock.unlock() }
        count += 1
        return count
    }
}

fileprivate let reviewInitialCounter = InitialCounter()

fileprivate struct ReviewReading: Codable, Sendable, Equatable {
    var celsius: Double
}

/// Records what reaches `UserDefaults`, so a test can see a value that the real store would reject.
fileprivate final class ReviewRecordingUserDefaults: UserDefaultsManaging, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Any] = [:]

    func object(forKey key: String) -> Any? {
        lock.lock(); defer { lock.unlock() }
        return storage[key]
    }

    func removeObject(forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        storage[key] = nil
    }

    func set(_ value: Any?, forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        storage[key] = value
    }
}

fileprivate let reviewFilePath = "./ReviewFixTests"

extension Application {
    fileprivate var reviewCounter: State<Int> {
        state(initial: 0, feature: "ReviewFix", id: "counter")
    }

    fileprivate var reviewCountedInitial: State<Int> {
        state(initial: reviewInitialCounter.next(), feature: "ReviewFix", id: "countedInitial")
    }

    fileprivate var reviewHostValue: State<Int> {
        state(initial: 0, feature: "ReviewFix", id: "hostValue")
    }

    fileprivate var reviewReading: StoredState<ReviewReading> {
        storedState(initial: ReviewReading(celsius: 0), feature: "ReviewFix", id: "reading")
    }

    fileprivate var reviewRatio: StoredState<Double> {
        storedState(initial: 0, feature: "ReviewFix", id: "ratio")
    }

    @MainActor
    fileprivate var reviewFlagFile: FileState<Bool> {
        fileState(initial: false, path: reviewFilePath, filename: "flag", isBase64Encoded: false)
    }

    @MainActor
    fileprivate var reviewPinFile: FileState<Int> {
        fileState(initial: 0, path: reviewFilePath, filename: "pin", isBase64Encoded: false)
    }

    @MainActor
    fileprivate var reviewEncodedPinFile: FileState<Int> {
        fileState(initial: 0, path: reviewFilePath, filename: "encodedPin")
    }

    fileprivate var reviewQuietCounter: State<Int> {
        state(initial: 0, feature: "ReviewFix", id: "quietCounter")
    }

    fileprivate var reviewPromotedService: Dependency<String> {
        dependency("real", feature: "ReviewFix", id: "promotedService")
    }

    fileprivate var reviewService: Dependency<String> {
        dependency("real", feature: "ReviewFix", id: "service")
    }
}

#if canImport(Combine)
@MainActor
fileprivate final class ReviewCustomPublisherHost: ObservableObject {
    nonisolated(unsafe) let objectWillChange = PassthroughSubject<Void, Never>()

    @AppState(\.reviewHostValue) var value: Int
}

@MainActor
fileprivate final class ReviewDefaultPublisherHost: ObservableObject {
    @AppState(\.reviewHostValue) var value: Int
}
#endif

#if canImport(Security)
fileprivate final class ReviewExternalChangeCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock(); defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock(); defer { lock.unlock() }
        count += 1
    }
}

fileprivate let reviewExternalChanges = ReviewExternalChangeCounter()

fileprivate final class ReviewPromotedApplication: Application {
    override func didChangeExternally(notification: Notification) {
        reviewExternalChanges.increment()
    }
}
#endif

// MARK: - ReviewFixTests

/// One test per defect found in the review of the state and dependency types.
final class ReviewFixTests: XCTestCase {
    @MainActor
    override func tearDown() async throws {
        try? FileManager.default.removeItem(atPath: reviewFilePath)
    }

    // MARK: State cache

    /// A read used to seed the cache from a deferred task when XCTest was not loaded, and that
    /// task undid a write made in the same turn. The getter now has one path, exercised here.
    @MainActor
    func testWriteAfterFirstReadSurvivesQueuedMainActorJobs() async {
        var counter = Application.state(\.reviewCounter)
        XCTAssertEqual(counter.value, 0)

        counter.value = 5

        await Task.yield()
        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(Application.state(\.reviewCounter).value, 5)

        Application.reset(\.reviewCounter)
    }

    @MainActor
    func testStateInitialIsEvaluatedOnce() async {
        let first = Application.state(\.reviewCountedInitial).value

        for _ in 0..<5 {
            XCTAssertEqual(Application.state(\.reviewCountedInitial).value, first)
        }

        XCTAssertEqual(reviewInitialCounter.value, 1)

        var state = Application.state(\.reviewCountedInitial)
        state.value = 40
        state.value = 41
        Application.reset(\.reviewCountedInitial)

        XCTAssertEqual(Application.state(\.reviewCountedInitial).value, first)
        XCTAssertEqual(reviewInitialCounter.value, 1)
    }

    /// The getter fills the cache on a first read. That must stay invisible to observers, or a
    /// SwiftUI view body would invalidate itself by reading its own state.
    @MainActor
    func testFirstReadDoesNotNotifyObservers() async {
        Application.reset(\.reviewQuietCounter)
        Application.shared.cache.remove(Application.shared.reviewQuietCounter.scope.key)

        let changes = InitialCounter()

        withObservationTracking {
            _ = Application.state(\.reviewQuietCounter).value
            _ = Application.state(\.reviewQuietCounter).value
        } onChange: {
            _ = changes.next()
        }

        XCTAssertEqual(changes.value, 0)

        var counter = Application.state(\.reviewQuietCounter)
        counter.value = 1

        XCTAssertEqual(changes.value, 1)

        Application.reset(\.reviewQuietCounter)
    }

    // MARK: Enclosing-instance setter

    #if canImport(Combine)
    @MainActor
    func testWriteThroughHostWithCustomObjectWillChangeIsStored() async {
        let host = ReviewCustomPublisherHost()
        host.value = 7

        XCTAssertEqual(host.value, 7)
        XCTAssertEqual(Application.state(\.reviewHostValue).value, 7)

        let defaultHost = ReviewDefaultPublisherHost()
        var changes = 0
        let cancellable = defaultHost.objectWillChange.sink { changes += 1 }
        defaultHost.value = 8

        XCTAssertEqual(defaultHost.value, 8)
        XCTAssertEqual(changes, 1)

        cancellable.cancel()
        Application.reset(\.reviewHostValue)
    }
    #endif

    // MARK: StoredState

    @MainActor
    func testStoredStateRejectsValueThatIsNeitherJSONNorPropertyList() async {
        let defaults = ReviewRecordingUserDefaults()
        let override = Application.override(\.userDefaults, with: defaults)

        var reading = Application.storedState(\.reviewReading)
        reading.value = ReviewReading(celsius: 21)
        reading.value = ReviewReading(celsius: .nan)

        // The real `UserDefaults` raises an Objective-C exception for a non-property-list object.
        XCTAssertTrue(defaults.object(forKey: "ReviewFix/reading") is Data)
        XCTAssertEqual(Application.storedState(\.reviewReading).value, ReviewReading(celsius: 21))

        var ratio = Application.storedState(\.reviewRatio)
        ratio.value = .infinity

        XCTAssertEqual(Application.storedState(\.reviewRatio).value, .infinity)

        Application.reset(storedState: \.reviewReading)
        Application.reset(storedState: \.reviewRatio)
        await override.cancel()
    }

    // MARK: FileState

    @MainActor
    func testUnencodedFileStateReadsBackBase64LookingValues() async {
        var flag = Application.fileState(\.reviewFlagFile)
        flag.value = true
        var pin = Application.fileState(\.reviewPinFile)
        pin.value = 1234
        var encodedPin = Application.fileState(\.reviewEncodedPinFile)
        encodedPin.value = 5678

        // A relaunch loses the in-memory cache and keeps the files.
        Application.shared.cache.remove("\(reviewFilePath)/flag")
        Application.shared.cache.remove("\(reviewFilePath)/pin")
        Application.shared.cache.remove("\(reviewFilePath)/encodedPin")

        XCTAssertEqual(Application.fileState(\.reviewFlagFile).value, true)
        XCTAssertEqual(Application.fileState(\.reviewPinFile).value, 1234)
        XCTAssertEqual(Application.fileState(\.reviewEncodedPinFile).value, 5678)

        Application.shared.cache.remove("\(reviewFilePath)/flag")
        Application.shared.cache.remove("\(reviewFilePath)/pin")
        Application.shared.cache.remove("\(reviewFilePath)/encodedPin")
    }

    // A Windows file URL carries a drive letter, so the literal comparison below is POSIX only.
    #if !os(Windows)
    func testDefaultFileStatePathIsNotPercentEncoded() {
        let documents = URL(fileURLWithPath: "/Users/José Doe/Documents", isDirectory: true)

        XCTAssertEqual(
            FileManager.fileStatePath(inDocumentsDirectory: documents).precomposedStringWithCanonicalMapping,
            "/Users/José Doe/Documents/App".precomposedStringWithCanonicalMapping
        )
    }
    #endif

    // MARK: DependencyOverride

    @MainActor
    func testReleasingOverrideRestoresDependency() async {
        do {
            let token = Application.override(\.reviewService, with: "mock")

            withExtendedLifetime(token) {
                XCTAssertEqual(Application.dependency(\.reviewService), "mock")
            }
        }

        XCTAssertEqual(Application.dependency(\.reviewService), "real")
    }

    @MainActor
    func testReleaseAfterCancelDoesNotUndoLaterOverride() async {
        var first: Application.DependencyOverride? = Application.override(\.reviewService, with: "first")
        await first?.cancel()

        XCTAssertEqual(Application.dependency(\.reviewService), "real")

        let second = Application.override(\.reviewService, with: "second")
        first = nil

        XCTAssertEqual(Application.dependency(\.reviewService), "second")

        await second.cancel()

        XCTAssertEqual(Application.dependency(\.reviewService), "real")
    }

    /// Off the main thread the release cannot restore synchronously. It restores on the main
    /// actor's next turn.
    @MainActor
    func testOverrideReleasedOffMainThreadRestoresOnMainActor() async {
        func releaseOffMain(_ token: sending Application.DependencyOverride) async {
            await Task.detached {
                XCTAssertFalse(Thread.isMainThread)
                _ = token
            }.value
        }

        XCTAssertEqual(Application.dependency(\.reviewService), "real")

        await releaseOffMain(Application.override(\.reviewService, with: "mock"))

        for _ in 0..<50 where Application.dependency(\.reviewService) != "real" {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTAssertEqual(Application.dependency(\.reviewService), "real")
    }

    /// `promote(_:with:)` keeps its override itself, so a promotion outlives the call.
    @MainActor
    func testPromotedDependencyOutlivesTheCall() async {
        let original = Application.dependency(\.reviewPromotedService)

        Application.promote(\.reviewPromotedService, with: "promoted")

        await Task.yield()
        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(original, "real")
        XCTAssertEqual(Application.dependency(\.reviewPromotedService), "promoted")
    }

    // MARK: promote(to:)

    #if canImport(Security)
    @MainActor
    func testPromoteKeepsExternalChangeObserver() async {
        _ = Application.dependency(\.icloudStore)

        Application.promote(to: ReviewPromotedApplication.self)

        let before = reviewExternalChanges.value

        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )

        XCTAssertEqual(reviewExternalChanges.value - before, 1)

        Application.promote(to: Application.self)
    }
    #endif
}
