import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif
import XCTest
@testable import AppState

fileprivate extension Application {
    var isLoading: State<Bool> {
        state(initial: false)
    }
    
    var username: State<String> {
        state(initial: "Leif")
    }
    
    var date: State<Date> {
        state(initial: Date())
    }
    
    var colors: State<[String: String]> {
        state(initial: ["primary": "#A020F0"])
    }

    var count: State<Int> {
        state(initial: 42)
    }

    var piValue: State<Double> {
        state(initial: 3.14159)
    }

    var customStruct: State<TestStruct> {
        state(initial: TestStruct(id: 1, name: "InitialStruct"))
    }

    var customEnum: State<TestEnum> {
        state(initial: .caseA)
    }
}

fileprivate struct TestStruct: Equatable, Codable {
    let id: Int
    let name: String
}

fileprivate enum TestEnum: Equatable, Codable {
    case caseA
    case caseB(String)
}

@MainActor
fileprivate class ExampleViewModel {
    @AppState(\.username) var username
    
    func testPropertyWrapper() {
        username = "Hello, ExampleView"
    }
}

#if !os(Linux) && !os(Windows)
extension ExampleViewModel: ObservableObject { }

fileprivate struct ExampleView: View {
    @AppState(\.username) var username
    @AppState(\.isLoading) var isLoading
    
    func testPropertyWrappers() {
        username = "Hello, ExampleView"
        #if !os(Linux) && !os(Windows)
        _ = Toggle(isOn: $isLoading) {
            Text("Is Loading")
        }
        #endif
    }
    
    var body: some View { EmptyView() }
}
#else
@MainActor
fileprivate struct ExampleView {
    @AppState(\.username) var username
    @AppState(\.isLoading) var isLoading
    
    func testPropertyWrappers() {
        username = "Hello, ExampleView"
    }
}
#endif

final class AppStateTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        Application.logging(isEnabled: true)
    }

    @MainActor
    override func tearDown() async throws {
        let applicationDescription = Application.description
        Application.logger.debug("AppStateTests \(applicationDescription)")
        
        var username: Application.State = Application.state(\.username)
        
        username.value = "Leif"
    }

    @MainActor
    func testState() async {
        var appState: Application.State = Application.state(\.username)
        
        XCTAssertEqual(appState.value, "Leif")
        
        appState.value = "0xL"
        
        XCTAssertEqual(appState.value, "0xL")
        XCTAssertEqual(Application.state(\.username).value, "0xL")
    }

    @MainActor
    func testStateClosureCachesValueOnGet() async {
        let dateState: Application.State = Application.state(\.date)
        
        let copyOfDateState: Application.State = Application.state(\.date)
        
        XCTAssertEqual(copyOfDateState.value, dateState.value)
    }

    @MainActor
    func testPropertyWrappers() async {
        let exampleView = ExampleView()
        
        XCTAssertEqual(exampleView.username, "Leif")
        
        exampleView.testPropertyWrappers()
        
        XCTAssertEqual(exampleView.username, "Hello, ExampleView")
        
        let viewModel = ExampleViewModel()
        
        XCTAssertEqual(viewModel.username, "Hello, ExampleView")
        
        viewModel.username = "Hello, ViewModel"
        
        XCTAssertEqual(viewModel.username, "Hello, ViewModel")
    }

    @MainActor
    func testStateWithDifferentDataTypes() async {
        // Test Int
        var countState: Application.State<Int> = Application.state(\.count)
        XCTAssertEqual(countState.value, 42)
        countState.value = 100
        XCTAssertEqual(Application.state(\.count).value, 100)

        // Test Double
        var piState: Application.State<Double> = Application.state(\.piValue)
        XCTAssertEqual(piState.value, 3.14159)
        piState.value = 3.14
        XCTAssertEqual(Application.state(\.piValue).value, 3.14)

        // Test Dictionary
        var colorsState: Application.State<[String: String]> = Application.state(\.colors)
        XCTAssertEqual(colorsState.value["primary"], "#A020F0")
        colorsState.value["secondary"] = "#FFFFFF"
        XCTAssertEqual(Application.state(\.colors).value["secondary"], "#FFFFFF")

        // Test Custom Struct
        var structState: Application.State<TestStruct> = Application.state(\.customStruct)
        XCTAssertEqual(structState.value, TestStruct(id: 1, name: "InitialStruct"))
        structState.value = TestStruct(id: 2, name: "UpdatedStruct")
        XCTAssertEqual(Application.state(\.customStruct).value, TestStruct(id: 2, name: "UpdatedStruct"))

        // Test Custom Enum
        var enumState: Application.State<TestEnum> = Application.state(\.customEnum)
        XCTAssertEqual(enumState.value, .caseA)
        enumState.value = .caseB("TestValue")
        XCTAssertEqual(Application.state(\.customEnum).value, .caseB("TestValue"))
    }

    @MainActor
    func testInitialValueClosureIsCalledOnce() async {
        var callCount = 0
        let initialValueClosure: () -> Int = {
            callCount += 1
            return 123
        }

        // Define a unique key for this test state
        let testKey = "testInitialValueClosureKey"

        // First access - closure should be called
        XCTAssertEqual(Application.shared.state(initial: initialValueClosure(), id: testKey).value, 123)
        XCTAssertEqual(callCount, 1, "Initial value closure should be called on first access.")

        // Second access - closure should not be called, value should be cached
        XCTAssertEqual(Application.shared.state(initial: initialValueClosure(), id: testKey).value, 123)
        XCTAssertEqual(callCount, 1, "Initial value closure should not be called on subsequent access if cached.")

        // Reset for next part of test: remove the value from cache
        Application.shared.cache.removeValue(forKey: testKey)
        callCount = 0 // Reset call count

        // Re-access to ensure closure is called again if not cached
        XCTAssertEqual(Application.shared.state(initial: initialValueClosure(), id: testKey).value, 123)
        XCTAssertEqual(callCount, 1, "Initial value closure should be called again if the value was removed from cache.")
    }

    @MainActor
    func testLoggingToggle() {
        // Assuming default is true from setUp
        XCTAssertTrue(Application.isLoggingEnabled)
        Application.logger.debug("This should be logged from testLoggingToggle.")

        Application.logging(isEnabled: false)
        XCTAssertFalse(Application.isLoggingEnabled)
        Application.logger.debug("This should NOT be logged from testLoggingToggle.") // This won't be asserted, just for manual check if needed

        Application.logging(isEnabled: true)
        XCTAssertTrue(Application.isLoggingEnabled)
        Application.logger.debug("This should be logged again from testLoggingToggle.")
    }

    @MainActor
    func testConcurrentWrites() async {
        let iterations = 1000
        let concurrentWriters = 5
        let keyPath = \Application.count
        let targetValueBase = 999

        var countState = await Application.state(keyPath) // Must await due to @MainActor
        await MainActor.run { countState.value = 0 }      // Ensure mutation is on MainActor

        await withTaskGroup(of: Void.self) { group in
            for writerId in 0..<concurrentWriters {
                group.addTask { // These tasks are nonisolated
                    for i in 0..<iterations {
                        let valueToWrite = targetValueBase + writerId
                        // Perform state mutation on the MainActor
                        await MainActor.run {
                            var state = Application.state(keyPath) // Application.state is @MainActor
                            state.value = valueToWrite             // State.value is @MainActor
                        }

                        if i % 10 == 0 { await Task.yield() }
                    }
                }
            }
        }

        // After all writes, the value should be one of the values written by the writers.
        let finalValueState = await Application.state(keyPath) // Access on MainActor
        let finalValue = await finalValueState.value
        let possibleValues = (0..<concurrentWriters).map { targetValueBase + $0 }
        XCTAssertTrue(possibleValues.contains(finalValue), "Final value \(finalValue) is not one of the expected written values \(possibleValues). This might indicate a race condition in the set operation or the test logic itself.")
    }

    @MainActor
    func testConcurrentReadsAndWrites() async {
        let keyPath = \Application.username
        let writeValuePrefix = "ConsistentValue"
        let iterations = 1000
        let numReaders = 5

        var usernameState = await Application.state(keyPath) // Must await
        await MainActor.run { usernameState.value = "Initial" } // Mutate on MainActor

        await withTaskGroup(of: Void.self) { group in
            // Writer Task
            group.addTask { // nonisolated task
                for i in 0..<iterations {
                    await MainActor.run {
                        var state = Application.state(keyPath)
                        state.value = "\(writeValuePrefix)_\(i)"
                    }
                    if i % 10 == 0 { await Task.yield() }
                }
                await MainActor.run {
                    var finalState = Application.state(keyPath)
                    finalState.value = "FinalStableValue"
                }
                // print("Writer finished, set to FinalStableValue") // Best to avoid print in tests
            }

            // Reader Tasks
            for readerId in 0..<numReaders {
                group.addTask { // nonisolated task
                    var reads = 0
                    var sawFinal = false
                    while reads < iterations {
                        let currentValue = await MainActor.run { Application.state(keyPath).value }
                        XCTAssertNotNil(currentValue, "Reader \(readerId) read a nil value unexpectedly.")
                        if currentValue == "FinalStableValue" {
                            sawFinal = true
                            break
                        }
                        reads += 1
                        await Task.yield()
                    }

                    if !sawFinal { // If not seen during loop, poll a bit
                        for _ in 0..<20 { // Increased polling attempts
                            await MainActor.run { // Ensure read is on MainActor
                                if Application.state(keyPath).value == "FinalStableValue" {
                                    sawFinal = true
                                }
                            }
                            if sawFinal { break }
                            do {
                                try await Task.sleep(nanoseconds: 20_000_000) // 20ms, allow writer to complete
                            } catch {
                                XCTFail("Task.sleep threw an error: \(error)")
                            }
                        }
                    }
                    await MainActor.run { // Final assertion on MainActor
                        XCTAssertEqual(Application.state(keyPath).value, "FinalStableValue", "Reader \(readerId) did not observe 'FinalStableValue' as the final state.")
                    }
                }
            }
        }

        // Final assertion after task group completion
        let finalAssertState = await Application.state(keyPath)
        let finalValue = await finalAssertState.value
        XCTAssertEqual(finalValue, "FinalStableValue", "The final state was not the expected 'FinalStableValue'.")
    }
}
