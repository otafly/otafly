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
    
    func query(req: Request) async throws -> AppMetaViewModel {
        let items = try await app.appSvc.query()
        return try .init(items: items.map { try .init(dbItem: $0) })
    }
    
    func get(req: Request) async throws -> AppMetaViewModel.Item {
        guard let idString = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "missing app meta id")
        }
        guard let id = UUID(uuidString: idString) else {
            throw Abort(.badRequest, reason: "wrong id format: \(idString)")
        }
        let item = try await app.appSvc.get(id: id)
        guard let item else {
            throw Abort(.notFound)
        }
        return try .init(dbItem: item)
    }
    
    func create(req: Request) async throws -> HTTPStatus {
        let form = try req.content.decode(AppMetaForm.self)
        try await app.appSvc.create(form: form)
        return .created
    }
}
