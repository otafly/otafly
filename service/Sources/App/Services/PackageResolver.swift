import Foundation
import Vapor
import ZIPFoundation
import Yams

protocol PackageResolver {
    
    func extract(_ packageURL: URL) throws -> PackageInfo
}

struct PackageInfo {
    
    let bundleId: String
    let version: String
    let build: String
}

extension Platform {
    
    var packageResolver: PackageResolver {
        switch self {
        case .ios: return IOSPackageResolver()
        case .android: return AndroidPackageResolver()
        }
    }
}

class IOSPackageResolver: PackageResolver {
    
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

class AndroidPackageResolver: PackageResolver {
    
    func extract(_ packageURL: URL) throws -> PackageInfo {
        guard let apktool = findFilePath(name: "apktool") else {
            throw Abort(.internalServerError, reason: "apktool not found")
        }
        let apkoutURL = packageURL.appendingPathExtension("out")
        defer {
            try? FileManager.default.removeItem(at: apkoutURL)
        }
        let process = Process()
        process.launchPath = apktool
        process.arguments = ["d", "-o", apkoutURL.path, "-s", "-f", packageURL.path]
        process.launch()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw Abort(.badRequest, reason: "failed to extract from apk")
        }
        let manifestURL = apkoutURL.appendingPathComponent("AndroidManifest.xml")
        let manifestData = try Data(contentsOf: manifestURL)
        let doc = try XMLDocument(data: manifestData)
        guard let bundleId = doc.rootElement()?.attribute(forName: "package")?.stringValue else {
            throw Abort(.badRequest, reason: "bundle id not found")
        }
        let apktoolURL = apkoutURL.appendingPathComponent("apktool.yml")
        guard let dict = try Yams.load(yaml: String(contentsOf: apktoolURL)) as? [String: Any],
              let versionInfo = dict["versionInfo"] as? [String: Any],
              let versionName = versionInfo["versionName"] as? String,
              let versionCode = versionInfo["versionCode"] as? String
        else {
            throw Abort(.badRequest, reason: "version or build not found")
        }
        
        return PackageInfo(bundleId: bundleId, version: versionName, build: versionCode)
    }
    
    private func findFilePath(name: String) -> String? {
        ["/usr/bin/", "usr/local/bin", "/opt/homebrew/bin/"].first(where: {
            FileManager.default.fileExists(atPath: $0 + name)
        }).map { $0 + name }
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
