
import Foundation
import Vapor


extension Request {
    
    var baseURL: String {
        let scheme = headers[.xForwardedProto].first ?? "https"
        let host = headers[.xForwardedHost].first ?? "127.0.0.1"
        let port = headers[.xForwardedPort].first.map { ":" + $0 } ?? ""
        return "\(scheme)://\(host)\(port)"
    }
}

extension HTTPHeaders.Name {
    
    static let xForwardedPort = HTTPHeaders.Name("X-Forwarded-Port")
}
