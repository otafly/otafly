import Foundation

class FileStorage {
    
    private let name: String
    private let baseURL: URL
    
    init(name: String, dir: String) {
        self.name = name
        self.baseURL = URL(fileURLWithPath: dir).appendingPathComponent(name)
        try! FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
    }
    
    func localUrlFor(id: String) -> URL {
        baseURL.appendingPathComponent(id)
    }
    
    func relativeUrl(id: String) -> String {
        "/\(name)/\(id)"
    }
}

extension AppPackage {
    
    func fileId() throws -> String {
        let ext: String = {
            switch platform {
            case .ios: return "ipa"
            case .android: return "apk"
            }
        }()
        return "\(try requireID().uuidString).\(ext)"
    }
}
