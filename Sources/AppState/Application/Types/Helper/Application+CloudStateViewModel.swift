#if !os(Linux) && !os(Windows)
import Cache
import Combine
import Foundation
import SwiftUI

extension Application {
    public class CloudStateViewModel<Value: Codable & Equatable>: ObservableObject {
        @AppDependency(\.icloudDocumentStore) private var cloudDocumentStore: CloudStateStore

        @Published var value: Value?

        private let scope: Scope
        private var filePresenter: FilePresenter<CloudStateViewModel<Value>>?

        init(scope: Scope) {
            self.scope = scope
            Task {
                self.filePresenter = await cloudDocumentStore.startMonitoringFile(scope: scope)
                self.filePresenter?.observedObject = self
            }

            Task {
                guard
                    let viewModel = await cloudDocumentStore.viewModels[scope.key] as? Application.CloudStateViewModel<Value>
                else {
                    await cloudDocumentStore.update(viewModel: self, forKey: scope.key)

                    return
                }

                await MainActor.run {
                    value = viewModel.value
                }
            }
        }

        deinit {
            guard let filePresenter else { return }

            NSFileCoordinator.removeFilePresenter(filePresenter)

            self.filePresenter = nil
        }

        func getValue(cachedValue: Value?) {
            Task {
                do {
                    await MainActor.run {
                        var initialFetchesState: State<Set<String>> = Application.state(\.initialFetches)
                        initialFetchesState.value.insert(scope.key)

                        var externalFetchesState: State<[String: ExternalChange]> = Application.state(\.externalChanges)
                        externalFetchesState.value[scope.key]?.hasCompletedChange = true
                    }

                    let cloudStoreValue: Value = try await cloudDocumentStore.get(scope)

                    guard cachedValue != cloudStoreValue else { return }

                    await MainActor.run {
                        shared.cache.set(
                            value: Application.State(
                                type: .cloud,
                                initial: cloudStoreValue,
                                scope: scope
                            ),
                            forKey: scope.key
                        )
                    }
                } catch {
                    switch error {
                    case CloudStateStore.CloudError.unitTest:
                        log(
                            debug: "⚠️ CloudState Fetching isn't allowed for unit tests.",
                            fileID: #fileID,
                            function: #function,
                            line: #line,
                            column: #column
                        )
                    default:
                        log(
                            error: error,
                            message: "☁️ CloudState Fetching",
                            fileID: #fileID,
                            function: #function,
                            line: #line,
                            column: #column
                        )
                    }
                }
            }
        }

        func setValue(newValue: Value) {
            Task {
                do {
                    try await cloudDocumentStore.set(scope, value: newValue)
                } catch {
                    switch error {
                    case CloudStateStore.CloudError.unitTest:
                        log(
                            debug: "⚠️ CloudState Saving isn't allowed for unit tests.",
                            fileID: #fileID,
                            function: #function,
                            line: #line,
                            column: #column
                        )
                    default:
                        log(
                            error: error,
                            message: "☁️ CloudState Saving",
                            fileID: #fileID,
                            function: #function,
                            line: #line,
                            column: #column
                        )
                    }
                }
            }
        }

        func removeValue() {
            Task {
                do {
                    try await cloudDocumentStore.remove(scope)
                } catch {
                    switch error {
                    case CloudStateStore.CloudError.unitTest:
                        log(
                            debug: "⚠️ CloudState Deleting isn't allowed for unit tests.",
                            fileID: #fileID,
                            function: #function,
                            line: #line,
                            column: #column
                        )
                    default:
                        log(
                            error: error,
                            message: "☁️ CloudState Deleting",
                            fileID: #fileID,
                            function: #function,
                            line: #line,
                            column: #column
                        )
                    }
                }
            }
        }
    }
}
#endif
