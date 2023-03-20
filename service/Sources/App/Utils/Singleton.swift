import Foundation

class Singleton {
    
    private var cache: [ObjectIdentifier: AnyObject] = [:]
    private let locker = NSLock()
    
    func create<T: AnyObject>(_ creator: () -> T) -> T {
        let id = ObjectIdentifier(T.self)
        if let obj = cache[id] { return obj as! T }
        defer { locker.unlock() }
        locker.lock()
        if let obj = cache[id] { return obj as! T }
        let obj = creator()
        cache[id] = obj
        return obj
    }
}

