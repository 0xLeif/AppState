import XCTest

final class DemoUITests: XCTestCase {
    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func value(_ id: String, in app: XCUIApplication) -> String {
        let element = app.staticTexts["\(id)-value"]
        XCTAssertTrue(element.waitForExistence(timeout: 10), "\(id) is missing")
        return element.label
    }

    private func expect(_ id: String, _ expected: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let element = app.staticTexts["\(id)-value"]
        let predicate = NSPredicate(format: "label == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "\(id) is \(element.label), expected \(expected)", file: file, line: line)
    }

    private func tap(_ id: String, in app: XCUIApplication, times: Int = 1) {
        for _ in 0..<times { app.buttons["\(id)-button"].tap() }
    }

    override func setUp() { continueAfterFailure = false }

    func testStateAndSliceUpdateTheView() {
        let app = launch(["-reset"])

        expect("counter", "0", in: app)
        tap("counter", in: app, times: 3)
        expect("counter", "3", in: app)

        expect("name", "Ada", in: app)
        tap("name", in: app)
        expect("name", "Grace", in: app)
    }

    /// Outside XCTest the old getter filled the cache from a later task, which undid this write.
    func testWriteRightAfterFirstReadIsKept() {
        let app = launch(["-reset"])

        expect("fresh", "0", in: app)
        tap("fresh", in: app)
        expect("fresh", "5", in: app)

        // Give any deferred work time to run, then make the view render again.
        Thread.sleep(forTimeInterval: 1)
        tap("counter", in: app)
        expect("counter", "1", in: app)
        expect("fresh", "5", in: app)
    }

    func testPersistedStateSurvivesRelaunch() {
        var app = launch(["-reset"])

        expect("stored", "0", in: app)
        expect("file", "0", in: app)
        expect("secret", "nil", in: app)

        tap("stored", in: app, times: 2)
        tap("storedProfile", in: app)
        tap("file", in: app, times: 3)
        tap("fileList", in: app, times: 2)
        tap("secret", in: app)

        expect("stored", "2", in: app)
        expect("storedProfile", "Lin-1", in: app)
        expect("file", "3", in: app)
        expect("fileList", "i0,i1", in: app)
        expect("secret", "s3cret", in: app)

        app.terminate()
        app = launch([])

        expect("stored", "2", in: app)
        expect("storedProfile", "Lin-1", in: app)
        expect("file", "3", in: app)
        expect("fileList", "i0,i1", in: app)
        expect("secret", "s3cret", in: app)
        expect("counter", "0", in: app)

        tap("stored", in: app)
        tap("file", in: app)
        expect("stored", "3", in: app)
        expect("file", "4", in: app)

        app.terminate()
        app = launch(["-reset"])

        expect("stored", "0", in: app)
        expect("file", "0", in: app)
        expect("fileList", "empty", in: app)
        expect("secret", "nil", in: app)
    }

    func testFailedWriteReachesTheHookAndTheAppKeepsWorking() {
        let app = launch(["-reset"])

        // The blocked file cannot be read either. That is reported once, however often the view renders.
        expect("failures", "1", in: app)
        tap("counter", in: app, times: 3)
        expect("failures", "1", in: app)

        tap("blocked", in: app)
        expect("failures", "2", in: app)
        expect("blocked", "1", in: app)

        Thread.sleep(forTimeInterval: 1)
        expect("failures", "2", in: app)

        tap("counter", in: app)
        expect("counter", "4", in: app)
    }

    func testOverrideHeldByTheAppLastsForTheSession() {
        var app = launch(["-reset"])
        expect("greeter", "real", in: app)
        app.terminate()

        app = launch(["-reset", "-mock"])
        expect("greeter", "mock", in: app)
        tap("counter", in: app, times: 2)
        expect("counter", "2", in: app)
        expect("greeter", "mock", in: app)
    }
}
