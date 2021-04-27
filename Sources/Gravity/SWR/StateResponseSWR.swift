//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import SwiftUI

public extension StateResponse {
    /// Revalidate current SWR
    func revalidate(mutated: Value? = nil, makeRequest: Bool = true) {
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

enum GravityError: LocalizedError {
    /// SWR couldn't decode data
    case DecodeError
    /// SWR couldn't encode data
    case EncodeError
    /// SWR couldn't fetch data
    case FetchError
}
