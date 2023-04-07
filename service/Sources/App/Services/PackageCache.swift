import Foundation
import FluentKit

actor ModelCache<T> {
    
    var cache = [String: T]()
    
    func set(key: String, model: T) {
        cache[key] = model
    }
    
    func get(key: String) -> T? {
        cache[key]
    }
    
    func remove(key: String) {
        cache.removeValue(forKey: key)
    }
}
