import Fluent
import Vapor

struct AppPackageController: RouteCollection {
    
    let app: Application
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("api", "app", "packages", use: query)
        let package = routes.grouped("api", "app", "package")
        package.group(":id") { package in
            package.get(use: get)
            package.get("manifest", use: getManifest)
        }
    }
    
    func query(req: Request) async throws -> AppMetaViewModel {
        let items = try await app.appSvc.queryMeta()
        return try .init(items: items.map { try .init(dbItem: $0) })
    }
    
    func get(req: Request) async throws -> AppMetaViewModel.Item {
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
    
    func getManifest(req: Request) async throws -> Response {
        guard let idString = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "missing app package id")
        }
        guard let id = UUID(uuidString: idString) else {
            throw Abort(.badRequest, reason: "wrong id format: \(idString)")
        }
        guard let xml = try await app.appSvc.getPackageManifestXml(id: id, baseURL: req.baseURL) else {
            throw Abort(.notFound)
        }
        let body = Response.Body(data: xml)
        let response = Response(status: .ok, body: body)
        response.headers.contentType = .xml
        return response
    }
    
    func create(req: Request) async throws -> HTTPStatus {
        let form = try req.content.decode(AppMetaForm.self)
        try await app.appSvc.createMeta(form: form)
        return .created
    }
}
