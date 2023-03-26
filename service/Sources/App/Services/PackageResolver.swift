import Foundation
import Vapor
import ZIPFoundation

struct PackageInfo {
    
    let bundleId: String
    let version: String
    let build: String
}

class PackageResolver {
    
    func extract(_ packageURL: URL) throws -> PackageInfo {
        guard let archive = Archive(url: packageURL, accessMode: .read) else {
            throw Abort(.internalServerError, reason: "extract package failed: \(packageURL)")
        }
        let plistEntry = try archive.plistEntry()
        var plistData = Data()
        _ = try archive.extract(plistEntry) { data in
            plistData.append(data)
        }
        guard let dict = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? NSDictionary else {
            throw Abort(.badRequest, reason: "Info.plist data is wrong")
        }
        guard let bundleId = dict["CFBundleIdentifier"] as? String else { throw Abort(.badRequest) }
        guard let version = dict["CFBundleShortVersionString"] as? String else { throw Abort(.badRequest) }
        guard let build = dict["CFBundleVersion"] as? String else { throw Abort(.badRequest) }
        return PackageInfo(bundleId: bundleId, version: version, build: build)
    }
}

private extension Archive {
    
    func plistEntry() throws -> Entry {
        let regex = try NSRegularExpression(pattern: #"^Payload\/.+\.app\/$"#)
        for entry in self {
            let result = regex.matches(in: entry.path, range: entry.path.searchRange)
            if result.count > 0 {
                guard let entry = self[entry.path + "Info.plist"], entry.type == .file else {
                    break
                }
                return entry
            }
        }
        throw Abort(.badRequest, reason: "Invalid ipa file, Info.plist not found.")
    }
}
