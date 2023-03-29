import Fluent
import Vapor
import MultipartKit

struct AppPackageController: RouteCollection {
    
    let app: Application
    
    func boot(routes: RoutesBuilder) throws {
        let packages = routes.grouped("api", "app", "packages")
        packages.get(use: query)
        packages.get("latest", use: queryLatest)
        
        let package = routes.grouped("api", "app", "package")
        package.group(":id") { package in
            package.get(use: get)
            package.get("manifest", use: getManifest)
        }
        package.on(.POST, body: .stream, use: create)
    }
    
    func get(req: Request) async throws -> AppPackageModel.Item {
        guard let idString = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "missing app package id")
        }
        guard let id = UUID(uuidString: idString) else {
            throw Abort(.badRequest, reason: "wrong id format: \(idString)")
        }
        guard let item = try await app.appSvc.getPackage(id: id)?.mapToModel(req: req) else {
            throw Abort(.notFound)
        }
        return item
    }
    
    func query(req: Request) async throws -> AppPackageModel {
        let query = try req.query.decode(AppPackageModel.Query.self)
        guard let id = UUID(uuidString: query.appId) else {
            throw Abort(.badRequest, reason: "wrong appId format: \(query.appId)")
        }
        return try await app.appSvc.queryPackages(appId: id).mapToModel(req: req)
    }
    
    func create(req: Request) async throws -> HTTPStatus {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw Abort(.internalServerError, reason: "cachesDirectory not found")
        }
        let resolver = FormDataResolver(cacheURL: cacheURL.appendingPathComponent("otafly"))
        
        var token: String?
        var content: String?
        var tempURL: URL?
        
        for try await (name, value) in try await resolver.resolve(req: req) {
            switch value {
            case .text(let value):
                switch name {
                case "token":
                    guard let value else {
                        throw Abort(.badRequest, reason: "missing token")
                    }
                    token = value
                case "content":
                    content = value
                default: continue
                }
            case .file(let url):
                if name == "file" {
                    tempURL = url
                }
            }
        }
        guard let token else {
            throw Abort(.badRequest, reason: "missing token")
        }
        guard let tempURL else {
            throw Abort(.badRequest, reason: "missing file")
        }
        try await app.appSvc.createPackage(accessToken: token, content: content, tempFileURL: tempURL)
        return .created
    }
    
    func queryLatest(req: Request) async throws -> AppPackageModel {
        try await app.appSvc.queryLatestPackages().mapToModel(req: req)
    }
    
    func getManifest(req: Request) async throws -> Response {
        guard let idString = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "missing app package id")
        }
        guard let id = UUID(uuidString: idString) else {
            throw Abort(.badRequest, reason: "wrong id format: \(idString)")
        }
        guard let plist = try await app.appSvc.getPackageManifestXml(id: id, baseURL: req.baseURLFromForwarded(app: app)) else {
            throw Abort(.notFound)
        }
        let body = Response.Body(data: plist)
        let response = Response(status: .ok, body: body)
        response.headers.contentDisposition = .init(.attachment, filename: "manifest.plist")
        response.headers.contentType = .xml
        return response
    }
}

struct AppPackageModel: Content {
    
    struct Query: Content {
        let appId: String
    }
    
    struct Item: Content {
        let id: String
        let appId: String
        let url: String
        let title: String
        let content: String
        let platform: Platform
        let appBundleId: String
        let appVersion: String
        let appBuild: String
        let createdAt: Date
        let updatedAt: Date
    }
    
    let items: [Item]
}

private extension Sequence where Element == AppPackage {
    
    func mapToModel(req: Request) throws -> AppPackageModel {
        let svc = req.application.appSvc
        let baseURL = req.baseURLFromForwarded(app: req.application)
        return AppPackageModel(items: try self.map {
            try AppPackageModel.Item(dbItem: $0, svc: svc, baseURL: baseURL)
        })
    }
}

private extension AppPackage {
    
    func mapToModel(req: Request) throws -> AppPackageModel.Item {
        try AppPackageModel.Item(
            dbItem: self,
            svc: req.application.appSvc,
            baseURL: req.baseURLFromForwarded(app: req.application))
    }
}
