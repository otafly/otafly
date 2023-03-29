
import Foundation
import Vapor

extension Request {
    
    func baseURLFromForwarded(app: Application) -> String {
#if DEBUG
        let scheme = headers[.xForwardedProto].first ?? "http"
        let host = headers[.xForwardedHost].first ?? app.http.server.configuration.hostname
        let port = headers[.xForwardedPort].first.map { ":" + $0 } ?? ":" + String(app.http.server.configuration.port)
#else
        let scheme = headers[.xForwardedProto].first ?? "https"
        let host = headers[.xForwardedHost].first ?? "127.0.0.1"
        let port = headers[.xForwardedPort].first.map { ":" + $0 } ?? ""
#endif
        return "\(scheme)://\(host)\(port)"
    }
}

extension HTTPHeaders.Name {
    
    static let xForwardedPort = HTTPHeaders.Name("X-Forwarded-Port")
}

extension String {

    var searchRange: NSRange {
        .init(location: .zero, length: (self as NSString).length)
    }
    
    var urlDecoded: String? {
        replacingOccurrences(of: "+", with: "%20").removingPercentEncoding
    }
}
