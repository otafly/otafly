import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    try app.register(collection: WebRouteController(app: app))
    try app.register(collection: AppPackageController(app: app))
    try AppMetaController(app: app).boot(routes: app.routes
        .grouped(UserAuthenticator())
        .grouped(User.guardMiddleware())
    )
    try UserController(app: app).boot(routes: app.routes
        .grouped(UserAuthenticator())
        .grouped(User.guardMiddleware())
    )
}
