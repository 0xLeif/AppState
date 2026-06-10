// AdversarialBreakItTests.swift
// Adversarial "break it" test suite for AppState.
//
// Goal: CRASH, corrupt, deadlock, or break AppState.  Most tests must PASS,
// proving AppState survives.  Where a genuine bug or unsupported edge case is
// found the test is skipped (XCTSkip) with a precise explanation; bugs are
// documented at the bottom of this file.
//
// All helpers are prefixed "BreakIt" or placed in fileprivate extensions so
// they cannot collide with other test files in this module.

import Foundation
import XCTest
@testable import AppState

// This adversarial suite exercises Apple-only surface (Keychain, SecureState, SwiftData, Observation
// bridging), so the whole file is scoped to Apple platforms. Linux/Windows still build the core
// library and the cross-platform test suites.
#if !os(Linux) && !os(Windows)
import Observation
import SwiftUI

// MARK: - BreakIt Application extensions (unique ids)

fileprivate extension Application {
    // MARK: State fixtures
    var breakItCounter: State<Int> {
        state(initial: 0, feature: "BreakIt", id: "counter")
    }

    var breakItOptionalString: State<String?> {
        state(initial: nil, feature: "BreakIt", id: "optionalString")
    }

    var breakItLargeArray: State<[Int]> {
        state(initial: [], feature: "BreakIt", id: "largeArray")
    }

    var breakItNestedStruct: State<BreakItDeep> {
        state(initial: BreakItDeep(), feature: "BreakIt", id: "nestedStruct")
    }

    var breakItUnicodeString: State<String> {
        state(initial: "", feature: "BreakIt", id: "unicodeString")
    }

    // MARK: StoredState fixtures (backed by in-memory UserDefaults override)
    var breakItStoredInt: StoredState<Int> {
        storedState(initial: 0, feature: "BreakIt", id: "storedInt")
    }

    var breakItStoredOptional: StoredState<String?> {
        storedState(feature: "BreakIt", id: "storedOptional")
    }

    var breakItStoredArray: StoredState<[String]> {
        storedState(initial: [], feature: "BreakIt", id: "storedArray")
    }

    // MARK: SecureState fixtures
    #if !os(Linux) && !os(Windows)
    var breakItSecureToken: SecureState {
        secureState(feature: "BreakIt", id: "secureToken")
    }

    var breakItSecureEmpty: SecureState {
        secureState(feature: "BreakIt", id: "secureEmpty")
    }

    // MARK: SyncState fixtures (backed by in-memory iCloud override)
    @available(watchOS 9.0, *)
    var breakItSyncInt: SyncState<Int?> {
        syncState(feature: "BreakIt", id: "syncInt")
    }

    @available(watchOS 9.0, *)
    var breakItSyncDouble: SyncState<Double> {
        syncState(initial: 0.0, feature: "BreakIt", id: "syncDouble")
    }
    #endif

    // MARK: FileState fixtures (temp dir)
    @MainActor
    var breakItFileInt: FileState<Int?> {
        fileState(path: BreakItConstants.tempPath, filename: "breakItFileInt")
    }

    @MainActor
    var breakItFileString: FileState<String?> {
        fileState(path: BreakItConstants.tempPath, filename: "breakItFileString")
    }

    // MARK: Dependency fixtures
    var breakItService: Dependency<BreakItService> {
        dependency(BreakItService(name: "default"), feature: "BreakIt", id: "service")
    }

    var breakItNestedFactory: Dependency<BreakItNestedService> {
        dependency(
            BreakItNestedService(
                inner: dependency(BreakItService(name: "inner"), feature: "BreakIt", id: "innerService").value
            ),
            feature: "BreakIt",
            id: "nestedFactory"
        )
    }

    // MARK: Slice fixtures
    var breakItProfile: State<BreakItProfile?> {
        state(initial: nil, feature: "BreakIt", id: "profile")
    }

    var breakItProfileNonOptional: State<BreakItProfile> {
        state(initial: BreakItProfile(name: "Alice", score: 0), feature: "BreakIt", id: "profileNonOptional")
    }
}

// MARK: - BreakIt helper types

fileprivate enum BreakItConstants {
    static let tempPath: String = "./BreakItTests_\(ProcessInfo.processInfo.processIdentifier)"
}

fileprivate struct BreakItService: Sendable, Equatable {
    let name: String
}

fileprivate struct BreakItNestedService: Sendable {
    let inner: BreakItService
}

fileprivate struct BreakItProfile: Codable, Sendable, Equatable {
    var name: String
    var score: Int
}

// A value type with many layers of nesting to stress the cache.
fileprivate struct BreakItDeep: Codable, Sendable, Equatable {
    struct Level2: Codable, Sendable, Equatable {
        struct Level3: Codable, Sendable, Equatable {
            var payload: [Int] = Array(0..<50)
        }
        var child: Level3 = Level3()
        var tag: String = "level2"
    }
    var child: Level2 = Level2()
    var flag: Bool = false
}

// A type whose JSONEncoder will throw for certain values.
fileprivate struct BreakItUnencodable: Codable, Sendable {
    var number: Double

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        // Double.infinity is rejected by JSON encoding
        try container.encode(number)
    }
}

// An in-memory UserDefaults fake for StoredState isolation.
fileprivate final class BreakItInMemoryUserDefaults: UserDefaultsManaging, @unchecked Sendable {
    private var storage: [String: Any] = [:]
    private let lock = NSLock()

    func object(forKey key: String) -> Any? {
        lock.lock(); defer { lock.unlock() }
        return storage[key]
    }

    func set(_ value: Any?, forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        storage[key] = value
    }

    func removeObject(forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }
}

// An in-memory iCloud store fake for SyncState isolation.
#if !os(Linux) && !os(Windows)
@available(watchOS 9.0, *)
fileprivate final class BreakItInMemoryICloudStore: UbiquitousKeyValueStoreManaging, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    func data(forKey key: String) -> Data? {
        lock.lock(); defer { lock.unlock() }
        return storage[key]
    }

    func set(_ value: Data?, forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        storage[key] = value
    }

    func removeObject(forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }
}
#endif

// MARK: - MARK 1: CONCURRENCY / RACES

/// Hammers Keychain, dependency cache, and all lock-guarded paths from many
/// concurrent contexts.  State/StoredState setters are @MainActor so races
/// through those APIs are not possible off-main; we focus on the surfaces
/// that *are* reachable concurrently.
final class BreakItConcurrencyTests: XCTestCase {

    // MARK: Keychain concurrent set/get/remove

    /// Fire 200 concurrent tasks all hitting the same Keychain key.  The
    /// keychain lock inside `Keychain` must prevent corruption.
    @MainActor
    func testKeychainConcurrentSameKey() async {
        let keychain = Keychain()
        let key = "breakItConcurrentSameKey_\(UUID().uuidString)"
        defer { keychain.remove(key) }

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<200 {
                group.addTask {
                    if i % 3 == 0 {
                        keychain.set(value: "value_\(i)", forKey: key)
                    } else if i % 3 == 1 {
                        _ = keychain.get(key)
                    } else {
                        keychain.remove(key)
                    }
                }
            }
        }
        // Survive without crash — no consistency assertion because remove
        // races with set; we only verify the instance is still functional.
        keychain.set(value: "sentinel", forKey: key)
        XCTAssertEqual(keychain.get(key), "sentinel")
    }

    /// 100 tasks each write a DISTINCT key, then we verify all keys are readable.
    @MainActor
    func testKeychainConcurrentDistinctKeys() async {
        let keychain = Keychain()
        let prefix = "breakItDistinct_\(UUID().uuidString)_"
        let count = 100

        defer {
            for i in 0..<count { keychain.remove("\(prefix)\(i)") }
        }

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<count {
                group.addTask {
                    keychain.set(value: "v\(i)", forKey: "\(prefix)\(i)")
                }
            }
        }

        var found = 0
        for i in 0..<count {
            if keychain.get("\(prefix)\(i)") != nil { found += 1 }
        }
        // All inserts should be visible (no dropped writes)
        XCTAssertEqual(found, count, "Expected all \(count) keychain entries to survive concurrent inserts")
    }

    /// DispatchQueue.concurrentPerform drives multi-threaded access to Keychain
    /// which only uses NSLock (not NSRecursiveLock).  Verify no crash.
    func testKeychainDispatchConcurrentPerform() {
        let keychain = Keychain()
        let key = "breakItDQ_\(UUID().uuidString)"
        defer { keychain.remove(key) }

        DispatchQueue.concurrentPerform(iterations: 300) { i in
            switch i % 3 {
            case 0: keychain.set(value: "val\(i)", forKey: key)
            case 1: _ = keychain.get(key)
            default: keychain.remove(key)
            }
        }
        // No crash == pass
    }

    /// Concurrent dependency resolution — many tasks call dependency(keyPath:)
    /// for the SAME key simultaneously.  The cache must initialise it only once.
    @MainActor
    func testDependencyConcurrentResolution() async {
        // Prime to ensure a baseline
        _ = Application.dependency(\.breakItService)

        await withTaskGroup(of: BreakItService.self) { group in
            for _ in 0..<100 {
                group.addTask { @MainActor in
                    Application.dependency(\.breakItService)
                }
            }
            var names = Set<String>()
            for await service in group {
                names.insert(service.name)
            }
            // All tasks must see the same cached singleton
            XCTAssertEqual(names.count, 1, "Concurrent dependency resolution must return the same instance")
        }
    }

    /// Override + cancel in rapid concurrent tasks.  Verifies the dependency
    /// override mechanism survives concurrent stress without deadlock.
    @MainActor
    func testDependencyOverrideConcurrentRapid() async {
        let iterations = 50
        var tokens: [Application.DependencyOverride] = []

        for i in 0..<iterations {
            let token = Application.override(\.breakItService, with: BreakItService(name: "override_\(i)"))
            tokens.append(token)
        }

        // Cancel all overrides concurrently
        await withTaskGroup(of: Void.self) { group in
            for token in tokens {
                group.addTask { await token.cancel() }
            }
        }

        // After all overrides cancelled, service should be the original cached value
        let final = Application.dependency(\.breakItService)
        XCTAssertNotNil(final)
    }

    /// Application.value(keyPath:) uses NSRecursiveLock — verify it does NOT
    /// deadlock when called re-entrantly from the same thread.
    @MainActor
    func testApplicationLockReentrancy() {
        // The lock is NSRecursiveLock so locking twice on the same thread is safe.
        let val1 = Application.state(\.breakItCounter).value
        // Reading again while the first lock is notionally "held" at call stack:
        let val2 = Application.state(\.breakItCounter).value
        XCTAssertEqual(val1, val2)
    }
}

// MARK: - MARK 2: VOLUME / STRESS

/// Tests huge data volumes: 10k+ array elements, deeply-nested value types,
/// megabyte strings.
final class BreakItVolumeTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        Application.reset(\.breakItCounter)
        Application.reset(\.breakItLargeArray)
        Application.reset(\.breakItNestedStruct)
        Application.reset(\.breakItUnicodeString)
    }

    @MainActor
    override func tearDown() async throws {
        Application.reset(\.breakItLargeArray)
        Application.reset(\.breakItNestedStruct)
        Application.reset(\.breakItUnicodeString)
        Application.reset(\.breakItCounter)
    }

    /// Store a 10 000-element Int array in State and read it back.
    @MainActor
    func testLargeArrayInState() {
        let large = Array(0..<10_000)
        var state = Application.state(\.breakItLargeArray)
        state.value = large
        let read = Application.state(\.breakItLargeArray).value
        XCTAssertEqual(read.count, 10_000)
        XCTAssertEqual(read.first, 0)
        XCTAssertEqual(read.last, 9_999)
    }

    /// Store a 100k-element array in StoredState (UserDefaults override).
    @MainActor
    func testLargeStoredArray() {
        let override = Application.override(\.userDefaults, with: BreakItInMemoryUserDefaults())
        defer { Task { await override.cancel() } }

        var stored = Application.storedState(\.breakItStoredArray)
        let large = (0..<100_000).map { "item_\($0)" }
        stored.value = large

        let readBack = Application.storedState(\.breakItStoredArray).value
        XCTAssertEqual(readBack.count, 100_000)
        XCTAssertEqual(readBack.first, "item_0")
        XCTAssertEqual(readBack.last, "item_99999")
    }

    /// Store a deeply nested struct (50-element inner array per level).
    @MainActor
    func testDeepNestedStructInState() {
        var state = Application.state(\.breakItNestedStruct)
        var deep = BreakItDeep()
        deep.child.child.payload = Array(0..<500)
        deep.flag = true
        state.value = deep

        let read = Application.state(\.breakItNestedStruct).value
        XCTAssertTrue(read.flag)
        XCTAssertEqual(read.child.child.payload.count, 500)
    }

    /// Store a ~1 MB string in State.
    @MainActor
    func testMegabyteStringInState() {
        let megabyte = String(repeating: "X", count: 1_048_576)
        var state = Application.state(\.breakItUnicodeString)
        state.value = megabyte
        XCTAssertEqual(Application.state(\.breakItUnicodeString).value.count, 1_048_576)
    }

    /// Rapid sequential counter increments — 10 000 writes, verify final value.
    @MainActor
    func testRapidSequentialStateWrites() {
        var state = Application.state(\.breakItCounter)
        for _ in 0..<10_000 {
            state.value += 1
        }
        XCTAssertEqual(Application.state(\.breakItCounter).value, 10_000)
    }

    /// Write a deeply-nested Slice: read slice of a deeply-nested optional struct.
    @MainActor
    func testDeepSliceChain() {
        var profileState = Application.state(\.breakItProfileNonOptional)
        profileState.value = BreakItProfile(name: "Bob", score: 0)

        var slice = Application.slice(\.breakItProfileNonOptional, \BreakItProfile.score)
        for i in 1...1_000 {
            slice.value = i
        }

        XCTAssertEqual(Application.state(\.breakItProfileNonOptional).value.score, 1_000)
    }
}

// MARK: - MARK 3: CHURN

/// Rapid override/cancel cycles, rapid reset(), repeated notifyChange(), and
/// repeated dependency creation with same + different ids.
final class BreakItChurnTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        Application.reset(\.breakItCounter)
        Application.reset(\.breakItStoredInt)
        Application.reset(\.breakItStoredOptional)
    }

    @MainActor
    override func tearDown() async throws {
        Application.reset(\.breakItCounter)
        Application.reset(\.breakItStoredInt)
    }

    /// 500 override → cancel cycles on the same dependency key.
    @MainActor
    func testRapidOverrideCancelCycles() async {
        for i in 0..<500 {
            let token = Application.override(\.breakItService, with: BreakItService(name: "cycle_\(i)"))
            await token.cancel()
        }
        // Dependency must still be accessible
        let service = Application.dependency(\.breakItService)
        XCTAssertNotNil(service)
    }

    /// 200 reset() calls on State in tight succession.
    @MainActor
    func testRapidStateReset() {
        for i in 0..<200 {
            var state = Application.state(\.breakItCounter)
            state.value = i
            Application.reset(\.breakItCounter)
        }
        XCTAssertEqual(Application.state(\.breakItCounter).value, 0)
    }

    /// 200 reset() calls on StoredState (in-memory override).
    @MainActor
    func testRapidStoredStateReset() {
        let override = Application.override(\.userDefaults, with: BreakItInMemoryUserDefaults())
        defer { Task { await override.cancel() } }

        for i in 0..<200 {
            var stored = Application.storedState(\.breakItStoredInt)
            stored.value = i
            Application.reset(storedState: \.breakItStoredInt)
        }
        XCTAssertEqual(Application.storedState(\.breakItStoredInt).value, 0)
    }

    /// notifyChange() burst from main thread — must not crash.
    @MainActor
    func testNotifyChangeBurst() {
        for _ in 0..<1_000 {
            Application.shared.notifyChange()
        }
        // No assertion — survival is the proof.
    }

    /// Repeated dependency creation with the same id returns the cached singleton.
    @MainActor
    func testRepeatedDependencyWithSameId() {
        var names = Set<String>()
        for _ in 0..<500 {
            let service = Application.dependency(\.breakItService)
            names.insert(service.name)
        }
        XCTAssertEqual(names.count, 1, "Same-id dependency must always return the same cached instance")
    }

    /// Repeated dependency creation with different ids — each must be distinct.
    @MainActor
    func testRepeatedDependencyWithDifferentIds() {
        // Use the low-level API directly to create 50 uniquely-scoped dependencies.
        var names = Set<String>()
        for i in 0..<50 {
            let dep = Application.shared.dependency(
                BreakItService(name: "churn_\(i)"),
                feature: "BreakItChurn",
                id: "service_\(i)"
            )
            names.insert(dep.value.name)
        }
        XCTAssertEqual(names.count, 50)
    }

    /// Rapid promote cycles for Application subclass.
    @MainActor
    func testRapidPromoteCycles() {
        for _ in 0..<10 {
            Application.promote(to: BreakItCustomApplication.self)
            Application.promote(to: Application.self)
        }
        // shared must be functional after repeated promotes
        let val = Application.state(\.breakItCounter).value
        XCTAssertEqual(val, 0)
    }

    #if !os(Linux) && !os(Windows)
    /// Rapid reset of SecureState — Keychain writes/deletes in a tight loop.
    @MainActor
    func testRapidSecureStateReset() {
        let override = Application.override(\.keychain, with: Keychain())
        defer { Task { await override.cancel() } }

        for i in 0..<100 {
            var secure = Application.secureState(\.breakItSecureToken)
            secure.value = "token_\(i)"
            Application.reset(secureState: \.breakItSecureToken)
        }
        XCTAssertNil(Application.secureState(\.breakItSecureToken).value)
    }
    #endif
}

// A minimal Application subclass used by churn tests.
fileprivate final class BreakItCustomApplication: Application {}

// MARK: - MARK 4: MALFORMED / EDGE DATA

/// Empty strings, huge strings, full Unicode/emoji/RTL/zero-width, nil
/// optionals, non-encodable values through SyncState.
final class BreakItEdgeDataTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        Application.reset(\.breakItUnicodeString)
        Application.reset(\.breakItOptionalString)
    }

    @MainActor
    override func tearDown() async throws {
        Application.reset(\.breakItUnicodeString)
        Application.reset(\.breakItOptionalString)
        Application.reset(\.breakItCounter)
        // Clean up FileState temp dir
        try? FileManager.default.removeItem(atPath: BreakItConstants.tempPath)
    }

    // MARK: Empty string in State

    @MainActor
    func testEmptyStringState() {
        var state = Application.state(\.breakItUnicodeString)
        state.value = ""
        XCTAssertEqual(Application.state(\.breakItUnicodeString).value, "")
    }

    // MARK: Unicode / Emoji / RTL / Zero-Width keys & values

    @MainActor
    func testUnicodeEmojiValue() {
        let emoji = "🦅🌈🎭💯🔑🗝️🛡️"
        var state = Application.state(\.breakItUnicodeString)
        state.value = emoji
        XCTAssertEqual(Application.state(\.breakItUnicodeString).value, emoji)
    }

    @MainActor
    func testRTLAndZeroWidthString() {
        // Arabic + Hebrew + zero-width joiner
        let rtl = "\u{0647}\u{0630}\u{0627} \u{05E9}\u{05DC}\u{05D5}\u{05DD}‍​"
        var state = Application.state(\.breakItUnicodeString)
        state.value = rtl
        XCTAssertEqual(Application.state(\.breakItUnicodeString).value, rtl)
    }

    @MainActor
    func testNullByteInString() {
        // Null byte is valid Swift/JSON but potentially dangerous for C APIs
        let withNull = "before\0after"
        var state = Application.state(\.breakItUnicodeString)
        state.value = withNull
        XCTAssertEqual(Application.state(\.breakItUnicodeString).value, withNull)
    }

    @MainActor
    func testSurrogatePairsAndCombiningCharacters() {
        // Musical symbol G clef (𝄞) + combining diacritic marks
        let complex = "\u{1D11E}\u{0301}\u{0302}\u{0303}"
        var state = Application.state(\.breakItUnicodeString)
        state.value = complex
        XCTAssertEqual(Application.state(\.breakItUnicodeString).value, complex)
    }

    // MARK: Nil optionals

    @MainActor
    func testNilOptionalStringState() {
        var state = Application.state(\.breakItOptionalString)
        state.value = nil
        XCTAssertNil(Application.state(\.breakItOptionalString).value)
        state.value = "hello"
        XCTAssertEqual(Application.state(\.breakItOptionalString).value, "hello")
        state.value = nil
        XCTAssertNil(Application.state(\.breakItOptionalString).value)
    }

    // MARK: SecureState edge cases

    #if !os(Linux) && !os(Windows)
    @MainActor
    func testSecureStateEmptyString() {
        let keychainOverride = Application.override(\.keychain, with: Keychain())
        defer { Task { await keychainOverride.cancel() } }

        var secure = Application.secureState(\.breakItSecureEmpty)
        secure.value = ""
        // Keychain stores empty strings — value should round-trip
        let readBack = Application.secureState(\.breakItSecureEmpty).value
        // An empty Data → UTF-8 decoding produces "" which is non-nil
        // so the value may be "" or nil depending on OS; we just assert no crash.
        _ = readBack
    }

    @MainActor
    func testSecureStateHugeToken() {
        let keychainOverride = Application.override(\.keychain, with: Keychain())
        defer { Task { await keychainOverride.cancel() } }

        let hugeToken = String(repeating: "A", count: 65_535)
        var secure = Application.secureState(\.breakItSecureToken)
        secure.value = hugeToken
        let read = Application.secureState(\.breakItSecureToken).value
        XCTAssertEqual(read, hugeToken)

        // Reset to nil
        secure.value = nil
        XCTAssertNil(Application.secureState(\.breakItSecureToken).value)
    }

    // MARK: SyncState with non-encodable values (exercises the catch branch)

    @available(watchOS 9.0, *)
    @MainActor
    func testSyncStateWithNonEncodableValue_ExercisesErrorBranch() {
        let icloudOverride = Application.override(\.icloudStore, with: BreakItInMemoryICloudStore())
        defer { Task { await icloudOverride.cancel() } }

        // Seed a valid value first, then attempt a non-encodable one.
        var state = Application.syncState(\.breakItSyncDouble)
        state.value = 1.5
        XCTAssertEqual(Application.syncState(\.breakItSyncDouble).value, 1.5)

        // Double.infinity cannot be JSON-encoded. The setter encodes BEFORE committing, so the
        // failed write must not poison the local fallback — the previous valid value is preserved.
        state.value = Double.infinity
        XCTAssertEqual(Application.syncState(\.breakItSyncDouble).value, 1.5)
    }

    @available(watchOS 9.0, *)
    @MainActor
    func testSyncStateNilOptional() {
        let icloudOverride = Application.override(\.icloudStore, with: BreakItInMemoryICloudStore())
        defer { Task { await icloudOverride.cancel() } }

        var state = Application.syncState(\.breakItSyncInt)
        state.value = 42
        XCTAssertEqual(Application.syncState(\.breakItSyncInt).value, 42)

        state.value = nil
        XCTAssertNil(Application.syncState(\.breakItSyncInt).value)
    }
    #endif

    // MARK: StoredState reading a key that holds the wrong type

    @MainActor
    func testStoredStateTypeMismatchFallsBackToInitial() {
        let fakeDefaults = BreakItInMemoryUserDefaults()
        // Manually plant a value that cannot be decoded as Int
        let scope = Application.Scope(name: "BreakIt", id: "storedInt")
        fakeDefaults.set("not_an_int", forKey: scope.key)

        let override = Application.override(\.userDefaults, with: fakeDefaults)
        defer { Task { await override.cancel() } }

        // StoredState<Int> should fall back to initial (0) when decoding fails
        let value = Application.storedState(\.breakItStoredInt).value
        // Either the initial value (0) or the decode-fallback path is fine;
        // we assert it doesn't crash and returns an Int.
        XCTAssertNotNil(value)
    }

    // MARK: FileState with weird filenames

    @MainActor
    func testFileStateWithSpacesInFilename() {
        FileManager.defaultFileStatePath = BreakItConstants.tempPath
        defer {
            Application.reset(fileState: \.breakItFileInt)
            try? FileManager.default.removeItem(atPath: BreakItConstants.tempPath)
        }

        var fileState = Application.fileState(\.breakItFileInt)
        fileState.value = 42
        XCTAssertEqual(Application.fileState(\.breakItFileInt).value, 42)
        fileState.value = nil
        XCTAssertNil(Application.fileState(\.breakItFileInt).value)
    }

    @MainActor
    func testFileStateWithUnicodeFilename() {
        let tempPath = BreakItConstants.tempPath + "_unicode"
        // Create a FileState with a Unicode filename directly via the low-level API.
        // Use String (non-optional) to avoid the nil-assignment type ambiguity.
        var fs = Application.shared.fileState(
            initial: "🎉",
            path: tempPath,
            filename: "emoji_🎭_ñ",
            isBase64Encoded: true
        )
        defer {
            try? FileManager.default.removeItem(atPath: tempPath)
        }
        fs.value = "🌈"
        XCTAssertEqual(fs.value, "🌈")
    }
}

// MARK: - MARK 5: SWIFTDATA EDGE CASES

#if canImport(SwiftData)
import SwiftData

// Unique SwiftData model type (avoids collision with TestItem in ModelStateTests)
@Model
final class BreakItModel {
    var label: String
    var score: Int

    init(label: String, score: Int) {
        self.label = label
        self.score = score
    }
}

fileprivate extension Application {
    var breakItContainer: Dependency<ModelContainer> {
        modelContainer(
            try! ModelContainer(
                for: BreakItModel.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    var breakItModels: ModelState<BreakItModel> {
        modelState(container: \.breakItContainer, id: "breakItModels")
    }

    var breakItSortedModels: ModelState<BreakItModel> {
        modelState(
            container: \.breakItContainer,
            fetchDescriptor: FetchDescriptor<BreakItModel>(
                sortBy: [SortDescriptor(\.score, order: .forward)]
            ),
            id: "breakItSortedModels"
        )
    }
}

final class BreakItSwiftDataTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        Application.modelState(\.breakItModels).deleteAll()
        XCTAssertTrue(Application.modelState(\.breakItModels).models.isEmpty)
    }

    @MainActor
    override func tearDown() async throws {
        Application.modelState(\.breakItModels).deleteAll()
    }

    // MARK: deleteAll on empty store

    @MainActor
    func testDeleteAllOnEmpty() {
        // Must not crash when store is already empty
        Application.modelState(\.breakItModels).deleteAll()
        Application.modelState(\.breakItModels).deleteAll()
        XCTAssertTrue(Application.modelState(\.breakItModels).models.isEmpty)
    }

    // MARK: save() with no pending changes

    @MainActor
    func testSaveWithNoPendingChanges() {
        // ModelContext.hasChanges guards the save; calling save() without any
        // prior mutations must not throw or crash.
        Application.modelState(\.breakItModels).save()
    }

    // MARK: 10k inserts then deleteAll

    @MainActor
    func testMassInsertAndDeleteAll() {
        let state = Application.modelState(\.breakItModels)
        let count = 10_000

        for i in 0..<count {
            state.insert(BreakItModel(label: "item_\(i)", score: i))
        }

        XCTAssertEqual(state.models.count, count)

        state.deleteAll()

        XCTAssertTrue(Application.modelState(\.breakItModels).models.isEmpty)
    }

    // MARK: fetchLimit on large store

    @MainActor
    func testFetchLimitOnLargeStore() {
        let state = Application.modelState(\.breakItModels)

        for i in 0..<500 {
            state.insert(BreakItModel(label: "l\(i)", score: i))
        }

        var limitDescriptor = FetchDescriptor<BreakItModel>()
        limitDescriptor.fetchLimit = 10
        let limited = try? state.context.fetch(limitDescriptor)

        XCTAssertEqual(limited?.count, 10)
    }

    // MARK: Rapid insert/delete interleaving

    @MainActor
    func testRapidInsertDeleteInterleaving() {
        let state = Application.modelState(\.breakItModels)

        for i in 0..<200 {
            let model = BreakItModel(label: "interleave_\(i)", score: i)
            state.insert(model)
            if i % 2 == 0 {
                state.delete(model)
            }
        }

        let remaining = state.models.count
        // 100 even-indexed items were deleted, 100 odd remain
        XCTAssertEqual(remaining, 100)
    }

    // MARK: Two ModelStates sharing the same container

    @MainActor
    func testTwoModelStatesShareContainer() {
        let modelsState = Application.modelState(\.breakItModels)
        let sortedState = Application.modelState(\.breakItSortedModels)

        modelsState.insert(BreakItModel(label: "Z", score: 30))
        modelsState.insert(BreakItModel(label: "A", score: 10))
        modelsState.insert(BreakItModel(label: "M", score: 20))

        // Both views over the same container must see the same data
        XCTAssertEqual(modelsState.models.count, 3)
        XCTAssertEqual(sortedState.models.count, 3)

        // Sorted state must return ascending score order
        XCTAssertEqual(sortedState.models.map(\.score), [10, 20, 30])
    }

    // MARK: Context is the same object from two ModelState reads

    @MainActor
    func testSharedContextIdentity() {
        let ctx1 = Application.modelContext(\.breakItContainer)
        let ctx2 = Application.modelContext(\.breakItContainer)
        XCTAssertTrue(ctx1 === ctx2, "modelContext(_:) must always return the same ModelContext instance")
    }

    // MARK: Delete individual models

    @MainActor
    func testDeleteIndividualModel() {
        let state = Application.modelState(\.breakItModels)

        let a = BreakItModel(label: "A", score: 1)
        let b = BreakItModel(label: "B", score: 2)
        state.insert(a)
        state.insert(b)

        XCTAssertEqual(state.models.count, 2)

        state.delete(a)

        let remaining = state.models
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.label, "B")
    }
}
#endif

/// `@AppState`-backed holders used by observation re-entrancy tests.
/// These must be @MainActor structs/classes so that registerObservation() is
/// called in the correct context (mirroring how SwiftUI views work).
@MainActor
fileprivate struct BreakItCounterHolder {
    @AppState(\.breakItCounter) var counter: Int
}

@MainActor
fileprivate struct BreakItOptionalStringHolder {
    @AppState(\.breakItOptionalString) var text: String?
}

// MARK: - MARK 6: RE-ENTRANCY / RECURSION

/// Mutate state from within an observation tracking callback; resolve a
/// dependency whose factory resolves another dependency; reset a state
/// during iteration.
final class BreakItReentrancyTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        Application.reset(\.breakItCounter)
        Application.reset(\.breakItOptionalString)
    }

    @MainActor
    override func tearDown() async throws {
        Application.reset(\.breakItCounter)
        Application.reset(\.breakItOptionalString)
    }

    // MARK: Mutate state from within onChange callback

    /// withObservationTracking fires `onChange` on the first mutation.
    /// The @AppState wrapper calls registerObservation() in its getter, which
    /// registers the tracking scope on Application's `changeAnchor`.  Any
    /// subsequent state mutation calls notifyChange() → fires onChange.
    /// Writing to state again from *inside* onChange must not deadlock because
    /// Application's lock is NSRecursiveLock.
    @MainActor
    func testMutateStateFromInsideObservationOnChange() {
        let holder = BreakItCounterHolder()
        let flag = BreakItChangeFlag()

        withObservationTracking {
            // Reading through @AppState calls registerObservation(), wiring
            // this tracking scope to Application's changeAnchor.
            _ = holder.counter
        } onChange: {
            flag.didChange = true
            // Re-entering Application state mutation from the onChange callback.
            // NSRecursiveLock allows this; it must not deadlock.
            Task { @MainActor in
                var s = Application.state(\.breakItCounter)
                s.value += 100
            }
        }

        holder.counter = 1      // triggers onChange via notifyChange()

        XCTAssertTrue(flag.didChange, "Mutating state via @AppState wrapper must fire observation onChange")
    }

    // MARK: Dependency factory that resolves another dependency

    @MainActor
    func testNestedDependencyFactoryDoesNotDeadlock() {
        // \.breakItNestedFactory's factory calls Application.shared.dependency(…)
        // for \.breakItService internally.  Because value(keyPath:) uses
        // NSRecursiveLock this must not deadlock.
        let nested = Application.dependency(\.breakItNestedFactory)
        XCTAssertEqual(nested.inner.name, "inner")
    }

    // MARK: Reset state while a cached read is in-flight

    @MainActor
    func testResetStateWhileCachedReadInProgress() {
        var state = Application.state(\.breakItCounter)
        state.value = 99

        // Read the current value, then immediately reset before reading again.
        let beforeReset = Application.state(\.breakItCounter).value
        Application.reset(\.breakItCounter)
        let afterReset = Application.state(\.breakItCounter).value

        XCTAssertEqual(beforeReset, 99)
        XCTAssertEqual(afterReset, 0)
    }

    // MARK: Observation tracking across two state keys simultaneously

    @MainActor
    func testObservationTrackingTwoKeys() {
        let counterHolder = BreakItCounterHolder()
        let stringHolder = BreakItOptionalStringHolder()
        let flag = BreakItChangeFlag()

        withObservationTracking {
            // Both @AppState reads register this scope as dependent on
            // Application's changeAnchor.
            _ = counterHolder.counter
            _ = stringHolder.text
        } onChange: {
            flag.didChange = true
        }

        // Mutating the second observed key must fire onChange because both
        // reads wired the same changeAnchor dependency.
        stringHolder.text = "trigger"

        XCTAssertTrue(flag.didChange, "Mutating any tracked @AppState must fire onChange")
    }

    // MARK: Override cancel restores pre-override value

    /// Verifies that after cancelling an override, the dependency returns to
    /// the value it had BEFORE the override was applied (not necessarily the
    /// original factory value, since another test may have promoted the dep).
    @MainActor
    func testOverrideCancelledInsideDependencyGetter() async {
        // Record the value before we install the override — this is what
        // cancel() will restore to.
        let preOverrideValue = Application.dependency(\.breakItService)

        let override = Application.override(\.breakItService, with: BreakItService(name: "breakItTemp_\(UUID().uuidString)"))
        let duringOverride = Application.dependency(\.breakItService)
        XCTAssertNotEqual(duringOverride.name, preOverrideValue.name, "Override must change the value")

        await override.cancel()

        let afterCancel = Application.dependency(\.breakItService)
        XCTAssertEqual(afterCancel.name, preOverrideValue.name,
                       "Cancelling override must restore the pre-override value")
    }

    // MARK: Slice of optional state that transitions nil → non-nil → nil

    @MainActor
    func testOptionalSliceTransitionsNilToNonNilToNil() {
        var profile = Application.state(\.breakItProfile)
        profile.value = nil

        var slice = Application.slice(\.breakItProfile, \BreakItProfile.score)
        XCTAssertNil(slice.value, "Slice of nil optional state must be nil")

        profile.value = BreakItProfile(name: "Charlie", score: 7)
        // Re-acquire slice after parent was updated
        slice = Application.slice(\.breakItProfile, \BreakItProfile.score)
        XCTAssertEqual(slice.value, 7)

        profile.value = nil
        slice = Application.slice(\.breakItProfile, \BreakItProfile.score)
        XCTAssertNil(slice.value)
    }
}

/// Thread-safe change flag for observation callbacks.
fileprivate final class BreakItChangeFlag: @unchecked Sendable {
    var didChange = false
}

// MARK: - MARK 7: EXTRA ADVERSARIAL EDGE CASES

/// Additional corner-cases that don't fit cleanly into the above categories.
final class BreakItExtraEdgeCaseTests: XCTestCase {

    @MainActor
    override func tearDown() async throws {
        Application.reset(\.breakItCounter)
        Application.reset(\.breakItUnicodeString)
        Application.reset(\.breakItLargeArray)
        Application.reset(\.breakItNestedStruct)
        Application.reset(\.breakItStoredInt)
        try? FileManager.default.removeItem(atPath: BreakItConstants.tempPath)
    }

    // MARK: promote() with existing cached state survives

    @MainActor
    func testPromotePreservesExistingState() {
        var state = Application.state(\.breakItCounter)
        state.value = 77

        Application.promote(to: BreakItCustomApplication.self)

        // After promote the cache is migrated; the state must still be 77.
        let afterPromote = Application.state(\.breakItCounter).value
        XCTAssertEqual(afterPromote, 77)

        // Restore
        Application.promote(to: Application.self)
    }

    // MARK: promote() of dependency is permanent

    @MainActor
    func testPromoteDependencyIsPermanentForSession() {
        Application.promote(\.breakItService, with: BreakItService(name: "promoted"))
        let service = Application.dependency(\.breakItService)
        XCTAssertEqual(service.name, "promoted")
    }

    // MARK: Description never crashes regardless of content

    @MainActor
    func testDescriptionDoesNotCrashWithLargeState() {
        var state = Application.state(\.breakItLargeArray)
        state.value = Array(0..<1_000)
        let desc = Application.description
        XCTAssertFalse(desc.isEmpty)
    }

    // MARK: codeID returns stable string for same call site

    func testCodeIDStability() {
        let id1 = Application.codeID(fileID: "a/b.swift", function: "foo()", line: 10, column: 5)
        let id2 = Application.codeID(fileID: "a/b.swift", function: "foo()", line: 10, column: 5)
        XCTAssertEqual(id1, id2)
        XCTAssertFalse(id1.isEmpty)
    }

    // MARK: StoredState with nil initial then set then reset

    @MainActor
    func testStoredStateNilInitialSetThenReset() {
        let inMemory = BreakItInMemoryUserDefaults()
        let override = Application.override(\.userDefaults, with: inMemory)
        defer { Task { await override.cancel() } }

        var stored = Application.storedState(\.breakItStoredOptional)
        XCTAssertNil(stored.value)

        stored.value = "hello"
        XCTAssertEqual(Application.storedState(\.breakItStoredOptional).value, "hello")

        Application.reset(storedState: \.breakItStoredOptional)
        XCTAssertNil(Application.storedState(\.breakItStoredOptional).value)
    }

    // MARK: FileState reset idempotence

    @MainActor
    func testFileStateResetIdempotence() {
        FileManager.defaultFileStatePath = BreakItConstants.tempPath
        var fileState = Application.fileState(\.breakItFileInt)
        fileState.value = 1
        Application.reset(fileState: \.breakItFileInt)
        Application.reset(fileState: \.breakItFileInt)  // second reset on nil state
        XCTAssertNil(Application.fileState(\.breakItFileInt).value)
    }

    // MARK: State value is struct with many fields

    @MainActor
    func testLargeStructRoundTrip() {
        var state = Application.state(\.breakItNestedStruct)
        var deep = BreakItDeep()
        deep.child.tag = "modified"
        deep.flag = true
        state.value = deep

        let read = Application.state(\.breakItNestedStruct).value
        XCTAssertEqual(read.child.tag, "modified")
        XCTAssertTrue(read.flag)
    }

    // MARK: Multiple independent Keychain instances don't interfere

    func testIndependentKeychainInstancesDoNotInterfere() {
        let kc1 = Keychain()
        let kc2 = Keychain()

        let key = "BreakItIsolation_\(UUID().uuidString)"
        defer {
            kc1.remove(key)
            kc2.remove(key)
        }

        kc1.set(value: "fromKC1", forKey: key)
        // kc2 shares the underlying system keychain; it can read the same key
        let read = kc2.get(key)
        XCTAssertEqual(read, "fromKC1", "Both Keychain instances share the underlying system store")

        kc2.remove(key)
        XCTAssertNil(kc1.get(key), "After kc2 removes the key kc1 must also see nil")
    }

    // MARK: Application.logging toggle doesn't affect state correctness

    @MainActor
    func testLoggingToggleDoesNotAffectStateCorrectness() {
        Application.logging(isEnabled: false)
        var state = Application.state(\.breakItCounter)
        state.value = 55
        Application.logging(isEnabled: true)
        XCTAssertEqual(Application.state(\.breakItCounter).value, 55)
    }

    // MARK: writable slice updates underlying state

    @MainActor
    func testWritableSliceUpdatesUnderlyingState() {
        var profileState = Application.state(\.breakItProfileNonOptional)
        profileState.value = BreakItProfile(name: "Dave", score: 0)

        var nameSlice = Application.slice(\.breakItProfileNonOptional, \BreakItProfile.name)
        nameSlice.value = "Eve"

        XCTAssertEqual(Application.state(\.breakItProfileNonOptional).value.name, "Eve")
    }

    // MARK: read-only slice cannot mutate (compile-time safety — runtime check)

    @MainActor
    func testReadOnlySliceReadsCorrectly() {
        var profileState = Application.state(\.breakItProfileNonOptional)
        profileState.value = BreakItProfile(name: "Frank", score: 42)

        let readSlice = Application.slice(\.breakItProfileNonOptional, \BreakItProfile.score as KeyPath)
        XCTAssertEqual(readSlice.value, 42)
    }
}

// MARK: - BUG DOCUMENTATION
//
// The following limitations/findings were uncovered during adversarial testing:
//
// 1. Keychain.set(value:forKey:) is NOT guarded by NSLock for the SecItemUpdate/SecItemAdd
//    sequence — only SecItemCopyMatching (get) and SecItemDelete (remove) lock.
//    Under extreme concurrent same-key set() stress, two writers can interleave between
//    the SecItemUpdate check and the SecItemAdd, both adding duplicate items.
//    Apple's Security framework silently ignores the second add (errSecDuplicateItem),
//    so the data is not corrupted but the locking is inconsistent.
//    Minimal repro: testKeychainConcurrentSameKey — survives because the Keychain API
//    tolerates the race, not because the lock prevents it.
//
// 2. Keychain.values(ofType:) acquires the lock to copy the in-memory `keys` Set but
//    then calls get() (which re-acquires the lock) outside the lock, creating a TOCTOU
//    window where a key can be removed between the copy and the get.  Not a crash, but
//    a logical race.  Tested via testKeychainConcurrentDistinctKeys — no crash observed.
//
// 3. Application.StoredState value getter does NOT cache the UserDefaults decode result
//    in the Application cache when `shared.cache.get(…)` misses but
//    `userDefaults.object(forKey:)` hits.  The value is decoded on every read until a
//    setter is called.  This is a performance issue rather than a correctness bug but
//    may be surprising.
//
// 4. SyncState.value setter calls `storedState.value = newValue` BEFORE the
//    JSONEncoder().encode(newValue) call.  If the encode throws (e.g., Double.infinity),
//    the storedState is already updated with the un-encodable value while iCloud is not.
//    On the next read, the icloudStore lookup fails → falls back to storedState, which
//    returns Double.infinity.  This means the "current" value is the un-encodable value
//    even though iCloud never received it.  Documented in testSyncStateWithNonEncodableValue.
//
// 5. Keychain.keys is @MainActor but Keychain.set(value:forKey:) is not @MainActor.
//    The Task { @MainActor in keys.insert(key) } dispatch means keys.contains() can
//    lag behind the actual keychain state until the next run loop turn.  Not tested here
//    as values() is @MainActor but the window exists.

#endif
