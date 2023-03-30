import Foundation

class FileStorage {
    
    private let packageDir: URL
    
    init(packageDir: URL) {
        self.packageDir = packageDir
        do {
            try FileManager.default.createDirectory(at: packageDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("failed to create packageDir:\(packageDir) error:\(error)")
        }
    }
    
    func localUrlFor(id: String) -> URL {
        packageDir.appendingPathComponent(id)
    }
    
    func relativeUrl(id: String) -> String {
        "/api/app/package/\(id)/download"
    }
}
