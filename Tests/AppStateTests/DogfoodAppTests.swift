import Foundation
#if canImport(Observation)
import Observation
#endif
#if canImport(SwiftData)
import SwiftData
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
import XCTest
@testable import AppState

// A notebook-shaped session that drives every AppState kind the way an app would:
// in-memory session, stored preferences, a file draft, keychain and iCloud where
// those platforms exist, injected services, and a SwiftData notebook/page/tag graph.

private struct DogfoodSession: Codable, Sendable, Equatable {
    var query: String
    var isEditing: Bool
}

private struct DogfoodPick: Sendable, Equatable {
    var title: String
}

private struct DogfoodPrefs: Codable, Sendable, Equatable {
    var sortPinnedFirst: Bool
    var fontSize: Int
}

private struct DogfoodMarker: Sendable, Equatable {
    var name: String
    var note: String
}

private final class DogfoodClock: @unchecked Sendable {
    var label: String
    var ticks: Int

    init(label: String, ticks: Int) {
        self.label = label
        self.ticks = ticks
    }
}

private final class DogfoodFactoryTally: @unchecked Sendable {
    var explicitCalls = 0
    var autoCalls = 0

    func nextAuto() -> Int {
        autoCalls += 1
        return autoCalls
    }
}

private let dogfoodFactoryTally = DogfoodFactoryTally()

private enum DogfoodSupport {
    static let directory: String = {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("appstate-dogfood-session", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.path
    }()

    static let emptySession = DogfoodSession(query: "", isEditing: false)
    static let emptyPrefs = DogfoodPrefs(sortPinnedFirst: true, fontSize: 16)
}

#if canImport(SwiftUI)
@MainActor
private final class DogfoodEditorService: ObservableObject {
    @Published var revision: Int = 0
}
#endif

#if canImport(SwiftData)
@Model
final class DogfoodNotebook {
    var title: String
    @Relationship(deleteRule: .cascade, inverse: \DogfoodPage.notebook)
    var pages: [DogfoodPage]

    init(title: String) {
        self.title = title
        self.pages = []
    }
}

@Model
final class DogfoodPage {
    var title: String
    var body: String
    var pinned: Bool
    var rank: Int
    var notebook: DogfoodNotebook?
    @Relationship(deleteRule: .nullify, inverse: \DogfoodTag.pages)
    var tags: [DogfoodTag]

    init(title: String, body: String, pinned: Bool, rank: Int) {
        self.title = title
        self.body = body
        self.pinned = pinned
        self.rank = rank
        self.tags = []
    }
}

@Model
final class DogfoodTag {
    var name: String
    var pages: [DogfoodPage]

    init(name: String) {
        self.name = name
        self.pages = []
    }
}
#endif

private extension Application {
    var dogfoodSession: State<DogfoodSession> {
        state(initial: DogfoodSupport.emptySession, feature: "DogfoodApp", id: "session")
    }

    var dogfoodSelection: State<DogfoodPick?> {
        state(initial: nil, feature: "DogfoodApp", id: "selection")
    }

    var dogfoodPrefs: StoredState<DogfoodPrefs> {
        storedState(initial: DogfoodSupport.emptyPrefs, feature: "DogfoodApp", id: "prefs")
    }

    @MainActor
    var dogfoodDraft: FileState<String> {
        fileState(
            initial: "",
            path: DogfoodSupport.directory,
            filename: "draft.txt",
            isBase64Encoded: false
        )
    }

    var dogfoodClock: Dependency<DogfoodClock> {
        dependency(DogfoodClock(label: "idle", ticks: 0), feature: "DogfoodApp", id: "clock")
    }

    var dogfoodMarker: Dependency<DogfoodMarker> {
        dependency(DogfoodMarker(name: "start", note: "original"), feature: "DogfoodApp", id: "marker")
    }

    var dogfoodExplicitFactory: Dependency<Int> {
        dependency({
            dogfoodFactoryTally.explicitCalls += 1
            return dogfoodFactoryTally.explicitCalls
        }, feature: "DogfoodApp", id: "explicitFactory")
    }

    var dogfoodAutoFactory: Dependency<Int> {
        dependency(dogfoodFactoryTally.nextAuto())
    }
}

#if canImport(SwiftUI)
private extension Application {
    @MainActor
    var dogfoodEditorService: Dependency<DogfoodEditorService> {
        dependency(DogfoodEditorService(), feature: "DogfoodApp", id: "editorService")
    }
}
#endif

#if canImport(Security)
private extension Application {
    var dogfoodToken: SecureState {
        secureState(initial: nil, feature: "DogfoodApp", id: "token")
    }
}

@available(watchOS 9.0, *)
private extension Application {
    var dogfoodCloudName: SyncState<String> {
        syncState(initial: "Notebook", feature: "DogfoodApp", id: "cloudName")
    }
}
#endif

#if canImport(SwiftData)
private extension Application {
    var dogfoodModelContainer: Dependency<ModelContainer> {
        modelContainer(
            try! ModelContainer(
                for: DogfoodNotebook.self, DogfoodPage.self, DogfoodTag.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    var dogfoodNotebooks: ModelState<DogfoodNotebook> {
        modelState(container: \.dogfoodModelContainer, feature: "DogfoodApp", id: "notebooks")
    }

    var dogfoodPages: ModelState<DogfoodPage> {
        modelState(
            container: \.dogfoodModelContainer,
            fetchDescriptor: FetchDescriptor<DogfoodPage>(
                sortBy: [SortDescriptor(\.rank, order: .forward)]
            ),
            feature: "DogfoodApp",
            id: "pages"
        )
    }

    var dogfoodPinnedPages: ModelState<DogfoodPage> {
        modelState(
            container: \.dogfoodModelContainer,
            fetchDescriptor: FetchDescriptor<DogfoodPage>(
                predicate: #Predicate { $0.pinned == true },
                sortBy: [SortDescriptor(\.title, order: .forward)]
            ),
            feature: "DogfoodApp",
            id: "pinnedPages"
        )
    }

    var dogfoodLimitedPages: ModelState<DogfoodPage> {
        var descriptor = FetchDescriptor<DogfoodPage>(
            sortBy: [SortDescriptor(\.rank, order: .forward)]
        )
        descriptor.fetchLimit = 1
        return modelState(
            container: \.dogfoodModelContainer,
            fetchDescriptor: descriptor,
            feature: "DogfoodApp",
            id: "limitedPages"
        )
    }

    var dogfoodOffsetPages: ModelState<DogfoodPage> {
        var descriptor = FetchDescriptor<DogfoodPage>(
            sortBy: [SortDescriptor(\.rank, order: .forward)]
        )
        descriptor.fetchOffset = 1
        return modelState(
            container: \.dogfoodModelContainer,
            fetchDescriptor: descriptor,
            feature: "DogfoodApp",
            id: "offsetPages"
        )
    }

    var dogfoodTags: ModelState<DogfoodTag> {
        modelState(container: \.dogfoodModelContainer, feature: "DogfoodApp", id: "tags")
    }
}

@MainActor
private final class DogfoodModelEditor {
    @ModelState(\.dogfoodPages) var pages
    @ModelState(\.dogfoodNotebooks) var notebooks

    func add(page: DogfoodPage, to notebook: DogfoodNotebook) {
        page.notebook = notebook
        $pages.insert(page)
    }
}
#endif

@MainActor
private final class DogfoodMarkerEditor {
    @DependencySlice(\.dogfoodMarker, \.name) var name
}

#if !os(Linux) && !os(Windows)
extension DogfoodMarkerEditor: ObservableObject {}
#endif

@MainActor
private final class DogfoodEditor {
    @AppState(\.dogfoodSession) var session
    @Slice(\.dogfoodSession, \.isEditing) var isEditing
    @Constant(\.dogfoodSession, \.query) var query
    @OptionalSlice(\.dogfoodSelection, \.title) var selectedTitle
    @OptionalConstant(\.dogfoodSelection, \.title) var constantTitle
    @StoredState(\.dogfoodPrefs) var prefs
    @Slice(\.dogfoodPrefs, \.fontSize) var fontSize
    @FileState(\.dogfoodDraft) var draft
    @AppDependency(\.dogfoodClock) var clock
    @DependencySlice(\.dogfoodClock, \.label) var clockLabel
    @DependencyConstant(\.dogfoodClock, \.ticks) var clockTicks
    #if canImport(SwiftUI)
    @ObservedDependency(\.dogfoodEditorService) var editorService
    #endif

    func beginEditing(query: String) {
        session.query = query
        isEditing = true
        fontSize = 18
        draft = "draft:\(query)"
        clockLabel = "editing"
        clock.ticks += 1
        #if canImport(SwiftUI)
        editorService.revision += 1
        #endif
    }
}

#if !os(Linux) && !os(Windows)
extension DogfoodEditor: ObservableObject {}
#endif

#if canImport(Security)
@MainActor
private final class DogfoodSecretEditor {
    @SecureState(\.dogfoodToken) var token
}

@available(watchOS 9.0, *)
@MainActor
private final class DogfoodCloudEditor {
    @SyncState(\.dogfoodCloudName) var cloudName
}

#if !os(Linux) && !os(Windows)
extension DogfoodSecretEditor: ObservableObject {}

@available(watchOS 9.0, *)
extension DogfoodCloudEditor: ObservableObject {}
#endif
#endif

final class DogfoodAppTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        Application.logging(isEnabled: true)
        Application.reset(\.dogfoodSession)
        Application.reset(\.dogfoodSelection)
        Application.reset(\.dogfoodPrefs)
        Application.reset(fileState: \.dogfoodDraft)
        #if canImport(Security)
        Application.reset(secureState: \.dogfoodToken)
        if #available(watchOS 9.0, *) {
            Application.reset(syncState: \.dogfoodCloudName)
        }
        #endif
        let clock = Application.dependency(\.dogfoodClock)
        clock.label = "idle"
        clock.ticks = 0
        #if canImport(SwiftUI)
        Application.dependency(\.dogfoodEditorService).revision = 0
        #endif
        #if canImport(SwiftData)
        Application.modelState(\.dogfoodPages).deleteAll()
        Application.modelState(\.dogfoodTags).deleteAll()
        Application.modelState(\.dogfoodNotebooks).deleteAll()
        #endif
    }

    @MainActor
    override func tearDown() async throws {
        Application.reset(\.dogfoodSession)
        Application.reset(\.dogfoodSelection)
        Application.reset(\.dogfoodPrefs)
        Application.reset(fileState: \.dogfoodDraft)
        #if canImport(Security)
        Application.reset(secureState: \.dogfoodToken)
        if #available(watchOS 9.0, *) {
            Application.reset(syncState: \.dogfoodCloudName)
        }
        #endif
        #if canImport(SwiftData)
        Application.modelState(\.dogfoodPages).deleteAll()
        Application.modelState(\.dogfoodTags).deleteAll()
        Application.modelState(\.dogfoodNotebooks).deleteAll()
        #endif
    }

    @MainActor
    func testEditorSessionUsesTheInMemoryStoredFileAndDependencyStates() async throws {
        let editor = DogfoodEditor()
        let other = DogfoodEditor()

        XCTAssertEqual(editor.query, "")
        XCTAssertFalse(editor.isEditing)
        XCTAssertNil(editor.selectedTitle)
        XCTAssertNil(editor.constantTitle)
        XCTAssertEqual(editor.prefs, DogfoodSupport.emptyPrefs)
        XCTAssertEqual(editor.draft, "")
        XCTAssertEqual(editor.clockLabel, "idle")
        XCTAssertEqual(editor.clockTicks, 0)

        editor.beginEditing(query: "field notes")
        var selection = Application.state(\.dogfoodSelection)
        selection.value = DogfoodPick(title: "Pinned")

        XCTAssertEqual(other.query, "field notes")
        XCTAssertTrue(other.isEditing)
        XCTAssertEqual(other.selectedTitle, "Pinned")
        XCTAssertEqual(other.constantTitle, "Pinned")
        XCTAssertEqual(other.fontSize, 18)
        XCTAssertEqual(other.prefs.sortPinnedFirst, true)
        XCTAssertEqual(other.draft, "draft:field notes")
        XCTAssertEqual(other.clock.label, "editing")
        XCTAssertEqual(other.clockTicks, 1)
        XCTAssertEqual(Application.state(\.dogfoodSession).value.query, "field notes")
        XCTAssertEqual(Application.storedState(\.dogfoodPrefs).value.fontSize, 18)

        let draftURL = URL(fileURLWithPath: DogfoodSupport.directory)
            .appendingPathComponent("draft.txt")
        let draftData = try Data(contentsOf: draftURL)
        let draftOnDisk = try JSONDecoder().decode(String.self, from: draftData)
        XCTAssertEqual(draftOnDisk, "draft:field notes")

        other.selectedTitle = "Renamed"
        XCTAssertEqual(Application.state(\.dogfoodSelection).value?.title, "Renamed")

        selection.value = nil
        XCTAssertNil(editor.selectedTitle)
        XCTAssertNil(editor.constantTitle)

        #if canImport(SwiftUI)
        XCTAssertEqual(other.editorService.revision, 1)
        #endif
    }

    #if canImport(Security)
    @MainActor
    func testSecureAndSyncStateStayIndependentOfStoredPreferences() async {
        let secrets = DogfoodSecretEditor()
        secrets.token = "notebook-token"
        XCTAssertEqual(DogfoodSecretEditor().token, "notebook-token")
        XCTAssertEqual(Application.secureState(\.dogfoodToken).value, "notebook-token")

        if #available(watchOS 9.0, *) {
            let cloud = DogfoodCloudEditor()
            cloud.cloudName = "Field Kit"
            XCTAssertEqual(DogfoodCloudEditor().cloudName, "Field Kit")
            XCTAssertEqual(Application.syncState(\.dogfoodCloudName).value, "Field Kit")
        }

        Application.reset(\.dogfoodPrefs)
        XCTAssertEqual(Application.secureState(\.dogfoodToken).value, "notebook-token")
        XCTAssertEqual(Application.storedState(\.dogfoodPrefs).value, DogfoodSupport.emptyPrefs)

        secrets.token = nil
        XCTAssertNil(Application.secureState(\.dogfoodToken).value)
    }
    #endif

    @MainActor
    func testExplicitDependencyFactoryRunsOnce() async {
        let tally = DogfoodFactoryTally()
        let id = "explicit-\(UUID().uuidString)"

        let first = Application.shared.dependency(
            {
                tally.explicitCalls += 1
                return tally.explicitCalls
            },
            feature: "DogfoodApp",
            id: id
        )
        let second = Application.shared.dependency(
            {
                tally.explicitCalls += 1
                return tally.explicitCalls
            },
            feature: "DogfoodApp",
            id: id
        )

        XCTAssertEqual(tally.explicitCalls, 1)
        XCTAssertEqual(first.value, 1)
        XCTAssertEqual(second.value, 1)
    }

    @MainActor
    func testCallSiteDependencyFactoryRunsOnce() async {
        let before = dogfoodFactoryTally.autoCalls

        let cached = Application.dependency(\.dogfoodAutoFactory)
        _ = Application.dependency(\.dogfoodAutoFactory)

        let after = dogfoodFactoryTally.autoCalls
        XCTAssertEqual(after, max(before, 1))
        XCTAssertLessThanOrEqual(after, before + 1)
        XCTAssertEqual(cached, after)
    }

    @MainActor
    func testStructDependencySliceWriteReachesTheStoredDependency() async {
        let editor = DogfoodMarkerEditor()
        editor.name = "renamed"

        XCTAssertEqual(Application.dependency(\.dogfoodMarker).name, "renamed")

        var marker = Application.dependencySlice(\.dogfoodMarker, \.name)
        marker.value = "again"

        XCTAssertEqual(editor.name, "again")
        XCTAssertEqual(Application.dependency(\.dogfoodMarker).name, "again")
        XCTAssertEqual(Application.dependencySlice(\.dogfoodMarker, \.name).value, "again")
    }

    @MainActor
    func testHeldDependencySliceKeepsSiblingFieldsAndReadsLive() async {
        var setupName = Application.dependencySlice(\.dogfoodMarker, \.name)
        setupName.value = "start"
        var setupNote = Application.dependencySlice(\.dogfoodMarker, \.note)
        setupNote.value = "original"

        var heldName = Application.dependencySlice(\.dogfoodMarker, \.name)

        var otherName = Application.dependencySlice(\.dogfoodMarker, \.name)
        otherName.value = "from-other"
        XCTAssertEqual(heldName.value, "from-other")

        var note = Application.dependencySlice(\.dogfoodMarker, \.note)
        note.value = "edited"

        heldName.value = "renamed"

        XCTAssertEqual(Application.dependency(\.dogfoodMarker).name, "renamed")
        XCTAssertEqual(Application.dependency(\.dogfoodMarker).note, "edited")
        XCTAssertEqual(heldName.value, "renamed")
    }

    @MainActor
    func testHeldDependencySliceWritesThroughAnOverride() async {
        let original = Application.dependency(\.dogfoodClock)
        original.label = "idle"
        original.ticks = 0

        var label = Application.dependencySlice(\.dogfoodClock, \.label)
        let token = Application.override(\.dogfoodClock, with: DogfoodClock(label: "mock", ticks: 9))

        label.value = "changed"

        XCTAssertEqual(Application.dependency(\.dogfoodClock).label, "changed")
        XCTAssertEqual(Application.dependency(\.dogfoodClock).ticks, 9)

        await token.cancel()

        XCTAssertTrue(Application.dependency(\.dogfoodClock) === original)

        label.value = "after"

        XCTAssertEqual(original.label, "after")
        XCTAssertEqual(original.ticks, 0)
        XCTAssertTrue(Application.dependency(\.dogfoodClock) === original)
    }

    @MainActor
    func testHeldStructDependencySliceWritesThroughAnOverride() async {
        var name = Application.dependencySlice(\.dogfoodMarker, \.name)
        var note = Application.dependencySlice(\.dogfoodMarker, \.note)
        name.value = "before"
        note.value = "before-note"

        let token = Application.override(
            \.dogfoodMarker,
            with: DogfoodMarker(name: "mock", note: "mock-note")
        )

        name.value = "during"

        XCTAssertEqual(Application.dependency(\.dogfoodMarker).name, "during")
        XCTAssertEqual(Application.dependency(\.dogfoodMarker).note, "mock-note")
        XCTAssertEqual(name.value, "during")

        await token.cancel()

        XCTAssertEqual(name.value, "before")
        XCTAssertEqual(Application.dependency(\.dogfoodMarker).name, "before")
        XCTAssertEqual(Application.dependency(\.dogfoodMarker).note, "before-note")
    }

    #if canImport(SwiftData)
    @MainActor
    func testSwiftDataGraphInsertsRelationshipsAndSorts() async throws {
        let notebooks = Application.modelState(\.dogfoodNotebooks)
        let pages = Application.modelState(\.dogfoodPages)
        let tags = Application.modelState(\.dogfoodTags)
        let editor = DogfoodModelEditor()

        let notebook = DogfoodNotebook(title: "Field")
        notebooks.insert(notebook)

        editor.add(
            page: DogfoodPage(title: "Later", body: "second", pinned: true, rank: 2),
            to: notebook
        )
        editor.add(
            page: DogfoodPage(title: "First", body: "opener", pinned: false, rank: 1),
            to: notebook
        )

        let storedPages = pages.models
        XCTAssertEqual(storedPages.map(\.title), ["First", "Later"])
        XCTAssertEqual(storedPages.map(\.notebook?.title), ["Field", "Field"])
        XCTAssertEqual(notebooks.models.first?.pages.count, 2)

        let later = try XCTUnwrap(storedPages.first { $0.title == "Later" })
        later.tags.append(DogfoodTag(name: "swift"))
        try pages.strict.save()

        XCTAssertEqual(tags.models.map(\.name), ["swift"])
        XCTAssertEqual(tags.models.first?.pages.map(\.title), ["Later"])
        XCTAssertEqual(editor.pages.map(\.rank), [1, 2])
        XCTAssertEqual(Application.modelState(\.dogfoodPinnedPages).models.map(\.title), ["Later"])
        XCTAssertEqual(Application.modelState(\.dogfoodLimitedPages).models.map(\.title), ["First"])

        let context = Application.modelContext(\.dogfoodModelContainer)
        XCTAssertTrue(context === pages.context)
        let direct = DogfoodPage(title: "Direct", body: "from context", pinned: false, rank: 0)
        direct.notebook = notebooks.models.first
        context.insert(direct)
        try context.save()

        XCTAssertEqual(pages.models.map(\.title), ["Direct", "First", "Later"])
    }

    @MainActor
    func testFilteredDeleteAllLeavesOtherPagesAndCascadeRemovesTheGraph() async throws {
        let notebooks = Application.modelState(\.dogfoodNotebooks)
        let pages = Application.modelState(\.dogfoodPages)
        let tags = Application.modelState(\.dogfoodTags)

        let notebook = DogfoodNotebook(title: "Field")
        notebooks.insert(notebook)

        let pinned = DogfoodPage(title: "Pinned", body: "", pinned: true, rank: 1)
        let loose = DogfoodPage(title: "Loose", body: "", pinned: false, rank: 2)
        pinned.notebook = notebook
        loose.notebook = notebook
        pinned.tags.append(DogfoodTag(name: "keep"))
        pages.insert(pinned)
        pages.insert(loose)
        try pages.strict.save()

        XCTAssertEqual(pages.models.map(\.title), ["Pinned", "Loose"])
        XCTAssertEqual(tags.models.first?.pages.count, 1)

        try Application.modelState(\.dogfoodPinnedPages).strict.deleteAll()

        XCTAssertEqual(pages.models.map(\.title), ["Loose"])
        XCTAssertEqual(notebooks.models.count, 1)
        XCTAssertEqual(tags.models.map(\.name), ["keep"])
        XCTAssertEqual(tags.models.first?.pages.count, 0)

        try notebooks.strict.deleteAll()

        XCTAssertTrue(notebooks.models.isEmpty)
        XCTAssertTrue(pages.models.isEmpty)
        XCTAssertEqual(tags.models.count, 1)
    }

    @MainActor
    func testDeleteAllIgnoresFetchLimitAndRemovesEveryMatch() async throws {
        let notebooks = Application.modelState(\.dogfoodNotebooks)
        let pages = Application.modelState(\.dogfoodPages)
        let limited = Application.modelState(\.dogfoodLimitedPages)

        let notebook = DogfoodNotebook(title: "Field")
        notebooks.insert(notebook)

        let first = DogfoodPage(title: "First", body: "", pinned: false, rank: 1)
        let second = DogfoodPage(title: "Second", body: "", pinned: false, rank: 2)
        first.notebook = notebook
        second.notebook = notebook
        pages.insert(first)
        pages.insert(second)

        XCTAssertEqual(pages.models.map(\.title), ["First", "Second"])
        XCTAssertEqual(limited.models.map(\.title), ["First"])

        try limited.strict.deleteAll()

        XCTAssertTrue(limited.models.isEmpty)
        XCTAssertTrue(pages.models.isEmpty)
        XCTAssertEqual(notebooks.models.count, 1)
    }

    @MainActor
    func testDeleteAllIgnoresFetchOffsetAndRemovesEveryMatch() async throws {
        let notebooks = Application.modelState(\.dogfoodNotebooks)
        let pages = Application.modelState(\.dogfoodPages)
        let offset = Application.modelState(\.dogfoodOffsetPages)

        let notebook = DogfoodNotebook(title: "Field")
        notebooks.insert(notebook)

        let first = DogfoodPage(title: "First", body: "", pinned: false, rank: 1)
        let second = DogfoodPage(title: "Second", body: "", pinned: false, rank: 2)
        first.notebook = notebook
        second.notebook = notebook
        pages.insert(first)
        pages.insert(second)

        XCTAssertEqual(offset.models.map(\.title), ["Second"])

        try offset.strict.deleteAll()

        XCTAssertTrue(offset.models.isEmpty)
        XCTAssertTrue(pages.models.isEmpty)
    }

    #if canImport(Observation)
    @MainActor
    func testModelEditsDoNotBroadcastWhileSessionEditsDo() async {
        let editor = DogfoodEditor()
        let models = DogfoodModelEditor()
        let sessionFlag = ObservationChangeFlag()
        let modelFlag = ObservationChangeFlag()

        withObservationTracking {
            _ = editor.isEditing
        } onChange: {
            sessionFlag.didChange = true
        }

        editor.isEditing = true
        XCTAssertTrue(sessionFlag.didChange)

        withObservationTracking {
            _ = models.pages
        } onChange: {
            modelFlag.didChange = true
        }

        models.$pages.insert(DogfoodPage(title: "Quiet", body: "", pinned: false, rank: 1))

        XCTAssertFalse(
            modelFlag.didChange,
            "ModelState writes go through SwiftData and do not bump Application's observation anchor."
        )
        XCTAssertEqual(models.pages.count, 1)
    }
    #endif
    #endif
}

#if canImport(Observation) && canImport(SwiftData)
private final class ObservationChangeFlag: @unchecked Sendable {
    var didChange = false
}
#endif
