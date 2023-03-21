import Foundation

actor FileStorage {
    
    private let name: String
    private let baseURL: URL
    
    init(name: String, dir: String) {
        self.name = name
        self.baseURL = URL(fileURLWithPath: dir).appendingPathComponent("archives")
        try! FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
    }
    
    nonisolated func pathFor(id: String) -> URL {
        baseURL.appendingPathComponent(id)
    }
    
    nonisolated func relativeUrl(id: String) -> String {
        "/\(name)/\(id)"
    }
}
