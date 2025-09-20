import Foundation
import XCTest
@testable import AppState

/// Thread safety and concurrency tests for AppState

@MainActor
fileprivate extension Application {
    var concurrencyCounter: State<Int> {
        state(initial: 0)
    }
    
    var concurrencyMessage: State<String> {
        state(initial: "initial")
    }
    
    var concurrencyData: State<[String: String]> {
        state(initial: [:])
    }
    
    var concurrencyStoredCounter: StoredState<Int> {
        storedState(initial: 0, id: "concurrency_stored_counter")
    }
    
    // Dependencies that contain AppState internally
    var statefulService: Dependency<StatefulService> {
        dependency(StatefulService())
    }
    
    var statefulManager: Dependency<StatefulManager> {
        dependency(StatefulManager())
    }
    
    // Realistic service with FileState
    var stopwatchService: Dependency<StopwatchService> {
        dependency(StopwatchService())
    }
    
    // AppState for the service
    var serviceData: State<[String: String]> {
        state(initial: [:])
    }
    
    var serviceCounter: State<Int> {
        state(initial: 0)
    }
    
    // AppState for the manager
    var managerOperations: State<[String]> {
        state(initial: [])
    }
    
    var managerCoordinationCount: State<Int> {
        state(initial: 0)
    }
    
    // AppState for operation counts - stress test caching
    var serviceOperationCount: State<Int> {
        state(initial: 0)
    }
    
    var managerOperationCount: State<Int> {
        state(initial: 0)
    }
    
    // FileState for persistent service data
    var stopwatchState: FileState<StopwatchAppletState> {
        fileState(initial: StopwatchAppletState(), filename: "stopwatch_state")
    }
    
    var serviceMetrics: FileState<ServiceMetrics> {
        fileState(initial: ServiceMetrics(), filename: "service_metrics")
    }
}

// MARK: - Test Support Data Structures

/// Realistic stopwatch state that would be persisted to file
public struct StopwatchAppletState: Codable, Sendable, Equatable {
    var isRunning: Bool = false
    var startTime: Date?
    var elapsedTime: TimeInterval = 0
    var lapTimes: [TimeInterval] = []
    var totalLaps: Int = 0
    
    mutating func start() {
        isRunning = true
        startTime = Date()
    }
    
    mutating func stop() {
        isRunning = false
        if let start = startTime {
            elapsedTime += Date().timeIntervalSince(start)
        }
        startTime = nil
    }
    
    mutating func addLap() {
        if isRunning, let start = startTime {
            let lapTime = Date().timeIntervalSince(start)
            lapTimes.append(lapTime)
            totalLaps += 1
            startTime = Date() // Reset for next lap
        }
    }
    
    mutating func reset() {
        isRunning = false
        startTime = nil
        elapsedTime = 0
        lapTimes.removeAll()
        totalLaps = 0
    }
}

/// Service metrics for tracking performance
public struct ServiceMetrics: Codable, Sendable, Equatable {
    var totalOperations: Int = 0
    var averageResponseTime: TimeInterval = 0
    var lastUpdated: Date = Date()
    var errorCount: Int = 0
    var successCount: Int = 0
    
    mutating func recordOperation(responseTime: TimeInterval, success: Bool) {
        totalOperations += 1
        if success {
            successCount += 1
        } else {
            errorCount += 1
        }
        
        // Update average response time
        averageResponseTime = (averageResponseTime * Double(totalOperations - 1) + responseTime) / Double(totalOperations)
        lastUpdated = Date()
    }
}

// MARK: - Test Support Classes for Dependencies with AppState

/// A service that contains AppState internally and manages its own state
@MainActor
final class StatefulService: ObservableObject, @unchecked Sendable {
    @AppState(\.serviceOperationCount) var operationCount: Int
    @AppState(\.serviceData) var serviceData: [String: String]
    @AppState(\.serviceCounter) var serviceCounter: Int
    
    func performOperation() {
        operationCount += 1
    }
    
    // Service methods that interact with AppState
    func updateServiceData(_ key: String, value: String) {
        serviceData[key] = value
    }
    
    func incrementServiceCounter() {
        serviceCounter += 1
    }
    
    func getServiceData() -> [String: String] {
        serviceData
    }
    
    func getServiceCounter() -> Int {
        serviceCounter
    }
}

/// A manager (view model) that contains AppState and coordinates with the StatefulService
@MainActor
final class StatefulManager: ObservableObject, @unchecked Sendable {
    @AppState(\.managerOperationCount) var operationCount: Int
    @AppState(\.managerOperations) var managerOperations: [String]
    @AppState(\.managerCoordinationCount) var managerCoordinationCount: Int
    
    // Manager methods that interact with AppState and the service
    func recordOperation(_ operation: String) {
        managerOperations.append("\(operation) at \(Date().timeIntervalSince1970)")
        operationCount += 1
    }
    
    func coordinate() {
        managerCoordinationCount += 1
    }
    
    func getManagerOperations() -> [String] {
        managerOperations
    }
    
    func getManagerCoordinationCount() -> Int {
        managerCoordinationCount
    }
    
    // Manager coordinates with the service
    func coordinateWithService(_ service: StatefulService, operation: String) {
        // Record the operation in manager's AppState
        recordOperation(operation)
        
        // Update service's AppState
        service.performOperation()  // This increments serviceOperationCount
        service.updateServiceData("manager_operation", value: operation)
        service.incrementServiceCounter()
        
        // Coordinate
        coordinate()
    }
}

/// Realistic service that uses @FileState for persistence
@MainActor
public final class StopwatchService: ObservableObject {
    @FileState(\.stopwatchState) public var state: StopwatchAppletState
    @FileState(\.serviceMetrics) public var metrics: ServiceMetrics
    
    private var _operationCount = 0
    
    public init() {}
    
    var operationCount: Int {
        _operationCount
    }
    
    // Stopwatch operations
    func startStopwatch() {
        state.start()
        _operationCount += 1
    }
    
    func stopStopwatch() {
        state.stop()
        _operationCount += 1
    }
    
    func addLap() {
        state.addLap()
        _operationCount += 1
    }
    
    func resetStopwatch() {
        state.reset()
        _operationCount += 1
    }
    
    func recordMetrics(responseTime: TimeInterval, success: Bool) {
        metrics.recordOperation(responseTime: responseTime, success: success)
    }
    
    func getStopwatchState() -> StopwatchAppletState {
        state
    }
    
    func getMetrics() -> ServiceMetrics {
        metrics
    }
}

final class ConcurrencyTests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        
        await MainActor.run {
            Application.reset(\.concurrencyCounter)
            Application.reset(\.concurrencyMessage)
            
            // Reset FileState between tests to prevent interference
            var stopwatchState = Application.fileState(\.stopwatchState)
            stopwatchState.value = StopwatchAppletState()
            
            var serviceMetrics = Application.fileState(\.serviceMetrics)
            serviceMetrics.value = ServiceMetrics()
            Application.reset(\.concurrencyData)
            Application.reset(\.concurrencyStoredCounter)
            Application.reset(\.serviceData)
            Application.reset(\.serviceCounter)
            Application.reset(\.managerOperations)
            Application.reset(\.managerCoordinationCount)
            Application.reset(\.serviceOperationCount)
            Application.reset(\.managerOperationCount)
            Application.reset(\.stopwatchState)
            Application.reset(\.serviceMetrics)
            Application.logging(isEnabled: true)
        }
    }
    
    // MARK: - Basic State Concurrency Tests
    
    func testStateConcurrency() async {
        let tasks = 10
        let iterations = 100
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        await MainActor.run {
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value = counter.value + 1
                        }
                    }
                }
            }
        }
        
        await MainActor.run {
            let finalValue = Application.state(\.concurrencyCounter).value
            XCTAssertEqual(finalValue, tasks * iterations, "Counter should equal total operations")
        }
    }
    
    func testStateReadWriteConcurrency() async {
        let readTasks = 5
        let writeTasks = 5
        let iterations = 50
        
        await withTaskGroup(of: Void.self) { group in
            // Read tasks
            for _ in 0..<readTasks {
                group.addTask {
                    for _ in 0..<iterations {
                        await MainActor.run {
                            let _ = Application.state(\.concurrencyMessage).value
                        }
                        try? await Task.sleep(nanoseconds: 100_000) // 0.1ms
                    }
                }
            }
            
            // Write tasks
            for _ in 0..<writeTasks {
                group.addTask {
                    for _ in 0..<iterations {
                        await MainActor.run {
                            var message = Application.state(\.concurrencyMessage)
                            message.value = "task_\(Int.random(in: 0...999))_iteration_\(Int.random(in: 0...999))"
                        }
                        try? await Task.sleep(nanoseconds: 50_000) // 0.05ms
                    }
                }
            }
        }
        
        await MainActor.run {
            let finalMessage = Application.state(\.concurrencyMessage).value
            XCTAssertTrue(finalMessage.hasPrefix("task_"), "Message should have been written")
        }
    }
    
    func testComplexStateConcurrency() async {
        let tasks = 8
        let iterations = 50
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        await MainActor.run {
                            // Read and update multiple states
                            let currentData = Application.state(\.concurrencyData).value
                            var newData = currentData
                            newData["task_\(Int.random(in: 0...999))"] = "iteration_\(Int.random(in: 0...999))"
                            var data = Application.state(\.concurrencyData)
                            data.value = newData
                            
                            // Update counter
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value = counter.value + 1
                        }
                        
                        try? await Task.sleep(nanoseconds: 10_000) // 0.01ms
                    }
                }
            }
        }
        
        await MainActor.run {
            let finalData = Application.state(\.concurrencyData).value
            let finalCounter = Application.state(\.concurrencyCounter).value
            
            XCTAssertEqual(finalCounter, tasks * iterations, "Counter should equal total operations")
            XCTAssertTrue(finalData.count > 0, "Data should contain values")
        }
    }
    
    // MARK: - StoredState Concurrency Tests
    
    func testStoredStateConcurrency() async {
        let tasks = 5
        let iterations = 20
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        await MainActor.run {
                            let currentCounter = Application.storedState(\.concurrencyStoredCounter).value
                            var storedCounter = Application.storedState(\.concurrencyStoredCounter)
                            storedCounter.value = currentCounter + 1
                        }
                        
                        try? await Task.sleep(nanoseconds: 20_000) // 0.02ms
                    }
                }
            }
        }
        
        await MainActor.run {
            let finalCounter = Application.storedState(\.concurrencyStoredCounter).value
            XCTAssertEqual(finalCounter, tasks * iterations, "Stored counter should equal total operations")
        }
    }
    
    // MARK: - Race Condition Tests
    
    func testRaceConditionPrevention() async {
        let tasks = 15
        let iterations = 30
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        // Simulate processing delay
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 1000...5000))
                        
                        // Use atomic increment to prevent race conditions
                        await MainActor.run {
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value += 1  // Atomic increment
                        }
                    }
                }
            }
        }
        
        await MainActor.run {
            let finalValue = Application.state(\.concurrencyCounter).value
            XCTAssertEqual(finalValue, tasks * iterations, "No race conditions should have occurred")
        }
    }
    
    func testDeadlockPrevention() async {
        let tasks = 8
        let iterations = 15
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        await MainActor.run {
                            // Access multiple states in different orders
                            let counter = Application.state(\.concurrencyCounter).value
                            let _ = Application.state(\.concurrencyMessage).value
                            
                            // Update states
                            var counterState = Application.state(\.concurrencyCounter)
                            counterState.value = counter + 1
                            var messageState = Application.state(\.concurrencyMessage)
                            messageState.value = "deadlock_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))"
                        }
                        
                        try? await Task.sleep(nanoseconds: 1_000) // 0.001ms
                    }
                }
            }
        }
        
        // If we reach here without hanging, deadlock prevention is working
        await MainActor.run {
            let finalCounter = Application.state(\.concurrencyCounter).value
            XCTAssertEqual(finalCounter, tasks * iterations, "All operations should complete")
        }
    }
    
    // MARK: - Performance Tests
    
    func testHighConcurrencyPerformance() async {
        let tasks = 20
        let iterations = 50
        let startTime = Date()
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        await MainActor.run {
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value = counter.value + 1
                        }
                    }
                }
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, 3.0, "High concurrency should complete within reasonable time")
        
        await MainActor.run {
            let finalCounter = Application.state(\.concurrencyCounter).value
            XCTAssertEqual(finalCounter, tasks * iterations, "All operations should complete")
        }
    }
    
    // MARK: - Dependencies with AppState Tests
    
    func testDependencyWithAppStateConcurrency() async {
        let tasks = 15
        let iterations = 20
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        // Access dependencies that contain AppState
                        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
                        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
                        
                        // Perform operations on dependencies with AppState
                        await MainActor.run {
                            statefulService.performOperation()
                            statefulService.updateServiceData("task_\(Int.random(in: 0...999))", value: "iteration_\(Int.random(in: 0...999))")
                            statefulService.incrementServiceCounter()
                            
                            statefulManager.recordOperation("operation_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))")
                            statefulManager.coordinate()
                        }
                        
                        // Also update external AppState
                        await MainActor.run {
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value = counter.value + 1
                            
                            var message = Application.state(\.concurrencyMessage)
                            message.value = "dependency_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))"
                        }
                        
                        try? await Task.sleep(nanoseconds: 5_000) // 0.005ms
                    }
                }
            }
        }
        
        // Verify dependencies worked correctly
        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        let finalMessage = await MainActor.run { Application.state(\.concurrencyMessage).value }
        let serviceData = await MainActor.run { statefulService.getServiceData() }
        let serviceCounter = await MainActor.run { statefulService.getServiceCounter() }
        let managerOperations = await MainActor.run { statefulManager.getManagerOperations() }
        let managerCoordinationCount = await MainActor.run { statefulManager.getManagerCoordinationCount() }
        
        let serviceOperationCount = await MainActor.run { statefulService.operationCount }
        XCTAssertTrue(serviceOperationCount > 0, "Stateful service should have performed operations")
        XCTAssertTrue(serviceData.count > 0, "Stateful service should have AppState data")
        XCTAssertTrue(serviceCounter > 0, "Stateful service should have incremented counter")
        XCTAssertTrue(managerOperations.count > 0, "Stateful manager should have recorded operations")
        XCTAssertTrue(managerCoordinationCount > 0, "Stateful manager should have coordinated")
        XCTAssertEqual(finalCounter, tasks * iterations, "External counter should equal total operations")
        XCTAssertTrue(finalMessage.hasPrefix("dependency_"), "External message should have been updated")
    }
    
    func testDependencyAppStateInteraction() async {
        let tasks = 12
        let iterations = 15
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
                        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
                        
                        // Complex interaction: dependencies read external state, update their AppState
                        let externalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
                        let externalMessage = await MainActor.run { Application.state(\.concurrencyMessage).value }
                        
                        // Update service AppState based on external state
                        await statefulService.updateServiceData("external_counter", value: "\(externalCounter)")
                        await statefulService.updateServiceData("external_message", value: externalMessage)
                        await statefulService.incrementServiceCounter()
                        
                        // Record the interaction in manager AppState
                        await statefulManager.recordOperation("interaction_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))")
                        await statefulManager.coordinate()
                        
                        // Update external state based on dependency operations
                        await MainActor.run {
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value = counter.value + 1
                            
                            var data = Application.state(\.concurrencyData)
                            var newData = data.value
                            newData["dependency_\(Int.random(in: 0...999))"] = "iteration_\(Int.random(in: 0...999))"
                            data.value = newData
                        }
                        
                        try? await Task.sleep(nanoseconds: 3_000) // 0.003ms
                    }
                }
            }
        }
        
        // Verify complex interaction worked
        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        let finalData = await MainActor.run { Application.state(\.concurrencyData).value }
        let serviceData = await statefulService.getServiceData()
        let managerOperations = await statefulManager.getManagerOperations()
        
        XCTAssertTrue(serviceData.count > 0, "Service should have AppState data")
        XCTAssertTrue(managerOperations.count > 0, "Manager should have recorded operations")
        XCTAssertEqual(finalCounter, tasks * iterations, "External counter should equal total operations")
        XCTAssertTrue(finalData.count > 0, "External data should contain values")
    }
    
    func testRealisticServiceManagerArchitecture() async {
        let tasks = 10
        let iterations = 20
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
                        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
                        
                        // Realistic scenario: Manager coordinates with Service
                        await MainActor.run {
                            statefulManager.coordinateWithService(
                                statefulService, 
                                operation: "task_\(Int.random(in: 0...999))_iteration_\(Int.random(in: 0...999))"
                            )
                        }
                        
                        // Also update external AppState
                        await MainActor.run {
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value = counter.value + 1
                        }
                        
                        try? await Task.sleep(nanoseconds: 2_000) // 0.002ms
                    }
                }
            }
        }
        
        // Verify the realistic architecture worked
        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        let serviceData = await MainActor.run { statefulService.getServiceData() }
        let serviceCounter = await MainActor.run { statefulService.getServiceCounter() }
        let managerOperations = await MainActor.run { statefulManager.getManagerOperations() }
        let managerCoordinationCount = await MainActor.run { statefulManager.getManagerCoordinationCount() }
        
        XCTAssertTrue(serviceData.count > 0, "Service should have AppState data")
        XCTAssertTrue(serviceCounter > 0, "Service should have incremented counter")
        XCTAssertTrue(managerOperations.count > 0, "Manager should have recorded operations")
        XCTAssertTrue(managerCoordinationCount > 0, "Manager should have coordinated")
        XCTAssertEqual(finalCounter, tasks * iterations, "External counter should equal total operations")
        
        // Verify the service has manager operations stored
        XCTAssertTrue(serviceData["manager_operation"] != nil, "Service should have manager operation data")
    }
    
    func testDependencyStatefulServiceStressTest() async {
        let tasks = 20
        let iterations = 25
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
                        
                        // Stress test: rapid operations on dependency with internal state
                        await MainActor.run {
                            statefulService.performOperation()
                        }
                        await MainActor.run {
                            statefulService.updateServiceData("stress_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))", value: "value_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))")
                        }
                        
                        // Also access external state
                        let _ = await MainActor.run { Application.state(\.concurrencyCounter).value }
                        let _ = await MainActor.run { Application.state(\.concurrencyMessage).value }
                        
                        // Update external state
                        await MainActor.run {
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value = counter.value + 1
                        }
                        
                        try? await Task.sleep(nanoseconds: 1_000) // 0.001ms
                    }
                }
            }
        }
        
        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        let serviceData = await statefulService.getServiceData()
        
        let serviceOperationCount = await MainActor.run { statefulService.operationCount }
        XCTAssertTrue(serviceOperationCount > 0, "Service should have performed operations")
        XCTAssertTrue(serviceData.count > 0, "Service should have AppState data")
        XCTAssertEqual(finalCounter, tasks * iterations, "External counter should equal total operations")
    }
    
    func testDependencyStatefulManagerCoordination() async {
        let tasks = 10
        let iterations = 30
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
                        
                        // Coordination test: manager coordinates between multiple states
                        await statefulManager.recordOperation("coordination_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))")
                        await statefulManager.coordinate()
                        
                        // Update multiple external states
                        await MainActor.run {
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value = counter.value + 1
                            
                            var message = Application.state(\.concurrencyMessage)
                            message.value = "coordinated_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))"
                            
                            var data = Application.state(\.concurrencyData)
                            var newData = data.value
                            newData["coordinated_\(Int.random(in: 0...999))"] = "iteration_\(Int.random(in: 0...999))"
                            data.value = newData
                        }
                        
                        try? await Task.sleep(nanoseconds: 2_000) // 0.002ms
                    }
                }
            }
        }
        
        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        let finalMessage = await MainActor.run { Application.state(\.concurrencyMessage).value }
        let finalData = await MainActor.run { Application.state(\.concurrencyData).value }
        
        let managerOperations = await statefulManager.getManagerOperations()
        let managerCoordinationCount = await statefulManager.getManagerCoordinationCount()
        XCTAssertTrue(managerOperations.count > 0, "Manager should have recorded operations")
        XCTAssertTrue(managerCoordinationCount > 0, "Manager should have coordinated")
        XCTAssertEqual(finalCounter, tasks * iterations, "Counter should equal total operations")
        XCTAssertTrue(finalMessage.hasPrefix("coordinated_"), "Message should have been coordinated")
        XCTAssertTrue(finalData.count > 0, "Data should contain coordinated values")
    }
    
    func testDependencyRaceConditionPrevention() async {
        let tasks = 25
        let iterations = 20
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        // Simulate processing delay
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 1000...5000))
                        
                        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
                        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
                        
                        // Update both dependency and external state atomically
                        await MainActor.run {
                            let currentCounter = Application.state(\.concurrencyCounter).value
                            statefulService.updateServiceData("race_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))", value: "\(currentCounter)")
                            statefulManager.recordOperation("race_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))")
                            
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value += 1  // Atomic increment
                        }
                    }
                }
            }
        }
        
        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        
        let serviceData = await statefulService.getServiceData()
        let managerOperations = await statefulManager.getManagerOperations()
        XCTAssertTrue(serviceData.count > 0, "Service should have AppState data")
        XCTAssertTrue(managerOperations.count > 0, "Manager should have recorded operations")
        XCTAssertEqual(finalCounter, tasks * iterations, "No race conditions should have occurred")
    }
    
    func testDependencyDeadlockPrevention() async {
        let tasks = 15
        let iterations = 10
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        // Complex access pattern that could cause deadlocks
                        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
                        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
                        
                        // Access multiple states and dependencies in different orders
                        await MainActor.run {
                            let _ = Application.state(\.concurrencyCounter).value
                            let _ = Application.state(\.concurrencyMessage).value
                            
                            // Update dependencies
                            statefulService.performOperation()
                            statefulService.updateServiceData("deadlock_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))", value: "value_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))")
                            statefulManager.recordOperation("deadlock_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))")
                            statefulManager.coordinate()
                            
                            // Update external states atomically
                            var counterState = Application.state(\.concurrencyCounter)
                            counterState.value += 1  // Atomic increment
                            
                            var messageState = Application.state(\.concurrencyMessage)
                            messageState.value = "deadlock_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))"
                        }
                        
                        try? await Task.sleep(nanoseconds: 1_000) // 0.001ms
                    }
                }
            }
        }
        
        // If we reach here without hanging, deadlock prevention is working
        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        
        let managerOperations = await statefulManager.getManagerOperations()
        let serviceOperationCount = await MainActor.run { statefulService.operationCount }
        XCTAssertTrue(serviceOperationCount > 0, "Service should have performed operations")
        XCTAssertTrue(managerOperations.count > 0, "Manager should have recorded operations")
        XCTAssertEqual(finalCounter, tasks * iterations, "All operations should complete")
    }
    
    // MARK: - AppState Caching Stress Tests
    
    func testAppStateCachingStressTest() async {
        let tasks = 20
        let iterations = 50
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        // Get dependencies that use AppState internally
                        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
                        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
                        
                        // Stress test: Rapid AppState access and updates
                        await MainActor.run {
                            // Service operations - all using AppState
                            statefulService.performOperation()
                            statefulService.updateServiceData("stress_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))", value: "value_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))")
                            statefulService.incrementServiceCounter()
                            
                            // Manager operations - all using AppState
                            statefulManager.recordOperation("stress_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))")
                            statefulManager.coordinate()
                            
                            // Direct AppState access to stress caching
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value = counter.value + 1
                            
                            var message = Application.state(\.concurrencyMessage)
                            message.value = "task_\(Int.random(in: 0...999))_iteration_\(Int.random(in: 0...999))"
                            
                            var data = Application.state(\.concurrencyData)
                            var dataValue = data.value
                            dataValue["key_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))"] = "value_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))"
                            data.value = dataValue
                        }
                        
                        // Read AppState values to stress caching
                        let _ = await MainActor.run { Application.state(\.concurrencyCounter).value }
                        let _ = await MainActor.run { Application.state(\.concurrencyMessage).value }
                        let _ = await MainActor.run { Application.state(\.concurrencyData).value }
                        let _ = await MainActor.run { statefulService.operationCount }
                        let _ = await MainActor.run { statefulManager.operationCount }
                        
                        try? await Task.sleep(nanoseconds: 1_000)
                    }
                }
            }
        }
        
        // Verify all AppState operations completed
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        let finalMessage = await MainActor.run { Application.state(\.concurrencyMessage).value }
        let finalData = await MainActor.run { Application.state(\.concurrencyData).value }
        let serviceOperationCount = await MainActor.run { Application.state(\.serviceOperationCount).value }
        let managerOperationCount = await MainActor.run { Application.state(\.managerOperationCount).value }
        
        XCTAssertEqual(finalCounter, tasks * iterations, "All operations should complete")
        XCTAssertTrue(finalMessage.contains("task_"), "Message should be updated")
        XCTAssertTrue(finalData.count > 0, "Data should be populated")
        XCTAssertTrue(serviceOperationCount > 0, "Service should have operations")
        XCTAssertTrue(managerOperationCount > 0, "Manager should have operations")
    }
    
    func testAppStateServiceManagerCoordination() async {
        let tasks = 15
        let iterations = 30
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        // Get dependencies that coordinate via AppState
                        let statefulService = await MainActor.run { Application.dependency(\.statefulService) }
                        let statefulManager = await MainActor.run { Application.dependency(\.statefulManager) }
                        
                        // Complex coordination using AppState
                        await MainActor.run {
                            // Manager coordinates with service - both use AppState
                            statefulManager.coordinateWithService(
                                statefulService, 
                                operation: "coordination_\(Int.random(in: 0...999))_\(Int.random(in: 0...999))"
                            )
                            
                            // Additional AppState stress
                            var counter = Application.state(\.concurrencyCounter)
                            counter.value = counter.value + 1
                        }
                        
                        // Read multiple AppState values to stress caching
                        let _ = await MainActor.run { Application.state(\.concurrencyCounter).value }
                        let _ = await MainActor.run { statefulService.getServiceData() }
                        let _ = await MainActor.run { statefulService.getServiceCounter() }
                        let _ = await MainActor.run { statefulManager.getManagerOperations() }
                        let _ = await MainActor.run { statefulManager.getManagerCoordinationCount() }
                        
                        try? await Task.sleep(nanoseconds: 2_000)
                    }
                }
            }
        }
        
        // Verify coordination worked through AppState
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        let serviceData = await MainActor.run { Application.state(\.serviceData).value }
        let serviceCounter = await MainActor.run { Application.state(\.serviceCounter).value }
        let managerOperations = await MainActor.run { Application.state(\.managerOperations).value }
        let managerCoordinationCount = await MainActor.run { Application.state(\.managerCoordinationCount).value }
        let serviceOperationCount = await MainActor.run { Application.state(\.serviceOperationCount).value }
        let managerOperationCount = await MainActor.run { Application.state(\.managerOperationCount).value }
        
        XCTAssertEqual(finalCounter, tasks * iterations, "All operations should complete")
        XCTAssertTrue(serviceData.count > 0, "Service should have data from coordination")
        XCTAssertTrue(serviceCounter > 0, "Service should have counter updates")
        XCTAssertTrue(managerOperations.count > 0, "Manager should have operations")
        XCTAssertTrue(managerCoordinationCount > 0, "Manager should have coordination")
        XCTAssertTrue(serviceOperationCount > 0, "Service should have operation count")
        XCTAssertTrue(managerOperationCount > 0, "Manager should have operation count")
    }

    // MARK: - Cache Deadlock Prevention Tests
    
    /// Test to prevent the specific cache deadlock issue from the stack trace
    /// This tests the scenario where FileState operations cause recursive cache access
    func testCacheDeadlockPrevention() async {
        let tasks = 10
        let iterations = 20
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        // Simulate the exact deadlock scenario from the stack trace
                        // Multiple FileState operations that could cause recursive cache access
                        await MainActor.run {
                            // Access FileState values (like SettingsService.settings)
                            let _ = Application.fileState(\.stopwatchState).value
                            let _ = Application.fileState(\.serviceMetrics).value
                            
                            // Modify FileState values (like AppsAppletState)
                            var stopwatch = Application.fileState(\.stopwatchState)
                            stopwatch.value = StopwatchAppletState(
                                isRunning: true,
                                startTime: Date(),
                                elapsedTime: 0,
                                lapTimes: [],
                                totalLaps: Int.random(in: 1...10)
                            )
                            
                            var metrics = Application.fileState(\.serviceMetrics)
                            metrics.value = ServiceMetrics(
                                totalOperations: Int.random(in: 1...100),
                                averageResponseTime: Double.random(in: 0.001...0.1),
                                lastUpdated: Date(),
                                errorCount: 0,
                                successCount: Int.random(in: 1...100)
                            )
                            
                            // Additional cache operations that could trigger the deadlock
                            let counter = Application.state(\.concurrencyCounter).value
                            var counterState = Application.state(\.concurrencyCounter)
                            counterState.value = counter + 1
                        }
                        
                        // Simulate the timing that could cause the deadlock
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 1000...5000))
                    }
                }
            }
        }
        
        // Verify no deadlock occurred
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        let finalStopwatchState = await MainActor.run { Application.fileState(\.stopwatchState).value }
        let finalMetrics = await MainActor.run { Application.fileState(\.serviceMetrics).value }
        
        XCTAssertEqual(finalCounter, tasks * iterations, "All operations should complete without deadlock")
        XCTAssertTrue(finalStopwatchState.totalLaps > 0, "Stopwatch state should have been updated")
        XCTAssertTrue(finalMetrics.totalOperations > 0, "Metrics should have been updated")
    }
    
    /// Test concurrent FileState operations that could cause cache deadlocks
    func testConcurrentFileStateDeadlockPrevention() async {
        let tasks = 15
        let iterations = 10
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        // Simulate concurrent FileState operations that could deadlock
                        await MainActor.run {
                            // Multiple FileState reads and writes in sequence
                            let stopwatch1 = Application.fileState(\.stopwatchState).value
                            let metrics1 = Application.fileState(\.serviceMetrics).value
                            
                            // Update FileState values
                            var stopwatch = Application.fileState(\.stopwatchState)
                            stopwatch.value = StopwatchAppletState(
                                isRunning: stopwatch1.isRunning,
                                startTime: stopwatch1.startTime,
                                elapsedTime: stopwatch1.elapsedTime,
                                lapTimes: stopwatch1.lapTimes + [Double.random(in: 0.1...10.0)],
                                totalLaps: stopwatch1.totalLaps + 1
                            )
                            
                            var metrics = Application.fileState(\.serviceMetrics)
                            metrics.value = ServiceMetrics(
                                totalOperations: metrics1.totalOperations + 1,
                                averageResponseTime: (metrics1.averageResponseTime + Double.random(in: 0.001...0.1)) / 2,
                                lastUpdated: Date(),
                                errorCount: metrics1.errorCount,
                                successCount: metrics1.successCount + 1
                            )
                            
                            // Additional cache operations
                            let counter = Application.state(\.concurrencyCounter).value
                            var counterState = Application.state(\.concurrencyCounter)
                            counterState.value = counter + 1
                        }
                        
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 500...2000))
                    }
                }
            }
        }
        
        // Verify no deadlock occurred
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        let finalStopwatch = await MainActor.run { Application.fileState(\.stopwatchState).value }
        let finalMetrics = await MainActor.run { Application.fileState(\.serviceMetrics).value }
        
        XCTAssertEqual(finalCounter, tasks * iterations, "All operations should complete without deadlock")
        XCTAssertTrue(finalStopwatch.totalLaps > 0, "Stopwatch should have laps")
        XCTAssertTrue(finalMetrics.totalOperations > 0, "Metrics should have operations")
    }
    
    /// Test the specific deadlock scenario from the stack trace
    /// This tests FileState operations that could cause recursive cache access
    func testFileStateRecursiveCacheDeadlock() async {
        let tasks = 8
        let iterations = 15
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        // Simulate the exact scenario from the stack trace
                        await MainActor.run {
                            // This simulates the deadlock scenario:
                            // 1. FileState.value.getter() calls Cache.get()
                            // 2. While in Cache.get(), another operation calls Cache.set()
                            // 3. This creates a recursive lock deadlock
                            
                            // Read FileState values (triggers Cache.get)
                            let _ = Application.fileState(\.stopwatchState).value
                            let _ = Application.fileState(\.serviceMetrics).value
                            
                            // Update FileState values (triggers Cache.set while Cache.get is still active)
                            var stopwatch = Application.fileState(\.stopwatchState)
                            stopwatch.value = StopwatchAppletState(
                                isRunning: true,
                                startTime: Date(),
                                elapsedTime: 0,
                                lapTimes: [],
                                totalLaps: Int.random(in: 1...10)
                            )
                            
                            var metrics = Application.fileState(\.serviceMetrics)
                            metrics.value = ServiceMetrics(
                                totalOperations: Int.random(in: 1...100),
                                averageResponseTime: Double.random(in: 0.001...0.1),
                                lastUpdated: Date(),
                                errorCount: 0,
                                successCount: Int.random(in: 1...100)
                            )
                            
                            // Additional operations that could trigger the deadlock
                            let counter = Application.state(\.concurrencyCounter).value
                            var counterState = Application.state(\.concurrencyCounter)
                            counterState.value = counter + 1
                        }
                        
                        // Simulate the timing that could cause the deadlock
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 1000...3000))
                    }
                }
            }
        }
        
        // Verify no deadlock occurred
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        XCTAssertEqual(finalCounter, tasks * iterations, "All operations should complete without deadlock")
    }
    
    /// Test the specific cache deadlock scenario from the stack trace
    /// This tests the exact conditions that caused the deadlock in the real app
    func testCacheMutexDeadlockPrevention() async {
        let tasks = 12
        let iterations = 8
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        // This test simulates the exact deadlock scenario from the stack trace:
                        // 1. Cache.get() is called and acquires a mutex lock
                        // 2. While holding the lock, another operation tries to call Cache.set()
                        // 3. This creates a deadlock because the same thread is trying to acquire the same lock twice
                        
                        await MainActor.run {
                            // Simulate the deadlock scenario by accessing FileState values
                            // that could trigger recursive cache operations
                            
                            // Read multiple FileState values (triggers Cache.get)
                            let stopwatchState = Application.fileState(\.stopwatchState).value
                            let serviceMetrics = Application.fileState(\.serviceMetrics).value
                            
                            // While the cache is still processing the get operations,
                            // try to set new values (triggers Cache.set)
                            var stopwatch = Application.fileState(\.stopwatchState)
                            stopwatch.value = StopwatchAppletState(
                                isRunning: true,
                                startTime: Date(),
                                elapsedTime: stopwatchState.elapsedTime,
                                lapTimes: stopwatchState.lapTimes + [Double.random(in: 0.1...10.0)],
                                totalLaps: stopwatchState.totalLaps + 1
                            )
                            
                            var metrics = Application.fileState(\.serviceMetrics)
                            metrics.value = ServiceMetrics(
                                totalOperations: serviceMetrics.totalOperations + 1,
                                averageResponseTime: (serviceMetrics.averageResponseTime + Double.random(in: 0.001...0.1)) / 2,
                                lastUpdated: Date(),
                                errorCount: serviceMetrics.errorCount,
                                successCount: serviceMetrics.successCount + 1
                            )
                            
                            // Additional operations that could trigger the deadlock
                            let counter = Application.state(\.concurrencyCounter).value
                            var counterState = Application.state(\.concurrencyCounter)
                            counterState.value = counter + 1
                        }
                        
                        // Simulate the timing that could cause the deadlock
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 1000...4000))
                    }
                }
            }
        }
        
        // Verify no deadlock occurred
        let finalCounter = await MainActor.run { Application.state(\.concurrencyCounter).value }
        let finalStopwatch = await MainActor.run { Application.fileState(\.stopwatchState).value }
        let finalMetrics = await MainActor.run { Application.fileState(\.serviceMetrics).value }
        
        XCTAssertEqual(finalCounter, tasks * iterations, "All operations should complete without deadlock")
        XCTAssertTrue(finalStopwatch.totalLaps > 0, "Stopwatch should have laps")
        XCTAssertTrue(finalMetrics.totalOperations > 0, "Metrics should have operations")
    }

    // MARK: - Realistic FileState Service Tests
    
    func testStopwatchServiceWithFileState() async {
        let tasks = 12
        let iterations = 15
        
        // Get the service instance once to ensure we're using the same instance
        let stopwatchService = await MainActor.run { Application.dependency(\.stopwatchService) }
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        
                        // Realistic stopwatch operations with FileState persistence
                        await MainActor.run {
                            stopwatchService.startStopwatch()
                        }
                        
                        // Simulate some work
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 1000...5000))
                        
                        // Add lap while running
                        await MainActor.run {
                            stopwatchService.addLap()
                        }
                        
                        // Record metrics
                        let responseTime = Double.random(in: 0.001...0.1)
                        let success = Int.random(in: 0...2) % 3 != 0 // Simulate some failures
                        await MainActor.run {
                            stopwatchService.recordMetrics(responseTime: responseTime, success: success)
                        }
                        
                        // Add another lap before stopping
                        await MainActor.run {
                            stopwatchService.addLap()
                            stopwatchService.stopStopwatch()
                        }
                        
                        // Don't reset to ensure laps accumulate
                    }
                }
            }
        }
        
        // Verify the realistic service worked correctly
        let finalState = await MainActor.run { stopwatchService.getStopwatchState() }
        let finalMetrics = await MainActor.run { stopwatchService.getMetrics() }
        
        let operationCount = await MainActor.run { stopwatchService.operationCount }
        XCTAssertTrue(operationCount > 0, "Stopwatch service should have performed operations")
        XCTAssertTrue(finalMetrics.totalOperations > 0, "Metrics should have recorded operations")
        XCTAssertTrue(finalMetrics.successCount > 0, "Should have some successful operations")
        XCTAssertTrue(finalMetrics.averageResponseTime > 0, "Should have recorded response times")
        XCTAssertTrue(finalState.totalLaps > 0, "Should have recorded laps")
    }
    
    func testStopwatchServiceConcurrencyStressTest() async {
        let tasks = 20
        let iterations = 25
        
        // Get the service instance once to ensure we're using the same instance
        let stopwatchService = await MainActor.run { Application.dependency(\.stopwatchService) }
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        // Stress test: rapid stopwatch operations
                        await MainActor.run {
                            stopwatchService.startStopwatch()
                            stopwatchService.addLap()  // Add lap while running
                        }
                        
                        // Simulate rapid operations
                        try? await Task.sleep(nanoseconds: UInt64.random(in: 100...1000))
                        
                        await MainActor.run {
                            stopwatchService.addLap()  // Add another lap
                            stopwatchService.stopStopwatch()
                        }
                        
                        // Record metrics for each operation
                        let responseTime = Double.random(in: 0.001...0.05)
                        await MainActor.run {
                            stopwatchService.recordMetrics(responseTime: responseTime, success: true)
                        }
                    }
                }
            }
        }
        
        // Verify stress test results
        let finalState = await MainActor.run { stopwatchService.getStopwatchState() }
        let finalMetrics = await MainActor.run { stopwatchService.getMetrics() }
        
        let operationCount = await MainActor.run { stopwatchService.operationCount }
        XCTAssertTrue(operationCount > 0, "Service should have performed operations")
        XCTAssertTrue(finalMetrics.totalOperations > 0, "Metrics should have recorded operations")
        XCTAssertTrue(finalMetrics.successCount > 0, "Should have successful operations")
        XCTAssertTrue(finalState.totalLaps > 0, "Should have recorded laps")
    }
    
    func testStopwatchServiceFileStatePersistence() async {
        let tasks = 8
        let iterations = 20
        
        // Get the service instance once to ensure we're using the same instance
        let stopwatchService = await MainActor.run { Application.dependency(\.stopwatchService) }
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        
                        // Test FileState persistence with complex operations
                        await MainActor.run {
                            stopwatchService.startStopwatch()
                        }
                        
                        // Simulate work with varying durations
                        let workDuration = UInt64.random(in: 1000...10000)
                        try? await Task.sleep(nanoseconds: workDuration)
                        
                        // Add multiple laps
                        for _ in 0..<3 {
                            await MainActor.run {
                            stopwatchService.addLap()
                        }
                            try? await Task.sleep(nanoseconds: 1000)
                        }
                        
                        // Record detailed metrics
                        let responseTime = Double.random(in: 0.001...0.2)
                        let success = Int.random(in: 0...3) % 4 != 0 // Some failures
                        await MainActor.run {
                            stopwatchService.recordMetrics(responseTime: responseTime, success: success)
                        }
                        
                        await MainActor.run {
                            stopwatchService.stopStopwatch()
                        }
                        
                        // Don't reset to ensure laps accumulate
                    }
                }
            }
        }
        
        // Verify FileState persistence worked correctly
        let finalState = await MainActor.run { stopwatchService.getStopwatchState() }
        let finalMetrics = await MainActor.run { stopwatchService.getMetrics() }
        
        let operationCount = await MainActor.run { stopwatchService.operationCount }
        XCTAssertTrue(operationCount > 0, "Service should have performed operations")
        XCTAssertTrue(finalMetrics.totalOperations > 0, "Metrics should have recorded operations")
        XCTAssertTrue(finalMetrics.successCount > 0, "Should have successful operations")
        XCTAssertTrue(finalMetrics.errorCount >= 0, "May have some errors")
        XCTAssertTrue(finalMetrics.averageResponseTime > 0, "Should have recorded response times")
        XCTAssertTrue(finalState.totalLaps > 0, "Should have recorded laps")
        XCTAssertTrue(finalState.lapTimes.count > 0, "Should have lap times recorded")
    }
    
    // MARK: - Edge Case Tests
    
    func testRapidStateChanges() async {
        let iterations = 500
        
        await withTaskGroup(of: Void.self) { group in
            // Rapid read task
            group.addTask {
                for _ in 0..<iterations {
                    await MainActor.run {
                        let _ = Application.state(\.concurrencyCounter).value
                    }
                }
            }
            
            // Rapid write task
            group.addTask {
                for i in 0..<iterations {
                    await MainActor.run {
                        var counter = Application.state(\.concurrencyCounter)
                        counter.value = i
                    }
                }
            }
        }
        
        await MainActor.run {
            let finalValue = Application.state(\.concurrencyCounter).value
            XCTAssertTrue(finalValue >= 0 && finalValue < iterations, "Final value should be within expected range")
        }
    }
    
    func testConcurrentStateAccess() async {
        let tasks = 10
        let iterations = 20
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<iterations {
                        await MainActor.run {
                            // Access multiple states concurrently
                            let _ = Application.state(\.concurrencyCounter).value
                            let _ = Application.state(\.concurrencyMessage).value
                            let _ = Application.state(\.concurrencyData).value
                        }
                    }
                }
            }
        }
        
        // If we reach here without hanging, concurrent access is working
        await MainActor.run {
            let finalCounter = Application.state(\.concurrencyCounter).value
            XCTAssertTrue(finalCounter >= 0, "Counter should be accessible")
        }
    }
}
