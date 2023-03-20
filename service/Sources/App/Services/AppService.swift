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
        let baseURL = URL(fileURLWithPath: app.directory.publicDirectory).appendingPathComponent("archives")
        storage = FileStorage(baseURL: baseURL)
    }
    
    func query() async throws -> [AppMeta] {
        let dbQuery = AppMeta.query(on: app.db)
        return try await dbQuery.sort(\.$updatedAt, .descending).all()
    }
    
    func get(id: UUID) async throws -> AppMeta? {
        try await AppMeta.find(id, on: app.db)
    }
    
    func create(form: AppMetaForm) async throws {
        let dbItem = AppMeta(title: form.title, content: form.content ?? "", platform: form.platform)
        try await dbItem.save(on: app.db)
    }
    
    func cleanup() async {
        
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
