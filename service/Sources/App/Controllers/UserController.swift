import Fluent
import Vapor

struct UserController: RouteCollection {
    
    let app: Application
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("api", "user", use: get)
    }
    
    func get(req: Request) throws -> User {
        try req.auth.require()
    }
}
