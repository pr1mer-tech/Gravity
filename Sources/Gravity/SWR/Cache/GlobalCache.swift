//
//  GlobalCache.swift
//  SwiftSWR
//
//  Created by Arthur Guiot on 4/5/21.
//

import Foundation
import Combine

internal class SWRCache {
    public static var shared = SWRCache()
    
    let notification = NotificationCenter()
    
    struct CacheEntry {
        let timestamp: TimeInterval
        let data: Data
    }
    
    var cache: [Int: CacheEntry] = [:]
    var onGoing = [Int]()
    var queued: [Int: [(Data?, Error?) -> Void]] = [:]
    
    enum CacheError: Error {
        case invalidKey
    }
    /// Read from the cache
    func get<Key>(for location: Key) throws -> Data where Key: Hashable {
        // Hasher
        var hasher = Hasher()
        location.hash(into: &hasher)
        let key = hasher.finalize()
        
        guard let entry = cache[key] else { throw CacheError.invalidKey }
        return entry.data
    }
    /// Write to the cache
    func set<Key>(for location: Key, value: Data) where Key: Hashable {
        // Hasher
        var hasher = Hasher()
        location.hash(into: &hasher)
        let key = hasher.finalize()
        
        cache[key] = CacheEntry(timestamp: Date().timeIntervalSince1970,
                                data: value)
    }
    /// Fetch and store data in the cache
    public func request<Key, Value>(from location: Key, using fetcher: Fetcher<Key, Value>, completionHandler: @escaping (Data?, Error?) -> Void) {
        // Hasher
        var hasher = Hasher()
        location.hash(into: &hasher)
        let key = hasher.finalize()
        
        // Limit number of requests
        let now = Date().timeIntervalSince1970
        let then = cache[key]?.timestamp
        if then != nil && now - then! <= 1 {
            completionHandler(cache[key]?.data, nil)
            return
        }
        
        if onGoing.contains(key) {
            if queued[key] != nil {
                queued[key]?.append(completionHandler)
            } else {
                queued[key] = [completionHandler]
            }
            return
        }
        
        // Register task
        self.onGoing.append(key)
        // Start task
        do {
            try fetcher.fetch(location: location) { (data, error) in
                self.onGoing.removeAll { $0 == key } // Finish on going data task
                
                if let value = data {
                    self.set(for: location, value: value)
                }
                // Pass to callback
                completionHandler(data, error)
                // Pass to other callbacks
                self.queued[key]?.forEach { $0(data, error) }
                self.queued.removeValue(forKey: key)
            }
        } catch {
            self.onGoing.removeAll { $0 == key } // Finish on going data task
            // Pass to callback
            completionHandler(nil, error)
            // Pass to other callbacks
            self.queued[key]?.forEach { $0(nil, error) }
            self.queued.removeValue(forKey: key)
        }
    }
}
