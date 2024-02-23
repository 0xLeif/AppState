import XCTest
@testable import AppState

fileprivate class SomeApplication: Application {
    static func someFunction() { /* no-op */ }
}

final class ApplicationTests: XCTestCase {
    func testCustomFunction() throws {
        let applicationType = Application.logging(isEnabled: true)
            .load(dependency: \.userDefaults)
            .promote(to: SomeApplication.self)

        applicationType.someFunction()
    }
}
