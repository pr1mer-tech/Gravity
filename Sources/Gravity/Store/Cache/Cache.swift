//
//  Database.swift
//  
//
//  Created by Arthur Guiot on 22/03/2023.
//

import CoreData
import Foundation

final class Cache<Element> where Element: RemoteRepresentable {
    typealias Key = Element.ID
    typealias Value = Element
    
    let entryCache = NSCache<WrappedKey<Key>, Entry>()
    
    
    private let dateProvider: () -> Date
    var entryLifetime: TimeInterval
    private let keyTracker = KeyTracker()
    
    internal var reference: String
    
    internal init(reference: String,
         dateProvider: @escaping () -> Date = Date.init,
         entryLifetime: TimeInterval = 12 * 60 * 60,
         maximumEntryCount: Int = 50) {
        self.reference = reference
        self.dateProvider = dateProvider
        self.entryLifetime = entryLifetime
        entryCache.countLimit = maximumEntryCount
        entryCache.delegate = keyTracker
    }
    
    deinit {
        try? self.saveToDisk()
    }
    
    func insert(_ value: Value, with request: RemoteRequest<Key>) {
        let date = dateProvider().addingTimeInterval(entryLifetime)
        let entry = Entry(value: value, expirationDate: date)
        entryCache.setObject(entry, forKey: WrappedKey(value.id))
        let reqIds = request.ids
        if keyTracker.requestCache[reqIds] == nil {
            keyTracker.requestCache[reqIds] = WrappedKeys(.init(arrayLiteral: value.id))
        } else {
            keyTracker.requestCache[reqIds]?.keys.insert(value.id)
        }
        keyTracker.keys.insert(value.id)
    }
    
    func value(forKey key: Key) -> Value? {
        guard let entry = entryCache.object(forKey: WrappedKey(key)) else {
            return nil
        }
        
        guard dateProvider() < entry.expirationDate else {
            // Discard values that have expired
            removeValue(forKey: key)
            return nil
        }
        
        return entry.value
    }
    
    func keys(forRequest request: RemoteRequest<Key>) -> [Key]? {
        guard let keys = keyTracker.requestCache[request.ids]?.keys else { return nil }
        return Array(keys)
    }
    
    func removeValue(forKey key: Key, silently: Bool = false) {
        if silently {
            self.keyTracker.keys.remove(key)
            self.keyTracker.requestCache.forEach { $1.keys.remove(key) }
        }
        entryCache.removeObject(forKey: WrappedKey(key))
    }
    
    var allKeys: [Key]? {
        let keys = keyTracker.keys
        guard !keys.isEmpty else { return nil }
        return Array(keys)
    }
}

extension Cache {
    final class Entry: Codable, Equatable {
        static func == (lhs: Cache<Element>.Entry, rhs: Cache<Element>.Entry) -> Bool {
            guard lhs.value.id == rhs.value.id else { return false }
            return true
        }
        
        let value: Value
        let expirationDate: Date
        
        init(value: Value, expirationDate: Date) {
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}

private extension Cache {
    final class KeyTracker: NSObject, NSCacheDelegate {
        var keys = Set<Key>()
        
        var requestCache = Dictionary<[Key], WrappedKeys<Key>>()
        
        func cache(_ cache: NSCache<AnyObject, AnyObject>,
                   willEvictObject object: Any) {
            guard let entry = object as? Entry else {
                return
            }
            
            keys.remove(entry.value.id)
            requestCache = requestCache.filter { !$1.keys.contains(entry.value.id) } // Removing all request where entry was dropped
        }
    }
}

extension Cache: Codable {
    fileprivate func insert(entry: Entry) {
        entryCache.setObject(entry, forKey: WrappedKey(entry.value.id))
        keyTracker.keys.insert(entry.value.id)
    }
    fileprivate func entry(forKey key: Key) -> Entry? {
        guard let entry = entryCache.object(forKey: WrappedKey(key)) else {
            return nil
        }
        
        guard dateProvider() < entry.expirationDate else {
            removeValue(forKey: key)
            return nil
        }
        
        return entry
    }
    
    private enum CodingKeys: String, CodingKey {
        case entries
        case requestCache
        case entryLifetime
        case maximumEntryCount
        case reference
    }

    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let reference = try container.decode(String.self, forKey: .reference)
        let entryLifetime = try container.decode(TimeInterval.self, forKey: .entryLifetime)
        let maximumEntryCount = try container.decode(Int.self, forKey: .maximumEntryCount)
        
        self.init(reference: reference, entryLifetime: entryLifetime, maximumEntryCount: maximumEntryCount)
        
        let entries = try container.decode([Entry].self, forKey: .entries)
        entries.forEach(insert)
        keyTracker.requestCache = try container.decode(
            Dictionary<[Key], WrappedKeys<Key>>.self,
            forKey: .requestCache
        )
    }

    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyTracker.keys.compactMap(entry), forKey: .entries)
        try container.encode(keyTracker.requestCache, forKey: .requestCache)
        try container.encode(self.entryLifetime, forKey: .entryLifetime)
        try container.encode(self.entryCache.countLimit, forKey: .maximumEntryCount)
        try container.encode(self.reference, forKey: .reference)
    }
}


extension Cache: Equatable {
    static func == (lhs: Gravity.Cache<Element>, rhs: Gravity.Cache<Element>) -> Bool {
        guard lhs.keyTracker.keys.count == rhs.keyTracker.keys.count else { return false }
        // Use reduce to check if all keys are equal
        guard lhs.keyTracker.keys.reduce(true, { $0 && (rhs.entry(forKey: $1) == lhs.entry(forKey: $1)) }) else {
            return false
        }

        guard lhs.keyTracker.requestCache == rhs.keyTracker.requestCache else { return false }
        return true
    }
}
