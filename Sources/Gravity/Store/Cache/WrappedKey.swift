//
//  File.swift
//  
//
//  Created by Arthur Guiot on 23/03/2023.
//

import Foundation

extension Cache {
    final class WrappedKey<ID: Codable & Hashable>: NSObject {
        let key: ID
        
        init(_ key: ID) { self.key = key }
        
        override var hash: Int { return key.hashValue }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }
            
            return value.key == key
        }
    }

    final class WrappedKeys<ID: Codable & Hashable>: NSObject, Codable {
        var keys: Set<ID>
        
        init(_ keys: Set<ID>) { self.keys = keys }
        
        override var hash: Int { return keys.hashValue }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKeys else {
                return false
            }
            
            return value.keys == keys
        }
    }
}
