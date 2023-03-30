import Fluent
import Vapor

struct AppMetaController: RouteCollection {
    
    let app: Application
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("api", "app", "metas", use: query)
        let meta = routes.grouped("api", "app", "meta")
        meta.group(":id") { meta in
            meta.get(use: get)
        }
        meta.post(use: create)
    }
    
    func query(req: Request) async throws -> AppMetaModel {
        try await .init(items: app.appSvc.queryMeta().map {
            try .init(dbItem: $0, isAdmin: true)
        })
    }
    
    func get(req: Request) async throws -> AppMetaModel.Item {
        guard let idString = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "missing app meta id")
        }
        guard let id = UUID(uuidString: idString) else {
            throw Abort(.badRequest, reason: "wrong id format: \(idString)")
        }
        let item = try await app.appSvc.getMeta(id: id)
        guard let item else {
            throw Abort(.notFound)
        }
        return try .init(dbItem: item)
    }
    
    func create(req: Request) async throws -> HTTPStatus {
        let form = try req.content.decode(AppMetaForm.self)
        try await app.appSvc.createMeta(form: form)
        return .created
    }
}

struct AppMetaModel: Content {
    
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
