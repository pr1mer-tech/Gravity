//
//  StateResponse.swift
//  
//
//  Created by Arthur Guiot on 4/27/21.
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
}
