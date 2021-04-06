//
//  File.swift
//  
//
//  Created by Arthur Guiot on 4/4/21.
//

import SwiftUI

@available(OSX 10.15, *)
public class StateResponse<Value>: ObservableObject {
    public var awaiting: Bool {
        return data == nil
    }
    
    @Published public var error: Error? = nil
    @Published public var data: Value? = nil
    
    internal let identifier: Int?
    
    /// Create StateResponse
    init(id: Int? = nil, data: Value? = nil, error: Error? = nil) {
        self.data = data
        self.error = error
        self.identifier = id
    }
    /// Revalidate current SWR
    public func revalidate(mutated: Value? = nil) {
        guard let id = identifier else { return }
        Cache.shared.notification.post(name: .init(String(id)), object: nil)
        guard let mutated = mutated else { return }
        self.data = mutated
    }
}

enum SWRError: LocalizedError {
    /// SWR couldn't retreive data from cache
    case CacheError
}
