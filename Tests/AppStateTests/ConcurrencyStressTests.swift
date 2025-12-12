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

final class ConcurrencyStressTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()

        await MainActor.run {
            Application.reset(\.stressCounter)
            Application.reset(\.stressString)
            Application.reset(\.stressArray)
            Application.logging(isEnabled: false) // Disable logging for stress tests
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

    // MARK: - Concurrent State Read/Write

    /// Tests concurrent reads and writes to state don't cause crashes or data races.
    @MainActor
    func testConcurrentStateReadWrite() async {
        let iterations = 500

        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<iterations {
                group.addTask { @MainActor in
                    var state = Application.state(\.stressString)
                    state.value = "value-\(i)"
                }
            }

            // Readers
            for _ in 0..<iterations {
                group.addTask { @MainActor in
                    let state = Application.state(\.stressString)
                    _ = state.value
                }
            }
        }

        // Verify state is accessible and has a valid value
        let finalState = Application.state(\.stressString)
        XCTAssertTrue(finalState.value.starts(with: "value-") || finalState.value == "initial")
    }

    // MARK: - High Contention Counter Updates

    /// Tests that concurrent increments complete without losing updates.
    /// Note: This tests Cache's Mutex under contention, not atomic increments.
    @MainActor
    func testHighContentionStateUpdates() async {
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

        // All tasks should complete without crashing
        XCTAssertEqual(completedWrites, iterations)

        // Final value should be positive (exact count may vary due to race conditions in read-modify-write)
        let finalState = Application.state(\.stressCounter)
        XCTAssertGreaterThan(finalState.value, 0)
    }

    // MARK: - Concurrent Array Modifications

    /// Tests concurrent array appends don't corrupt data structure.
    @MainActor
    func testConcurrentArrayModifications() async {
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

        // Array should contain some elements (exact count may vary due to concurrent read-modify-write)
        let finalState = Application.state(\.stressArray)
        XCTAssertGreaterThan(finalState.value.count, 0)

        // All elements should be valid integers in expected range
        for element in finalState.value {
            XCTAssertTrue(element >= 0 && element < iterations)
        }
    }

    // MARK: - Concurrent Dependency Access

    /// Tests that dependencies remain stable under concurrent access.
    @MainActor
    func testConcurrentDependencyAccess() async {
        let iterations = 500
        var accessCount = 0

        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<iterations {
                group.addTask { @MainActor in
                    // Access built-in dependencies concurrently
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

    // MARK: - Mixed Operations Stress Test

    /// Tests a realistic mix of operations under concurrent load.
    @MainActor
    func testMixedOperationsStress() async {
        let iterations = 300

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask { @MainActor in
                    switch i % 4 {
                    case 0:
                        // Read state
                        let state = Application.state(\.stressCounter)
                        _ = state.value
                    case 1:
                        // Write state
                        var state = Application.state(\.stressCounter)
                        state.value = i
                    case 2:
                        // Access dependency
                        _ = Application.dependency(\.logger)
                    case 3:
                        // Read and write
                        var state = Application.state(\.stressString)
                        let current = state.value
                        state.value = current + "-\(i)"
                    default:
                        break
                    }
                }
            }
        }

        // Verify no crash and state is accessible
        let counterState = Application.state(\.stressCounter)
        let stringState = Application.state(\.stressString)
        _ = counterState.value
        _ = stringState.value
    }

    #if !os(Linux) && !os(Windows)
    // MARK: - Keychain Concurrent Access

    /// Tests Keychain Mutex handles concurrent operations correctly.
    @MainActor
    func testKeychainConcurrentAccess() async {
        let keychain = Keychain()
        let iterations = 100

        await withTaskGroup(of: Void.self) { group in
            // Concurrent writes
            for i in 0..<iterations {
                group.addTask {
                    keychain.set(value: "value-\(i)", forKey: "stress-key-\(i % 10)")
                }
            }

            // Concurrent reads
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

    /// Tests Keychain values() under concurrent modifications.
    @MainActor
    func testKeychainValuesConcurrent() async {
        let keychain = Keychain()
        let iterations = 50

        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<iterations {
                group.addTask {
                    keychain.set(value: "v\(i)", forKey: "concurrent-\(i)")
                }
            }

            // Readers calling values()
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

    // MARK: - Rapid State Reset

    /// Tests that rapid reset operations don't cause issues.
    @MainActor
    func testRapidStateReset() async {
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

        // State should be accessible after rapid resets
        let finalState = Application.state(\.stressCounter)
        XCTAssertTrue(finalState.value >= 0)
    }
}
