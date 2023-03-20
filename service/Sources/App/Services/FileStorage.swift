import Foundation

actor FileStorage {
    
    private let baseURL: URL
    
    init(baseURL: URL) {
        try! FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
        self.baseURL = baseURL
    }
    
    nonisolated func pathFor(id: String) -> URL {
        baseURL.appendingPathComponent(id)
    }
}
