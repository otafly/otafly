import Foundation
import Vapor

struct UserAuthenticator: AsyncBasicAuthenticator {
    typealias User = App.User
    
    let username: String
    let password: String
    
    init() {
        username = Environment.get("ADMIN_USERNAME") ?? ""
        password = Environment.get("ADMIN_PASSWORD") ?? ""
    }
    
    func authenticate(basic: BasicAuthorization, for request: Request) async throws {
        let hashed = try hash(password: basic.password)
        if basic.username == username && hashed == password {
            request.auth.login(User(name: basic.username))
        }
    }
    
    private func hash(password: String) throws -> String {
        guard let hashed = (password + "otafly").sha256 else {
            throw Abort(.internalServerError)
        }
        return hashed
    }
}

struct User: Content, Authenticatable {
    
    let name: String
}
