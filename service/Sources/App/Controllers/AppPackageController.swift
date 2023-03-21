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
        guard let boundary = req.headers.contentType?.parameters["boundary"] else {
            throw Abort(.unsupportedMediaType)
        }

        let parser = MultipartParser(boundary: boundary)
        
        var parts = [MultipartPart]()
        var headers = HTTPHeaders()
        var data = ByteBuffer()

        parser.onHeader = { (field, value) in
            headers.replaceOrAdd(name: field, value: value)
        }
        parser.onBody = { new in
            data.writeBuffer(&new)
        }
        parser.onPartComplete = {
            let part = MultipartPart(headers: headers, body: data)
            headers = [:]
            data = ByteBuffer()
            parts.append(part)
        }
        await parser.drain(req: req)
        return .created
    }
}


extension MultipartParser {
    
    func drain(req: Request) async {
        return await withCheckedContinuation { continuation in
            req.body.drain {
                switch $0 {
                case .buffer(let buffer):
                    do {
                        try self.execute(buffer)
                    } catch {}
                    return req.eventLoop.makeSucceededFuture(())
                case .error:
                    continuation.resume(returning: ())
                    return req.eventLoop.makeSucceededFuture(())
                case .end:
                    continuation.resume(returning: ())
                    return req.eventLoop.makeSucceededFuture(())
                }
            }
        }
    }
}
