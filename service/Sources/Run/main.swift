import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)

defer { app.shutdown() }
try configure(app)

#if DEBUG && Xcode
import Cocoa

let configuration = app.http.server.configuration
let scheme = configuration.tlsConfiguration == nil ? "http" : "https"
switch configuration.address {
case .hostname(let hostname, let port):
    let urlString = "\(scheme)://\(hostname ?? configuration.hostname):\(port ?? configuration.port)"
    let url = URL(string: urlString)!
    DispatchQueue.global().async {
        NSWorkspace.shared.open(url)
    }
default: break
}
#endif

try app.run()
