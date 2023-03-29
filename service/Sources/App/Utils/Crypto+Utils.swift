import Foundation
import Crypto

extension String {
    
    public var sha256: String? {
        return data(using: .utf8)?.sha256
    }
}

extension Data {

    public var sha256: String {
        Crypto.SHA256.hash(data: self).map { String(format: "%02x", $0) }.joined()
    }
}
