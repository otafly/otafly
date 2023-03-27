import Fluent
import Vapor

struct WebRouteController: RouteCollection {
    
    let app: Application
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
        ["setting"].forEach {
            routes.get($0, use: index)
        }
    }
    
    func index(req: Request) -> Response {
        req.fileio.streamFile(at: req.application.directory.publicDirectory + "index.html")
    }
}
