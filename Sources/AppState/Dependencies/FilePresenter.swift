#if !os(Linux) && !os(Windows)
import Combine
import Foundation
#if os(iOS)
import SwiftUI
#endif

extension URLResourceValues: @unchecked Sendable { }

class FilePresenter<Observed: ObservableObject>: NSObject, NSFilePresenter {
    @AppDependency(\.icloudDocumentStore) private var cloudDocumentStore: CloudStateStore

    private let scope: Application.Scope

    var presentedItemOperationQueue: OperationQueue
    var presentedItemURL: URL?

    weak var observedObject: Observed?

    init(scope: Application.Scope, url: URL) {
        self.scope = scope
        self.presentedItemOperationQueue = .main
        self.presentedItemURL = url
        super.init()

        NSFileCoordinator.addFilePresenter(self)

        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        #endif
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }

    func presentedItemDidChange() {
        guard let presentedItemURL else { return }

        Task {
            let resourceValues: URLResourceValues = try await cloudDocumentStore.resourceValues(scope)
            let contentModificationDate: Date? = resourceValues.contentModificationDate
            let attributeModificationDate: Date? = resourceValues.attributeModificationDate

            Application.shared.cloudStoreItemDidChange(
                scope: scope,
                url: presentedItemURL,
                modificationDate: contentModificationDate,
                attributeModificationDate: attributeModificationDate,
                completion: { [weak self] in
                    guard
                        let publisher = self?.observedObject?.objectWillChange as? ObservableObjectPublisher
                    else { return }

                    publisher.send()
                }
            )
        }
    }

    #if os(iOS)
    @objc
    private func didEnterBackground() {
        NSFileCoordinator.removeFilePresenter(self)
    }

    @objc
    private func willEnterForeground() {
        NSFileCoordinator.addFilePresenter(self)
    }
    #endif
}
#endif
