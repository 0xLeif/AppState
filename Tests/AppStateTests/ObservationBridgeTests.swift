// Apple-only fuller Observation bridge suite. See `CrossPlatformObservationTests` for the
// Linux/Windows-discoverable delivery smoke tests, and the note atop `ObservationTests.swift`
// for why synchronous `@MainActor` XCTest methods stay gated off those platforms.
#if !os(Linux) && !os(Windows)
import Foundation
import Observation
import XCTest
@testable import AppState

// MARK: - Application state extensions (ObsBridge-prefixed to avoid collisions)

fileprivate extension Application {
    var obsBridgeCounter: State<Int> {
        state(initial: 0, id: "obsBridgeCounter")
    }

    var obsBridgeStoredInt: StoredState<Int> {
        storedState(initial: 0, id: "obsBridgeStoredInt")
    }

    @available(watchOS 9.0, *)
    var obsBridgeSyncString: SyncState<String> {
        syncState(initial: "bridge", id: "obsBridgeSyncString")
    }

    @MainActor
    var obsBridgeFileString: FileState<String?> {
        fileState(path: "./ObsBridgeTests", filename: "obsBridgeFileString")
    }

    var obsBridgeSecureToken: SecureState {
        secureState(feature: "ObsBridgeTests", id: "obsBridgeSecureToken")
    }

    var obsBridgePoint: State<ObsBridgePoint> {
        state(initial: ObsBridgePoint(x: 0, y: 0), id: "obsBridgePoint")
    }

    var obsBridgeOptionalPoint: State<ObsBridgePoint?> {
        state(initial: nil, id: "obsBridgeOptionalPoint")
    }

    var obsBridgeMathService: Dependency<ObsBridgeMathService> {
        dependency(ObsBridgeMathService(), id: "obsBridgeMathService")
    }

    var obsBridgeOptionalRecord: State<ObsBridgeRecord?> {
        state(initial: nil, id: "obsBridgeOptionalRecord")
    }
}

// MARK: - Supporting types

private struct ObsBridgePoint: Equatable, Codable, Sendable {
    var x: Int
    var y: Int
}

/// A record with an optional field, used to exercise the `optionalValueKeyPath` path
/// in `OptionalConstant.wrappedValue` — specifically the `return nil` branch when
/// the nested optional is nil.
private struct ObsBridgeRecord: Equatable, Codable, Sendable {
    var nickname: String?
    var score: Int
}

/// Using a class so DependencySlice mutations (which modify the reference in place) persist.
@MainActor
private final class ObsBridgeMathService: Sendable {
    var multiplier: Int = 3
}

// MARK: - ChangeFlag helper

/// A `Sendable` mutable flag that an `@Sendable` `onChange` closure can write to.
private final class ObsBridgeChangeFlag: @unchecked Sendable {
    var didChange: Bool = false
    var changeCount: Int = 0
    func fire() { didChange = true; changeCount += 1 }
    func reset() { didChange = false; changeCount = 0 }
}

// MARK: - Property wrapper holders for observation tracking

@MainActor
private struct ObsBridgeAppStateHolder {
    @AppState(\.obsBridgeCounter) var counter: Int
}

@MainActor
private struct ObsBridgeStoredStateHolder {
    @StoredState(\.obsBridgeStoredInt) var value: Int
}

@available(watchOS 9.0, *)
@MainActor
private struct ObsBridgeSyncStateHolder {
    @SyncState(\.obsBridgeSyncString) var label: String
}

@MainActor
private struct ObsBridgeFileStateHolder {
    @FileState(\.obsBridgeFileString) var content: String?
}

@MainActor
private struct ObsBridgeSecureStateHolder {
    @SecureState(\.obsBridgeSecureToken) var token: String?
}

@MainActor
private struct ObsBridgeSliceHolder {
    @Slice(\.obsBridgePoint, \.x) var xCoord: Int
}

@MainActor
private struct ObsBridgeOptionalSliceHolder {
    @OptionalSlice(\.obsBridgeOptionalPoint, \.x) var optX: Int?
}

@MainActor
private struct ObsBridgeDependencySliceHolder {
    @DependencySlice(\.obsBridgeMathService, \.multiplier) var multiplier: Int
}

/// Uses the `optionalValueKeyPath` form of `OptionalConstant` so the `return nil`
/// branch (line 43 of OptionalConstant.swift) can be exercised when the nested
/// optional field is nil.
@MainActor
private struct ObsBridgeOptionalConstantHolder {
    @OptionalConstant(\.obsBridgeOptionalRecord, \.nickname) var nickname: String?
}

// MARK: - ObservationBridgeTests

/// Verifies the Observation bridge for every state-style property wrapper:
/// reading registers an observation dependency, mutating fires the `onChange` closure,
/// and reading without mutation does not fire.
///
/// This extends the coverage of `ObservationTests.swift` without duplicating its logic.
@MainActor
final class ObservationBridgeTests: XCTestCase {

    // MARK: - Overrides

    private var userDefaultsOverride: Application.DependencyOverride?
    private var icloudOverride: Application.DependencyOverride?
    private var mathServiceOverride: Application.DependencyOverride?

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        Application.logging(isEnabled: false)

        userDefaultsOverride = Application.override(
            \.userDefaults,
            with: ObsBridgeInMemoryUserDefaults() as UserDefaultsManaging
        )

        if #available(watchOS 9.0, *) {
            icloudOverride = Application.override(
                \.icloudStore,
                with: ObsBridgeInMemoryKeyValueStore() as UbiquitousKeyValueStoreManaging
            )
        }

        // Provide a fresh service instance so DependencySlice mutations don't bleed across tests.
        mathServiceOverride = Application.override(\.obsBridgeMathService, with: ObsBridgeMathService())

        Application.reset(\.obsBridgeCounter)
        Application.reset(storedState: \.obsBridgeStoredInt)
        Application.reset(secureState: \.obsBridgeSecureToken)
        Application.reset(fileState: \.obsBridgeFileString)
        Application.reset(\.obsBridgePoint)
        Application.reset(\.obsBridgeOptionalPoint)
        Application.reset(\.obsBridgeOptionalRecord)

        if #available(watchOS 9.0, *) {
            Application.reset(syncState: \.obsBridgeSyncString)
        }

        FileManager.defaultFileStatePath = "./ObsBridgeTests"
    }

    override func tearDown() async throws {
        Application.reset(\.obsBridgeCounter)
        Application.reset(storedState: \.obsBridgeStoredInt)
        Application.reset(secureState: \.obsBridgeSecureToken)
        Application.reset(fileState: \.obsBridgeFileString)
        Application.reset(\.obsBridgePoint)
        Application.reset(\.obsBridgeOptionalPoint)
        Application.reset(\.obsBridgeOptionalRecord)

        if #available(watchOS 9.0, *) {
            Application.reset(syncState: \.obsBridgeSyncString)
        }

        try? Application.dependency(\.fileManager).removeItem(atPath: "./ObsBridgeTests")

        await mathServiceOverride?.cancel()
        mathServiceOverride = nil
        await icloudOverride?.cancel()
        icloudOverride = nil
        await userDefaultsOverride?.cancel()
        userDefaultsOverride = nil

        try await super.tearDown()
    }

    // MARK: - @AppState observation bridge

    func testAppStateMutationFiresObservation() {
        let holder = ObsBridgeAppStateHolder()
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = holder.counter
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange, "No mutation yet — observer should not have fired")

        holder.counter = 10

        XCTAssertTrue(flag.didChange, "Mutation should fire the observer")
        XCTAssertEqual(holder.counter, 10)
    }

    func testAppStateReadWithoutMutationDoesNotFire() {
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = Application.state(\.obsBridgeCounter).value
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange, "Read without mutation must not fire the observer")
    }

    // MARK: - @StoredState observation bridge

    func testStoredStateMutationFiresObservation() {
        let holder = ObsBridgeStoredStateHolder()
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = holder.value
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)

        holder.value = 99

        XCTAssertTrue(flag.didChange, "StoredState mutation should fire the observer")
        XCTAssertEqual(holder.value, 99)
    }

    func testStoredStateReadWithoutMutationDoesNotFire() {
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = Application.storedState(\.obsBridgeStoredInt).value
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)
    }

    // MARK: - @SyncState observation bridge

    @available(watchOS 9.0, *)
    func testSyncStateMutationFiresObservation() {
        let holder = ObsBridgeSyncStateHolder()
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = holder.label
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)

        holder.label = "updated"

        XCTAssertTrue(flag.didChange, "SyncState mutation should fire the observer")
        XCTAssertEqual(holder.label, "updated")
    }

    @available(watchOS 9.0, *)
    func testSyncStateReadWithoutMutationDoesNotFire() {
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = Application.syncState(\.obsBridgeSyncString).value
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)
    }

    // MARK: - @FileState observation bridge

    func testFileStateMutationFiresObservation() {
        let holder = ObsBridgeFileStateHolder()
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = holder.content
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)

        holder.content = "file-written"

        XCTAssertTrue(flag.didChange, "FileState mutation should fire the observer")
        XCTAssertEqual(holder.content, "file-written")
    }

    func testFileStateReadWithoutMutationDoesNotFire() {
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = Application.fileState(\.obsBridgeFileString).value
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)
    }

    // MARK: - @SecureState observation bridge

    func testSecureStateMutationFiresObservation() {
        let holder = ObsBridgeSecureStateHolder()
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = holder.token
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)

        holder.token = "secure-value"

        XCTAssertTrue(flag.didChange, "SecureState mutation should fire the observer")
        XCTAssertEqual(holder.token, "secure-value")
    }

    func testSecureStateReadWithoutMutationDoesNotFire() {
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = Application.secureState(\.obsBridgeSecureToken).value
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)
    }

    // MARK: - @Slice observation bridge

    func testSliceMutationFiresObservation() {
        let holder = ObsBridgeSliceHolder()
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = holder.xCoord
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)

        holder.xCoord = 55

        XCTAssertTrue(flag.didChange, "Slice mutation should fire the observer")
        XCTAssertEqual(Application.state(\.obsBridgePoint).value.x, 55)
    }

    func testSliceReadWithoutMutationDoesNotFire() {
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = Application.slice(\.obsBridgePoint, \.x as WritableKeyPath).value
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)
    }

    // MARK: - @OptionalSlice observation bridge

    func testOptionalSliceMutationFiresObservationWhenParentIsSet() {
        var pointState = Application.state(\.obsBridgeOptionalPoint)
        pointState.value = ObsBridgePoint(x: 0, y: 0)

        let holder = ObsBridgeOptionalSliceHolder()
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = holder.optX
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)

        holder.optX = 12

        XCTAssertTrue(flag.didChange, "OptionalSlice mutation should fire the observer")
        XCTAssertEqual(Application.state(\.obsBridgeOptionalPoint).value?.x, 12)
    }

    // MARK: - @OptionalConstant nil path coverage

    /// Exercises the `return nil` guard-else branch inside `OptionalConstant.wrappedValue`.
    ///
    /// The branch at `OptionalConstant.swift` line 43 is taken when the *outer* optional state
    /// value is `nil` — i.e. `State<Record?>.value == nil`. In that case
    /// `Application.slice(stateKeyPath, optionalValueKeyPath).value` returns `nil` (a nil
    /// `SliceValue??`), the `guard let slicedValue` condition fails, and `return nil` executes.
    func testOptionalConstantReturnsNilWhenOuterStateIsNil() {
        // Ensure the outer optional state is nil so the guard fails.
        Application.reset(\.obsBridgeOptionalRecord)

        let holder = ObsBridgeOptionalConstantHolder()

        XCTAssertNil(holder.nickname, "OptionalConstant must return nil when the outer state is nil")
    }

    /// Verifies that `OptionalConstant` correctly returns the value when both optionals are non-nil.
    func testOptionalConstantReturnsValueWhenBothOptionalsAreSet() {
        var state = Application.state(\.obsBridgeOptionalRecord)
        state.value = ObsBridgeRecord(nickname: "Leif", score: 10)

        let holder = ObsBridgeOptionalConstantHolder()

        XCTAssertEqual(holder.nickname, "Leif")
    }

    /// Verifies that `OptionalConstant` returns nil when outer state is non-nil but inner field is nil.
    func testOptionalConstantReturnsNilWhenInnerOptionalFieldIsNil() {
        var state = Application.state(\.obsBridgeOptionalRecord)
        state.value = ObsBridgeRecord(nickname: nil, score: 42)

        let holder = ObsBridgeOptionalConstantHolder()

        // The guard succeeds (outer is Some) but `slicedValue` is `String?.none` = nil.
        XCTAssertNil(holder.nickname, "OptionalConstant with nil inner optional must return nil")
    }

    // MARK: - @DependencySlice observation bridge

    func testDependencySliceMutationFiresObservation() {
        let holder = ObsBridgeDependencySliceHolder()
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = holder.multiplier
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)

        holder.multiplier = 6

        XCTAssertTrue(flag.didChange, "DependencySlice mutation should fire the observer")
        XCTAssertEqual(Application.dependency(\.obsBridgeMathService).multiplier, 6)
    }

    func testDependencySliceReadWithoutMutationDoesNotFire() {
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = Application.dependencySlice(\.obsBridgeMathService, \.multiplier as WritableKeyPath).value
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)
    }

    // MARK: - Multiple independent observers

    func testMultipleIndependentObserversAllFire() {
        let holder = ObsBridgeAppStateHolder()
        let flag1 = ObsBridgeChangeFlag()
        let flag2 = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = holder.counter
        } onChange: {
            flag1.fire()
        }

        withObservationTracking {
            _ = holder.counter
        } onChange: {
            flag2.fire()
        }

        holder.counter = 77

        XCTAssertTrue(flag1.didChange, "First observer should fire")
        XCTAssertTrue(flag2.didChange, "Second observer should fire")
    }

    func testSubsequentObservationsTrackIndependently() {
        let holder = ObsBridgeAppStateHolder()
        let firstFlag = ObsBridgeChangeFlag()
        let secondFlag = ObsBridgeChangeFlag()

        // Register first observer
        withObservationTracking {
            _ = holder.counter
        } onChange: {
            firstFlag.fire()
        }

        holder.counter = 1
        XCTAssertTrue(firstFlag.didChange)

        // First observer has been consumed; register a fresh one
        withObservationTracking {
            _ = holder.counter
        } onChange: {
            secondFlag.fire()
        }

        XCTAssertFalse(secondFlag.didChange, "Second observer should not fire yet")

        holder.counter = 2
        XCTAssertTrue(secondFlag.didChange, "Second observer fires after second mutation")
    }

    // MARK: - Application.notifyChange() directly

    /// Calling `notifyChange()` on the main thread bumps `changeAnchor`, which fires
    /// any registered observation observers — the same mechanism SwiftUI uses.
    func testNotifyChangeDirectlyBumpsObservers() {
        let holder = ObsBridgeAppStateHolder()
        let flag = ObsBridgeChangeFlag()

        withObservationTracking {
            _ = holder.counter
        } onChange: {
            flag.fire()
        }

        XCTAssertFalse(flag.didChange)

        Application.shared.notifyChange()

        XCTAssertTrue(flag.didChange, "notifyChange() must fire registered observers")
    }

    func testNotifyChangeCanBeCalledRepeatedly() {
        // Just verifying it does not crash or assert on repeated main-thread calls.
        for _ in 0..<5 {
            Application.shared.notifyChange()
        }
    }

    // MARK: - didChangeExternally(notification:)

    /// Exercises the `didChangeExternally(notification:)` path so the body is covered.
    /// The method only logs — verifying it does not throw or crash is sufficient.
    @available(watchOS 9.0, *)
    func testDidChangeExternallyDoesNotCrash() {
        let notification = Notification(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            userInfo: [
                NSUbiquitousKeyValueStoreChangeReasonKey: NSUbiquitousKeyValueStoreServerChange,
                NSUbiquitousKeyValueStoreChangedKeysKey: ["someKey"]
            ]
        )

        // Call on the main actor (the invariant the method requires).
        Application.shared.didChangeExternally(notification: notification)
    }

    /// Also verify a custom `Application` subclass can override `didChangeExternally`.
    @available(watchOS 9.0, *)
    func testCustomApplicationSubclassCanOverrideDidChangeExternally() {
        final class ObsBridgeCustomApplication: Application {
            @MainActor
            var externalChangeReceived: Bool = false

            @MainActor
            override func didChangeExternally(notification: Notification) {
                externalChangeReceived = true
                super.didChangeExternally(notification: notification)
            }
        }

        let customApp = ObsBridgeCustomApplication()
        let notification = Notification(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )

        customApp.didChangeExternally(notification: notification)

        XCTAssertTrue(customApp.externalChangeReceived)
    }
}

// MARK: - In-memory test doubles (ObsBridge-prefixed)

private final class ObsBridgeInMemoryUserDefaults: UserDefaultsManaging, @unchecked Sendable {
    private var storage: [String: Any] = [:]
    func object(forKey key: String) -> Any? { storage[key] }
    func set(_ value: Any?, forKey key: String) { storage[key] = value }
    func removeObject(forKey key: String) { storage.removeValue(forKey: key) }
}

@available(watchOS 9.0, *)
private final class ObsBridgeInMemoryKeyValueStore: UbiquitousKeyValueStoreManaging, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    func data(forKey key: String) -> Data? { storage[key] }
    func set(_ value: Data?, forKey key: String) { storage[key] = value }
    func removeObject(forKey key: String) { storage.removeValue(forKey: key) }
}

#endif // !os(Linux) && !os(Windows)
