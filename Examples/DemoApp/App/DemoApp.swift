import AppState
import SwiftUI

struct Profile: Codable, Sendable, Equatable {
    var name: String
    var visits: Int
}

let blockerDirectory = NSTemporaryDirectory() + "uitest-blocker"

extension Application {
    var counter: State<Int> { state(initial: 0) }
    var fresh: State<Int> { state(initial: 0) }
    var profile: State<Profile> { state(initial: Profile(name: "Ada", visits: 0)) }
    var failureCount: State<Int> { state(initial: 0) }
    var storedCount: StoredState<Int> { storedState(initial: 0, id: "uitest.storedCount") }
    var storedProfile: StoredState<Profile> { storedState(initial: Profile(name: "none", visits: 0), id: "uitest.storedProfile") }
    @MainActor var fileCount: FileState<Int> { fileState(initial: 0, filename: "uitest-fileCount") }
    @MainActor var fileList: FileState<[String]> { fileState(initial: [], filename: "uitest-fileList") }
    @MainActor var blockedFile: FileState<Int> { fileState(initial: 0, path: blockerDirectory + "/sub", filename: "blocked") }
    var secret: SecureState { secureState(id: "uitest.secret") }
    var greeter: Dependency<String> { dependency("real") }
}

final class DemoApplication: Application {
    override func didFailToPersist(_ failure: PersistenceFailure) {
        var count = Application.state(\.failureCount)
        count.value += 1
    }
}

@main
struct DemoApp: App {
    @SwiftUI.State private var overrides: [Application.DependencyOverride] = []

    init() {
        Application.promote(to: DemoApplication.self)

        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("-reset") {
            Application.reset(storedState: \.storedCount)
            Application.reset(storedState: \.storedProfile)
            Application.reset(fileState: \.fileCount)
            Application.reset(fileState: \.fileList)
            Application.reset(secureState: \.secret)
        }

        // A regular file where a directory is expected makes every write below it fail.
        try? FileManager.default.removeItem(atPath: blockerDirectory)
        try? Data("blocker".utf8).write(to: URL(fileURLWithPath: blockerDirectory))

        if arguments.contains("-mock") {
            _overrides = SwiftUI.State(initialValue: [Application.override(\.greeter, with: "mock")])
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @AppState(\.counter) private var counter: Int
    @AppState(\.fresh) private var fresh: Int
    @AppState(\.failureCount) private var failureCount: Int
    @Slice(\.profile, \.name) private var name: String
    @StoredState(\.storedCount) private var storedCount: Int
    @StoredState(\.storedProfile) private var storedProfile: Profile
    @FileState(\.fileCount) private var fileCount: Int
    @FileState(\.fileList) private var fileList: [String]
    @FileState(\.blockedFile) private var blockedFile: Int
    @SecureState(\.secret) private var secret: String?
    @AppDependency(\.greeter) private var greeter: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                row("counter", "\(counter)") { counter += 1 }
                // Not a wrapper write: a first read followed at once by a write, in plain code.
                row("fresh", "\(fresh)") {
                    var state = Application.state(\.fresh)
                    _ = state.value
                    state.value = 5
                }
                row("name", name) { name = name == "Ada" ? "Grace" : "Ada" }
                row("stored", "\(storedCount)") { storedCount += 1 }
                row("storedProfile", "\(storedProfile.name)-\(storedProfile.visits)") {
                    storedProfile = Profile(name: "Lin", visits: storedProfile.visits + 1)
                }
                row("file", "\(fileCount)") { fileCount += 1 }
                row("fileList", fileList.isEmpty ? "empty" : fileList.joined(separator: ",")) { fileList.append("i\(fileList.count)") }
                row("secret", secret ?? "nil") { secret = "s3cret" }
                row("blocked", "\(blockedFile)") { blockedFile += 1 }
                Text("\(failureCount)").accessibilityIdentifier("failures-value")
                Text(greeter).accessibilityIdentifier("greeter-value")
            }
            .padding()
        }
    }

    private func row(_ id: String, _ value: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(value).accessibilityIdentifier("\(id)-value")
            Spacer()
            Button("tap \(id)", action: action).accessibilityIdentifier("\(id)-button")
        }
    }
}
