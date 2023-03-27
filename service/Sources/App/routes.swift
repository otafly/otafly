import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    try app.register(collection: WebRouteController(app: app))
    try app.register(collection: AppMetaController(app: app))
    try app.register(collection: AppPackageController(app: app))
}
