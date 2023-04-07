import Vapor
import SQLKit
import Fluent
import MultipartKit

class AppService {
    
    let app: Application
    let storage: FileStorage
    let packageCache: ModelCache<AppPackage>
    
    init(app: Application) {
        self.app = app
        storage = FileStorage(packageDir: app.baseDir.appendingPathComponent("packages"))
        packageCache = .init()
    }
    
    func queryMeta() async throws -> [AppMeta] {
        try await AppMeta.query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .all()
    }
    
    func getMeta(id: UUID) async throws -> AppMeta? {
        try await AppMeta.find(id, on: app.db)
    }
    
    func createMeta(form: AppMetaForm) async throws {
        let dbItem = AppMeta(title: form.title, content: form.content ?? "", platform: form.platform)
        try await dbItem.save(on: app.db)
    }
    
    func findMeta(accessToken: String) async throws -> AppMeta? {
        try await AppMeta.query(on: app.db)
            .filter(\.$accessToken == accessToken)
            .first()
    }
    
    func cleanup() async {
        
    }
    
    func getPackage(id: UUID) async throws -> AppPackage? {
        try await AppPackage.query(on: app.db).filter(\.$id == id).first()
    }
    
    func queryLatestPackages(platform: Platform?) async throws -> [AppPackage] {
        var packages = [AppPackage]()
        var builder = AppMeta.query(on: app.db)
        if let platform {
            builder = builder.filter(\.$platform == platform)
        }
        for appId in try await builder.unique().all(\.$id) {
            if let package = await packageCache.get(key: appId.uuidString) {
                packages.append(package)
            } else if let package = try await AppPackage.query(on: app.db)
                .filter(\.$appMeta.$id == appId)
                .sort(\.$authorAt, .descending)
                .sort(\.$updatedAt, .descending)
                .first() {
                packages.append(package)
                await packageCache.set(key: appId.uuidString, model: package)
            } else {
                continue
            }
        }

#if os(Linux)
        let array = (packages.map(AppPackageObjC.init) as NSArray).sortedArray(using: [
            .init(keyPath: \AppPackageObjC.authorAt, ascending: false),
            .init(keyPath: \AppPackageObjC.updatedAt, ascending: false)
        ]) as! [AppPackageObjC]
        packages = array.map { $0.package }
#else
        packages.sort(using: [
            KeyPathComparator(\.authorAt, order: .reverse),
            KeyPathComparator(\.updatedAt, order: .reverse)
        ])
#endif
        
        return packages
    }
    
    func queryPackages(appId: UUID) async throws -> [AppPackage] {
        try await AppPackage.query(on: app.db)
            .filter(\.$appMeta.$id == appId)
            .sort(\.$authorAt, .descending)
            .sort(\.$updatedAt, .descending)
            .all()
    }
    
    func createPackage(accessToken: String, content: String?, date: Date?, tempFileURL: URL) async throws {
        defer {
            cleanup(tempFileURL: tempFileURL)
        }
        guard let appMeta = try await findMeta(accessToken: accessToken) else {
            throw Abort(.badRequest, reason: "invalid token")
        }
        let info = try appMeta.platform.packageResolver.extract(tempFileURL)
        let package = try AppPackage(id: UUID(), appMeta: appMeta, info: info, content: content, authorAt: date)
        let dest = storage.localUrlFor(id: try package.requireID().uuidString)
        try FileManager.default.moveItem(at: tempFileURL, to: dest)
        try await package.save(on: app.db)
        await packageCache.remove(key: try appMeta.requireID().uuidString)
    }
    
    func getPackageManifestXml(id: UUID, baseURL: String) async throws -> Data? {
        guard let package = try await AppPackage.find(id, on: app.db) else { return nil }
        let url = baseURL + storage.relativeUrl(id: try package.requireID().uuidString)
        
        let plistDict: [String: Any] = [
            "items": [
                [
                    "assets": [
                        [
                            "kind": "software-package",
                            "url": url
                        ]
                    ],
                    "metadata": [
                        "bundle-identifier": package.appBundleId,
                        "bundle-version": "\(package.appVersion) (\(package.appBuild))",
                        "kind": "software",
                        "title": package.appDisplayName
                    ]
                ]
            ]
        ]
        return try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
    }
    
    func getInstallURL(package: AppPackage, baseURL: String) throws -> String {
        switch package.platform {
        case .ios:
            let id = try package.requireID().uuidString
            return "itms-services://?action=download-manifest&url=\(baseURL)/api/app/package/\(id)/manifest"
        case .android:
            return baseURL + storage.relativeUrl(id: try package.requireID().uuidString)
        }
    }
    
    func cleanupPackages(reserved: Int) async throws {
        try await truncatePackages(reserved: reserved)
        try await prunePackages()
    }
    
    private func truncatePackages(reserved: Int) async throws {
        let appMetas = try await AppMeta.query(on: app.db).all()
        var reservedIds = [UUID]()
        for appMeta in appMetas {
            let ids = try await AppPackage.query(on: app.db)
                .filter(\.$appMeta.$id == appMeta.requireID())
                .sort(\.$updatedAt, .descending)
                .limit(reserved)
                .all(\.$id)
            reservedIds.append(contentsOf: ids)
        }
        try await AppPackage.query(on: app.db).filter(\.$id !~ reservedIds).delete(force: true)
    }
    
    private func prunePackages() async throws {
        let ids = try await AppPackage.query(on: app.db).all(\.$id)
        try storage.prune(reserved: ids.map {$0.uuidString })
    }
    
    private func cleanup(tempFileURL: URL) {
        do {
            if FileManager.default.fileExists(atPath: tempFileURL.path) {
                try FileManager.default.removeItem(at: tempFileURL)
            }
        } catch {
            app.logger.warning("failed to cleanup temp file \(tempFileURL) with error: \(error)")
        }
    }
}

extension AppMetaModel.Item {
    
    init(dbItem: AppMeta, isAdmin: Bool = false) throws {
        id = try dbItem.requireID().uuidString
        title = dbItem.title
        content = dbItem.content
        platform = dbItem.platform
        accessToken = isAdmin ? dbItem.accessToken : ""
        createdAt = dbItem.createdAt ?? Date(timeIntervalSince1970: 0)
        updatedAt = dbItem.updatedAt ?? createdAt
    }
}

extension AppPackageModel.Item {
    
    init(dbItem: AppPackage, svc: AppService, baseURL: String) throws {
        id = try dbItem.requireID().uuidString
        appId = dbItem.appId.uuidString
        title = dbItem.title
        content = dbItem.content
        platform = dbItem.platform
        appBundleId = dbItem.appBundleId
        appVersion = dbItem.appVersion
        appBuild = dbItem.appBuild
        createdAt = dbItem.createdAt ?? Date(timeIntervalSince1970: 0)
        updatedAt = dbItem.updatedAt ?? createdAt
        authorAt = dbItem.authorAt ?? updatedAt
        url = try svc.getInstallURL(package: dbItem, baseURL: baseURL)
    }
}

#if os(Linux)

final class AppPackageObjC: NSObject {
    
    let package: AppPackage
    
    @objc dynamic var authorAt: Date? { package.authorAt }
    
    @objc dynamic var updatedAt: Date? { package.updatedAt }
    
    init(_ package: AppPackage) {
        self.package = package
        super.init()
    }
}

#endif
