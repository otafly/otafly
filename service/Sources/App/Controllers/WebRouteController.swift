import Fluent
import Vapor

struct WebRouteController: RouteCollection {
    
    let app: Application
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
        routes.get("view", .anything, use: index)
    }
    
    func index(req: Request) -> Response {
        req.fileio.streamFile(at: app.directory.publicDirectory + "index.html")
    }
}
