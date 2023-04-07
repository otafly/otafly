import Fluent
import Vapor
import MultipartKit

struct AppPackageController: RouteCollection {
    
    let app: Application
    let formResolver: FormDataResolver
    
    var storage: FileStorage { app.appSvc.storage }
    
    init(app: Application) {
        self.app = app
        formResolver = FormDataResolver(tempDir: app.baseDir.appendingPathComponent("temp"))
    }
    
    func boot(routes: RoutesBuilder) throws {
        let packages = routes.grouped("api", "app", "packages")
        packages.get(use: query)
        packages.get("latest", use: queryLatest)
        
        let package = routes.grouped("api", "app", "package")
        package.group(":id") { package in
            package.get(use: get)
            package.get("manifest", use: getManifest)
            package.get("download", use: download)
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
        guard let appId = query.appId else {
            throw Abort(.badRequest, reason: "missing appId")
        }
        guard let id = UUID(uuidString: appId) else {
            throw Abort(.badRequest, reason: "wrong appId format: \(appId)")
        }
        async let appTask = app.appSvc.getMeta(id: id)
        async let packagesTask = app.appSvc.queryPackages(appId: id)
        let (appMeta, packages) = try await (appTask, packagesTask)
        return try packages.mapToModel(req: req, appMeta: appMeta)
    }
    
    func create(req: Request) async throws -> HTTPStatus {
        var token: String?
        var content: String?
        var tempURL: URL?
        var date: Date?
        
        for try await (name, value) in try await formResolver.resolve(req: req) {
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
                case "date":
                    if let value {
                        if let interval = TimeInterval(value) {
                            date = Date(timeIntervalSince1970: interval)
                        } else {
                            throw Abort(.badRequest, reason: "wrong format of date: \(value)")
                        }
                    }
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
        try await app.appSvc.createPackage(accessToken: token, content: content, date: date, tempFileURL: tempURL)
        return .created
    }
    
    func queryLatest(req: Request) async throws -> AppPackageModel {
        let query = try req.query.decode(AppPackageModel.Query.self)
        return try await app.appSvc
            .queryLatestPackages(platform: query.platform.toValue(req: req))
            .mapToModel(req: req)
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
    
    func download(req: Request) async throws -> Response {
        guard let idString = req.parameters.get("id") else {
            throw Abort(.badRequest, reason: "missing app package id")
        }
        guard let id = UUID(uuidString: idString) else {
            throw Abort(.badRequest, reason: "wrong id format: \(idString)")
        }
        guard let package = try await app.appSvc.getPackage(id: id) else {
            throw Abort(.notFound)
        }
        let resp = req.fileio.streamFile(at: storage.localUrlFor(id: idString).path, mediaType: .binary)
        resp.headers.contentDisposition = .init(.attachment, filename: package.appDisplayName + package.platform.packageExtension)
        return resp
    }
}

struct AppPackageModel: Content {
    
    enum QueryPlatform: String, Content {
        case all
        case ios
        case android
    }
    
    struct Query: Content {
        let appId: String?
        let platform: QueryPlatform?
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
        let authorAt: Date
        let createdAt: Date
        let updatedAt: Date
    }
    
    let items: [Item]
    
    let app: AppMetaModel.Item?
}

private extension Request {
    
    var platformFromAgent: Platform? {
        guard let userAgent = headers[.userAgent].first else { return nil }
        if userAgent.contains("iPhone") || userAgent.contains("iPad") { return .ios }
        if userAgent.contains("Android") { return .android }
        return nil
    }
}

private extension Optional<AppPackageModel.QueryPlatform> {
    
    func toValue(req: Request) -> Platform? {
        switch self {
        case .none: return req.platformFromAgent
        case .all: return nil
        case .ios: return .ios
        case .android: return .android
        }
    }
}

private extension Sequence where Element == AppPackage {
    
    func mapToModel(req: Request, appMeta: AppMeta? = nil) throws -> AppPackageModel {
        let svc = req.application.appSvc
        let baseURL = req.baseURLFromForwarded(app: req.application)
        let isAdmin = req.auth.has(User.self)
        return .init(
            items: try map {
                try .init(dbItem: $0, svc: svc, baseURL: baseURL)
            },
            app: try appMeta.map {
                try .init(dbItem: $0, isAdmin: isAdmin)
            })
    }
}

private extension AppPackage {
    
    func mapToModel(req: Request) throws -> AppPackageModel.Item {
        try .init(
            dbItem: self,
            svc: req.application.appSvc,
            baseURL: req.baseURLFromForwarded(app: req.application))
    }
}

private extension Platform {

    var packageExtension: String {
        switch self {
        case .ios: return ".ipa"
        case .android: return ".apk"
        }
    }
}
