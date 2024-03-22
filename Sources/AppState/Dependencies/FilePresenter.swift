#if !os(Linux) && !os(Windows)
import Combine
import Foundation

class FilePresenter<Observed: ObservableObject>: NSObject, NSFilePresenter {
    var presentedItemOperationQueue: OperationQueue
    var presentedItemURL: URL?

    weak var observedObject: Observed?

    init(url: URL) {
        self.presentedItemOperationQueue = .main
        self.presentedItemURL = url
        super.init()

        NSFileCoordinator.addFilePresenter(self)
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }

    func presentedItemDidChange() {
        guard let presentedItemURL else { return }

        Application.shared.cloudStoreItemDidChange(url: presentedItemURL)

        guard
            let publisher = observedObject?.objectWillChange as? ObservableObjectPublisher
        else { return }

        publisher.send()
    }
}
#endif
