//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import SwiftUI

@available(OSX 10.15, *)
public class StateResponse<Key, Value>: ObservableObject where Key: Hashable {
    public var awaiting: Bool {
        return data == nil
    }
    
    @Published public var error: Error? = nil
    @Published public var data: Value? = nil
    
    internal let identifier: Key
    
    /// Create StateResponse
    init(key: Key, data: Value? = nil, error: Error? = nil) {
        self.data = data
        self.error = error
        self.identifier = key
    }
    /// Revalidate current SWR
    public func revalidate(mutated: Value? = nil, makeRequest: Bool = true) {
        // Hasher
        var hasher = Hasher()
        self.identifier.hash(into: &hasher)
        let id = hasher.finalize()
        
        var dictionary: [String: Any] = [
            "makeRequest": makeRequest
        ]
        
        if mutated != nil {
            dictionary["mutated"] = mutated!
        }
        Cache.shared.notification.post(name: .init(String(id)), object: nil, userInfo: dictionary)
    }
}

enum SWRError: LocalizedError {
    /// SWR couldn't retreive data from cache
    case CacheError
    /// SWR couldn't decode data
    case DecodeError
    /// SWR couldn't encode data
    case EncodeError
    /// SWR couldn't fetch data
    case FetchError
}
