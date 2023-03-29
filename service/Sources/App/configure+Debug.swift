#if DEBUG

import Foundation
import Vapor

extension Application {
    
    func setupCors() {
        middleware = .init()
        middleware.use(ErrorMiddleware.custom(environment: environment))
        middleware.use(CorsMiddleware())
    }
}

private class CorsMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard request.method == .OPTIONS else {
            return next.respond(to: request).map { response in
                response.headers.setupCors()
                return response
            }
        }
        var headers = HTTPHeaders()
        headers.setupCors()
        return request.eventLoop.makeSucceededFuture(Response(status: .ok, headers: headers))
    }
}



private extension HTTPHeaders {
    
    mutating func setupCors() {
        add(name: "Access-Control-Allow-Origin", value: "http://localhost:3000")
        add(name: "Access-Control-Allow-Headers", value: "Content-Type, Authorization")
        add(name: "Access-Control-Allow-Methods", value: "GET, POST, PUT, DELETE, OPTIONS")
    }
}

private extension ErrorMiddleware {
    
    struct CustomErrorResponse: Codable {
        /// Always `true` to indicate this is a non-typical JSON response.
        var error: Bool

        /// The reason for the error.
        var reason: String
    }
    
    static func custom(environment: Environment) -> ErrorMiddleware {
        return .init { req, error in
            // variables to determine
            let status: HTTPResponseStatus
            let reason: String
            var headers: HTTPHeaders

            // inspect the error type
            switch error {
            case let abort as AbortError:
                // this is an abort error, we should use its status, reason, and headers
                reason = abort.reason
                status = abort.status
                headers = abort.headers
            default:
                // if not release mode, and error is debuggable, provide debug info
                // otherwise, deliver a generic 500 to avoid exposing any sensitive error info
                reason = environment.isRelease
                    ? "Something went wrong."
                    : String(describing: error)
                status = .internalServerError
                headers = [:]
            }
            
            headers.setupCors()
            
            // Report the error to logger.
            req.logger.report(error: error)
            
            // create a Response with appropriate status
            let response = Response(status: status, headers: headers)
            
            // attempt to serialize the error to json
            do {
                let errorResponse = CustomErrorResponse(error: true, reason: reason)
                response.body = try .init(data: JSONEncoder().encode(errorResponse), byteBufferAllocator: req.byteBufferAllocator)
                response.headers.replaceOrAdd(name: .contentType, value: "application/json; charset=utf-8")
            } catch {
                response.body = .init(string: "Oops: \(error)", byteBufferAllocator: req.byteBufferAllocator)
                response.headers.replaceOrAdd(name: .contentType, value: "text/plain; charset=utf-8")
            }
            return response
        }
    }
}

#endif
