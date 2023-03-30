import Vapor
import SQLKit
import Fluent
import MultipartKit

class AppService {
    
    let app: Application
    let storage: FileStorage
    
    init(app: Application) {
        self.app = app
        storage = FileStorage(packageDir: app.baseDir.appendingPathComponent("packages"))
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
    
    func queryLatestPackages() async throws -> [AppPackage] {
        guard let sql = app.db as? SQLDatabase else {
            throw Abort(.internalServerError)
        }
        return try await sql.raw("SELECT p.* FROM app_meta m INNER JOIN app_package p ON p.app_meta_id = m.id WHERE p.id = (SELECT id FROM app_package WHERE app_meta_id = m.id ORDER BY updated_at DESC LIMIT 1) ORDER BY p.author_at DESC, p.updated_at DESC")
            .all(decoding: AppPackage.self)
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
        guard let meta = try await findMeta(accessToken: accessToken) else {
            throw Abort(.badRequest, reason: "invalid token")
        }
        let info = try meta.platform.packageResolver.extract(tempFileURL)
        let package = try AppPackage(id: UUID(), appMeta: meta, info: info, content: content, authorAt: date)
        let dest = storage.localUrlFor(id: try package.requireID().uuidString)
        try FileManager.default.moveItem(at: tempFileURL, to: dest)
        try await package.save(on: app.db)
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
                        "title": package.title
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
