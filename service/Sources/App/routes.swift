import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    app.get { req in
        req.redirect(to: "index.html")
    }

    try app.register(collection: AppMetaController(app: app))
}
