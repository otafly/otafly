import Fluent
import Vapor
import MultipartKit

struct AppPackageController: RouteCollection {
    
    let app: Application
    
    func boot(routes: RoutesBuilder) throws {
        //routes.get("api", "app", "packages", use: query)
        let package = routes.grouped("api", "app", "package")
        package.group(":id") { package in
            //package.get(use: get)
            package.get("manifest", use: getManifest)
        }
        package.on(.POST, body: .stream, use: create)
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
}
