import Foundation
import XCTest
@testable import AppState

fileprivate extension Application {
    var stressCounter: State<Int> {
        state(initial: 0)
    }

    var stressString: State<String> {
        state(initial: "initial")
    }

    var stressArray: State<[Int]> {
        state(initial: [])
    }
}

/// Tests for high-volume operations and true concurrent access.
///
/// Note: State/Dependency tests use `@MainActor` because the Application API requires it.
/// These tests verify stability under high-volume sequential operations, not parallel execution.
/// Keychain tests are truly concurrent as Keychain methods are nonisolated and Mutex-protected.
final class ConcurrencyStressTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()

        await MainActor.run {
            Application.reset(\.stressCounter)
            Application.reset(\.stressString)
            Application.reset(\.stressArray)
            Application.logging(isEnabled: false)
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            Application.reset(\.stressCounter)
            Application.reset(\.stressString)
            Application.reset(\.stressArray)
        }

        try await super.tearDown()
    }

    // MARK: - High-Volume MainActor Operations
    // These tests verify stability under many sequential operations on MainActor.
    // They are NOT true concurrency tests since @MainActor serializes execution.

    /// Tests high-volume reads and writes to state are stable.
    @MainActor
    func testHighVolumeStateReadWrite() async {
        let iterations = 500

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask { @MainActor in
                    var state = Application.state(\.stressString)
                    state.value = "value-\(i)"
                }
            }

            for _ in 0..<iterations {
                group.addTask { @MainActor in
                    let state = Application.state(\.stressString)
                    _ = state.value
                }
            }
        }

        let finalState = Application.state(\.stressString)
        XCTAssertTrue(finalState.value.starts(with: "value-") || finalState.value == "initial")
    }

    /// Tests high-volume counter updates complete without crashes.
    @MainActor
    func testHighVolumeStateUpdates() async {
        let iterations = 100
        var completedWrites = 0

        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<iterations {
                group.addTask { @MainActor in
                    var state = Application.state(\.stressCounter)
                    let current = state.value
                    state.value = current + 1
                    return true
                }
            }

            for await success in group {
                if success { completedWrites += 1 }
            }
        }

        XCTAssertEqual(completedWrites, iterations)
        let finalState = Application.state(\.stressCounter)
        XCTAssertGreaterThan(finalState.value, 0)
    }

    /// Tests high-volume array modifications don't corrupt data.
    @MainActor
    func testHighVolumeArrayModifications() async {
        let iterations = 200

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask { @MainActor in
                    var state = Application.state(\.stressArray)
                    var array = state.value
                    array.append(i)
                    state.value = array
                }
            }
        }

        let finalState = Application.state(\.stressArray)
        XCTAssertGreaterThan(finalState.value.count, 0)

        for element in finalState.value {
            XCTAssertTrue(element >= 0 && element < iterations)
        }
    }

    /// Tests high-volume dependency access is stable.
    @MainActor
    func testHighVolumeDependencyAccess() async {
        let iterations = 500
        var accessCount = 0

        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<iterations {
                group.addTask { @MainActor in
                    _ = Application.dependency(\.logger)
                    _ = Application.dependency(\.userDefaults)
                    _ = Application.dependency(\.fileManager)
                    return true
                }
            }

            for await success in group {
                if success { accessCount += 1 }
            }
        }

        XCTAssertEqual(accessCount, iterations)
    }

    /// Tests mixed operations under high volume.
    @MainActor
    func testHighVolumeMixedOperations() async {
        let iterations = 300

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask { @MainActor in
                    switch i % 4 {
                    case 0:
                        let state = Application.state(\.stressCounter)
                        _ = state.value
                    case 1:
                        var state = Application.state(\.stressCounter)
                        state.value = i
                    case 2:
                        _ = Application.dependency(\.logger)
                    case 3:
                        var state = Application.state(\.stressString)
                        let current = state.value
                        state.value = current + "-\(i)"
                    default:
                        break
                    }
                }
            }
        }

        let counterState = Application.state(\.stressCounter)
        let stringState = Application.state(\.stressString)
        _ = counterState.value
        _ = stringState.value
    }

    /// Tests rapid state reset operations are stable.
    @MainActor
    func testHighVolumeStateReset() async {
        let iterations = 200

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask { @MainActor in
                    if i % 2 == 0 {
                        var state = Application.state(\.stressCounter)
                        state.value = i
                    } else {
                        Application.reset(\.stressCounter)
                    }
                }
            }
        }

        let finalState = Application.state(\.stressCounter)
        XCTAssertTrue(finalState.value >= 0)
    }

    #if !os(Linux) && !os(Windows)
    // MARK: - True Concurrent Access (Keychain)
    // These tests ARE truly concurrent - Keychain methods are nonisolated and Mutex-protected.

    /// Tests Keychain Mutex handles true concurrent operations correctly.
    @MainActor
    func testKeychainConcurrentAccess() async {
        let keychain = Keychain()
        let iterations = 100

        await withTaskGroup(of: Void.self) { group in
            // Concurrent writes - truly parallel, no @MainActor
            for i in 0..<iterations {
                group.addTask {
                    keychain.set(value: "value-\(i)", forKey: "stress-key-\(i % 10)")
                }
            }

            // Concurrent reads - truly parallel, no @MainActor
            for i in 0..<iterations {
                group.addTask {
                    _ = keychain.get("stress-key-\(i % 10)")
                }
            }
        }

        // Verify keychain is still functional
        keychain.set(value: "final", forKey: "stress-final")
        let finalValue = keychain.get("stress-final")
        XCTAssertEqual(finalValue, "final")

        // Cleanup
        for i in 0..<10 {
            keychain.remove("stress-key-\(i)")
        }
        keychain.remove("stress-final")
    }

    /// Tests Keychain values() under true concurrent modifications.
    @MainActor
    func testKeychainConcurrentValues() async {
        let keychain = Keychain()
        let iterations = 50

        await withTaskGroup(of: Void.self) { group in
            // Writers - truly parallel
            for i in 0..<iterations {
                group.addTask {
                    keychain.set(value: "v\(i)", forKey: "concurrent-\(i)")
                }
            }

            // Readers - truly parallel
            for _ in 0..<iterations {
                group.addTask {
                    _ = keychain.values()
                }
            }
        }

        // Cleanup
        for i in 0..<iterations {
            keychain.remove("concurrent-\(i)")
        }
    }
    #endif
}
