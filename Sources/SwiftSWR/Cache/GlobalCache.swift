//
//  GlobalCache.swift
//  SwiftSWR
//
//  Created by Arthur Guiot on 4/5/21.
//

import Foundation
import Combine

public class Cache {
    public static var shared = Cache()
    
    let notification = NotificationCenter()
    
    struct RequestCache {
        let timestamp: TimeInterval
        let data: Data
    }
    
    var cache: [Int: RequestCache] = [:]
    var onGoing = [Int]()
    var queued: [Int: [(Data?, URLResponse?, Error?) -> Void]] = [:]
    
    enum CacheError: Error {
        case invalidKey
    }
    
    func get(key: Int) throws -> RequestCache {
        guard let entry = cache[key] else { throw CacheError.invalidKey }
        return entry
    }
    
    func set(key: Int, value: Data) {
        let now = Date().timeIntervalSinceReferenceDate
        cache[key] = RequestCache(timestamp: now, data: value)
    }
    
    public func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? {
        // Hasher
        var hasher = Hasher()
        url.hash(into: &hasher)
        let key = hasher.finalize()
        
        if onGoing.contains(key) {
            if queued[key] != nil {
                queued[key]?.append(completionHandler)
            } else {
                queued[key] = [completionHandler]
            }
            return nil
        }
        // URLTask
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            self.onGoing.removeAll { $0 == key } // Finish on going data task
            
            if let value = data {
                self.set(key: key, value: value)
            }
            // Pass to callback
            completionHandler(data, response, error)
            // Pass to other callbacks
            self.queued[key]?.forEach { $0(data, response, error) }
            self.queued.removeValue(forKey: key)
        }
        
        // Check cache
        let now = Date().timeIntervalSinceReferenceDate // Get TimeStamp
        guard let entry = try? get(key: key) else {
            self.onGoing.append(key)
            return task
        }
        let then = entry.timestamp
        guard now - then < 1 else {
            self.onGoing.append(key)
            return task
        }
        
        // Return from cache
        completionHandler(entry.data, nil, nil)
        
        return nil
    }
}
