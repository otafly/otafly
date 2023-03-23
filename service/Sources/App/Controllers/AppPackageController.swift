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
        guard let plist = try await app.appSvc.getPackageManifestXml(id: id, baseURL: req.baseURL) else {
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
        let resolver = FormDataResolver(cacheURL: cacheURL)
        for value in try await resolver.handle(req: req) {
            switch value {
            case .text(let item):
                print("\(item.name) value=\(item.value ?? "")")
            case .file(let item):
                print("\(item.name) file=\(item.tempFileURL.absoluteString)")
                try app.appSvc.createPackage(tempFileURL: item.tempFileURL)
            }
        }
        return .created
    }
}
