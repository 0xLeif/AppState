import Cache
import Foundation

actor CloudStateStore {
    struct Blob<Value: Codable>: Codable {
        let value: Value
    }
    
    enum CloudError: LocalizedError {
        case invalidURL(String?)
        case noData(String?)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL(let string): return "Invalid URL \(String(describing: string))"
            case .noData(let string): return "No data for \(String(describing: string))"
            }
        }
    }
    
    private let coordinator: NSFileCoordinator
    
    @AppDependency(\.fileManager) private var fileManager: FileManager
    
    private var cloudDocumentsURL: URL? {
        fileManager
            .url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
    }
    
    var viewModels: [String: any ObservableObject]
    
    init() {
        self.coordinator = NSFileCoordinator()
        self.viewModels = [:]
    }
    
    func update(viewModel: any ObservableObject, forKey key: String) {
        viewModels[key] = viewModel
    }
    
    func `get`<Value: Codable>(
        _ scope: Application.Scope
    ) throws -> Value {
        let documentURL = cloudDocumentsURL?.appendingPathComponent("\(scope.name).\(scope.id)")
        
        guard let documentURL else {
            throw CloudError.invalidURL(documentURL?.absoluteString)
        }
        
        var coordinationError: NSError?
        var readData: Data?
        var readError: Error?
        
        coordinator.coordinate(
            readingItemAt: documentURL,
            options: [],
            error: &coordinationError,
            byAccessor: { url in
                do {
                    if let cloudDocumentsURL {
                        try? fileManager.createDirectory(at: cloudDocumentsURL, withIntermediateDirectories: true)
                    }
                    readData = try Data(contentsOf: url)
                } catch {
                    readError = error
                }
            }
        )
        
        if let error = readError {
            throw error
        }
        
        if let coordinationError = coordinationError {
            throw coordinationError
        }
        
        guard let data = readData else {
            throw CloudError.noData(documentURL.absoluteString)
        }
        
        guard let base64DecodedData = Data(base64Encoded: data) else {
            return try JSONDecoder().decode(Blob<Value>.self, from: data).value
        }
        
        return try JSONDecoder().decode(Blob<Value>.self, from: base64DecodedData).value
    }
    
    func `set`<Value: Codable>(
        _ scope: Application.Scope,
        value: Value,
        isBase64Encoded: Bool = true
    ) throws {
        let documentURL = cloudDocumentsURL?.appendingPathComponent("\(scope.name).\(scope.id)")
        
        guard let documentURL else {
            throw CloudError.invalidURL(documentURL?.absoluteString)
        }
        
        let blob = Blob(value: value)
        
        var data = try JSONEncoder().encode(blob)
        
        if isBase64Encoded {
            data = data.base64EncodedData()
        }
        
        var coordinationError: NSError?
        var writeError: Error?
        
        coordinator.coordinate(
            writingItemAt: documentURL,
            options: [
                .forDeleting
            ],
            error: &coordinationError,
            byAccessor: { url in
                do {
                    if let cloudDocumentsURL {
                        try? fileManager.createDirectory(at: cloudDocumentsURL, withIntermediateDirectories: true)
                    }
                    try data.write(to: url, options: .atomic)
                } catch {
                    writeError = error
                }
            }
        )
        
        if let error = writeError {
            throw error
        }
        
        if let coordinationError = coordinationError {
            throw coordinationError
        }
    }
    
    func remove(
        _ scope: Application.Scope
    ) throws {
        let documentURL = cloudDocumentsURL?.appendingPathComponent("\(scope.name).\(scope.id)")
        
        guard let documentURL else {
            throw CloudError.invalidURL(documentURL?.absoluteString)
        }
        
        var coordinationError: NSError?
        var removeError: Error?
        
        coordinator.coordinate(
            writingItemAt: documentURL,
            options: [
                .forDeleting
            ],
            error: &coordinationError,
            byAccessor: { url in
                do {
                    try fileManager.removeItem(at: documentURL)
                } catch {
                    removeError = error
                }
            }
        )
        
        if let error = removeError {
            throw error
        }
        
        if let coordinationError = coordinationError {
            throw coordinationError
        }
    }
    
    func startMonitoringFile<Observed: ObservableObject>(
        scope: Application.Scope
    ) -> FilePresenter<Observed>? {
        guard let documentURL = cloudDocumentsURL?.appendingPathComponent("\(scope.name).\(scope.id)") else {
            return nil
        }
        
        return FilePresenter(url: documentURL)
    }
}
