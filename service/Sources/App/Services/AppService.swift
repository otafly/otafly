import Vapor
import Fluent

struct AppMetaViewModel: Content {
    
    struct Item: Content {
        let id: String
        let title: String
        let content: String
        let platform: Platform
        let accessToken: String
        let createdAt: Date
        let updatedAt: Date
    }
    
    let items: [Item]
}

struct AppMetaForm: Content {
    
    let title: String
    let content: String?
    let platform: Platform
}

class AppService {
    
    private let app: Application
    private let storage: FileStorage
    
    init(app: Application) {
        self.app = app
        storage = FileStorage(name: "archives", dir: app.directory.publicDirectory)
    }
    
    func queryMeta() async throws -> [AppMeta] {
        let dbQuery = AppMeta.query(on: app.db)
        return try await dbQuery.sort(\.$updatedAt, .descending).all()
    }
    
    func getMeta(id: UUID) async throws -> AppMeta? {
        try await AppMeta.find(id, on: app.db)
    }
    
    func createMeta(form: AppMetaForm) async throws {
        let dbItem = AppMeta(title: form.title, content: form.content ?? "", platform: form.platform)
        try await dbItem.save(on: app.db)
    }
    
    func cleanup() async {
        
    }
    
    func getPackageManifestXml(id: UUID, baseURL: String) async throws -> Data? {
        guard let package = try await AppPackage.find(id, on: app.db) else { return nil }
        guard let idString = package.id?.uuidString else { return nil }
        let url = baseURL + storage.relativeUrl(id: idString)
        
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
                        "title": "Panda"
                    ]
                ]
            ]
        ]
        return try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
    }
}

extension AppMetaViewModel.Item {
    
    init(dbItem: AppMeta) throws {
        id = try dbItem.requireID().uuidString
        title = dbItem.title
        content = dbItem.content
        platform = dbItem.platform
        accessToken = dbItem.accessToken
        createdAt = dbItem.createdAt ?? Date(timeIntervalSince1970: 0)
        updatedAt = dbItem.updatedAt ?? createdAt
    }
}
