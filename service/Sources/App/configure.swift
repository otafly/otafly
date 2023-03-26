import Fluent
import FluentMySQLDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
#if DEBUG
    app.middleware.use(CorsMiddleware())
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
#endif
    
    app.views.use(.leaf)
    
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init(_:)) ?? 8080
    
    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = .none
    
    app.databases.use(.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "127.0.0.1",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? MySQLConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "",
        database: Environment.get("DATABASE_NAME") ?? "otafly",
        tlsConfiguration: tls
    ), as: .mysql)
    
    app.migrations.add(CreateAppMeta(), CreateAppPackage())
    try app.autoMigrate().wait()
    
    app.queues.schedule(CleanupJob()).hourly().at(0)
    try app.queues.startScheduledJobs()
    
    try routes(app)
}

let singleton = Singleton()

extension Application {
    
    var appSvc: AppService {
        singleton.create {
            AppService(app: self)
        }
    }
}

private class CorsMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.add(name: "Access-Control-Allow-Origin", value: "*")
            response.headers.add(name: "Access-Control-Allow-Headers", value: "Content-Type")
            response.headers.add(name: "Access-Control-Allow-Methods", value: "GET, POST, PUT, DELETE, OPTIONS")
            return response
        }
    }
}

extension NonBlockingFileIO {
    
    static var `default`: NonBlockingFileIO = {
        let pool = NIOThreadPool(numberOfThreads: Self.defaultThreadPoolSize)
        pool.start()
        return NonBlockingFileIO(threadPool: pool)
    }()
}
